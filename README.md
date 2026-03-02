# Ralph - SPECKit Edition

Ralph is an autonomous AI agent loop that runs repeatedly until all PRD items are complete. This version integrates **SPECKit** for spec-driven development and **RPI** (Research-Plan-Implement) pattern.

## Features

- ✅ **SPECKit Integration** - Spec-Driven Development methodology
- ✅ **RPI Pattern** - Research → Plan → Implement workflow
- ✅ **Multi-Tool Support** - qwen, opencode, cline, kilocode, iflow
- ✅ **Auto Worktree** - Automatic git worktree creation/cleanup
- ✅ **Spec Management** - Auto-generate and archive specs
- ✅ **Progress Tracking** - Live progress.txt updates

## Quick Start

```bash
# 初始化 (如果需要)
npx ralphy-spec init

# 创建 PRD
cp prd.json.example prd.json
# 编辑 prd.json 添加你的任务

# 运行 Ralph
./ralph.sh

# 指定工具
./ralph.sh --tool opencode 20

# 查看状态
./ralph.sh status
```

## Project Structure

```
ralph-fork/
├── specs/
│   ├── active/           # 当前任务规格
│   ├── archive/          # 已完成任务规格
│   └── templates/        # 规格模板
├── prd.json              # 任务定义
├── progress.txt          # 进度日志
├── archive/              # 运行历史
├── ralph.sh              # 循环脚本
└── prompt.md             # Agent 提示词
```

## SPECKit Workflow

```
┌─────────────────────────────────────────┐
│           Constitution                  │
│   制定项目开发原则和约束                  │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│           Specify                       │
│   定义详细规格 (从 PRD 生成 spec.md)      │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│            Plan                         │
│   制定技术实现计划                        │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│            Tasks                        │
│   分解为可执行的任务 (prd.json)          │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Implement                      │
│   Ralph Loop 迭代执行直到完成            │
└─────────────────────────────────────────┘
```

## RPI Pattern

Each task executes in three phases:

1. **Research** 🔬 - 研究现有代码结构
2. **Plan** 📋 - 制定实现步骤  
3. **Implement** ⚡ - 编写并验证代码

## Multi-Tool Commands

| Tool | Command |
|------|---------|
| qwen | `qwen -p "task"` |
| opencode | `opencode run --task="task"` |
| cline | `cline "task"` |
| kilocode | `kilocode run "task"` |
| iflow | `iflow run --config="task"` |

## Example Workflow

```bash
# 1. 创建 PRD
cp prd.json.example prd.json
nano prd.json

# 2. 运行 Ralph
./ralph.sh --tool opencode

# 3. 查看进度
./ralph.sh status

# 4. 检查日志
cat progress.txt
```

## Credits

- [Ralph Methodology](https://ghuntley.com/ralph) by Geoffrey Huntley
- [SPECKit](MEMORY.md) - Our spec-driven development method
- [OpenSpec](https://github.com/Fission-AI/OpenSpec)

## License

BSD-3-Clause