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
TARGET_DIR=""
FORCE=""
SKIP_DEPS=""

# 显示帮助
if [[ "$1" =~ (-h|--help) ]]; then
    cat << EOF
Ralph 安装脚本

用法：$0 [选项] [目标目录]

选项:
  -h, --help           显示帮助
  --force              强制覆盖已存在的文件
  --skip-deps          跳过依赖检查
  --source-dir DIR     从本地目录安装 (用于开发)

示例:
  # 安装到当前目录
  $0 .

  # 安装到指定目录
  $0 /path/to/my-project

  # 从本地目录安装
  $0 --source-dir /mnt/data/dev/decentralized-box/ralph .
EOF
    exit 0
fi

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
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
            if [ -z "$SOURCE_DIR" ]; then
                SOURCE_DIR="$(pwd)"
            fi
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# 默认目标目录
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)"
fi

# 默认源目录
if [ -z "$SOURCE_DIR" ]; then
    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Ralph 安装脚本                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# 检查目录
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: 目录不存在：$TARGET_DIR${NC}"
    exit 1
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${RED}Error: 不是 git 仓库：$TARGET_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}目标项目：${NC} $TARGET_DIR"
echo -e "${GREEN}源目录：${NC} $SOURCE_DIR"

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
        echo -e "${RED}缺少依赖：${missing[*]}${NC}"
        echo "安装：apt install ${missing[*]}"
        exit 1
    fi

    echo "  ✓ git, jq"
    echo -e "${GREEN}依赖检查完成${NC}"
}

# 创建 ralph 目录
setup_ralph_dir() {
    local ralph_dir="$TARGET_DIR/ralph"

    if [ -d "$ralph_dir" ]; then
        if [ "$FORCE" = "true" ]; then
            echo -e "${YELLOW}覆盖现有 ralph 目录${NC}"
            rm -rf "$ralph_dir"
        else
            echo -e "${YELLOW}ralph 目录已存在，将更新文件${NC}"
        fi
    fi

    mkdir -p "$ralph_dir"
    echo -e "${GREEN}创建目录：$ralph_dir${NC}"

    # 复制核心文件
    cp "$SOURCE_DIR/ralph.sh" "$ralph_dir/"
    cp "$SOURCE_DIR/ralph.conf" "$ralph_dir/"
    cp "$SOURCE_DIR/cron-tasks-optimized.conf" "$ralph_dir/" 2>/dev/null || true
    cp "$SOURCE_DIR/generate-specs.sh" "$ralph_dir/" 2>/dev/null || true
    cp "$SOURCE_DIR/README.md" "$ralph_dir/" 2>/dev/null || true

    chmod +x "$ralph_dir/ralph.sh"
    chmod +x "$ralph_dir/generate-specs.sh" 2>/dev/null || true

    echo -e "${GREEN}✓ 核心文件复制完成${NC}"
}

# 初始化任务
init_tasks() {
    echo ""
    echo -e "${YELLOW}初始化任务...${NC}"

    local ralph_dir="$TARGET_DIR/ralph"

    # 创建目录结构
    mkdir -p "$ralph_dir/specs/active"
    mkdir -p "$ralph_dir/specs/archive"
    mkdir -p "$ralph_dir/archive"

    # 复制示例 PRD（如果目标项目没有 prd.json）
    if [ ! -f "$TARGET_DIR/prd.json" ] && [ -f "$SOURCE_DIR/prd.json.example" ]; then
        cp "$SOURCE_DIR/prd.json.example" "$TARGET_DIR/prd.json"
        echo -e "${GREEN}创建 prd.json (请编辑添加任务)${NC}"
    elif [ ! -f "$TARGET_DIR/prd.json" ]; then
        echo -e "${YELLOW}提示：请创建 prd.json 定义任务${NC}"
    fi

    echo -e "${GREEN}目录结构创建完成${NC}"
}

# 配置项目
configure_project() {
    echo ""
    echo -e "${YELLOW}配置项目...${NC}"

    local ralph_dir="$TARGET_DIR/ralph"

    # 更新 ralph.conf 中的项目路径
    if [ -f "$ralph_dir/ralph.conf" ]; then
        sed -i "s|RALPH_PROJECT_DIR=.*|RALPH_PROJECT_DIR=\"$TARGET_DIR\"|" "$ralph_dir/ralph.conf"
        echo -e "${GREEN}更新项目路径：$TARGET_DIR${NC}"
    fi
}

# 安装 Skill 到 .claude/skills/
install_skills() {
    echo ""
    echo -e "${YELLOW}安装 Skills 到 .claude/skills/...${NC}"

    local source_skills_dir="$SOURCE_DIR/../.claude/skills"
    local target_skills_dir="$TARGET_DIR/.claude/skills"

    # 检查源 skills 目录
    if [ ! -d "$source_skills_dir" ]; then
        echo -e "${YELLOW}跳过：源 skills 目录不存在：$source_skills_dir${NC}"
        return 0
    fi

    # 创建目标目录
    mkdir -p "$target_skills_dir"

    # 复制 ralph 相关 skills
    for skill in ralph ralph-orchestration; do
        if [ -d "$source_skills_dir/$skill" ]; then
            echo -e "${GREEN}复制 skill: $skill${NC}"
            rm -rf "$target_skills_dir/$skill"
            cp -r "$source_skills_dir/$skill" "$target_skills_dir/"
            chmod +x "$target_skills_dir/$skill"/*.sh 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✓ Skills 安装完成${NC}"
    echo "  位置：$target_skills_dir"
}

# 显示完成信息
show_summary() {
    local ralph_dir="$TARGET_DIR/ralph"

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         安装完成!                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo "使用方法:"
    echo "  cd $TARGET_DIR"
    echo "  ./ralph/ralph.sh status          # 查看状态"
    echo "  ./ralph/ralph.sh spec            # 生成规格"
    echo "  ./ralph/ralph.sh --tool qwen     # 运行任务"
    echo ""
    echo "配置文件：$ralph_dir/ralph.conf"
    echo "任务定义：$TARGET_DIR/prd.json"
    echo ""

    # 提醒编辑 PRD
    if [ -f "$TARGET_DIR/prd.json" ] && grep -q '"passes": false' "$TARGET_DIR/prd.json" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  请编辑 prd.json 添加你的任务${NC}"
    fi
}

# ========== 主流程 ==========

# 检查依赖
[ -z "$SKIP_DEPS" ] && check_deps

# 设置目录
setup_ralph_dir

# 初始化
init_tasks

# 配置
configure_project

# 安装 Skills
install_skills

# 完成
show_summary
