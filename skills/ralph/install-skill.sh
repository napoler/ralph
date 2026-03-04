#!/bin/bash
# ============================================================
# Ralph Orchestration Skill 安装脚本
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SKILL_DIR="$HOME/.config/opencode/skills/ralph"
RALPH_FORK_DIR="$HOME/.openclaw/workspace/ralph-fork"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      🤖 Ralph Orchestration Skill - 安装程序            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查 OpenCode 是否安装
if ! command -v opencode &> /dev/null; then
    echo -e "${RED}✗ 错误：未找到 opencode${NC}"
    echo "请先安装 OpenCode: https://opencode.ai"
    exit 1
fi
echo -e "${GREEN}✓ OpenCode 已安装${NC}"

# 检查 ralph.sh 是否存在
if [ -f "$RALPH_FORK_DIR/ralph.sh" ]; then
    RALPH_PATH="$RALPH_FORK_DIR/ralph.sh"
    echo -e "${GREEN}✓ 找到 ralph.sh: $RALPH_PATH${NC}"
else
    echo -e "${YELLOW}⚠ 未找到 ralph.sh，请在安装后设置 RALPH_PATH 环境变量${NC}"
    RALPH_PATH=""
fi

# 创建技能目录
echo ""
echo -e "${BLUE}正在安装技能...${NC}"
mkdir -p "$SKILL_DIR"

# 复制技能文件
echo "复制技能文件到 $SKILL_DIR"
cp "$(dirname "${BASH_SOURCE[0]}")/ralph-orchestration.sh" "$SKILL_DIR/"
chmod +x "$SKILL_DIR/ralph-orchestration.sh"

# 创建配置目录
mkdir -p "$SKILL_DIR"

# 复制配置文件
if [ ! -f "$SKILL_DIR/config.yaml" ]; then
    cp "$(dirname "${BASH_SOURCE[0]}")/config.yaml.example" "$SKILL_DIR/config.yaml"
    echo -e "${GREEN}✓ 创建配置文件：$SKILL_DIR/config.yaml${NC}"
else
    echo -e "${YELLOW}⚠ 配置文件已存在，跳过${NC}"
fi

# 复制关键词配置
cp "$(dirname "${BASH_SOURCE[0]}")/keywords.conf" "$SKILL_DIR/keywords.conf"
echo -e "${GREEN}✓ 创建关键词配置：$SKILL_DIR/keywords.conf${NC}"

# 创建文档目录
DOC_DIR="$RALPH_FORK_DIR/docs"
mkdir -p "$DOC_DIR"

# 复制文档
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../../docs/RALPH-ORCHESTRATION-GUIDE.md" ]; then
    cp "$(dirname "${BASH_SOURCE[0]}")/../../docs/RALPH-ORCHESTRATION-GUIDE.md" "$DOC_DIR/"
    echo -e "${GREEN}✓ 复制文档到 $DOC_DIR${NC}"
fi

# 设置环境变量提示
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN} 安装完成！${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
echo ""

if [ -n "$RALPH_PATH" ]; then
    echo -e "${GREEN}✓ ralph.sh 已自动检测：$RALPH_PATH${NC}"
    echo ""
    echo "建议将以下配置添加到 ~/.bashrc 或 ~/.zshrc:"
    echo ""
    echo -e "${YELLOW}  export RALPH_PATH=\"$RALPH_PATH\"${NC}"
    echo -e "${YELLOW}  export RALPH_SUPERPOWERS=true${NC}"
    echo -e "${YELLOW}  export RALPH_TMUX=true${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠ 需要手动设置 ralph.sh 路径${NC}"
    echo ""
    echo "请将以下配置添加到 ~/.bashrc 或 ~/.zshrc:"
    echo ""
    echo -e "${YELLOW}  export RALPH_PATH=\"/path/to/ralph.sh\"${NC}"
    echo -e "${YELLOW}  export RALPH_SUPERPOWERS=true${NC}"
    echo -e "${YELLOW}  export RALPH_TMUX=true${NC}"
    echo ""
fi

echo -e "${BLUE}📚 使用指南:${NC}"
echo "   查看文档：cat $DOC_DIR/RALPH-ORCHESTRATION-GUIDE.md"
echo ""

echo -e "${BLUE}🚀 快速开始:${NC}"
echo "   /ralph \"实现用户登录功能\""
echo "   /ralph --superpowers --tmux \"开发 REST API\""
echo "   /ralph --tool opencode --max 20 \"重构认证模块\""
echo ""

echo -e "${GREEN}安装成功！请重启 OpenCode 或重新加载配置。${NC}"
