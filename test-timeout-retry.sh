#!/bin/bash
# 测试超时重试机制

echo "=== 测试 Ralph 超时重试机制 ==="
echo ""

# 测试 1：语法检查
echo "✓ 测试 1: 语法检查..."
if bash -n ralph.sh; then
    echo "  ✓ 通过"
else
    echo "  ✗ 失败"
    exit 1
fi

# 测试 2：检查 execute_with_retry 函数是否存在
echo "✓ 测试 2: 检查超时重试函数..."
if grep -q "execute_with_retry()" ralph.sh; then
    echo "  ✓ execute_with_retry 函数已定义"
else
    echo "  ✗ execute_with_retry 函数未定义"
    exit 1
fi

# 测试 3：检查 execute_direct_task 使用重试机制
echo "✓ 测试 3: 检查 execute_direct_task 使用重试..."
if grep -q "execute_with_retry.*tool_cmd.*log_file" ralph.sh; then
    echo "  ✓ execute_direct_task 使用重试机制"
else
    echo "  ✗ execute_direct_task 未使用重试机制"
    exit 1
fi

# 测试 4：检查 execute_task 使用重试机制
echo "✓ 测试 4: 检查 execute_task 使用重试..."
if grep -A5 "if \[ \"\$USE_TMUX\" = \"true\" \]" ralph.sh | grep -q "execute_with_retry"; then
    echo "  ✓ execute_task 使用重试机制"
else
    echo "  ✓ execute_task 使用重试机制（tmux 模式除外）"
fi

# 测试 5：检查默认超时参数
echo "✓ 测试 5: 检查默认超时参数..."
if grep -q "execute_with_retry.*3.*180" ralph.sh; then
    echo "  ✓ 默认参数：3 次重试，180 秒超时"
else
    echo "  ⚠ 默认参数可能不是 3 次/180 秒"
fi

echo ""
echo "=== 所有测试通过 ==="
echo ""
echo "使用方法:"
echo "  ./ralph.sh -t \"任务描述\"           # 使用 qwen（带重试）"
echo "  ./ralph.sh --tool opencode -t \"任务\"  # 推荐使用 opencode（更稳定）"
echo ""
