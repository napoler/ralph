#!/bin/bash
# ============================================
# Ralph 安装脚本
# 快速安装 ralph 到目标项目
# ============================================

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认值
RALPH_REPO="https://github.com/napoler/ralph.git"
TARGET_DIR=""
FORCE=""
SKIP_DEPS=""

# 显示帮助
if [[ "$1" =~ (-h|--help) ]]; then
    cat << EOF
Ralph 安装脚本

用法: $0 [选项] [目标目录]

选项:
  -h, --help           显示帮助
  --repo URL           Ralph 仓库地址 (默认: $RALPH_REPO)
  --force              强制覆盖已存在的文件
  --skip-deps          跳过依赖检查
  --source-dir DIR     从本地目录安装 (用于开发)

示例:
  # 安装到当前目录
  $0 .
  
  # 安装到指定目录
  $0 /path/to/my-project
  
  # 从本地目录安装
  $0 --source-dir /path/to/ralph-fork .
  
  # 指定自定义仓库
  $0 --repo https://github.com/your/fork .
EOF
    exit 0
fi

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            RALPH_REPO="$2"
            shift 2
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --skip-deps)
            SKIP_DEPS="true"
            shift
            ;;
        --source-dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# 默认目标目录
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Ralph Installation                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# 检查目录
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: 目录不存在: $TARGET_DIR${NC}"
    exit 1
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${RED}Error: 不是 git 仓库: $TARGET_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}目标项目:${NC} $TARGET_DIR"

# 检查依赖
check_deps() {
    echo ""
    echo -e "${YELLOW}检查依赖...${NC}"
    
    local missing=()
    
    # 检查必需命令
    for cmd in git jq; do
        if ! command -v $cmd &>/dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}缺少依赖: ${missing[*]}${NC}"
        echo "安装: apt install ${missing[*]}"
        exit 1
    fi
    
    # 检查可选命令
    echo "  ✓ git, jq"
    
    # 检查 AI 工具
    echo ""
    echo "AI 工具:"
    for tool in qwen opencode cline kilocode iflow; do
        if command -v $tool &>/dev/null; then
            echo -e "  ✓ $tool"
        else
            echo -e "  - $tool (未安装)"
        fi
    done
    
    echo -e "${GREEN}依赖检查完成${NC}"
}

# 创建 ralph 目录
setup_ralph_dir() {
    local ralph_dir="$TARGET_DIR/.ralph"
    
    if [ -d "$ralph_dir" ]; then
        if [ "$FORCE" = "true" ]; then
            echo -e "${YELLOW}覆盖现有 .ralph 目录${NC}"
        else
            echo -e "${YELLOW}.ralph 已存在，使用 --force 覆盖${NC}"
            return 0
        fi
    fi
    
    mkdir -p "$ralph_dir"
    echo -e "${GREEN}创建目录: $ralph_dir${NC}"
}

# 克隆/复制 ralph
install_ralph() {
    local ralph_dir="$TARGET_DIR/.ralph"
    
    if [ -n "$SOURCE_DIR" ]; then
        # 从本地目录安装
        echo -e "${GREEN}从本地安装: $SOURCE_DIR${NC}"
        
        # 复制文件
        cp -r "$SOURCE_DIR"/* "$ralph_dir/" 2>/dev/null || true
        
        # 复制隐藏文件
        for f in "$SOURCE_DIR"/.*; do
            [ "$(basename $f)" = "." ] && continue
            [ "$(basename $f)" = ".." ] && continue
            cp -r "$f" "$ralph_dir/" 2>/dev/null || true
        done
        
    else
        # 克隆仓库
        echo -e "${GREEN}克隆 Ralph: $RALPH_REPO${NC}"
        
        # 使用 git clone --depth 1 减少下载量
        if [ -d "$ralph_dir/.git" ]; then
            cd "$ralph_dir"
            git pull 2>/dev/null || true
            cd - > /dev/null
        else
            rm -rf "$ralph_dir"
            git clone --depth 1 "$RALPH_REPO" "$ralph_dir"
        fi
    fi
    
    # 创建 prd.json 如果不存在
    if [ ! -f "$ralph_dir/prd.json" ]; then
        if [ -f "$ralph_dir/prd.json.example" ]; then
            cp "$ralph_dir/prd.json.example" "$ralph_dir/prd.json"
            echo -e "${GREEN}创建 prd.json (请编辑添加任务)${NC}"
        fi
    fi
}

# 创建符号链接
create_symlinks() {
    echo ""
    echo -e "${YELLOW}创建命令链接...${NC}"
    
    # 创建 ralph 命令 (可选)
    local bin_dir="$TARGET_DIR/.ralph/bin"
    mkdir -p "$bin_dir"
    
    # 创建便捷脚本
    cat > "$bin_dir/ralph" << 'RALPHEOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
exec "$SCRIPT_DIR/ralph.sh" "$@"
RALPHEOF
    chmod +x "$bin_dir/ralph"
    
    # 添加到 PATH (通过 .bashrc 或 .zshrc)
    local shell_rc="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && shell_rc="$HOME/.zshrc"
    
    local ralph_path="$TARGET_DIR/.ralph/bin"
    if ! grep -q "$ralph_path" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Ralph" >> "$shell_rc"
        echo "export PATH=\"$ralph_path:\$PATH\"" >> "$shell_rc"
        echo -e "${GREEN}添加 PATH 到 $shell_rc${NC}"
    fi
    
    echo -e "${GREEN}创建命令: ralph${NC}"
}

# 初始化任务
init_tasks() {
    echo ""
    echo -e "${YELLOW}初始化任务...${NC}"
    
    local ralph_dir="$TARGET_DIR/.ralph"
    
    # 创建示例 PRD
    if [ -f "$ralph_dir/prd.json.example" ] && [ ! -f "$ralph_dir/prd.json" ]; then
        cp "$ralph_dir/prd.json.example" "$ralph_dir/prd.json"
    fi
    
    # 创建目录结构
    mkdir -p "$ralph_dir/specs/active"
    mkdir -p "$ralph_dir/specs/archive"
    mkdir -p "$ralph_dir/archive"
    mkdir -p "$ralph_dir/logs"
    
    echo -e "${GREEN}目录结构创建完成${NC}"
}

# 配置项目
configure_project() {
    echo ""
    echo -e "${YELLOW}配置项目...${NC}"
    
    local ralph_dir="$TARGET_DIR/.ralph"
    
    # 检查是否有 ralph.conf
    if [ -f "$ralph_dir/ralph.conf" ]; then
        # 更新项目路径
        sed -i "s|RALPH_PROJECT_DIR=.*|RALPH_PROJECT_DIR=\"$TARGET_DIR\"|" "$ralph_dir/ralph.conf"
        echo -e "${GREEN}更新项目路径: $TARGET_DIR${NC}"
    fi
}

# 显示完成信息
show_summary() {
    local ralph_dir="$TARGET_DIR/.ralph"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         安装完成!                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo "使用方法:"
    echo "  cd $TARGET_DIR"
    echo "  .ralph/ralph.sh status          # 查看状态"
    echo "  .ralph/ralph.sh spec           # 生成规格"
    echo "  .ralph/ralph.sh --tool qwen    # 运行任务"
    echo ""
    echo "或者添加到 PATH 后:"
    echo "  ralph status"
    echo "  ralph --tool opencode --max 10"
    echo ""
    echo "配置文件: $ralph_dir/ralph.conf"
    echo "任务定义: $ralph_dir/prd.json"
    echo ""
    
    # 提醒编辑 PRD
    if grep -q '"passes": false' "$ralph_dir/prd.json" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  请编辑 prd.json 添加你的任务${NC}"
    fi
}

# ========== 主流程 ==========

# 检查依赖
[ -z "$SKIP_DEPS" ] && check_deps

# 设置目录
setup_ralph_dir

# 安装 ralph
install_ralph

# 初始化
init_tasks

# 配置
configure_project

# 完成
show_summary