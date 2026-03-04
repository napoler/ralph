#!/bin/bash
# ============================================================
# Superpowers 技能自动调度器
# 
# 根据任务类型自动选择并调用合适的 Superpowers 技能
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
    if [[ "$task_lower" =~ (修复|bug|错误|问题|fail|fix|repair|debug) ]]; then
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
# 技能调度决策
# ============================================================

dispatch_skills() {
    local task_type="$1"
    local task="$2"
    
    case "$task_type" in
        creative)
            # 创造性任务：完整工作流
            dispatch_creative_workflow "$task"
            ;;
        bugfix)
            # Bug 修复：debugging + TDD
            dispatch_bugfix_workflow "$task"
            ;;
        refactor)
            # 重构：分析 + TDD
            dispatch_refactor_workflow "$task"
            ;;
        review)
            # 审查：code review
            dispatch_review_workflow "$task"
            ;;
        documentation)
            # 文档：writing skills
            dispatch_documentation_workflow "$task"
            ;;
        testing)
            # 测试：TDD
            dispatch_testing_workflow "$task"
            ;;
        general)
            # 通用：基础工作流
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
    
    # 输出技能调用指令
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
- 简单任务 → TDD → verification
- 咨询任务 → 直接回答

EOF
}

# ============================================================
# 主函数
# ============================================================

main() {
    local task="$*"
    
    if [ -z "$task" ]; then
        log ERROR "请提供任务描述"
        exit 1
    fi
    
    # 识别任务类型
    local task_type=$(identify_task_type "$task")
    
    # 调度技能
    dispatch_skills "$task_type" "$task"
}

# 执行
main "$@"
