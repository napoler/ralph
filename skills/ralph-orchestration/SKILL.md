# Ralph Orchestration Skill

> 交互式任务编排技能 - 根据任务自动选择最合适的 AI 工具

## 概述

Ralph Orchestration Skill 是一个 OpenCode 技能，用于**分析用户任务描述并自动选择最合适的 AI 工具**来执行任务。

### 核心功能

- 🎯 **智能工具匹配** - 通过关键词自动选择最佳工具
- 💬 **交互式确认** - 执行前确认任务参数
- ⚙️ **灵活配置** - 支持自定义关键词映射
- 🔧 **多工具支持** - qwen, opencode, cline, kilocode, iflow, gemini, oracle
- 📝 **日志记录** - 记录执行历史

## 快速开始

### 安装

```bash
# 方式 1: 使用安装脚本
cd /path/to/ralph-fork
bash skills/ralph-orchestration/install-skill.sh

# 方式 2: 手动复制
cp -r skills/ralph-orchestration ~/.config/opencode/skills/
chmod +x ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh
```

### 使用

```bash
# 基本用法
ralph 帮我修复这个 bug
ralph 实现用户登录功能

# 指定工具
ralph -t cline 编写自动化脚本
ralph --tool opencode 代码审查

# 指定参数
ralph --tool opencode --max 20 --project /path/to/project 实现功能
ralph -y "任务描述"  # 跳过交互确认
```

## 命令行参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--tool` | `-t` | 指定 AI 工具 | auto (自动匹配) |
| `--max` | `-m` | 最大迭代次数 | 10 |
| `--project` | `-p` | 项目目录 | 当前目录 |
| `--no-interactive` | `-y` | 跳过交互确认 | false |
| `--log` | `-l` | 显示执行日志 | - |
| `--help` | `-h` | 显示帮助 | - |

## 工具选择逻辑

```
用户输入任务
    ↓
解析参数 (--tool, --max 等)
    ↓
如果没有指定工具 → 关键词匹配
    ↓
根据关键词选择工具
    ↓
交互式确认 (可选)
    ↓
调用 ralph.sh 执行
```

## 关键词映射

Skill 内置了关键词到工具的自动映射：

| 关键词 | 工具 | 说明 |
|--------|------|------|
| shell, bash, script, 脚本, 终端 | **cline** | 终端/脚本开发 |
| review, refactor, 审查, 重构 | **opencode** | 代码审查/重构 |
| pr, github, pull request, mr | **kilocode** | GitHub 相关 |
| deploy, workflow, pipeline, 部署 | **iflow** | 部署/工作流 |
| mobile, ios, android, 移动端 | **opencode** | 移动开发 |
| architecture, 架构, 设计 | **oracle** | 架构设计 |
| api, rest, graphql, 接口 | **opencode** | API 开发 |
| database, db, sql, 数据 | **iflow** | 数据库相关 |
| test, 测试, 单元测试 | **opencode** | 测试相关 |
| doc, 文档, readme | **writing** | 文档编写 |
| *(无匹配)* | **qwen** | 默认 (负载均衡) |

### 自定义关键词

编辑 `keywords.conf` 文件添加自定义映射：

```bash
# 格式: keyword,tool
# 行首 # 为注释

# 示例：添加新的关键词映射
ai,opencode
机器学习,opencode
```

## 工具说明

| 工具 | 用途 | 特点 |
|------|------|------|
| **qwen** | 通用任务 | 默认，负载均衡 |
| **opencode** | 专业开发 | 代码审查、重构、复杂功能 |
| **cline** | 脚本开发 | 终端命令、自动化脚本 |
| **kilocode** | 交互编码 | 交互式问题解决 |
| **iflow** | 工作流 | 数据处理、CI/CD、部署 |
| **gemini** | AI 助手 | Google AI 能力 |
| **oracle** | 架构咨询 | 系统设计、技术方案 |

## 配置文件

### config.yaml

```yaml
name: ralph-orchestration
version: 1.0.0

defaults:
  tool: qwen
  max_iterations: 10
  load_balance: true

execution:
  ralph_path: auto
  log_level: info

ralph_paths:
  # 不再硬编码具体路径，使用智能检测机制
  # 优先级顺序:
  # 1. 环境变量 RALPH_PATH
  # 2. 从脚本位置推断 (skills/ralph-orchestration/../../ralph.sh)
  # 3. PATH 中的 ralph.sh 命令
  # 4. 常见位置搜索 ($PWD, $HOME/.local/bin, /usr/local/bin 等)
```

### keywords.conf

完整关键词列表见 [keywords.conf](keywords.conf)

## 使用示例

### 示例 1: 修复 Bug

```bash
ralph 帮我修复登录页面的 CSRF 错误
```

输出:
```
🤖 分析任务...
✓ 关键词匹配: 登录 → qwen
✓ 选中工具: qwen - 通用 AI 助手

📋 任务描述: 帮我修复登录页面的 CSRF 错误
⚙️  参数确认:
   工具:     qwen
   迭代次数: 10
   项目目录: 当前目录

[回车] 确认执行
→ (执行 ralph.sh)
```

### 示例 2: 编写脚本

```bash
ralph -t cline -m 5 编写自动备份数据库的脚本
```

### 示例 3: 代码审查

```bash
ralph --tool opencode --max 15 --project /path/to/project 代码审查
```

### 示例 4: 自动执行 (无交互)

```bash
ralph -y 部署应用到服务器
```

## 创建别名

添加到 `~/.bashrc` 或 `~/.zshrc`:

```bash
# 方式 1: 使用 install-skill.sh 安装后自动配置
# 安装脚本会创建符号链接到 ~/.local/bin/ralph

# 方式 2: 手动添加别名（路径会根据安装位置自动调整）
# 建议使用 install-skill.sh 安装，不要手动配置
alias ralph='ralph'  # 安装后直接使用
```

然后:

```bash
source ~/.bashrc
ralph 任务描述
```

## 日志

执行日志保存在: `~/.ralph/skill.log`

查看日志:

```bash
# 使用 skill 内置命令
ralph --log

# 或直接查看
cat ~/.ralph/skill.log
```

## 故障排除

### 问题: 找不到 ralph.sh

**解决方案**:
1. 确保 ralph.sh 已安装
2. 或修改 `config.yaml` 中的 `ralph_paths` 添加你的路径
3. 或运行安装脚本重新配置

### 问题: 工具选择不准确

**解决方案**:
1. 手动指定工具: `ralph -t cline 任务`
2. 修改 `keywords.conf` 添加自定义关键词

### 问题: 权限错误

**解决方案**:
```bash
chmod +x ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh
```

## 卸载

```bash
bash ~/.config/opencode/skills/ralph-orchestration/install-skill.sh uninstall
```

或手动删除:

```bash
rm -rf ~/.config/opencode/skills/ralph-orchestration
rm ~/.local/bin/ralph  # 如果创建了符号链接
```

## 文件结构

```
ralph-fork/
└── skills/
    └── ralph-orchestration/
        ├── skill.md                    # 本文档
        ├── ralph-orchestration.sh      # 主脚本
        ├── install-skill.sh            # 安装脚本
        ├── config.yaml                 # 配置文件
        └── keywords.conf               # 关键词映射
```

## 相关链接

- [Ralph 主脚本](../ralph.sh)
- [Ralph 配置文件](../ralph.conf)
- [计划任务文档](../RALPH-SCHEDULER.md)

---

*Version: 1.0.0 | Updated: 2026-03-03*