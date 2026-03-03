# Ralph Orchestration Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create an OpenCode skill that orchestrates AI tools dynamically by analyzing user tasks and invoking ralph.sh

**Architecture:** 
- Skill located at `~/.config/opencode/skills/ralph-orchestration/`
- Keyword-based tool matching with AI fallback
- Interactive Q&A for missing information
- Executes ralph.sh with matched parameters

**Tech Stack:** Bash, OpenCode Skill Framework, ralph.sh

---

## Task 1: Create Skill Directory Structure

**Files:**
- Create: `~/.config/opencode/skills/ralph-orchestration/skill.md`
- Create: `~/.config/opencode/skills/ralph-orchestration/config.yaml`
- Create: `~/.config/opencode/skills/ralph-orchestration/keywords.conf`

**Step 1: Create skill directory**

```bash
mkdir -p ~/.config/opencode/skills/ralph-orchestration
```

**Step 2: Create skill.md**

```markdown
# Ralph Orchestration Skill

## Overview
Interactive task orchestration - analyzes user task and invokes ralph.sh with optimal AI tool.

## Usage
/ralph <task description>
/ralph -t <tool> <task>
/ralph --tool <tool> --max <n> --project <path> <task>

## Parameters
- -t, --tool: AI tool (qwen, opencode, cline, kilocode, iflow, gemini)
- -m, --max: Max iterations
- -p, --project: Project directory
- -y, --no-interactive: Skip interactive Q&A
- --task: Task description

## Keywords
See keywords.conf for tool mapping rules.

## Example
/ralph 帮我修复登录 bug
/ralph -t cline 编写部署脚本
```

**Step 3: Create config.yaml**

```yaml
name: ralph-orchestration
description: Orchestrate AI tools based on task analysis
version: 1.0.0
author: Ralph Team

defaults:
  tool: qwen
  max_iterations: 10
  load_balance: true

execution:
  ralph_path: auto  # or specify absolute path
  log_level: info
```

**Step 4: Create keywords.conf**

```bash
# Keyword to Tool Mapping
# Format: keyword,tool

# Shell/Script
shell,cline
bash,cline
script,cline
terminal,cline
脚本,cline

# Code Review/Refactor
review,opencode
refactor,opencode
审查,opencode
重构,opencode

# GitHub
pr, kilocode
github, kilocode
pull request, kilocode
mr, kilocode

# Workflow/Deploy
workflow,iflow
pipeline,iflow
deploy,iflow
部署,iflow
数据处理,iflow

# Mobile
mobile,opencode
ios,opencode
android,opencode
移动端,opencode

# Architecture
architecture,oracle
架构,oracle
设计,oracle
```

**Step 5: Commit**

```bash
git add docs/plans/2026-03-03-ralph-orchestration-skill-design.md
git commit -m "docs: add ralph orchestration skill design"
```

---

## Task 2: Create Main Skill Script

**Files:**
- Create: `~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh`

**Step 1: Write the main skill script**

```bash
#!/bin/bash
# Ralph Orchestration Skill
# Analyzes tasks and invokes ralph.sh with optimal tool

set -e

# Config paths
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SKILL_DIR/config.yaml"
KEYWORDS_FILE="$SKILL_DIR/keywords.conf"

# Default values
TOOL="qwen"
MAX_ITERATIONS=10
PROJECT_DIR=""
TASK=""
INTERACTIVE=true

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tool)
                TOOL="$2"
                shift 2
                ;;
            -m|--max)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            -p|--project)
                PROJECT_DIR="$2"
                shift 2
                ;;
            -y|--no-interactive)
                INTERACTIVE=false
                shift
                ;;
            --task)
                TASK="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                exit 1
                ;;
            *)
                TASK="$1"
                shift
                ;;
        esac
    done
}

# Load keywords from config
load_keywords() {
    declare -A KEYWORD_TOOLS
    
    while IFS=',' read -r keyword tool; do
        [[ "$keyword" =~ ^# ]] && continue
        [[ -z "$keyword" ]] && continue
        KEYWORD_TOOLS["$keyword"]="$tool"
    done < "$KEYWORDS_FILE"
    
    echo "${!KEYWORD_TOOLS[@]}"
}

# Match tool based on task keywords
match_tool() {
    local task="$1"
    local matched_tool=""
    
    while IFS=',' read -r keyword tool; do
        [[ "$keyword" =~ ^# ]] && continue
        [[ -z "$keyword" ]] && continue
        
        if echo "$task" | grep -qi "$keyword"; then
            matched_tool="$tool"
            break
        fi
    done < "$KEYWORDS_FILE"
    
    echo "${matched_tool:-qwen}"
}

# Interactive Q&A
interactive_qa() {
    echo "🤖 任务理解: $TASK"
    echo ""
    echo "请确认:"
    echo "1. 任务类型: 代码开发/代码审查/脚本编写/部署/其他"
    echo "2. 工具偏好: [$TOOL]"
    echo "3. 迭代次数: [$MAX_ITERATIONS]"
    echo "4. 项目目录: [${PROJECT_DIR:-当前目录}]"
    echo ""
    echo "直接回车确认，或输入调整:"
}

# Execute ralph.sh
execute_ralph() {
    local tool="$1"
    local max="$2"
    local project="$3"
    local task="$4"
    
    # Find ralph.sh
    local ralph_path
    if [[ -f "$HOME/.openclaw/workspace/ralph-fork/ralph.sh" ]]; then
        ralph_path="$HOME/.openclaw/workspace/ralph-fork/ralph.sh"
    elif command -v ralph.sh &>/dev/null; then
        ralph_path="$(command -v ralph.sh)"
    else
        echo "Error: ralph.sh not found"
        exit 1
    fi
    
    # Build command
    local cmd="bash $ralph_path --tool $tool --max $max"
    [[ -n "$project" ]] && cmd="$cmd --project $project"
    cmd="$cmd \"$task\""
    
    echo "Executing: $cmd"
    eval "$cmd"
}

# Main
main() {
    parse_args "$@"
    
    # If no task provided, prompt
    if [[ -z "$TASK" ]]; then
        echo "请输入任务描述:"
        read -r TASK
    fi
    
    # Auto-match tool if not specified
    if [[ "$TOOL" == "qwen" ]] || [[ -z "$TOOL" ]]; then
        TOOL=$(match_tool "$TASK")
    fi
    
    # Interactive mode
    if $INTERACTIVE; then
        interactive_qa
        read -r confirm
    fi
    
    # Execute
    execute_ralph "$TOOL" "$MAX_ITERATIONS" "$PROJECT_DIR" "$TASK"
}

main "$@"
```

**Step 2: Make it executable**

```bash
chmod +x ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh
```

**Step 3: Commit**

```bash
git add docs/plans/
git commit -m "feat: add ralph-orchestration skill implementation"
```

---

## Task 3: Test the Skill

**Files:**
- Test: `~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh`

**Step 1: Test keyword matching**

```bash
# Test script with sample inputs
echo "shell script" | grep -qi "shell" && echo "matched: cline"
echo "代码审查" | grep -qi "审查" && echo "matched: opencode"
```

**Step 2: Test argument parsing**

```bash
bash ralph-orchestration.sh -t cline -m 5 "test task"
# Expected: parses -t cline -m 5 correctly
```

**Step 3: Commit**

```bash
git commit --allow-empty -m "test: verify skill functionality"
```

---

## Task 4: Create Slash Command Registration (Optional)

**Files:**
- Create: `~/.config/opencode/skills/ralph-orchestration/register.sh`

**Step 1: Create registration script**

```bash
#!/bin/bash
# Register /ralph slash command

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add to user's opencode config if needed
echo "To use /ralph command, add to your opencode config:"
echo "  - name: ralph-orchestration"
echo "    command: $SKILL_DIR/ralph-orchestration.sh"
```

**Step 2: Commit**

```bash
git commit -m "feat: add slash command registration"
```

---

## Execution Options

**Plan complete and saved to `docs/plans/2026-03-03-ralph-orchestration-skill-design.md` and `docs/plans/2026-03-03-ralph-orchestration-implementation-plan.md`.**

**Two execution options:**

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?