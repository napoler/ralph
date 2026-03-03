---
description: Ralph Orchestration - 分析任务并调用 ralph.sh 执行 AI 任务
---

# Ralph Orchestration Skill

你正在调用 **Ralph Orchestration Skill** 来分析和执行任务。

## 执行步骤

1. **解析用户任务** - 提取任务描述
2. **分析任务类型** - 确定需要的 AI 工具
3. **执行 ralph.sh** - 调用对应的 AI 工具

## 调用方式

直接在终端中执行以下命令：

```bash
ralph <任务描述>
```

或使用完整路径：

```bash
bash ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh "<任务描述>"
```

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| -t, --tool | 指定 AI 工具 | `-t cline` |
| -m, --max | 最大迭代次数 | `-m 20` |
| -y | 跳过交互确认 | `-y` |
| -p | 项目目录 | `-p /path` |

## 示例命令

```
ralph 帮我修复登录 bug
ralph -t cline 编写自动化脚本
ralph --tool opencode --max 15 代码审查
ralph -y 部署应用到服务器
```

## 当前任务

用户的任务是：{{task}}

请执行 ralph 命令来完成这个任务。