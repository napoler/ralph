#!/bin/bash
# ============================================
# SPEC.md 生成器
# 从 PRD user story 生成详细规格文档
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="${1:-$SCRIPT_DIR/prd.json}"
OUTPUT_DIR="${2:-$SCRIPT_DIR/specs/active}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 检查依赖
check_deps() {
  if ! command -v jq &>/dev/null; then
    log_warn "jq not found, using fallback parsing"
  fi
}

# 生成单个故事的 spec
generate_spec() {
  local story_id="$1"
  local story_json="$2"
  local output_file="$OUTPUT_DIR/${story_id}.md"
  
  local title=$(echo "$story_json" | jq -r '.title')
  local desc=$(echo "$story_json" | jq -r '.description')
  local priority=$(echo "$story_json" | jq -r '.priority')
  
  # 获取 acceptance criteria
  local criteria=""
  while IFS= read -r line; do
    criteria+="- $line\n"
  done < <(echo "$story_json" | jq -r '.acceptanceCriteria[]')
  
  # 获取 RPI
  local research=""
  local plan=""
  local implementation=""
  
  if echo "$story_json" | jq -e '.spec' >/dev/null 2>&1; then
    research=$(echo "$story_json" | jq -r '.spec.research // "待研究"')
    plan=$(echo "$story_json" | jq -r '.spec.plan // "待规划"')
    implementation=$(echo "$story_json" | jq -r '.spec.implementation // "待实施"')
  fi
  
  # 生成 spec.md
  cat > "$output_file" << EOF
# Specification: $story_id

## Story Info
| Field | Value |
|-------|-------|
| **ID** | $story_id |
| **Title** | $title |
| **Priority** | $priority |

## Description
$desc

---

## RPI Execution

### 🔬 Research (研究)
- [ ] $research

### 📋 Plan (规划)
1. $plan

### ⚡ Implement (实施)
- [ ] $implementation

---

## Acceptance Criteria

$criteria

---

## Verification Checklist

- [ ] 代码实现完成
- [ ] 类型检查通过 (Typecheck passes)
- [ ] 测试通过 (如有)
- [ ] UI 验证 (如适用)
- [ ] 文档更新 (如有需要)

---

## Notes

<!-- 在此添加执行过程中的笔记 -->

EOF

  log_info "Generated: $output_file"
}

# 主函数
main() {
  check_deps
  
  # 检查 PRD 文件
  if [ ! -f "$PRD_FILE" ]; then
    log_warn "PRD file not found: $PRD_FILE"
    echo "Usage: $0 [prd.json] [output_dir]"
    exit 1
  fi
  
  # 创建输出目录
  mkdir -p "$OUTPUT_DIR"
  
  log_info "Generating specs from: $PRD_FILE"
  log_info "Output directory: $OUTPUT_DIR"
  
  # 遍历所有未完成的任务
  local stories=$(jq -c '.userStories[] | select(.passes == false)' "$PRD_FILE")
  
  if [ -z "$stories" ]; then
    log_info "No pending tasks found!"
    exit 0
  fi
  
  while IFS= read -r story; do
    if [ -n "$story" ]; then
      local id=$(echo "$story" | jq -r '.id')
      generate_spec "$id" "$story"
    fi
  done <<< "$stories"
  
  log_info "Spec generation complete!"
  log_info "Total specs: $(echo "$stories" | wc -l)"
}

main "$@"