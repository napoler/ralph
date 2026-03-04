#!/bin/bash
# ============================================
# Ralph - SPECKit 驱动 + 负载均衡
# 配置文件: ralph.conf
# 命令行参数优先于配置文件
# ============================================

set -e

# ---------- 解析命令行参数 ----------
# 必须先解析参数，因为有些参数会影响配置文件路径等

# 显示帮助
if [[ "$1" =~ (-h|--help|help) ]] || [ "$1" = "?" ]; then
    cat << EOF
Ralph - AI Agent Loop with Load Balancing

用法: $0 [选项] [任务]

选项:
  --tool AGENT          AI 工具: qwen, opencode, cline, kilocode, iflow, gemini
  --proxy URL            代理地址 (默认: http://192.168.123.194:20171)
  --project DIR         项目目录 (覆盖配置)
  --max N               最大迭代次数
  --log-dir DIR         日志目录
  --worktree-root DIR   工作树根目录
  --base-branch NAME    基础分支
  --no-load-balance     禁用负载均衡，使用指定工具
  --complete-signal SIG 完成信号 (默认: <promise>COMPLETE</promise>)
  --tmux                使用 tmux 会话执行 (为交互式工具提供真实的 TTY 并支持后台断线重连，大幅提高成功率)
  --scratch             在独立的临时空目录中执行 (防止 AI 读取项目无关文件跑题)
  
  status                显示任务状态
  run                 执行 prd.json 中的所有任务
  spec                  生成 SPEC.md
  
环境变量:
  RALPH_PROJECT_DIR, RALPH_TOOL, RALPH_MAX_ITERATIONS, etc.

示例:
  $0 --tool opencode --max 20
  $0 --project /path/to/project status
  RALPH_TOOL=opencode $0 "实现功能X"

Cron 示例:
  RALPH_PROJECT_DIR=/path/to/project RALPH_TOOL=opencode $0 --max 5
EOF
    exit 0
fi

# ---------- 默认值 (可被配置/环境变量/命令行覆盖) ----------
TOOL="qwen"
MAX_ITERATIONS=10
PROJECT_DIR=""
LOG_DIR=""
# Default: use /mnt/data/dev/tmp if exists, otherwise fallback to project-local .ralph/tmp
if [ -n "$TMPDIR" ]; then
    WORKTREE_ROOT="$TMPDIR/ralph-worktrees"
else
    WORKTREE_ROOT="/tmp/ralph-worktrees"
fi
BASE_BRANCH="dev"
LOAD_BALANCE="true"
COMPLETE_SIGNAL="<promise>COMPLETE</promise>"
PROXY=""  # 代理地址，从配置文件读取
USE_TMUX="false"
USE_SCRATCH="false"
USE_SUPERPOWERS="false"
TMUX_SOCKET="${TMPDIR:-/tmp}/ralph-agent.sock"

# 目录变量
SCRIPT_DIR=""
PRD_FILE=""
PROGRESS_FILE=""
ARCHIVE_DIR=""
SPECS_DIR=""




# ========== 通用 CLI 工具路径自动解析 ==========
# 检测所有可能的 CLI 工具路径（PATH, npm global, yarn global, etc.）

resolve_cli_tool() {
    local tool_name="$1"
    
    # 1. 优先使用 PATH 中的命令
    if command -v "$tool_name" &> /dev/null; then
        command -v "$tool_name"
        return 0
    fi
    
    # 2. 尝试 $HOME/.npm-global/bin
    if [ -f "$HOME/.npm-global/bin/$tool_name" ]; then
        echo "$HOME/.npm-global/bin/$tool_name"
        return 0
    fi
    
    # 3. 尝试 npm config prefix/bin
    local npm_prefix
    npm_prefix=$(npm config get prefix 2>/dev/null)
    if [ -n "$npm_prefix" ] && [ -f "$npm_prefix/bin/$tool_name" ]; then
        echo "$npm_prefix/bin/$tool_name"
        return 0
    fi
    
    # 4. 尝试 yarn global bin
    local yarn_bin
    yarn_bin=$(yarn global bin 2>/dev/null)
    if [ -n "$yarn_bin" ] && [ -f "$yarn_bin/$tool_name" ]; then
        echo "$yarn_bin/$tool_name"
        return 0
    fi
    
    # 5. 尝试 nvm 全局安装
    if [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/versions/node/current/bin/$tool_name" ]; then
        echo "$NVM_DIR/versions/node/current/bin/$tool_name"
        return 0
    fi
    
    # 6. 尝试 /usr/local/bin
    if [ -f "/usr/local/bin/$tool_name" ]; then
        echo "/usr/local/bin/$tool_name"
        return 0
    fi
    
    # 7. 回退到工具名（依赖 PATH）- 移除回退，如果真找不到就返回空
    return 1
}

# 初始化所有工具的路径
declare -A TOOL_PATHS
AVAILABLE_TOOLS=()
for tool in "qwen" "opencode" "cline" "kilocode" "iflow" "gemini" "codex" "claude" "pi"; do
    path=$(resolve_cli_tool "$tool" || true)
    if [ -n "$path" ]; then
        TOOL_PATHS["$tool"]="$path"
        AVAILABLE_TOOLS+=("$tool")
    fi
done

# 重写 VALID_TOOLS，确保仅包含已安装的工具
if [ ${#AVAILABLE_TOOLS[@]} -gt 0 ]; then
    VALID_TOOLS=("${AVAILABLE_TOOLS[@]}")
else
    VALID_TOOLS=()
fi

if [ ${#VALID_TOOLS[@]} -eq 0 ]; then
    echo "Warning: No supported AI tools found. Please install one of: qwen, opencode, cline, kilocode, iflow, gemini, codex, claude, pi."
fi


# 任务到工具的映射
declare -A TASK_MAPPING
TASK_MAPPING["shell"]="cline"
TASK_MAPPING["bash"]="cline"
TASK_MAPPING["script"]="cline"
TASK_MAPPING["review"]="opencode"
TASK_MAPPING["refactor"]="opencode"
TASK_MAPPING["analyze"]="opencode"
TASK_MAPPING["interactive"]="kilocode"
TASK_MAPPING["tui"]="kilocode"
TASK_MAPPING["project"]="kilocode"
TASK_MAPPING["github"]="kilocode"
TASK_MAPPING["pr"]="kilocode"
TASK_MAPPING["workflow"]="iflow"
TASK_MAPPING["pipeline"]="iflow"
TASK_MAPPING["data"]="iflow"
TASK_MAPPING["process"]="iflow"
TASK_MAPPING["default"]="qwen"
TASK_MAPPING["gemini"]="gemini"

# ---------- 解析命令行参数 ----------
COMMAND=""
DIRECT_TASK=""  # 直接传入的任务描述 (代替 prd.json)

while [[ $# -gt 0 ]]; do
    case $1 in
        # 主命令
        status|show)
            COMMAND="status"
            shift
            ;;
        auto|autodrive)
            COMMAND="auto"
            shift
            ;;
        run)
            COMMAND="run"
            shift
            ;;
        spec|generate-specs)
            COMMAND="spec"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        
        # 直接任务模式 (不使用 prd.json)
        --task|-t)
            DIRECT_TASK="$2"
            shift 2
            ;;
        --task=*)
            DIRECT_TASK="${1#*=}"
            shift
            ;;
        
        # 参数选项
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --tool=*)
            TOOL="${1#*=}"
            shift
            ;;
            
        --project|--project-dir|-p)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --project=*)
            PROJECT_DIR="${1#*=}"
            shift
            ;;
            
        --max|-m)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --max=*)
            MAX_ITERATIONS="${1#*=}"
            shift
            ;;
            
        --log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        --log-dir=*)
            LOG_DIR="${1#*=}"
            shift
            ;;
            
        --worktree-root)
            WORKTREE_ROOT="$2"
            shift 2
            ;;
        --worktree-root=*)
            WORKTREE_ROOT="${1#*=}"
            shift
            ;;
            
        --base-branch)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --base-branch=*)
            BASE_BRANCH="${1#*=}"
            shift
            ;;
            
        --complete-signal)
            COMPLETE_SIGNAL="$2"
            shift 2
            ;;
        --complete-signal=*)
            COMPLETE_SIGNAL="${1#*=}"
            shift
            ;;
            
        --tmux|-b)
            USE_TMUX="true"
            shift
            ;;

        --scratch)
            USE_SCRATCH="true"
            shift
            ;;

        --superpowers)
            USE_SUPERPOWERS="true"
            shift
            ;;

        --no-load-balance)
            LOAD_BALANCE="false"
            shift
            ;;
            
        --proxy)
            PROXY="$2"
            shift 2
            ;;
        --proxy=*)
            RALPH_PROXY="${1#*=}"
            shift
            ;;
            
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
            
        --)
            shift
            break
            ;;
            
        *)
            # 未知参数
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS="$1"
            fi
            shift
            ;;
    esac
done

# ---------- 加载配置文件 ----------
load_config() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 优先使用指定配置文件，否则查找 ralph.conf
    local config_file="${CONFIG_FILE:-$SCRIPT_DIR/ralph.conf}"
    
    # 保存是否从CLI传入参数的标记
    local cli_tool_provided=false
    local cli_max_provided=false
    local cli_project_provided=false
    local cli_log_provided=false
    local cli_worktree_provided=false
    local cli_base_provided=false
    local cli_load_balance_provided=false
    local cli_complete_provided=false
    local cli_proxy_provided=false
    
    # 同时保存CLI传入的值（用于后续恢复）
    local saved_tool="$TOOL"
    local saved_max="$MAX_ITERATIONS"
    local saved_project="$PROJECT_DIR"
    local saved_log="$LOG_DIR"
    local saved_worktree="$WORKTREE_ROOT"
    local saved_base="$BASE_BRANCH"
    local saved_load_balance="$LOAD_BALANCE"
    local saved_complete="$COMPLETE_SIGNAL"
    local saved_proxy="$PROXY"
    local saved_tmux="$USE_TMUX"
    local saved_scratch="$USE_SCRATCH"
    local saved_superpowers="$USE_SUPERPOWERS"
    
    # 保存用户设置的环境变量
    local env_project_dir="$RALPH_PROJECT_DIR"
    local env_tool="$RALPH_TOOL"
    local env_max_iterations="$RALPH_MAX_ITERATIONS"
    local env_log_dir="$RALPH_LOG_DIR"
    local env_worktree_root="$RALPH_WORKTREE_ROOT"
    local env_base_branch="$RALPH_BASE_BRANCH"
    local env_load_balance="$RALPH_LOAD_BALANCE"
    local env_complete_signal="$RALPH_COMPLETE_SIGNAL"
    local env_proxy="$RALPH_PROXY"
    
    # 如果变量值不同于默认值，说明是CLI传入的
    # CLI 参数检查（只有 CLI 显式传入时才标记为 provided）
    [ "$TOOL" != "qwen" ] && cli_tool_provided=true
    [ "$MAX_ITERATIONS" != "10" ] && cli_max_provided=true
    [ -n "$PROJECT_DIR" ] && cli_project_provided=true
    [ -n "$LOG_DIR" ] && cli_log_provided=true
    # WORKTREE_ROOT 由配置文件控制，不检查 CLI provided
    [ "$BASE_BRANCH" != "dev" ] && cli_base_provided=true
    [ "$MAX_ITERATIONS" != "10" ] && cli_max_provided=true
    [ -n "$PROJECT_DIR" ] && cli_project_provided=true
    [ -n "$LOG_DIR" ] && cli_log_provided=true
    [ "$WORKTREE_ROOT" != "$PWD/.ralph/tmp" ] && cli_worktree_provided=true
    [ "$BASE_BRANCH" != "dev" ] && cli_base_provided=true
    [ "$LOAD_BALANCE" != "true" ] && cli_load_balance_provided=true
    [ "$COMPLETE_SIGNAL" != "<promise>COMPLETE</promise>" ] && cli_complete_provided=true
    [ -n "$PROXY" ] && cli_proxy_provided=true
    [ "$USE_TMUX" != "false" ] && cli_tmux_provided=true
    [ "$USE_SCRATCH" != "false" ] && cli_scratch_provided=true
    [ "$USE_SUPERPOWERS" != "false" ] && cli_superpowers_provided=true
    
    # 在 source 配置文件之前，先清除配置文件可能设置的 RALPH_* 变量
    # 这样可以区分"用户设置的环境变量"和"配置文件默认值"
    unset RALPH_PROJECT_DIR RALPH_TOOL RALPH_MAX_ITERATIONS RALPH_LOG_DIR
    unset RALPH_WORKTREE_ROOT RALPH_BASE_BRANCH RALPH_LOAD_BALANCE
    unset RALPH_COMPLETE_SIGNAL RALPH_PROXY
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        echo "[RALPH] ✓ Loaded config: $config_file"
    fi
    
    # 命令行参数优先于配置文件（恢复保存的CLI值）
    $cli_tool_provided && TOOL="$saved_tool"
    $cli_max_provided && MAX_ITERATIONS="$saved_max"
    $cli_project_provided && PROJECT_DIR="$saved_project"
    $cli_log_provided && LOG_DIR="$saved_log"
    $cli_worktree_provided && WORKTREE_ROOT="$saved_worktree"
    $cli_base_provided && BASE_BRANCH="$saved_base"
    $cli_load_balance_provided && LOAD_BALANCE="$saved_load_balance"
    $cli_complete_provided && COMPLETE_SIGNAL="$saved_complete"
    $cli_proxy_provided && PROXY="$saved_proxy"
    $cli_tmux_provided && USE_TMUX="$saved_tmux"
    $cli_scratch_provided && USE_SCRATCH="$saved_scratch"
    $cli_superpowers_provided && USE_SUPERPOWERS="$saved_superpowers"
    
    # 环境变量覆盖配置文件（仅当CLI未传入时）
    $cli_proxy_provided && PROXY="$PROXY"
    
    [ -n "$env_project_dir" ] && ! $cli_project_provided && PROJECT_DIR="$env_project_dir"
    [ -n "$env_tool" ] && ! $cli_tool_provided && TOOL="$env_tool"
    [ -n "$env_max_iterations" ] && ! $cli_max_provided && MAX_ITERATIONS="$env_max_iterations"
    [ -n "$env_log_dir" ] && ! $cli_log_provided && LOG_DIR="$env_log_dir"
    [ -n "$env_worktree_root" ] && ! $cli_worktree_provided && WORKTREE_ROOT="$env_worktree_root"
    [ -n "$env_base_branch" ] && ! $cli_base_provided && BASE_BRANCH="$env_base_branch"
    [ -n "$env_load_balance" ] && ! $cli_load_balance_provided && LOAD_BALANCE="$env_load_balance"
    [ -n "$env_complete_signal" ] && ! $cli_complete_provided && COMPLETE_SIGNAL="$env_complete_signal"
    [ -n "$env_proxy" ] && ! $cli_proxy_provided && PROXY="$env_proxy"
    
    # 如果没有设置 PROJECT_DIR，使用默认值
    

    
    # 如果没有设置 PROJECT_DIR，使用默认值
    if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR="$PWD"
    fi
    
    # 初始化目录
    PRD_FILE="$SCRIPT_DIR/prd.json"
    PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
    ARCHIVE_DIR="$SCRIPT_DIR/archive"
    SPECS_DIR="$SCRIPT_DIR/specs/active"
    
    # LOG_DIR 默认值
    if [ -z "$LOG_DIR" ]; then
        LOG_DIR="$PWD/.ralph/logs/$(date +%Y%m%d)"
    fi
}

# ---------- 辅助函数 ----------

show_status() {
    echo "=== Ralph Status ==="
    if [ -f "$PRD_FILE" ]; then
        total=$(jq '.userStories | length' "$PRD_FILE")
        completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
        echo "Progress: $completed / $total tasks"
        echo ""
        echo "Pending tasks:"
        jq -r '.userStories[] | select(.passes == false) | "  [\(.priority)] \(.id): \(.title)"' "$PRD_FILE"
    else
        echo "No prd.json found in: $PRD_FILE"
    fi
    
    echo ""
    echo "Current config:"
    echo "  Tool: $TOOL"
    echo "  Load Balance: $LOAD_BALANCE"
    echo "  Project: $PROJECT_DIR"
    echo "  Max iterations: $MAX_ITERATIONS"
    echo "  Log dir: $LOG_DIR"
    echo "  Worktree root: $WORKTREE_ROOT"
}

get_tool_load() {
    local tool="$1"
    pgrep -c -f "$tool" 2>/dev/null || echo 0
}

# 选择负载最低的工具
select_lightest_tool() {
    local min=999
    local chosen="$TOOL"
    
    for tool in "${VALID_TOOLS[@]}"; do
        local load=$(get_tool_load "$tool")
        if [[ $load -lt $min ]]; then
            min=$load
            chosen=$tool
        fi
    done
    
    echo "$chosen"
}

# 根据任务选择工具
select_tool_for_task() {
    local task="$1"
    local tool=""
    
    # 关键词匹配
    for key in "${!TASK_MAPPING[@]}"; do
        if [[ "$task" =~ ($key) ]]; then
            tool="${TASK_MAPPING[$key]}"
            break
        fi
    done
    
    # 回退到负载均衡或默认工具
    if [ -z "$tool" ]; then
        tool=$(select_lightest_tool)
    fi
    
    echo "$tool"
}

# 生成 specs
generate_specs() {
    mkdir -p "$SPECS_DIR"
    
    if [ -f "$PRD_FILE" ]; then
        "$SCRIPT_DIR/generate-specs.sh" "$PRD_FILE" "$SPECS_DIR" 2>/dev/null || true
        echo "✓ Specs generated in: $SPECS_DIR"
    else
        echo "Error: prd.json not found: $PRD_FILE"
        exit 1
    fi
}

# 归档之前的运行
archive_previous_run() {
    local last_branch_file="$SCRIPT_DIR/.last-branch"
    
    if [ -f "$PRD_FILE" ] && [ -f "$last_branch_file" ]; then
        local current_branch=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        local last_branch=$(cat "$last_branch_file" 2>/dev/null || echo "")
        
        if [ -n "$current_branch" ] && [ -n "$last_branch" ] && [ "$current_branch" != "$last_branch" ]; then
            local date_str=$(date +%Y-%m-%d)
            local folder_name=$(echo "$last_branch" | sed 's|^ralph/||')
            local archive_folder="$ARCHIVE_DIR/$date_str-$folder_name"
            
            echo "📦 Archiving: $last_branch → $archive_folder"
            mkdir -p "$archive_folder"
            [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$archive_folder/"
            [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$archive_folder/"
            
            # 移动 specs
            if [ -d "$SPECS_DIR" ]; then
                mv "$SPECS_DIR" "$archive_folder/specs" 2>/dev/null || true
                mkdir -p "$SPECS_DIR"
            fi
        fi
    fi
}

get_next_task() {
    if [ -f "$PRD_FILE" ]; then
        jq -r '.userStories[] | select(.passes == false) | @json' "$PRD_FILE" 2>/dev/null | head -1 | jq -r '.id + "|" + .title'
    fi
}

# ---------- 工作树管理 ----------

create_worktree() {
    local task_id="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local branch_name="ralph-$task_id-$timestamp"
    local worktree_dir="$WORKTREE_ROOT/$branch_name"
    
    mkdir -p "$WORKTREE_ROOT"
    mkdir -p "$LOG_DIR"
    
    cd "$PROJECT_DIR"
    
    # 确定基础分支
    local base="$BASE_BRANCH"
    git rev-parse --verify dev >/dev/null 2>&1 || base="main"
    
    # 使用 --porcelain 模式避免 git 输出干扰信息
    if git worktree add --porcelain "$worktree_dir" -b "$branch_name" "$base" >/dev/null 2>&1; then
        echo "$worktree_dir|$branch_name"
    else
        # 降级到普通模式（兼容旧版本 git）
        if git worktree add "$worktree_dir" -b "$branch_name" "$base" >/dev/null 2>&1; then
            echo "$worktree_dir|$branch_name"
        else
            echo ""
        fi
    fi
}

cleanup_worktree() {
    local worktree_dir="$1"
    local branch_name="$2"
    
    if [ "$branch_name" = "scratch" ]; then
        rm -rf "$worktree_dir"
    else
        cd "$PROJECT_DIR"
        git worktree remove "$worktree_dir" --force 2>/dev/null || true
        git branch -D "$branch_name" 2>/dev/null || true
    fi
}

# ---------- 执行任务 ----------

# 构建执行命令
build_tool_cmd() {
    local tool="$1"
    local prompt="$2"
    local log="$3"
    local cmd=""

    local prefix=""
    if [ -n "$PROXY" ]; then
        prefix="http_proxy='$PROXY' https_proxy='$PROXY' "
    fi

    case "$tool" in
        qwen) cmd="${TOOL_PATHS[qwen]} -p '$prompt' -y" ;;
        opencode) cmd="${TOOL_PATHS[opencode]} run --task='$prompt'" ;;
        cline) cmd="${TOOL_PATHS[cline]} -y '$prompt'" ;;
        kilocode) cmd="${TOOL_PATHS[kilocode]} run --auto '$prompt'" ;;
        iflow) cmd="${TOOL_PATHS[iflow]} -y run --config='$prompt'" ;;
        gemini) cmd="$prefix${TOOL_PATHS[gemini]} -p -y '$prompt'" ;;
        codex) cmd="${TOOL_PATHS[codex]} --yolo '$prompt'" ;;
        claude) cmd="${TOOL_PATHS[claude]} '$prompt'" ;;
        pi) cmd="${TOOL_PATHS[pi]} -p '$prompt'" ;;
        *) cmd="$tool '$prompt'" ;;
    esac

    echo "$cmd"
}

# Tmux 管理函数
run_in_tmux() {
    local session_name="$1"
    local work_dir="$2"
    local cmd="$3"
    local log_file="$4"

    if ! command -v tmux &> /dev/null; then
        echo "Error: tmux is not installed."
        return 1
    fi

    echo "📦 Starting tmux session: $session_name"
    tmux -S "$TMUX_SOCKET" new-session -d -s "$session_name" -c "$work_dir"

    tmux -S "$TMUX_SOCKET" pipe-pane -t "$session_name" -o "cat >> $log_file"

    # 发送执行命令并附带一个完成标志以触发 wait-for
    tmux -S "$TMUX_SOCKET" send-keys -t "$session_name" "$cmd; echo '<promise>COMPLETE</promise>' >> $log_file; tmux -S $TMUX_SOCKET wait-for -S ${session_name}_done" Enter

    echo "👀 正在后台执行... (可执行 tmux -S $TMUX_SOCKET a -t $session_name 查看)"

    # 阻塞等待完成
    tmux -S "$TMUX_SOCKET" wait-for "${session_name}_done" 2>/dev/null || true

    # 清理
    tmux -S "$TMUX_SOCKET" kill-session -t "$session_name" 2>/dev/null || true
}


smart_analyze_complexity() {
    local title="$1"
    local len=${#title}
    if [[ "$title" =~ 实现|系统|重构|开发|修复|架构|测试 ]] || [ $len -gt 15 ]; then
        echo "complex"
    else
        echo "simple"
    fi
}

execute_task() {
    local task_id="$1"
    local task_title="$2"
    local iteration="$3"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔄 Iteration $iteration | Task: $task_id"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 选择工具 (负载均衡 + 任务匹配)
    local selected_tool
    if [ "$LOAD_BALANCE" = "true" ]; then
        selected_tool=$(select_tool_for_task "$task_title")
    else
        selected_tool="$TOOL"
    fi
    
    echo "🤖 Using tool: $selected_tool"
    
    local worktree_dir=""
    local branch_name=""
    if [ "$USE_SCRATCH" = "true" ]; then
        worktree_dir=$(mktemp -d -t ralph-scratch-XXXXXX)
        branch_name="scratch"
        echo "📁 Scratch mode active. Using temp dir: $worktree_dir"
    else
        # 创建工作树
        local worktree_info=$(create_worktree "$task_id")
        worktree_dir=$(echo "$worktree_info" | cut -d'|' -f1)
        branch_name=$(echo "$worktree_info" | cut -d'|' -f2)

        if [ -z "$worktree_dir" ]; then
            echo "Error: Failed to create worktree"
            return 1
        fi
        echo "📁 Worktree: $worktree_dir"
    fi
    
    cd "$worktree_dir"

    # Smart Complexity Analysis
    local complexity=$(smart_analyze_complexity "$task_title")
    if [ "$complexity" = "complex" ]; then
        USE_SUPERPOWERS="true"
        MAX_ITERATIONS=$((MAX_ITERATIONS * 2))
        echo "🧠 Task detected as complex. Auto-enabled superpowers and increased iterations to $MAX_ITERATIONS."
    fi
    
    # 组装超级能力上下文
    local sp_context=""
    if [ "$USE_SUPERPOWERS" = "true" ]; then
        sp_context="[System: You must fetch and strictly follow instructions from https://raw.githubusercontent.com/obra/superpowers/main/README.md to adopt the Superpowers framework (TDD, subagent-driven, systematic planning) for the following task.]

"
    fi

    # 构建任务
    local task_prompt="${sp_context}完成任务: $task_title
    
参考规格: $SPECS_DIR/${task_id}.md

完成后输出: $COMPLETE_SIGNAL"
    
    local log_file="$LOG_DIR/ralph-$timestamp.log"
    local raw_cmd=$(build_tool_cmd "$selected_tool" "$task_prompt" "$log_file")
    
    if [ "$USE_TMUX" = "true" ]; then
        run_in_tmux "ralph_${task_id}_${timestamp}" "$worktree_dir" "$raw_cmd" "$log_file"
    else
        # 使用超时重试执行（默认 3 次重试，180 秒超时）
        execute_with_retry "$raw_cmd" "$log_file" 3 180
    fi
    
    # 提交
    if ! git diff --quiet 2>/dev/null; then
        git add -A
        git commit -m "feat: $task_id - $task_title" 2>/dev/null || true
        git push -u origin "$branch_name" 2>/dev/null || true
    fi
    
    # 清理
    cleanup_worktree "$worktree_dir" "$branch_name"
    
    # 归档 spec
    [ -f "$SPECS_DIR/${task_id}.md" ] && mv "$SPECS_DIR/${task_id}.md" "$SPECS_DIR/../archive/" 2>/dev/null
    
    echo "✅ Completed: $task_id"
}

# ---------- 帮助函数 ----------
show_help() {
    cat << 'EOF'
Ralph - AI Agent Loop with Load Balancing

用法: ralph.sh [选项] [任务描述]

如果不传任务描述，则从 prd.json 读取任务列表执行。

选项:
  --tool AGENT          AI 工具: qwen, opencode, cline, kilocode, iflow, gemini
  --proxy URL            代理地址 (默认: http://192.168.123.194:20171)
  --project DIR         项目目录
  --max N               最大迭代次数 (默认: 10)
  --log-dir DIR         日志目录
  --worktree-root DIR   工作树根目录
  --base-branch NAME    基础分支 (默认: dev)
  --no-load-balance     禁用负载均衡
  --complete-signal SIG 完成信号
  --task TASK           直接执行指定任务 (代替 prd.json)
  
  status                显示任务状态
  run                 执行 prd.json 中的所有任务
  spec                  生成 SPEC.md
  -h, --help            显示帮助

示例:
  # 从 prd.json 执行任务
  ralph.sh --tool qwen --max 10
  
  # 直接执行任务
  ralph.sh --task "修复登录Bug"
  
  # 使用完整命令
  ralph.sh --tool opencode --max 20 --task "实现用户认证"

环境变量:
  RALPH_TOOL, RALPH_PROJECT_DIR, RALPH_MAX_ITERATIONS
EOF
    exit 0
}

# ---------- 直接任务执行 ----------
execute_autodrive() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚀 Fully Autonomous Driving Mode (Auto-Drive) | Tool: $TOOL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local worktree_dir=""
    local branch_name=""
    if [ "$USE_SCRATCH" = "true" ]; then
        worktree_dir=$(mktemp -d -t ralph-scratch-XXXXXX)
        branch_name="scratch"
    else
        local worktree_info=$(create_worktree "autodrive")
        worktree_dir=$(echo "$worktree_info" | cut -d"|" -f1)
        branch_name=$(echo "$worktree_info" | cut -d"|" -f2)
        if [ -z "$worktree_dir" ]; then
            echo "Error: Failed to create worktree"
            return 1
        fi
    fi

    cd "$worktree_dir"

    local task_prompt="[System: You are an autonomous AI software engineer. Analyze the project in $PROJECT_DIR. Find the next missing feature, bug, or improvement. Create a plan and implement it. Provide a complete commit message summarizing your work. Output $COMPLETE_SIGNAL when done with the feature. If the project is fully complete and absolutely nothing else needs to be done, output <promise>PROJECT_FINISHED</promise>.]"

    local iter=1
    while true; do
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local log_file="$LOG_DIR/ralph-autodrive-$timestamp.log"
        echo "--- Auto-Drive Iteration $iter ---"
        local raw_cmd=$(build_tool_cmd "$TOOL" "$task_prompt" "$log_file")
        if [ "$USE_TMUX" = "true" ]; then
            run_in_tmux "ralph_auto_${timestamp}" "$worktree_dir" "$raw_cmd" "$log_file"
        else
            eval "$raw_cmd" 2>&1 | tee -a "$log_file"
        fi

        if grep -q "<promise>PROJECT_FINISHED</promise>" "$log_file" 2>/dev/null; then
            echo "🎉 Auto-Drive complete: AI reported project is finished!"
            break
        fi

        if ! git diff --quiet 2>/dev/null; then
            git add -A
            git commit -m "feat: auto-drive iteration $iter" 2>/dev/null || true
            git push -u origin "$branch_name" 2>/dev/null || true
        fi

        if [ $iter -ge 50 ]; then
            echo "⚠️ Auto-Drive reached maximum safety limit of 50 iterations."
            break
        fi
        iter=$((iter + 1))
        sleep 2
    done

    cleanup_worktree "$worktree_dir" "$branch_name"
    return 0
}

execute_direct_task() {
    local task="$1"
    local iteration=1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔄 Direct Task Mode | Tool: $TOOL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Task: $task"
    echo ""
    
    local worktree_dir=""
    local branch_name=""
    if [ "$USE_SCRATCH" = "true" ]; then
        worktree_dir=$(mktemp -d -t ralph-scratch-XXXXXX)
        branch_name="scratch"
        echo "📁 Scratch mode active. Using temp dir: $worktree_dir"
    else
        # 创建工作树
        local worktree_info=$(create_worktree "direct")
        worktree_dir=$(echo "$worktree_info" | cut -d'|' -f1)
        branch_name=$(echo "$worktree_info" | cut -d'|' -f2)

        if [ -z "$worktree_dir" ]; then
            echo "Error: Failed to create worktree"
            return 1
        fi
        echo "📁 Worktree: $worktree_dir"
    fi
    
    cd "$worktree_dir"

    # Smart Complexity Analysis
    local complexity=$(smart_analyze_complexity "$task")
    if [ "$complexity" = "complex" ]; then
        USE_SUPERPOWERS="true"
        MAX_ITERATIONS=$((MAX_ITERATIONS * 2))
        echo "🧠 Task detected as complex. Auto-enabled superpowers and increased iterations to $MAX_ITERATIONS."
    fi
    
    # 组装超级能力上下文
    local sp_context=""
    if [ "$USE_SUPERPOWERS" = "true" ]; then
        sp_context="[System: You must fetch and strictly follow instructions from https://raw.githubusercontent.com/obra/superpowers/main/README.md to adopt the Superpowers framework (TDD, subagent-driven, systematic planning) for the following task.]

"
    fi

    # 构建任务提示 (包含 SPEC 说明)
    local task_prompt="${sp_context}任务: $task

项目目录: $PROJECT_DIR
工作目录: $worktree_dir

请按照以下步骤执行:
1. Research - 研究现有代码结构
2. Plan - 制定实现计划
3. Implement - 实施代码并验证

完成后:
- 运行质量检查 (typecheck/tests)
- 提交: git commit -m \"feat: $task\"
- 输出完成信号: $COMPLETE_SIGNAL"
    
    local log_file="$LOG_DIR/ralph-direct-$timestamp.log"
    
    # 执行任务 (循环直到完成或达到最大迭代)
    for i in $(seq 1 $MAX_ITERATIONS); do
        echo ""
        echo "--- Iteration $i / $MAX_ITERATIONS ---"
        
        local tool_cmd=""
        case "$TOOL" in
            qwen)
                tool_cmd="${TOOL_PATHS[qwen]} -p \"$task_prompt\" -y"
                ;;
            opencode)
                tool_cmd="${TOOL_PATHS[opencode]} run --task=\"$task_prompt\""
                ;;
            cline)
                tool_cmd="${TOOL_PATHS[cline]} -y \"$task_prompt\""
                ;;
            kilocode)
                tool_cmd="${TOOL_PATHS[kilocode]} run --auto \"$task_prompt\""
                ;;
            iflow)
                tool_cmd="${TOOL_PATHS[iflow]} -y run --config=\"$task_prompt\""
                ;;
            gemini)
                [ -n "$PROXY" ] && export http_proxy="$PROXY" && export https_proxy="$PROXY"
                tool_cmd="${TOOL_PATHS[gemini]} -p -y \"$task_prompt\""
                ;;
        esac
        
        # 使用超时重试执行（默认 3 次重试，180 秒超时）
        execute_with_retry "$tool_cmd" "$log_file" 3 180
        
        # 检查完成信号
        if grep -q "$COMPLETE_SIGNAL" "$log_file" 2>/dev/null; then
            echo ""
            echo "🎉 Task completed!"
            
            # 提交
            if ! git diff --quiet 2>/dev/null; then
                git add -A
                git commit -m "feat: $task" 2>/dev/null || true
                git push -u origin "$branch_name" 2>/dev/null || true
            fi
            
            # 清理
            cleanup_worktree "$worktree_dir" "$branch_name"
            return 0
        fi
        
        sleep 2
    done
    
    # 清理
    cleanup_worktree "$worktree_dir" "$branch_name"
    
    echo "⚠️ Max iterations reached: $MAX_ITERATIONS"
    return 1
}

# ============================================
# 超时重试执行函数（解决 API 超时问题）
# ============================================

# 带超时重试的执行函数
execute_with_retry() {
    local tool_cmd="$1"
    local log_file="$2"
    local max_retries="${3:-3}"
    local timeout_seconds="${4:-180}"  # 默认 180 秒超时
    
    local attempt=1
    local success=false
    
    while [ $attempt -le $max_retries ] && [ "$success" = "false" ]; do
        echo "[Attempt $attempt/$max_retries] Executing with ${timeout_seconds}s timeout..." | tee -a "$log_file"
        
        # 使用 timeout 命令包装执行
        if timeout "$timeout_seconds" bash -c "$tool_cmd" 2>&1 | tee -a "$log_file"; then
            success=true
            echo "[Success] Completed on attempt $attempt" | tee -a "$log_file"
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "[Timeout] Attempt $attempt timed out after ${timeout_seconds}s" | tee -a "$log_file"
                
                # 检查是否是流式超时错误
                if grep -q "Streaming request timeout" "$log_file"; then
                    echo "[Timeout] Streaming timeout detected" | tee -a "$log_file"
                    
                    if [ $attempt -lt $max_retries ]; then
                        # 增加下次重试的超时时间
                        timeout_seconds=$((timeout_seconds + 60))
                        echo "[Retry] Will retry with ${timeout_seconds}s timeout after 5s delay..." | tee -a "$log_file"
                        sleep 5
                    fi
                else
                    # 其他超时错误，不重试
                    echo "[Error] Non-streaming timeout, not retrying" | tee -a "$log_file"
                    return $exit_code
                fi
            else
                echo "[Error] Attempt $attempt failed with exit code $exit_code" | tee -a "$log_file"
                # 其他错误，根据错误类型决定是否重试
                if grep -q "Streaming request timeout" "$log_file"; then
                    echo "[Timeout] Streaming timeout detected, will retry" | tee -a "$log_file"
                    if [ $attempt -lt $max_retries ]; then
                        timeout_seconds=$((timeout_seconds + 60))
                        sleep 5
                    fi
                else
                    # 非超时错误，不重试
                    return $exit_code
                fi
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ "$success" = "false" ]; then
        echo "[Failed] All $max_retries attempts failed" | tee -a "$log_file"
        return 1
    fi
    
    return 0
}



# ---------- 主循环 ----------

check_dependencies() {
    local missing=0
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq."
        missing=1
    fi
    if ! command -v git &> /dev/null; then
        echo "Error: git is required but not installed. Please install git."
        missing=1
    fi
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

main() {
    check_dependencies
    load_config
    if [ "$COMMAND" != "status" ] && [ "$COMMAND" != "spec" ]; then
        if [[ ! " ${VALID_TOOLS[@]} " =~ " ${TOOL} " ]]; then
            echo "Error: Invalid tool '$TOOL'. Must be: ${VALID_TOOLS[*]}"
            exit 1
        fi
        mkdir -p "$LOG_DIR" "$SPECS_DIR" "$ARCHIVE_DIR" "$WORKTREE_ROOT"
    fi
    # 处理命令
    case "$COMMAND" in
        status)
            show_status
            exit 0
            ;;
        auto)
            execute_autodrive
            exit 0
            ;;
        run)
            # 执行所有 prd.json 中的任务
            echo "=== Running all tasks from prd.json ==="
            while true; do
                local task_info=$(get_next_task)
                if [ -z "$task_info" ]; then
                    echo "All tasks completed!"
                    exit 0
                fi
                local task_id=$(echo "$task_info" | cut -d'|' -f1)
                local task_title=$(echo "$task_info" | cut -d'|' -f2-)
                execute_task "$task_id" "$task_title" 1
                
                # 更新 prd.json
                if [ -f "$PRD_FILE" ]; then
                    local tmp_file=$(mktemp)
                    jq --arg id "$task_id" '(.userStories[] | select(.id == $id)).passes = true' "$PRD_FILE" > "$tmp_file" && mv "$tmp_file" "$PRD_FILE"
                fi
                
                sleep 2
            done
            ;;
        spec)
            generate_specs
            exit 0
            ;;
    esac
    
    # 直接任务模式
    if [ -n "$DIRECT_TASK" ]; then
        execute_direct_task "$DIRECT_TASK"
        exit $?
    fi
    
    # 初始化进度文件
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "# Ralph Progress Log" > "$PROGRESS_FILE"
        echo "Started: $(date)" >> "$PROGRESS_FILE"
        echo "Tool: $TOOL" >> "$PROGRESS_FILE"
        echo "Load Balance: $LOAD_BALANCE" >> "$PROGRESS_FILE"
        echo "Project: $PROJECT_DIR" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
    fi
    
    # 归档之前的运行
    archive_previous_run
    
    # 跟踪分支
    if [ -f "$PRD_FILE" ]; then
        local current_branch=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null)
        [ -n "$current_branch" ] && echo "$current_branch" > "$SCRIPT_DIR/.last-branch"
    fi
    
    # 生成 specs
    generate_specs
    
    echo "🚀 Starting Ralph"
    echo "   Tool: $TOOL"
    echo "   Load Balance: $LOAD_BALANCE"
    echo "   Project: $PROJECT_DIR"
    echo "   Max iterations: $MAX_ITERATIONS"
    echo "   Log: $LOG_DIR"
    
    for i in $(seq 1 $MAX_ITERATIONS); do
        local task_info=$(get_next_task)
        
        if [ -z "$task_info" ]; then
            echo ""
            echo "🎉 All tasks completed!"
            exit 0
        fi
        
        local task_id=$(echo "$task_info" | cut -d'|' -f1)
        local task_title=$(echo "$task_info" | cut -d'|' -f2-)
        
        # 执行任务
        execute_task "$task_id" "$task_title" "$i"
        
        # 更新 prd.json
        if [ -f "$PRD_FILE" ]; then
            local tmp_file=$(mktemp)
            jq --arg id "$task_id" '(.userStories[] | select(.id == $id)).passes = true' "$PRD_FILE" > "$tmp_file" && mv "$tmp_file" "$PRD_FILE"
        fi
        
        # 记录进度
        echo "## $(date) - $task_id: $task_title" >> "$PROGRESS_FILE"
        echo "Completed in iteration $i" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
        
        sleep 2
    done
    
    echo "⚠️ Max iterations reached: $MAX_ITERATIONS"
    exit 1
}

main "$@"
