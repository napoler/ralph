# Ralph Orchestration Skill Design

> **Date**: 2026-03-03
> **Status**: Approved
> **Version**: 1.0.0

## Overview

**Skill Name**: `ralph-orchestration`

**Purpose**: An OpenCode skill that orchestrates AI tools dynamically by analyzing user tasks and invoking ralph.sh with the most appropriate tool.

## Core Features

1. **Interactive Task Analysis** - Understand user requirements through conversational Q&A
2. **Smart Tool Selection** - Match task to best AI tool using keywords + AI analysis
3. **Slash Command Support** - Quick invocation via `/ralph` command
4. **Configurable Rules** - User can customize keyword-to-tool mappings

## Workflow

```
User Input (/ralph task description)
           ↓
       Parse Arguments
           ↓
   Interactive Q&A (if needed)
           ↓
   Keyword + AI Analysis
           ↓
   Select Best Tool
           ↓
   Execute ralph.sh
           ↓
   Return Results
```

## Keyword Mapping (Default Rules)

| Keywords | Tool | Description |
|----------|------|-------------|
| shell, bash, script, terminal, 脚本 | cline | Terminal/script tasks |
| review, refactor, 审查, 重构 | opencode | Code review/refactor |
| pr, github, pull request, MR | kilocode | GitHub related |
| workflow, pipeline, 数据处理, 部署 | iflow | Workflow/deploy tasks |
| mobile, ios, android, 移动端 | opencode | Mobile development |
| architecture, 架构, 设计 | oracle | Architecture design |
| default | qwen (load balance) | General tasks |

## User Configuration

**Config File**: `~/.config/ralph/skill.conf` or `<project>/ralph-skill.conf`

```bash
# Default tool
RALPH_DEFAULT_TOOL="qwen"

# Max iterations
RALPH_MAX_ITERATIONS=10

# Custom keyword mappings
RALPH_KEYWORD_shell="cline"
RALPH_KEYWORD_review="opencode"
```

## Slash Command Usage

```bash
/ralph 帮我修复这个 bug
/ralph -t cline 编写自动化脚本
/ralph --tool opencode --max 20 实现用户登录
/ralph --project /path/to/project --task "任务描述"
```

## Parameters

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| `--tool` | `-t` | Specify AI tool | auto-detect |
| `--max` | `-m` | Max iterations | 10 |
| `--project` | `-p` | Project directory | current |
| `--task` | - | Task description | required |
| `--no-interactive` | `-y` | Skip interactive Q&A | false |

## Interactive Q&A Flow

```
🤖 任务理解：[parsed task]

请确认：
1. 任务类型？ [代码开发/代码审查/脚本/部署/其他]
2. 工具偏好？ [无/指定工具]
3. 迭代次数？ [默认: 10]
4. 项目目录？ [当前/指定]

确认后执行 ralph.sh
```

## Implementation Notes

- Use ralph.sh as the execution engine
- Leverage existing TOOL_PATHS mechanism for tool detection
- Support all CLI tools: qwen, opencode, cline, kilocode, iflow, gemini
- Follow OpenCode skill structure in `~/.config/opencode/skills/`

## Acceptance Criteria

1. ✅ `/ralph <task>` invokes ralph.sh with appropriate tool
2. ✅ Keyword matching works for default rules
3. ✅ Interactive Q&A collects missing info
4. ✅ User can customize keyword mappings via config
5. ✅ All parameters (--tool, --max, --project) work correctly
6. ✅ Returns execution results to user

## Related Files

- `ralph.sh` - Main execution engine
- `ralph.conf` - Ralph configuration
- `~/.config/opencode/skills/ralph-orchestration/` - This skill