#!/bin/bash
# ============================================================
# Ralph Orchestration Skill - Enhanced with Superpowers
# 
# 交互式任务编排 - 分析用户任务并调用 ralph.sh
# 集成 Superpowers 技能自动调度
# ============================================================

set -euo pipefail

# ============================================================
# 配置路径
# ============================================================
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPATCHER_SCRIPT="$SKILL_DIR/../ralph/skill-dispatcher.sh"
CONFIG_FILE="$SKILL_DIR/config.yaml"
KEYWORDS_FILE="$SKILL_DIR/keywords.conf"
LOG_FILE="${HOME}/.ralph/skill.log"

# ============================================================
# 默认值
# ============================================================
TOOL="qwen"
MAX_ITERATIONS=10
PROJECT_DIR=""
TASK=""
INTERACTIVE=true
RALPH_PATH=""
USE_SUPERPOWERS=false
USE_TMUX=false
USE_SCRATCH=false

# 工具列表
VALID_TOOLS=("qwen" "opencode" "cline" "kilocode" "iflow" "gemini" "oracle")

# ============================================================
# 颜色输出
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# 日志函数
# ============================================================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        ERROR)   echo -e "${RED}$message${NC}" ;;
        WARN)    echo -e "${YELLOW}$message${NC}" ;;
        SUCCESS) echo -e "${GREEN}$message${NC}" ;;
        INFO)    echo -e "${BLUE}$message${NC}" ;;
        *)       echo "$message" ;;
    esac
}

# ============================================================
# 显示帮助
# ============================================================
show_help() {
    cat << EOF
${BOLD}Ralph Orchestration Skill${NC}

${CYAN}用法:${NC}
  /ralph <任务描述>
  /ralph -t <tool> <任务>
  /ralph --tool <tool> --max <n> --project <path> <任务>

${CYAN}参数:${NC}
  -t, --tool <TOOL>      AI 工具：${VALID_TOOLS[*]}
  -m, --max <N>         最大迭代次数 (默认：10)
  -p, --project <DIR>  项目目录
  -y, --no-interactive  跳过交互式确认
  --superpowers         启用 Superpowers 技能自动调度
  --tmux               使用 tmux 后台执行
  --scratch            在临时空目录执行
  -l, --log             显示日志
  -h, --help            显示帮助

${CYAN}示例:${NC}
  /ralph 帮我修复登录 bug
  /ralph -t cline 编写自动化部署脚本
  /ralph --superpowers --tmux "实现用户认证"
  /ralph -y 代码审查  # 自动执行，不交互确认

${CYAN}关键词映射:${NC}
  shell/bash/script  → cline
  review/refactor    → opencode
  pr/github          → kilocode
  deploy/workflow   → iflow
  architecture      → oracle
  其他              → qwen (负载均衡)

${CYAN}更多信息:${NC}
  参见 SKILL.md
EOF
}

# ============================================================
# 显示日志
# ============================================================
show_log() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}=== 最近 50 条日志 ===${NC}"
        tail -50 "$LOG_FILE"
    else
        echo "暂无日志"
    fi
}

# ============================================================
# 加载配置文件
# ============================================================
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            
            if [[ "$line" =~ ^defaults: ]]; then
                continue
            elif [[ "$line" =~ tool:[[:space:]]*(.+) ]]; then
                TOOL="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ max_iterations:[[:space:]]*(.+) ]]; then
                MAX_ITERATIONS="${BASH_REMATCH[1]}"
            fi
        done < "$CONFIG_FILE"
    fi
}

# ============================================================
# 验证工具
# ============================================================
validate_tool() {
    local tool="$1"
    for valid in "${VALID_TOOLS[@]}"; do
        [[ "$tool" == "$valid" ]] && return 0
    done
    return 1
}

# ============================================================
# 关键词匹配
# ============================================================
match_tool() {
    local task="$1"
    local matched_tool=""
    
    if [[ ! -f "$KEYWORDS_FILE" ]]; then
        echo "qwen"
        return
    fi
    
    while IFS=',' read -r keyword tool; do
        [[ "$keyword" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$keyword" ]] && continue
        
        if echo "$task" | grep -qi "$keyword"; then
            matched_tool="$tool"
            log INFO "关键词匹配：'$keyword' -> $tool"
            break
        fi
    done < "$KEYWORDS_FILE"
    
    echo "${matched_tool:-qwen}"
}

# ============================================================
# 查找 ralph.sh 路径
# ============================================================
find_ralph() {
    local paths=(
        "${HOME}/.openclaw/workspace/ralph-fork/ralph.sh"
        "${HOME}/decentralized-box/ralph.sh"
        "/mnt/data/dev/decentralized-box/ralph.sh"
        "/mnt/data/dev/ralph-fork/ralph.sh"
        "$(command -v ralph.sh 2>/dev/null)"
    )
    
    for path in "${paths[@]}"; do
        if [[ -f "$path" ]]; then
            RALPH_PATH="$path"
            return 0
        fi
    done
    
    return 1
}

# ============================================================
# 显示工具信息
# ============================================================
show_tool_info() {
    local tool="$1"
    
    case "$tool" in
        qwen)      echo "qwen - 通用 AI 助手（负载均衡模式）" ;;
        opencode)  echo "opencode - 专业代码开发工具" ;;
        cline)     echo "cline - 终端/脚本开发工具" ;;
        kilocode)  echo "kilocode - 交互式编码工具" ;;
        iflow)     echo "iflow - 工作流/数据处理工具" ;;
        gemini)    echo "gemini - Google AI 工具" ;;
        oracle)    echo "oracle - 架构咨询工具" ;;
    esac
}

# ============================================================
# Superpowers 技能注入
# ============================================================
inject_superpowers_prompt() {
    log INFO "注入 Superpowers 技能提示"
    
    if [[ -f "$DISPATCHER_SCRIPT" ]]; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}🦸 Superpowers 技能自动调度${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        bash "$DISPATCHER_SCRIPT" "$TASK" || {
            log WARN "技能调度器执行失败，使用默认模式"
        }
        
        echo ""
        echo -e "${GREEN}✓${NC} Superpowers 技能已注入"
        echo ""
    else
        log WARN "技能调度器未找到：$DISPATCHER_SCRIPT"
        echo -e "${YELLOW}⚠ 技能调度器未找到，使用默认模式${NC}"
    fi
}

# ============================================================
# Tmux 后台执行
# ============================================================
execute_with_tmux() {
    local tool="$1"
    local max="$2"
    local project="$3"
    local task="$4"
    
    local session_name="ralph_$(echo "$task" | tr ' ' '_' | cut -c1-20)_$$"
    local socket_path="${TMPDIR:-/tmp}/ralph-agent.sock"
    
    log INFO "启动 tmux 后台会话：$session_name"
    
    tmux -S "$socket_path" new-session -d -s "$session_name"
    
    local cmd="bash '$RALPH_PATH' --tool '$tool' --max '$max'"
    [[ -n "$project" ]] && cmd="$cmd --project '$project'"
    cmd="$cmd '$task'"
    
    tmux -S "$socket_path" send-keys -t "$session_name" "$cmd" Enter
    
    echo ""
    echo -e "${GREEN}✓${NC} 任务已在后台启动"
    echo -e "${CYAN}会话名称：${MAGENTA}$session_name${NC}"
    echo -e "${CYAN}查看进度：${MAGENTA}tmux -S $socket_path a -t $session_name${NC}"
    echo -e "${CYAN}分离会话：${MAGENTA}Ctrl+B, D${NC}"
    echo ""
    
    log INFO "Tmux 会话已创建：$session_name"
}

# ============================================================
# Scratch 模式执行
# ============================================================
execute_in_scratch() {
    local tool="$1"
    local max="$2"
    local project="$3"
    local task="$4"
    
    local scratch_dir=$(mktemp -d -t ralph-scratch-XXXXXX)
    
    log INFO "创建临时 scratch 目录：$scratch_dir"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📦 Scratch 模式 - 临时空目录执行${NC}"
    echo -e "${CYAN}目录：${MAGENTA}$scratch_dir${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    (
        cd "$scratch_dir"
        bash "$RALPH_PATH" --tool "$tool" --max "$max" --project "$scratch_dir" "$task"
    )
    
    rm -rf "$scratch_dir"
    log INFO "已清理 scratch 目录：$scratch_dir"
}

# ============================================================
# 交互式问答
# ============================================================
interactive_qa() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         🤖 Ralph Orchestration - 任务确认              ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📋 任务描述:${NC}"
    echo -e "   ${YELLOW}$TASK${NC}"
    echo ""
    echo -e "${CYAN}⚙️  参数确认:${NC}"
    echo -e "   工具：     ${GREEN}$TOOL${NC}"
    echo -e "   迭代次数：${GREEN}$MAX_ITERATIONS${NC}"
    echo -e "   项目目录：${GREEN}${PROJECT_DIR:-当前目录}${NC}"
    if $USE_SUPERPOWERS; then
        echo -e "   Superpowers: ${GREEN}已启用${NC}"
    fi
    echo ""
    echo -e "${CYAN}📌 操作:${NC}"
    echo -e "   [回车] 确认执行"
    echo -e "   [q/Q]  退出"
    echo -e "   [工具 qwen] 修改工具"
    echo -e "   [迭代 20] 修改迭代次数"
    echo ""
    echo -n "➜ "
    
    read -r confirm
    
    case "$confirm" in
        q|Q)
            log INFO "用户取消执行"
            echo "已取消"
            exit 0
            ;;
        工具\ *)
            TOOL="${confirm#工具 }"
            validate_tool "$TOOL" || {
                log ERROR "无效工具：$TOOL，有效工具：${VALID_TOOLS[*]}"
                exit 1
            }
            echo "工具已修改为：$TOOL"
            ;;
        迭代\ *|max\ *)
            MAX_ITERATIONS="${confirm#* }"
            echo "迭代次数已修改为：$MAX_ITERATIONS"
            ;;
    esac
}

# ============================================================
# 执行 ralph.sh
# ============================================================
execute_ralph() {
    local tool="$1"
    local max="$2"
    local project="$3"
    local task="$4"
    
    find_ralph || {
        log ERROR "未找到 ralph.sh"
        echo ""
        echo -e "${RED}错误：找不到 ralph.sh${NC}"
        echo ""
        echo "请确保 ralph.sh 位于以下位置之一:"
        echo "  - ~/.openclaw/workspace/ralph-fork/ralph.sh"
        echo "  - ~/decentralized-box/ralph.sh"
        echo "  - /mnt/data/dev/decentralized-box/ralph.sh"
        echo ""
        echo "或运行安装脚本：bash install-skill.sh"
        exit 1
    }
    
    echo ""
    echo -e "${GREEN}✓${NC} 找到 ralph.sh: $RALPH_PATH"
    echo ""
    
    local cmd="bash '$RALPH_PATH' --tool '$tool' --max '$max'"
    [[ -n "$project" ]] && cmd="$cmd --project '$project'"
    cmd="$cmd '$task'"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}执行命令:${NC}"
    echo -e "${YELLOW}$cmd${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    log INFO "执行：tool=$tool, max=$max, project=${project:-none}"
    
    eval "$cmd"
}

# ============================================================
# 显示横幅
# ============================================================
show_banner() {
    cat << 'EOF'

 ██████╗ ███████╗███████╗██╗     ██╗███╗   ██╗███████╗
██╔═══██╗██╔════╝██╔════╝██║     ██║████╗  ██║██╔════╝
██║   ██║█████╗  █████╗  ██║     ██║██╔██╗ ██║█████╗  
██║   ██║██╔══╝  ██╔══╝  ██║     ██║██║╚██╗██║██╔══╝  
╚██████╔╝██║     ██║     ███████╗██║██║ ╚████║███████╗
 ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
                                                      
 Ralph Orchestration Skill v2.0.0 (with Superpowers)

EOF
}

# ============================================================
# 主函数
# ============================================================
main() {
    show_banner
    
    parse_args "$@"
    
    load_config
    
    if [[ -z "$TASK" ]]; then
        echo -e "${YELLOW}请输入任务描述:${NC}"
        read -r TASK
    fi
    
    if [[ -z "$TASK" ]]; then
        show_help
        exit 1
    fi
    
    # 自动匹配工具
    if [[ "$TOOL" == "qwen" ]]; then
        local matched
        matched=$(match_tool "$TASK")
        TOOL="$matched"
        log INFO "自动匹配工具：$TOOL"
    fi
    
    validate_tool "$TOOL" || {
        log ERROR "无效工具：$TOOL，有效工具：${VALID_TOOLS[*]}"
        exit 1
    }
    
    echo -e "${GREEN}✓${NC} 选中工具：$(show_tool_info "$TOOL")"
    
    # Superpowers 技能调度
    if $USE_SUPERPOWERS; then
        log INFO "启用 Superpowers 技能自动调度"
        inject_superpowers_prompt
    fi
    
    # Tmux 后台执行
    if $USE_TMUX; then
        execute_with_tmux "$TOOL" "$MAX_ITERATIONS" "$PROJECT_DIR" "$TASK"
        exit 0
    fi
    
    # Scratch 模式
    if $USE_SCRATCH; then
        execute_in_scratch "$TOOL" "$MAX_ITERATIONS" "$PROJECT_DIR" "$TASK"
        exit 0
    fi
    
    # 交互模式
    if $INTERACTIVE; then
        interactive_qa
    fi
    
    # 执行
    execute_ralph "$TOOL" "$MAX_ITERATIONS" "$PROJECT_DIR" "$TASK"
}

# 解析参数函数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--tool)
                TOOL="$2"
                shift 2
                ;;
            -m|--max)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            -p|--project)
                PROJECT_DIR="$2"
                shift 2
                ;;
            -y|--no-interactive)
                INTERACTIVE=false
                shift
                ;;
            --superpowers)
                USE_SUPERPOWERS=true
                shift
                ;;
            --tmux)
                USE_TMUX=true
                shift
                ;;
            --scratch)
                USE_SCRATCH=true
                shift
                ;;
            -l|--log)
                show_log
                exit 0
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            -*)
                log ERROR "未知选项：$1"
                show_help
                exit 1
                ;;
            *)
                TASK="$1"
                shift
                ;;
        esac
    done
}

main "$@"
