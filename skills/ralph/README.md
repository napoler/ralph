# Ralph Orchestration Skill

> 智能任务编排 - 分析用户任务并调用 ralph.sh 执行

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/napoler/ralph-fork)
[![Superpowers](https://img.shields.io/badge/superpowers-enabled-green.svg)](https://github.com/obra/superpowers)

---

## 📖 目录

- [安装](#安装)
- [快速开始](#快速开始)
- [功能特性](#功能特性)
- [配置](#配置)
- [文档](#文档)

---

## 🚀 安装

### 方式 1: 自动安装（推荐）

```bash
cd /home/terry/.openclaw/workspace/ralph-fork/skills/ralph
bash install-skill.sh
```

### 方式 2: 手动安装

```bash
# 1. 创建技能目录
mkdir -p ~/.config/opencode/skills/ralph

# 2. 复制文件
cp ralph-orchestration.sh ~/.config/opencode/skills/ralph/
cp config.yaml.example ~/.config/opencode/skills/ralph/config.yaml
cp keywords.conf ~/.config/opencode/skills/ralph/

# 3. 设置权限
chmod +x ~/.config/opencode/skills/ralph/ralph-orchestration.sh

# 4. 配置环境变量
echo 'export RALPH_PATH="/path/to/ralph.sh"' >> ~/.bashrc
echo 'export RALPH_SUPERPOWERS=true' >> ~/.bashrc
source ~/.bashrc
```

---

## 🎯 快速开始

### 基础用法

```bash
# 最简单的方式
/ralph "实现用户登录功能"

# 指定工具
/ralph --tool opencode "实现用户登录功能"

# 使用 Superpowers 模式（推荐）
/ralph --superpowers --tmux "开发 REST API"
```

### 参数说明

```bash
/ralph [选项] <任务描述>

选项:
  -t, --tool <tool>         AI 工具
  -m, --max <n>             最大迭代次数 (默认：10)
  -p, --project <dir>       项目目录
  --tmux                    使用 tmux 后台执行
  --scratch                 在临时空目录执行
  --superpowers             启用 Superpowers 框架
  --no-interactive          跳过确认直接执行
  --help                    显示帮助
```

---

## ✨ 功能特性

### 1. 智能工具选择

根据任务关键词自动选择最佳 AI 工具：

| 关键词 | 工具 | 场景 |
|--------|------|------|
| shell, bash, script | **cline** | 终端/脚本 |
| review, refactor | **opencode** | 审查/重构 |
| interactive, ui | **kilocode** | 交互界面 |
| workflow, data | **iflow** | 工作流 |

### 2. Superpowers 集成

启用 `--superpowers` 后，AI 自动遵循：

- ✅ **Brainstorming** - 设计确认
- ✅ **Writing-Plans** - 任务拆解
- ✅ **TDD** - 测试驱动开发
- ✅ **Verification** - 验证完成

### 3. Tmux 后台执行

```bash
# 启动后台任务
/ralph --tmux "实现复杂功能"

# 查看进度
tmux -S /tmp/ralph-agent.sock a -t ralph_<task>_<timestamp>

# 分离 (Ctrl+B, D)
# 任务继续运行

# 重新连接
tmux -S /tmp/ralph-agent.sock a -t ralph_<task>_<timestamp>
```

### 4. Scratch 模式

```bash
# 临时空目录执行，防止 AI 跑题
/ralph --scratch "编写工具函数"
```

---

## ⚙️ 配置

### 环境变量

```bash
# ~/.bashrc 或 ~/.zshrc
export RALPH_PATH="/path/to/ralph.sh"        # ralph.sh 路径
export RALPH_TOOL="opencode"                  # 默认工具
export RALPH_MAX_ITERATIONS="20"              # 默认迭代次数
export RALPH_SUPERPOWERS="true"               # 启用 Superpowers
export RALPH_TMUX="true"                      # 使用 tmux
```

### 配置文件 (config.yaml)

```yaml
tool: opencode
max_iterations: 20
use_tmux: true
superpowers: true
scratch: false
log_level: INFO
```

### 关键词配置 (keywords.conf)

```bash
# 关键词到工具的映射
shell:cline
review:opencode
interactive:kilocode
workflow:iflow
default:qwen
```

---

## 📚 文档

- **[使用指南](../../docs/RALPH-ORCHESTRATION-GUIDE.md)** - 完整使用文档
- [Ralph.sh](../../README.md) - Ralph.sh 文档
- [Superpowers](https://github.com/obra/superpowers) - Superpowers 技能系统

---

## 🎬 实战示例

### 开发新功能

```bash
# 使用 Superpowers 模式
/ralph --superpowers --tmux "实现用户认证系统"

# AI 自动执行:
# 1. Brainstorming - 设计架构
# 2. Writing-Plans - 拆解任务
# 3. TDD - 测试驱动实现
# 4. Verification - 验证完成
```

### Bug 修复

```bash
# 系统化调试
/ralph --superpowers "修复登录 500 错误"

# AI 自动执行:
# 1. Systematic Debugging - 4 阶段调试
# 2. TDD - 编写测试→修复→验证
```

### 并行任务

```bash
# 创建 git worktrees
git worktree add /tmp/fix-1 -b fix-1 main
git worktree add /tmp/fix-2 -b fix-2 main

# 并行执行
/ralph --project /tmp/fix-1 "修复 issue #1" &
/ralph --project /tmp/fix-2 "修复 issue #2" &
wait
```

---

## 🔧 故障排查

### 找不到 ralph.sh

```bash
# 设置环境变量
export RALPH_PATH="/path/to/ralph.sh"

# 或添加到 PATH
ln -s /path/to/ralph.sh /usr/local/bin/ralph.sh
```

### 没有可用的 AI 工具

```bash
# 安装 AI 工具
npm install -g @anthropic-ai/claude-code
npm install -g opencode
npm install -g @anthropic-ai/cline
```

### Tmux 未安装

```bash
# 安装 tmux
sudo apt install tmux

# 或不使用 tmux
/ralph --no-tmux "任务"
```

---

## 📊 技能架构

```
ralph-orchestration.sh
├── 参数解析
├── 工具选择 (keywords.conf)
├── 路径检测 (find_ralph)
├── 交互式确认
└── 任务执行
    ├── 直接执行
    ├── Tmux 后台执行
    └── Superpowers 注入
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

**开发设置**:

```bash
# Fork 项目
git clone https://github.com/your/ralph-fork.git

# 创建分支
git checkout -b feature/your-feature

# 提交代码
git commit -m "feat: add your feature"

# 推送
git push origin feature/your-feature
```

---

## 📄 许可证

BSD-3-Clause

---

## 🙏 致谢

- [Ralph Method](https://ghuntley.com/ralph) - Geoffrey Huntley
- [Superpowers](https://github.com/obra/superpowers) - Obra
- [Coding Agent](https://github.com/openclaw/skills) - Clawdbot

---

**版本**: 2.0.0  
**最后更新**: 2026-03-04  
**维护者**: Ralph Team
