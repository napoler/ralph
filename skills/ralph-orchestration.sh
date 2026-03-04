#!/bin/bash
# ============================================================
# Ralph Orchestration Skill
# 
# 交互式任务编排 - 分析用户任务并调用 ralph.sh
# 
# 用法:
#   /ralph <任务描述>
#   /ralph -t <tool> <任务>
#   /ralph --tool <tool> --max <n> --project <path> <任务>
# 
# 安装:
#   bash install-skill.sh
# ============================================================

set -euo pipefail

# ============================================================
# 配置路径
# ============================================================
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
USE_TMUX=false
SESSION_NAME=""
USE_SUPERPOWERS=false

# 工具列表与自动探测
resolve_tool() {
    local t="$1"
    if command -v "$t" &> /dev/null; then return 0; fi
    if [ -f "$HOME/.npm-global/bin/$t" ]; then return 0; fi
    if [ -n "$(npm config get prefix 2>/dev/null)" ] && [ -f "$(npm config get prefix 2>/dev/null)/bin/$t" ]; then return 0; fi
    if [ -n "$(yarn global bin 2>/dev/null)" ] && [ -f "$(yarn global bin 2>/dev/null)/$t" ]; then return 0; fi
    if [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/versions/node/current/bin/$t" ]; then return 0; fi
    if [ -f "/usr/local/bin/$t" ]; then return 0; fi
    return 1
}

AVAILABLE_TOOLS=()
for t in "qwen" "opencode" "cline" "kilocode" "iflow" "gemini" "oracle" "codex" "claude" "pi"; do
    if resolve_tool "$t"; then
        AVAILABLE_TOOLS+=("$t")
    fi
done

if [ ${#AVAILABLE_TOOLS[@]} -gt 0 ]; then
    VALID_TOOLS=("${AVAILABLE_TOOLS[@]}")
else
    VALID_TOOLS=()
    echo "Warning: No supported AI tools found. Please install one of: qwen, opencode, cline, kilocode, iflow, gemini, oracle, codex, claude, pi."
fi

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
    
    # 确保日志目录存在
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
  -t, --tool <TOOL>      AI 工具: ${VALID_TOOLS[*]}
  -m, --max <N>         最大迭代次数 (默认: 10)
  -p, --project <DIR>  项目目录
  -y, --no-interactive  跳过交互式确认
  -b, --tmux            在 tmux 后台会话中运行
  -s, --session <NAME>  指定 tmux 会话名称
  -sp, --superpowers    全程采用 Superpowers (obra/superpowers) AI 开发模式规范
  -l, --log             显示日志
  -h, --help            显示帮助

${CYAN}示例:${NC}
  /ralph 帮我修复登录 bug
  /ralph -t cline 编写自动化部署脚本
  /ralph --tool opencode --max 20 --project /path/to/project 实现用户认证
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
# 解析命令行参数
# ============================================================
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
            -b|--tmux)
                USE_TMUX=true
                shift
                ;;
            -s|--session)
                USE_TMUX=true
                SESSION_NAME="$2"
                shift 2
                ;;
            -sp|--superpowers)
                USE_SUPERPOWERS=true
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
                log ERROR "未知选项: $1"
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
        # 简单 YAML 解析
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
# 验证工具是否有效
# ============================================================
validate_tool() {
    local tool="$1"
    for valid in "${VALID_TOOLS[@]}"; do
        [[ "$tool" == "$valid" ]] && return 0
    done
    return 1
}

# ============================================================
# 关键词匹配 - 选择最合适的工具
# ============================================================
match_tool() {
    local task="$1"
    local matched_tool=""
    
    if [[ ! -f "$KEYWORDS_FILE" ]]; then
        echo "qwen"
        return
    fi
    
    while IFS=',' read -r keyword tool; do
        # 跳过注释和空行
        [[ "$keyword" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$keyword" ]] && continue
        
        # 不区分大小写匹配
        if echo "$task" | grep -qi "$keyword"; then
            matched_tool="$tool"
            log INFO "关键词匹配: '$keyword' -> $tool"
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
        "$PWD/ralph.sh"
        "$HOME/workspace/ralph-fork/ralph.sh"
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
    echo -e "   工具:     ${GREEN}$TOOL${NC}"
    echo -e "   迭代次数: ${GREEN}$MAX_ITERATIONS${NC}"
    echo -e "   项目目录: ${GREEN}${PROJECT_DIR:-当前目录}${NC}"
    echo ""
    echo -e "${CYAN}📌 操作:${NC}"
    echo -e "   [回车] 确认执行"
    echo -e "   [q/Q]  退出"
    echo -e "   [工具 qwen] 修改工具"
    echo -e "   [迭代 20] 修改迭代次数"
    echo ""
    echo -n "➜ "
    
    read -r confirm
    
    # 处理用户输入
    case "$confirm" in
        q|Q)
            log INFO "用户取消执行"
            echo "已取消"
            exit 0
            ;;
        工具\ *)
            TOOL="${confirm#工具 }"
            validate_tool "$TOOL" || {
                log ERROR "无效工具: $TOOL，有效工具: ${VALID_TOOLS[*]}"
                exit 1
            }
            echo "工具已修改为: $TOOL"
            ;;
        迭代\ *)
            MAX_ITERATIONS="${confirm#迭代 }"
            echo "迭代次数已修改为: $MAX_ITERATIONS"
            ;;
        max\ *)
            MAX_ITERATIONS="${confirm#max }"
            echo "迭代次数已修改为: $MAX_ITERATIONS"
            ;;
    esac
}

# ============================================================
# 显示工具信息
# ============================================================
show_tool_info() {
    local tool="$1"
    
    case "$tool" in
        qwen)
            echo "qwen - 通用 AI 助手（负载均衡模式）"
            ;;
        opencode)
            echo "opencode - 专业代码开发工具"
            ;;
        cline)
            echo "cline - 终端/脚本开发工具"
            ;;
        kilocode)
            echo "kilocode - 交互式编码工具"
            ;;
        iflow)
            echo "iflow - 工作流/数据处理工具"
            ;;
        gemini)
            echo "gemini - Google AI 工具"
            ;;
        oracle)
            echo "oracle - 架构咨询工具"
            ;;
        codex)
            echo "codex - 专注于自动执行的编程工具 (支持 background-first)"
            ;;
        claude)
            echo "claude - Claude Code"
            ;;
        pi)
            echo "pi - Pi Coding Agent"
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
    
    # 查找 ralph.sh
    find_ralph || {
        log ERROR "未找到 ralph.sh"
        echo ""
        echo -e "${RED}错误: 找不到 ralph.sh${NC}"
        echo ""
        echo "请确保 ralph.sh 位于以下位置之一:"
        echo "  - ~/.openclaw/workspace/ralph-fork/ralph.sh"
        echo "  - ~/decentralized-box/ralph.sh"
        echo "  - $PWD/ralph.sh"
        echo ""
        echo "或运行安装脚本: bash install-skill.sh"
        exit 1
    }
    
    echo ""
    echo -e "${GREEN}✓${NC} 找到 ralph.sh: $RALPH_PATH"
    echo ""
    
    # 构建命令
    local cmd="bash '$RALPH_PATH' --tool '$tool' --max '$max'"
    [[ -n "$project" ]] && cmd="$cmd --project '$project'"
    if [ "$USE_TMUX" = true ]; then cmd="$cmd --tmux"; fi
    if [ "$USE_SUPERPOWERS" = true ]; then cmd="$cmd --superpowers"; fi
    cmd="$cmd '$task'"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}执行命令:${NC}"
    echo -e "${YELLOW}$cmd${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    log INFO "执行: tool=$tool, max=$max, project=${project:-none}, tmux=$USE_TMUX"
    
    # 执行
    if [ "$USE_TMUX" = true ]; then
        if ! command -v tmux &> /dev/null; then
            echo -e "${RED}错误: 未安装 tmux。请先运行 'sudo apt install tmux'。${NC}"
            exit 1
        fi

        # 自动生成名称
        if [ -z "$SESSION_NAME" ]; then
            SESSION_NAME="ralph_$(date +%s)"
        fi

        echo -e "🚀 将在 ${GREEN}tmux${NC} 后台启动任务，会话名称: ${BOLD}$SESSION_NAME${NC}"

        # 启动 tmux
        tmux new-session -d -s "$SESSION_NAME"

        # 如果指定了项目路径，先切换过去
        if [ -n "$project" ]; then
            tmux send-keys -t "$SESSION_NAME" "cd '$project'" Enter
        fi

        # 发送命令
        tmux send-keys -t "$SESSION_NAME" "$cmd" Enter

        echo ""
        echo -e "✅ 任务已在后台挂起！"
        echo -e "   查看进度请执行: ${YELLOW}tmux attach-session -t $SESSION_NAME${NC}"
        echo -e "   列出所有后台任务: ${YELLOW}tmux ls${NC}"
    else
        eval "$cmd"
    fi
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
                                                      
 Ralph Orchestration Skill v1.0.0

EOF
}

# ============================================================
# 主函数
# ============================================================
main() {
    # 显示横幅
    show_banner
    
    # 解析参数
    parse_args "$@"
    
    # 加载配置
    load_config
    
    # 检查任务
    if [[ -z "$TASK" ]]; then
        echo -e "${YELLOW}请输入任务描述:${NC}"
        read -r TASK
    fi
    
    if [[ -z "$TASK" ]]; then
        show_help
        exit 1
    fi
    
    # 自动匹配工具（如果未指定）
    if [[ "$TOOL" == "qwen" ]]; then
        local matched
        matched=$(match_tool "$TASK")
        TOOL="$matched"
        log INFO "自动匹配工具: $TOOL"
    fi
    
    # 验证工具
    validate_tool "$TOOL" || {
        log ERROR "无效工具: $TOOL，有效工具: ${VALID_TOOLS[*]}"
        exit 1
    }
    
    # 显示选中的工具信息
    echo -e "${GREEN}✓${NC} 选中工具: $(show_tool_info "$TOOL")"
    
    # 交互模式
    if $INTERACTIVE; then
        interactive_qa
    fi
    
    # 执行
    execute_ralph "$TOOL" "$MAX_ITERATIONS" "$PROJECT_DIR" "$TASK"
}

main "$@"