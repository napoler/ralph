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
WORKTREE_ROOT="/mnt/data/dev/tmp"
BASE_BRANCH="dev"
LOAD_BALANCE="true"
COMPLETE_SIGNAL="<promise>COMPLETE</promise>"
PROXY=""  # 代理地址，从配置文件读取

# 目录变量
SCRIPT_DIR=""
PRD_FILE=""
PROGRESS_FILE=""
ARCHIVE_DIR=""
SPECS_DIR=""

# 有效工具列表
VALID_TOOLS=("qwen" "opencode" "cline" "kilocode" "iflow" "gemini")

# 工具命令映射
declare -A TOOL_COMMANDS
TOOL_COMMANDS["qwen"]="qwen -p"
TOOL_COMMANDS["opencode"]="opencode run --task"
TOOL_COMMANDS["cline"]="cline"
TOOL_COMMANDS["kilocode"]="kilocode run"
TOOL_COMMANDS["iflow"]="iflow run --config"
TOOL_COMMANDS["gemini"]="gemini -p"

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
            
        --no-load-balance)
            LOAD_BALANCE="false"
            shift
            ;;
            
        --proxy)
            RALPH_PROXY="$2"
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
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        echo "[RALPH] ✓ Loaded config: $config_file"
    fi
    
    # 环境变量覆盖配置文件
    [ -n "$RALPH_PROJECT_DIR" ] && PROJECT_DIR="$RALPH_PROJECT_DIR"
    [ -n "$RALPH_TOOL" ] && TOOL="$RALPH_TOOL"
    [ -n "$RALPH_MAX_ITERATIONS" ] && MAX_ITERATIONS="$RALPH_MAX_ITERATIONS"
    [ -n "$RALPH_LOG_DIR" ] && LOG_DIR="$RALPH_LOG_DIR"
    [ -n "$RALPH_WORKTREE_ROOT" ] && WORKTREE_ROOT="$RALPH_WORKTREE_ROOT"
    [ -n "$RALPH_BASE_BRANCH" ] && BASE_BRANCH="$RALPH_BASE_BRANCH"
    [ -n "$RALPH_LOAD_BALANCE" ] && LOAD_BALANCE="$RALPH_LOAD_BALANCE"
    [ -n "$RALPH_COMPLETE_SIGNAL" ] && COMPLETE_SIGNAL="$RALPH_COMPLETE_SIGNAL"
    [ -n "$RALPH_PROXY" ] && PROXY="$RALPH_PROXY"
    
    # 如果没有设置 PROJECT_DIR，使用默认值
    if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR="/mnt/data/dev/decentralized-box"
    fi
    
    # 初始化目录
    PRD_FILE="$SCRIPT_DIR/prd.json"
    PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
    ARCHIVE_DIR="$SCRIPT_DIR/archive"
    SPECS_DIR="$SCRIPT_DIR/specs/active"
    
    # LOG_DIR 默认值
    if [ -z "$LOG_DIR" ]; then
        LOG_DIR="/mnt/data/dev/tmp/ralph-$(date +%Y%m%d)/logs"
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
    
    if git worktree add "$worktree_dir" -b "$branch_name" 2>/dev/null; then
        echo "$worktree_dir|$branch_name"
    else
        echo ""
    fi
}

cleanup_worktree() {
    local worktree_dir="$1"
    local branch_name="$2"
    
    cd "$PROJECT_DIR"
    git worktree remove "$worktree_dir" --force 2>/dev/null || true
    git branch -D "$branch_name" 2>/dev/null || true
}

# ---------- 执行任务 ----------

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
    
    # 创建工作树
    local worktree_info=$(create_worktree "$task_id")
    local worktree_dir=$(echo "$worktree_info" | cut -d'|' -f1)
    local branch_name=$(echo "$worktree_info" | cut -d'|' -f2)
    
    if [ -z "$worktree_dir" ]; then
        echo "Error: Failed to create worktree"
        return 1
    fi
    
    echo "📁 Worktree: $worktree_dir"
    
    cd "$worktree_dir"
    
    # 构建任务
    local task_prompt="完成任务: $task_title
    
参考规格: $SPECS_DIR/${task_id}.md

完成后输出: $COMPLETE_SIGNAL"
    
    local log_file="$LOG_DIR/ralph-$timestamp.log"
    
    # 执行任务
    case "$selected_tool" in
        qwen)
            qwen -p "$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
        opencode)
            opencode run --task="$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
        cline)
            cline "$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
        kilocode)
            kilocode run "$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
        iflow)
            iflow run --config="$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
        gemini)
            # gemini 需要代理 (从配置读取)
            [ -n "$PROXY" ] && export http_proxy="$PROXY" && export https_proxy="$PROXY"
            gemini -p "$task_prompt" 2>&1 | tee -a "$log_file"
            ;;
    esac
    
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
    
    # 创建工作树
    local worktree_info=$(create_worktree "direct")
    local worktree_dir=$(echo "$worktree_info" | cut -d'|' -f1)
    local branch_name=$(echo "$worktree_info" | cut -d'|' -f2)
    
    if [ -z "$worktree_dir" ]; then
        echo "Error: Failed to create worktree"
        return 1
    fi
    
    echo "📁 Worktree: $worktree_dir"
    cd "$worktree_dir"
    
    # 构建任务提示 (包含 SPEC 说明)
    local task_prompt="任务: $task

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
        
        case "$TOOL" in
            qwen)
                qwen -p "$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
            opencode)
                opencode run --task="$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
            cline)
                cline "$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
            kilocode)
                kilocode run "$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
            iflow)
                iflow run --config="$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
            gemini)
                # gemini 需要代理 (从配置读取)
                [ -n "$PROXY" ] && export http_proxy="$PROXY" && export https_proxy="$PROXY"
                gemini -p "$task_prompt" 2>&1 | tee -a "$log_file"
                ;;
        esac
        
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

# ---------- 主循环 ----------

main() {
    load_config
    
    # 处理命令
    case "$COMMAND" in
        status)
            show_status
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
        # 验证工具
        if [[ ! " ${VALID_TOOLS[@]} " =~ " ${TOOL} " ]]; then
            echo "Error: Invalid tool '$TOOL'. Must be: ${VALID_TOOLS[*]}"
            exit 1
        fi
        
        mkdir -p "$LOG_DIR" "$SPECS_DIR" "$ARCHIVE_DIR" "$WORKTREE_ROOT"
        
        execute_direct_task "$DIRECT_TASK"
        exit $?
    fi
    
    # 验证工具
    if [[ ! " ${VALID_TOOLS[@]} " =~ " ${TOOL} " ]]; then
        echo "Error: Invalid tool '$TOOL'. Must be: ${VALID_TOOLS[*]}"
        exit 1
    fi
    
    # 创建必要目录
    mkdir -p "$LOG_DIR" "$SPECS_DIR" "$ARCHIVE_DIR" "$WORKTREE_ROOT"
    
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