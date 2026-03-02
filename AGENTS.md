# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs AI coding tools repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context.

**Features:**
- SPECKit 规范驱动开发
- RPI (Research-Plan-Implement) 模式
- 多工具支持 (qwen/opencode/cline/kilocode/iflow)
- 自动工作树管理

## Commands

```bash
# 运行 Ralph (默认 qwen)
./ralph.sh

# 指定工具和迭代次数
./ralph.sh --tool opencode 20

# 仅查看状态
./ralph.sh status
```

## Key Files

- `ralph.sh` - The bash loop that spawns fresh AI instances
- `prompt.md` - AI agent instructions (SPECKit + RPI)
- `prd.json` - Task definitions with acceptance criteria
- `progress.txt` - Progress log
- `specs/` - Specification files

## Project Structure

```
ralph-fork/
├── specs/
│   ├── active/          # Current iteration specs
│   ├── archive/         # Completed specs
│   └── templates/      # Specification templates
├── prd.json            # Task definitions
├── progress.txt        # Progress log
├── archive/            # Run history
└── ralph.sh            # Loop script
```

## Workflow

1. **Research** - Study codebase and existing patterns
2. **Plan** - Define implementation steps
3. **Implement** - Write code and verify
4. **Commit** - Push changes with proper message
5. **Update** - Mark task complete in prd.json

## Multi-Tool Support

Ralph supports 5 AI tools:
- `qwen` - Text generation / code
- `opencode` - Code development
- `cline` - Terminal coding
- `kilocode` - Interactive coding
- `iflow` - Workflow automation

## Patterns

- Each iteration spawns a fresh AI instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update this file with discovered patterns