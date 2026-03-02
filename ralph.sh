#!/bin/bash
# Ralph Wiggum - SPECKit 驱动 + 多工具支持
# 支持: qwen, opencode, cline, kilocode, iflow
# Usage: ./ralph.sh [--tool qwen|opencode|cline|kilocode|iflow] [max_iterations]

set -e

# 默认设置
TOOL="qwen"
MAX_ITERATIONS=10
PROJECT_DIR="/mnt/data/dev/decentralized-box"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    status)
      show_status
      exit 0
      ;;
    spec|generate-specs)
      generate_specs
      exit 0
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# 验证工具
VALID_TOOLS=("qwen" "opencode" "cline" "kilocode" "iflow")
if [[ ! " ${VALID_TOOLS[@]} " =~ " ${TOOL} " ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be: ${VALID_TOOLS[*]}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
SPECS_DIR="$SCRIPT_DIR/specs/active"
LOG_DIR="/mnt/data/dev/tmp/ralph-$(date +%Y%m%d)/logs"

mkdir -p "$LOG_DIR" "$SPECS_DIR" "$ARCHIVE_DIR"

# ============================================
# 辅助函数
# ============================================

show_status() {
  echo "=== Ralph Status ==="
  if [ -f "$PRD_FILE" ]; then
    total=$(jq '.userStories | length' "$PRD_FILE")
    completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
    echo "Progress: $completed / $total tasks"
    echo ""
    jq -r '.userStories[] | select(.passes == false) | "- [\(.priority)] \(.id): \(.title)"' "$PRD_FILE"
  else
    echo "No prd.json found"
  fi
}

# 生成 specs (如果还没有)
generate_specs() {
  if [ -f "$PRD_FILE" ]; then
    "$SCRIPT_DIR/generate-specs.sh" "$PRD_FILE" "$SPECS_DIR" 2>/dev/null || true
  fi
}

# 归档之前的运行
archive_previous_run() {
  if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
      DATE=$(date +%Y-%m-%d)
      FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
      ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
      
      echo "📦 Archiving previous run: $LAST_BRANCH"
      mkdir -p "$ARCHIVE_FOLDER"
      [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
      [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
      
      # 移动 specs 到 archive
      if [ -d "$SPECS_DIR" ]; then
        mv "$SPECS_DIR" "$ARCHIVE_FOLDER/specs" 2>/dev/null || true
        mkdir -p "$SPECS_DIR"
      fi
      
      echo "   → Archived to: $ARCHIVE_FOLDER"
    fi
  fi
}

# 获取下一个任务
get_next_task() {
  if [ -f "$PRD_FILE" ]; then
    jq -r '.userStories[] | select(.passes == false) | @json' "$PRD_FILE" 2>/dev/null | head -1 | jq -r '.id + "|" + .title'
  fi
}

# 验证 spec 文件存在，不存在则创建
ensure_spec_file() {
  local task_id="$1"
  local spec_file="$SPECS_DIR/${task_id}.md"
  
  if [ ! -f "$spec_file" ]; then
    # 从 PRD 获取任务信息生成 spec
    local task_info=$(jq -r ".userStories[] | select(.id == \"$task_id\")" "$PRD_FILE" 2>/dev/null)
    if [ -n "$task_info" ]; then
      local title=$(echo "$task_info" | jq -r '.title')
      local desc=$(echo "$task_info" | jq -r '.description')
      local criteria=$(echo "$task_info" | jq -r '.acceptanceCriteria[]' 2>/dev/null || echo "")
      
      cat > "$spec_file" << EOF
# Specification: $task_id - $title

## Description
$desc

## Acceptance Criteria
$criteria

## Status
- [ ] Research
- [ ] Plan  
- [ ] Implement
- [ ] Verify

EOF
      echo "📝 Created spec: $spec_file"
    fi
  fi
}

# 选择负载最低的工具
select_lightest_tool() {
  local min=999
  local tool="$TOOL"
  for t in "${VALID_TOOLS[@]}"; do
    count=$(pgrep -c -f "$t" 2>/dev/null || echo 0)
    if [[ $count -lt $min ]]; then
      min=$count
      tool=$t
    fi
  done
  echo "$tool"
}

# 执行 AI 任务
execute_task() {
  local task_id="$1"
  local task_title="$2"
  local timestamp=$(date +%Y%m%d-%H%M%S)
  
  # 创建工作树
  local branch_name="ralph-$task_id-$timestamp"
  local worktree_dir="/mnt/data/dev/tmp/$branch_name"
  
  cd "$PROJECT_DIR"
  
  # 确定基础分支
  local base_branch="main"
  git rev-parse --verify dev >/dev/null 2>&1 && base_branch="dev"
  
  echo "🌿 Creating worktree: $branch_name"
  
  if ! git worktree add "$worktree_dir" -b "$branch_name" 2>/dev/null; then
    echo "Error: Failed to create worktree"
    return 1
  fi
  
  cd "$worktree_dir"
  
  # SPECKit: 确保有 spec 文件
  ensure_spec_file "$task_id"
  
  echo "[RALPH] Using $TOOL for: $task_id - $task_title"
  echo "[RALPH] Worktree: $worktree_dir"
  
  # 构建任务提示
  local TASK_PROMPT="完成以下任务: $task_title
  
参考规格文件: $SPECS_DIR/${task_id}.markdown
  
按照 SPECKit 流程:
1. Research - 研究代码
2. Plan - 规划实现
3. Implement - 实施代码
  
完成后:
- 运行质量检查 (typecheck/tests)
- 提交代码: git commit -m \"feat: $task_id - $task_title\"
- 标记任务完成"
  
  # 执行任务
  case "$TOOL" in
    qwen)
      qwen -p "$TASK_PROMPT" 2>&1 | tee -a "$LOG_DIR/ralph-$timestamp.log"
      ;;
    opencode)
      opencode run --task="$TASK_PROMPT" 2>&1 | tee -a "$LOG_DIR/ralph-$timestamp.log"
      ;;
    cline)
      cline "$TASK_PROMPT" 2>&1 | tee -a "$LOG_DIR/ralph-$timestamp.log"
      ;;
    kilocode)
      kilocode run "$TASK_PROMPT" 2>&1 | tee -a "$LOG_DIR/ralph-$timestamp.log"
      ;;
    iflow)
      iflow run --config="$TASK_PROMPT" 2>&1 | tee -a "$LOG_DIR/ralph-$timestamp.log"
      ;;
  esac
  
  # 提交更改
  if ! git diff --quiet 2>/dev/null; then
    git add -A
    git commit -m "feat: $task_id - $task_title" 2>/dev/null || true
    git push -u origin "$branch_name" 2>/dev/null || true
  fi
  
  # 清理工作树
  cd "$PROJECT_DIR"
  git worktree remove "$worktree_dir" --force 2>/dev/null || true
  git branch -D "$branch_name" 2>/dev/null || true
  
  # 移动 spec 到 archive
  if [ -f "$SPECS_DIR/${task_id}.md" ]; then
    mv "$SPECS_DIR/${task_id}.md" "$SPECS_DIR/../archive/" 2>/dev/null || true
  fi
  
  echo "✅ Completed: $task_id - $task_title"
}

# ============================================
# 主循环
# ============================================

LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# 初始化进度文件
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "Tool: $TOOL" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# 归档之前的运行
archive_previous_run

# 生成 specs
generate_specs

# 跟踪当前分支
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

echo "🚀 Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "📁 Log directory: $LOG_DIR"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "  🔄 Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "════════════════════════════════════════════════════════════"
  
  # 获取下一个任务
  TASK_INFO=$(get_next_task)
  
  if [ -z "$TASK_INFO" ]; then
    echo ""
    echo "🎉 All tasks completed!"
    exit 0
  fi
  
  TASK_ID=$(echo "$TASK_INFO" | cut -d'|' -f1)
  TASK_TITLE=$(echo "$TASK_INFO" | cut -d'|' -f2-)
  
  echo "📋 Next task: [$TASK_ID] $TASK_TITLE"
  
  # 执行任务
  execute_task "$TASK_ID" "$TASK_TITLE"
  
  # 更新 prd.json 标记任务完成
  if [ -f "$PRD_FILE" ]; then
    local tmp_file=$(mktemp)
    jq --arg id "$TASK_ID" '.userStories[] | select(.id == $id) | .passes = true' "$PRD_FILE" > "$tmp_file" && mv "$tmp_file" "$PRD_FILE"
  fi
  
  # 记录进度
  echo "## $(date) - $TASK_ID: $TASK_TITLE" >> "$PROGRESS_FILE"
  echo "Completed in iteration $i" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
  
  sleep 2
done

echo ""
echo "⚠️ Ralph reached max iterations ($MAX_ITERATIONS)"
echo "Check $PROGRESS_FILE for status."
exit 1