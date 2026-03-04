#!/bin/bash
# Ralph.sh 集成测试脚本
# 用法：bash test/integration.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RALPH_SH="$PROJECT_DIR/ralph.sh"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试统计
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_pattern="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}[TEST $TESTS_RUN]${NC} $test_name"
    
    if eval "$test_cmd" 2>&1 | grep -qE "$expected_pattern"; then
        echo -e "  ${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "=================================="
echo "Ralph 集成测试套件"
echo "=================================="
echo ""

# 切换到项目目录
cd "$PROJECT_DIR"

# ---------- 参数解析测试 ----------
echo -e "${YELLOW}=== 参数解析测试 ===${NC}"

run_test "CLI 工具参数" \
    "bash ralph.sh --tool cline status 2>&1" \
    "Tool: cline"

run_test "CLI 迭代次数参数" \
    "bash ralph.sh --max 5 status 2>&1" \
    "Max iterations: 5"

run_test "环境变量工具" \
    "RALPH_TOOL=opencode bash ralph.sh status 2>&1" \
    "Tool: opencode"

run_test "环境变量迭代次数" \
    "RALPH_MAX_ITERATIONS=12 bash ralph.sh status 2>&1" \
    "Max iterations: 12"

run_test "CLI 覆盖环境变量" \
    "RALPH_TOOL=opencode bash ralph.sh --tool cline status 2>&1" \
    "Tool: cline"

run_test "项目目录参数" \
    "bash ralph.sh --project /test/path status 2>&1" \
    "Project: /test/path"

# ---------- 帮助信息测试 ----------
echo ""
echo -e "${YELLOW}=== 帮助信息测试 ===${NC}"

run_test "帮助 -h" \
    "bash ralph.sh -h 2>&1" \
    "Ralph - AI Agent Loop"

run_test "帮助 --help" \
    "bash ralph.sh --help 2>&1" \
    "示例:"



# ---------- 命令测试 ----------
echo ""
echo -e "${YELLOW}=== 命令测试 ===${NC}"

run_test "status 命令" \
    "bash ralph.sh status 2>&1" \
    "Tool:"

run_test "spec 命令 (需 prd.json)" \
    "cp prd.json.example prd.json && bash ralph.sh spec 2>&1" \
    "Generated:.*US-"

# ---------- 配置文件测试 ----------
echo ""
echo -e "${YELLOW}=== 配置文件测试 ===${NC}"

run_test "配置文件加载" \
    "bash ralph.sh status 2>&1" \
    "Loaded config"

# ---------- 工具验证测试 ----------
echo ""
echo -e "${YELLOW}=== 工具验证测试 ===${NC}"

run_test "有效工具 qwen" \
    "bash ralph.sh --tool qwen status 2>&1" \
    "Tool: qwen"

run_test "短参数 --tool 简写" \
    "bash ralph.sh --tool cline status 2>&1" \
    "Tool: cline"

run_test "短参数 -m" \
    "bash ralph.sh -m 7 status 2>&1" \
    "Max iterations: 7"

# ---------- 总结 ----------
echo ""
echo "=================================="
echo "测试结果"
echo "=================================="
echo -e "运行：${TESTS_RUN}"
echo -e "通过：${GREEN}${TESTS_PASSED}${NC}"
echo -e "失败：${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过!${NC}"
    exit 0
else
    echo -e "${RED}✗ 有测试失败${NC}"
    exit 1
fi
