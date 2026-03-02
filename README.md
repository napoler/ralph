# Ralph - SPECKit Edition

Ralph is an autonomous AI agent loop that runs repeatedly until all PRD items are complete. This version integrates **SPECKit** for spec-driven development, **RPI** pattern, and **Load Balancing** for multiple AI tools.

## Features

- ✅ **SPECKit Integration** - Spec-Driven Development methodology
- ✅ **RPI Pattern** - Research → Plan → Implement workflow
- ✅ **Load Balancing** - Auto-select least loaded AI tool
- ✅ **Multi-Tool Support** - qwen, opencode, cline, kilocode, iflow
- ✅ **Configurable** - All settings in `ralph.conf`
- ✅ **Auto Worktree** - Automatic git worktree creation/cleanup
- ✅ **Spec Management** - Auto-generate and archive specs

## Quick Start

```bash
# 1. 配置 (可选)
cp ralph.conf.example ralph.conf
# 编辑 ralph.conf 设置项目路径等

# 2. 创建 PRD
cp prd.json.example prd.json
# 编辑 prd.json 添加你的任务

# 3. 运行 Ralph
./ralph.sh

# 指定工具
./ralph.sh --tool opencode --max 20

# 查看状态
./ralph.sh status
```

## 配置文件 (ralph.conf)

所有配置通过 `ralph.conf` 管理：

```bash
# 项目目录 (必须)
RALPH_PROJECT_DIR="/mnt/data/dev/decentralized-box"

# 默认 AI 工具
RALPH_TOOL="qwen"

# 最大迭代次数
RALPH_MAX_ITERATIONS=10

# 启用负载均衡
RALPH_LOAD_BALANCE="true"

# 日志目录
RALPH_LOG_DIR="/mnt/data/dev/tmp/ralph-$(date +%Y%m%d)/logs"

# 基础分支
RALPH_BASE_BRANCH="dev"
```

### 环境变量覆盖

配置可以通过环境变量覆盖：

```bash
RALPH_PROJECT_DIR=/path/to/project RALPH_TOOL=opencode ./ralph.sh
```

## 负载均衡

Ralph 自动选择负载最低的 AI 工具：

| 工具 | 用途 |
|------|------|
| qwen | 通用代码生成 |
| opencode | 专业代码开发 |
| cline | CLI/终端编码 |
| kilocode | 交互式编码 |
| iflow | 工作流/数据处理 |

### 任务匹配

根据任务关键词自动选择工具：
- `shell`, `bash`, `script` → cline
- `review`, `refactor` → opencode
- `project`, `github`, `pr` → kilocode
- `workflow`, `pipeline` → iflow
- 其他 → 负载最低的工具

## Project Structure

```
ralph-fork/
├── ralph.conf           # 配置文件 (可选)
├── ralph.sh             # 主脚本
├── generate-specs.sh    # SPEC 生成器
├── prompt.md            # Agent 提示词
├── prd.json             # 任务定义
├── progress.txt         # 进度日志
├── specs/
│   ├── active/          # 当前规格
│   ├── archive/         # 归档
│   └── templates/       # 模板
├── archive/             # 运行历史
└── .ralph/              # 状态文件
```

## Commands

```bash
./ralph.sh               # 运行 (默认 qwen, 10 次迭代)
./ralph.sh --tool opencode --max 20  # 指定工具和迭代次数
./ralph.sh status        # 查看状态
./ralph.sh spec         # 生成 SPEC.md
./ralph.sh --project /path/to/project  # 指定项目目录
```

## SPECKit Workflow

```
Constitution → Specify → Plan → Tasks → Implement
```

## RPI Pattern

每个任务分三阶段：
1. **Research** 🔬 - 研究代码结构
2. **Plan** 📋 - 制定实现计划
3. **Implement** ⚡ - 编写并验证

## Credits

- [Ralph Methodology](https://ghuntley.com/ralph) by Geoffrey Huntley
- [opencode-ralph-wiggum](https://github.com/Th0rgal/opencode-ralph-wiggum) by @Th0rgal
- [SPECKit](MEMORY.md) - Our spec-driven development method

## License

BSD-3-Clause