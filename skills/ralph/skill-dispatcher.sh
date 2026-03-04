#!/bin/bash
# ============================================================
# Superpowers 技能自动调度器 v2.0
# 
# 智能判断任务复杂度，自动决定是否使用 Superpowers 模式
# ============================================================

set -euo pipefail

# 技能目录
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPERPOWERS_SKILL_DIR="$HOME/.config/opencode/skills/superpowers"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "${HOME}/.ralph/skill-dispatcher.log"
    
    case "$level" in
        ERROR)   echo -e "${RED}✗ $message${NC}" ;;
        WARN)    echo -e "${YELLOW}⚠ $message${NC}" ;;
        SUCCESS) echo -e "${GREEN}✓ $message${NC}" ;;
        INFO)    echo -e "${BLUE}ℹ $message${NC}" ;;
        *)       echo "$message" ;;
    esac
}

# ============================================================
# 任务类型识别
# ============================================================

identify_task_type() {
    local task="$1"
    local task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    
    # 创造性任务（需要 brainstorming）
    if [[ "$task_lower" =~ (实现 | 开发 | 创建 | 构建 | 添加 | 新功能 | feature|create|build|implement|add) ]]; then
        echo "creative"
        return 0
    fi
    
    # Bug 修复（需要 debugging + TDD）
    if [[ "$task_lower" =~ (修复|bug|错误|问题 |fail|fix|repair|debug) ]]; then
        echo "bugfix"
        return 0
    fi
    
    # 重构任务（需要分析 + TDD）
    if [[ "$task_lower" =~ (重构 | 优化 | 改进 | 清理 |refactor|optimize|improve|clean) ]]; then
        echo "refactor"
        return 0
    fi
    
    # 审查任务
    if [[ "$task_lower" =~ (审查 | 检查 | 分析 |review|check|analyze|audit) ]]; then
        echo "review"
        return 0
    fi
    
    # 文档任务
    if [[ "$task_lower" =~ (文档 |readme|doc|文档编写 |write) ]]; then
        echo "documentation"
        return 0
    fi
    
    # 测试任务
    if [[ "$task_lower" =~ (测试 |test|unit test|integration test) ]]; then
        echo "testing"
        return 0
    fi
    
    # 默认：通用任务
    echo "general"
}

# ============================================================
# 任务复杂度评估 (v2.0 新增)
# ============================================================

# 复杂度评分项
declare -A COMPLEXITY_SCORES=(
    # 高复杂度模式 (+3)
    "系统":3 "架构":3 "设计":3 "framework":3 "architecture":3 "system":3
    "集成":3 "整合":3 "integrate":3 "integration":3
    "多模块":3 "多组件":3 "multi-module":3 "multi-component":3
    "完整":3 "end-to-end":3 "full":3
    
    # 中复杂度模式 (+2)
    "功能":2 "feature":2 "module":2 "component":2
    "API":2 "接口":2 "endpoint":2 "service":2
    "数据库":2 "database":2 "model":2 "schema":2
    "认证":2 "auth":2 "security":2 "permission":2
    "异步":2 "async":2 "concurrent":2 "parallel":2
    
    # 低复杂度模式 (+1)
    "修复":1 "fix":1 "bug":1 "error":1 "issue":1
    "添加":1 "add":1 "create":1 "new":1
    "更新":1 "update":1 "modify":1 "change":1
    "优化":1 "optimize":1 "improve":1 "refactor":1
    "脚本":1 "script":1 "tool":1 "util":1
)

# 评估任务复杂度
evaluate_complexity() {
    local task="$1"
    local task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    local score=0
    local indicators=()
    
    # 长度评分（长任务通常更复杂）
    local word_count=$(echo "$task" | wc -w)
    if [[ $word_count -gt 20 ]]; then
        score=$((score + 2))
        indicators+=("长度>20 词")
    elif [[ $word_count -gt 10 ]]; then
        score=$((score + 1))
        indicators+=("长度>10 词")
    fi
    
    # 关键词匹配评分
    for keyword in "${!COMPLEXITY_SCORES[@]}"; do
        if echo "$task_lower" | grep -qi "$keyword"; then
            local points="${COMPLEXITY_SCORES[$keyword]}"
            score=$((score + points))
            indicators+=("$keyword(+$points)")
        fi
    done
    
    # 检查是否涉及多个文件/模块
    if echo "$task_lower" | grep -qiE "(多个 | 所有|all|multiple|across|throughout)"; then
        score=$((score + 2))
        indicators+=("多文件")
    fi
    
    # 检查是否需要测试
    if echo "$task_lower" | grep -qiE "(测试|test|确保|ensure|verify|validate)"; then
        score=$((score + 1))
        indicators+=("需测试")
    fi
    
    # 输出结果
    local indicators_str=$(IFS=','; echo "${indicators[*]}")
    echo "$score|$indicators_str"
}

# ============================================================
# 智能决策：是否需要 Superpowers
# ============================================================

should_use_superpowers() {
    local task="$1"
    local task_type="$2"
    
    # 特定任务类型总是需要 Superpowers
    case "$task_type" in
        creative|bugfix|refactor)
            echo "true|auto_type:$task_type"
            return 0
            ;;
    esac
    
    # 评估复杂度
    local result=$(evaluate_complexity "$task")
    local score="${result%|*}"
    local indicators="${result#*|}"
    
    # 阈值判断
    if [[ $score -ge 4 ]]; then
        echo "true|complexity:$score($indicators)"
    elif [[ $score -ge 2 ]]; then
        # 中等复杂度，建议但不强制
        echo "suggested|complexity:$score($indicators)"
    else
        echo "false|simple:$score"
    fi
}

# ============================================================
# 显示 Superpowers 智能建议
# ============================================================

show_superpowers_suggestion() {
    local task="$1"
    local task_type="$2"
    local decision_result="$3"
    
    local use_sp="${decision_result%%|*}"
    local reason="${decision_result#*|}"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🦸 Superpowers 智能决策${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    case "$use_sp" in
        true)
            echo -e "${GREEN}✓ 自动启用 Superpowers 模式${NC}"
            echo -e "${BLUE}决策理由:${NC} $reason"
            echo -e "${BLUE}任务类型:${NC} $task_type"
            echo ""
            echo "将自动调度以下技能链:"
            case "$task_type" in
                creative)   echo "  📋 brainstorming → 📝 writing-plans → 🧪 TDD → ✅ verification" ;;
                bugfix)     echo "  🔍 systematic-debugging → 🧪 TDD → ✅ verification" ;;
                refactor)   echo "  📋 brainstorming → 📝 writing-plans → 🧪 TDD" ;;
                review)     echo "  🔎 requesting-code-review" ;;
                testing)    echo "  🧪 test-driven-development" ;;
                *)          echo "  🔄 根据任务动态选择" ;;
            esac
            echo ""
            echo -e "${GREEN}→ 正在注入 Superpowers 技能...${NC}"
            ;;
        suggested)
            echo -e "${YELLOW}⚠ 建议但不强制使用 Superpowers 模式${NC}"
            echo -e "${BLUE}决策理由:${NC} $reason"
            echo ""
            echo "可以使用 --superpowers 强制启用，或直接执行使用默认模式"
            ;;
        false)
            echo -e "${BLUE}ℹ 任务较简单，使用标准模式${NC}"
            echo -e "${BLUE}决策理由:${NC} $reason"
            echo ""
            echo "直接执行即可，如需使用 Superpowers 可添加 --superpowers 参数"
            ;;
    esac
    
    echo ""
}

# ============================================================
# 技能调度决策
# ============================================================

dispatch_skills() {
    local task_type="$1"
    local task="$2"
    
    case "$task_type" in
        creative)
            dispatch_creative_workflow "$task"
            ;;
        bugfix)
            dispatch_bugfix_workflow "$task"
            ;;
        refactor)
            dispatch_refactor_workflow "$task"
            ;;
        review)
            dispatch_review_workflow "$task"
            ;;
        documentation)
            dispatch_documentation_workflow "$task"
            ;;
        testing)
            dispatch_testing_workflow "$task"
            ;;
        general)
            dispatch_general_workflow "$task"
            ;;
    esac
}

# ============================================================
# 工作流定义
# ============================================================

dispatch_creative_workflow() {
    local task="$1"
    
    log INFO "任务类型：创造性开发"
    log INFO "调度技能链：brainstorming → writing-plans → TDD → verification"
    
    cat << EOF
[技能调度：创造性工作流]

1. brainstorming - 设计确认
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 设计完整的实现方案
     [REQUIREMENTS]:
     1. 探索项目上下文
     2. 提问澄清问题（一次一个）
     3. 提出 2-3 种方案
     4. 展示设计并获取批准
     5. 保存到 docs/plans/
     6. 调用 writing-plans 技能

2. writing-plans - 任务拆解
   prompt: |
     [CONTEXT]: 设计已批准
     [GOAL]: 拆解为 2-5 分钟的原子任务
     [REQUIREMENTS]:
     1. 每个任务包含精确文件路径
     2. 每个任务包含完整代码
     3. 遵循 TDD 循环
     4. 保存到 specs/tasks/

3. test-driven-development - 实现
   prompt: |
     [CONTEXT]: 按计划实现
     [GOAL]: TDD 实现每个任务
     [REQUIREMENTS]:
     1. RED: 编写失败测试
     2. GREEN: 最小实现
     3. REFACTOR: 重构优化
     4. 提供验证证据

4. verification-before-completion - 验证
   prompt: |
     [CONTEXT]: 实现完成
     [GOAL]: 验证所有功能
     [REQUIREMENTS]:
     1. 运行所有测试
     2. 类型检查
     3. 代码质量检查
     4. 提供实际证据

EOF
}

dispatch_bugfix_workflow() {
    local task="$1"
    
    log INFO "任务类型：Bug 修复"
    log INFO "调度技能链：systematic-debugging → TDD → verification"
    
    cat << EOF
[技能调度：Bug 修复工作流]

1. systematic-debugging - 根因分析
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 找到根本原因
     [REQUIREMENTS]:
     1. 阅读错误信息
     2. 复现问题
     3. 检查最近变更
     4. 收集证据（添加诊断）
     5. 追踪数据流
     6. 形成假设

2. test-driven-development - 修复
   prompt: |
     [CONTEXT]: 根因已找到
     [GOAL]: TDD 修复 Bug
     [REQUIREMENTS]:
     1. 编写复现 Bug 的测试
     2. 看着测试失败
     3. 修复 Bug
     4. 看着测试通过
     5. 验证其他测试

3. verification-before-completion - 验证
   prompt: |
     [CONTEXT]: Bug 已修复
     [GOAL]: 验证修复有效
     [REQUIREMENTS]:
     1. 运行所有相关测试
     2. 验证原始症状消失
     3. 验证无新 Bug
     4. 提供证据

EOF
}

dispatch_refactor_workflow() {
    local task="$1"
    
    log INFO "任务类型：重构"
    log INFO "调度技能链：brainstorming → writing-plans → TDD"
    
    cat << EOF
[技能调度：重构工作流]

1. brainstorming - 设计方案
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 设计重构方案
     [REQUIREMENTS]:
     1. 分析现有代码结构
     2. 识别改进点
     3. 提出重构方案
     4. 评估风险
     5. 设计回滚策略

2. writing-plans - 拆解任务
   prompt: |
     [CONTEXT]: 重构方案已批准
     [GOAL]: 拆解为安全的小步骤
     [REQUIREMENTS]:
     1. 每个步骤保持测试通过
     2. 每个步骤可独立回滚
     3. 包含验证步骤

3. test-driven-development - 执行
   prompt: |
     [CONTEXT]: 按计划重构
     [GOAL]: 保持测试通过的重构
     [REQUIREMENTS]:
     1. 每步前确保测试通过
     2. 小步前进
     3. 随时准备回滚

EOF
}

dispatch_review_workflow() {
    local task="$1"
    
    log INFO "任务类型：审查"
    log INFO "调度技能：requesting-code-review"
    
    cat << EOF
[技能调度：审查工作流]

1. requesting-code-review - 代码审查
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 进行全面代码审查
     [REQUIREMENTS]:
     1. 检查代码质量
     2. 检查测试覆盖
     3. 检查文档完整性
     4. 识别潜在问题
     5. 提供改进建议

EOF
}

dispatch_documentation_workflow() {
    local task="$1"
    
    log INFO "任务类型：文档"
    log INFO "调度技能：writing-skills"
    
    cat << EOF
[技能调度：文档工作流]

1. writing-skills - 文档编写
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 编写清晰的文档
     [REQUIREMENTS]:
     1. 明确目标读者
     2. 结构化组织
     3. 提供示例
     4. 保持简洁
     5. 审查和修订

EOF
}

dispatch_testing_workflow() {
    local task="$1"
    
    log INFO "任务类型：测试"
    log INFO "调度技能：test-driven-development"
    
    cat << EOF
[技能调度：测试工作流]

1. test-driven-development - 测试实现
   prompt: |
     [CONTEXT]: $task
     [GOAL]: 实现完整的测试覆盖
     [REQUIREMENTS]:
     1. 编写测试用例
     2. 覆盖边界情况
     3. 使用真实代码
     4. 验证测试通过
     5. 添加覆盖率报告

EOF
}

dispatch_general_workflow() {
    local task="$1"
    
    log INFO "任务类型：通用"
    log INFO "调度技能：基础工作流"
    
    cat << EOF
[技能调度：通用工作流]

根据任务复杂度自动选择:

- 复杂任务 → brainstorming → writing-plans → TDD
- 简单任务 → 直接执行
- 咨询任务 → 直接回答

EOF
}

# ============================================================
# 主函数 - 智能模式
# ============================================================

main() {
    local task="$*"
    
    if [ -z "$task" ]; then
        log ERROR "请提供任务描述"
        exit 1
    fi
    
    # 识别任务类型
    local task_type=$(identify_task_type "$task")
    
    # 智能决策
    local decision=$(should_use_superpowers "$task" "$task_type")
    
    # 显示建议
    show_superpowers_suggestion "$task" "$task_type" "$decision"
    
    # 根据决策执行
    local use_sp="${decision%%|*}"
    
    if [[ "$use_sp" == "true" ]]; then
        # 自动执行技能调度
        dispatch_skills "$task_type" "$task"
    elif [[ "$use_sp" == "suggested" ]]; then
        # 显示建议，不自动执行
        echo -e "${YELLOW}⚠ 如需使用 Superpowers，请添加 --superpowers 参数重新运行${NC}"
    else
        # 简单任务，直接执行
        echo -e "${GREEN}✓ 任务简单，直接执行即可${NC}"
    fi
}

# 执行
main "$@"
