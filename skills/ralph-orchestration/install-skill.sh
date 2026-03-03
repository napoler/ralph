#!/bin/bash
# ============================================================
# Ralph Orchestration Skill - 安装脚本
# ============================================================
# 
# 将 skill 安装到 OpenCode 的 skills 目录
# 
# 用法:
#   bash install-skill.sh          # 交互式安装
#   bash install-skill.sh --force # 强制覆盖安装
#   bash install-skill.sh --uninstall # 卸载
# ============================================================

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="ralph-orchestration"
TARGET_DIR="${HOME}/.config/opencode/skills/${SKILL_NAME}"
SOURCE_DIR="${SCRIPT_DIR}"

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
                                                      
 Ralph Orchestration Skill - Installer v1.0.0

EOF
}

# ============================================================
# 检查依赖
# ============================================================
check_dependencies() {
    echo -e "${CYAN}检查依赖...${NC}"
    
    # 检查 OpenCode 配置目录
    if [[ ! -d "${HOME}/.config/opencode" ]]; then
        echo -e "${YELLOW}警告: OpenCode 配置目录不存在，将创建${NC}"
        mkdir -p "${HOME}/.config/opencode"
    fi
    
    # 检查技能源目录
    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo -e "${RED}错误: 源目录不存在: $SOURCE_DIR${NC}"
        exit 1
    fi
    
    # 检查必要文件
    local required_files=("ralph-orchestration.sh" "config.yaml" "keywords.conf" "skill.md")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SOURCE_DIR/$file" ]]; then
            echo -e "${RED}错误: 缺少必要文件: $file${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ 依赖检查通过${NC}"
}

# ============================================================
# 安装
# ============================================================
install() {
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                force=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    echo ""
    show_banner
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 检查目标目录
    if [[ -d "$TARGET_DIR" ]]; then
        if $force; then
            echo -e "${YELLOW}警告: 目标目录已存在，将覆盖安装${NC}"
            rm -rf "$TARGET_DIR"
        else
            echo -e "${YELLOW}目标目录已存在: $TARGET_DIR${NC}"
            echo -e "使用 ${GREEN}--force${NC} 强制覆盖"
            return 1
        fi
    fi
    
    # 创建目标目录
    echo -e "${CYAN}安装到: $TARGET_DIR${NC}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    
    # 复制文件
    echo -e "${CYAN}复制文件...${NC}"
    cp -r "$SOURCE_DIR" "$TARGET_DIR"
    
    # 设置权限
    echo -e "${CYAN}设置权限...${NC}"
    chmod +x "$TARGET_DIR/ralph-orchestration.sh"
    
    # 创建符号链接（可选）
    create_symlink
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ 安装成功!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}使用方法:${NC}"
    echo "  1. 直接调用:"
    echo "     bash ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh <任务>"
    echo ""
    echo "  2. 或创建别名 (添加到 ~/.bashrc):"
    echo "     alias ralph='bash ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh'"
    echo ""
    echo -e "${CYAN}示例:${NC}"
    echo "  ralph 帮我修复这个 bug"
    echo "  ralph -t cline 编写自动化脚本"
    echo "  ralph --tool opencode --max 20 实现功能"
    echo ""
    
    # 检查 ralph.sh
    check_ralph
    
    return 0
}

# ============================================================
# 创建符号链接
# ============================================================
create_symlink() {
    local bin_dir="${HOME}/.local/bin"
    local link_path="${bin_dir}/ralph"
    
    if [[ ! -d "$bin_dir" ]]; then
        mkdir -p "$bin_dir"
    fi
    
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
    fi
    
    ln -s "$TARGET_DIR/ralph-orchestration.sh" "$link_path"
    chmod +x "$link_path"
    
    # 检查是否在 PATH 中
    if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
        echo -e "${YELLOW}提示: 建议将 ${bin_dir} 添加到 PATH${NC}"
        echo "  echo 'export PATH=\$PATH:${bin_dir}' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
    
    echo -e "${GREEN}✓ 创建符号链接: $link_path${NC}"
}

# ============================================================
# 检查 ralph.sh
# ============================================================
check_ralph() {
    echo ""
    echo -e "${CYAN}检查 ralph.sh...${NC}"
    
    local ralph_paths=(
        "${HOME}/.openclaw/workspace/ralph-fork/ralph.sh"
        "${HOME}/decentralized-box/ralph.sh"
        "/mnt/data/dev/decentralized-box/ralph.sh"
    )
    
    for path in "${ralph_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo -e "${GREEN}✓ 找到: $path${NC}"
            return 0
        fi
    done
    
    echo -e "${YELLOW}警告: 未找到 ralph.sh${NC}"
    echo "  请确保 ralph.sh 已安装"
    return 1
}

# ============================================================
# 卸载
# ============================================================
uninstall() {
    echo -e "${YELLOW}卸载 Ralph Orchestration Skill...${NC}"
    
    if [[ -d "$TARGET_DIR" ]]; then
        rm -rf "$TARGET_DIR"
        echo -e "${GREEN}✓ 已删除: $TARGET_DIR${NC}"
    fi
    
    # 删除符号链接
    local link_path="${HOME}/.local/bin/ralph"
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
        echo -e "${GREEN}✓ 已删除符号链接: $link_path${NC}"
    fi
    
    echo -e "${GREEN}卸载完成!${NC}"
}

# ============================================================
# 显示状态
# ============================================================
status() {
    echo ""
    echo -e "${CYAN}Ralph Orchestration Skill - 状态${NC}"
    echo ""
    
    # 检查安装
    if [[ -d "$TARGET_DIR" ]]; then
        echo -e "安装状态: ${GREEN}已安装${NC}"
        echo -e "安装位置: $TARGET_DIR"
    else
        echo -e "安装状态: ${RED}未安装${NC}"
    fi
    
    echo ""
    
    # 检查 ralph.sh
    echo -e "${CYAN}ralph.sh 状态:${NC}"
    check_ralph
    
    echo ""
    
    # 显示文件列表
    if [[ -d "$TARGET_DIR" ]]; then
        echo -e "${CYAN}已安装文件:${NC}"
        ls -la "$TARGET_DIR"
    fi
    
    return 0
}

# ============================================================
# 主函数
# ============================================================
main() {
    local command="${1:-install}"
    
    case "$command" in
        install|--install)
            install "${@:2}"
            ;;
        uninstall|--uninstall|-u)
            uninstall
            ;;
        status|s)
            status
            ;;
        help|-h|--help)
            show_banner
            cat << 'EOF'

用法: bash install-skill.sh [命令] [选项]

命令:
  install     安装 skill (默认)
  uninstall   卸载 skill
  status      显示状态
  help        显示帮助

选项:
  -f, --force  强制覆盖安装

示例:
  bash install-skill.sh install
  bash install-skill.sh install --force
  bash install-skill.sh uninstall
  bash install-skill.sh status

EOF
            ;;
        *)
            echo -e "${RED}未知命令: $command${NC}"
            echo "使用 bash install-skill.sh help 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"