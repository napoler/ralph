#!/bin/bash
# ralph.sh 参数传递测试

cd /home/terry/.openclaw/workspace/ralph-fork

echo "=== Ralph.sh 参数传递修复测试 ==="
echo

echo "1. 测试 CLI 参数优先级:"
echo "   bash ralph.sh --tool cline --max 5 status"
bash ralph.sh --tool cline --max 5 status 2>&1 | grep -E "^  (Tool|Max iterations)" || true
echo

echo "2. 测试环境变量优先级:"
echo "   RALPH_TOOL=gemini RALPH_MAX_ITERATIONS=12 bash ralph.sh status"
RALPH_TOOL=gemini RALPH_MAX_ITERATIONS=12 bash ralph.sh status 2>&1 | grep -E "^  (Tool|Max iterations)" || true
echo

echo "3. 测试 CLI 覆盖环境变量:"
echo "   RALPH_TOOL=gemini RALPH_MAX_ITERATIONS=12 bash ralph.sh --tool opencode --max 8 status"
RALPH_TOOL=gemini RALPH_MAX_ITERATIONS=12 bash ralph.sh --tool opencode --max 8 status 2>&1 | grep -E "^  (Tool|Max iterations)" || true
echo

echo "4. 测试项目目录参数:"
echo "   bash ralph.sh --project /test/dir --log-dir /test/logs status"
bash ralph.sh --project /test/dir --log-dir /test/logs status 2>&1 | grep -E "^  (Project|Log dir:)" || true
echo

echo "5. 测试所有参数组合:"
echo "   RALPH_PROJECT_DIR=/env/path bash ralph.sh --tool cline --max 7 --project /cli/path status"
RALPH_PROJECT_DIR=/env/path bash ralph.sh --tool cline --max 7 --project /cli/path status 2>&1 | grep -E "^  (Tool|Max iterations|Project:)" || true
echo

echo "=== 测试完成 ==="
echo "如果所有测试都显示正确的参数值，说明参数传递问题已修复。"