# Ralph Skill v2.1

> 智能任务编排 - 分析用户任务并调用 ralph.sh 执行

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/napoler/ralph-fork)
[![Superpowers](https://img.shields.io/badge/superpowers-v2.1 智能判断-green.svg)](../../docs/SUPERPOWERS-SMART-AUTO.md)

---

## 📖 目录

- [安装](#安装)
- [快速开始](#快速开始)
- [功能特性](#功能特性)
- [Superpowers 智能判断](#superpowers-智能判断)
- [配置](#配置)
- [使用示例](#使用示例)

---

## 🚀 安装

### 方式 1: 自动安装（推荐）

```bash
cd /path/to/ralph-fork/skills/ralph
bash install-skill.sh
```

### 方式 2: 手动安装

```bash
# 1. 创建技能目录
mkdir -p ~/.config/opencode/skills/ralph

# 2. 复制文件
cp * ~/.config/opencode/skills/ralph/

# 3. 设置权限
chmod +x ~/.config/opencode/skills/ralph/*.sh
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
  --superpowers             强制启用 Superpowers
  --auto-superpowers        自动判断 (默认)
  --no-superpowers          禁用 Superpowers
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

### 2. Superpowers 智能判断 (v2.1)

**自动分析任务复杂度，决定是否启用 Superpowers 技能链**：

#### 智能决策逻辑

| 决策 | 条件 | 行为 |
|------|------|------|
| ✅ 启用 | 任务类型=creative/bugfix/refactor | 自动注入 Superpowers 技能链 |
| ✅ 启用 | 复杂度评分 ≥ 4 | 自动注入 Superpowers 技能链 |
| ⚠️ 建议 | 复杂度评分 2-3 | 显示建议，不自动启用 |
| ❌ 不启用 | 复杂度评分 < 2 | 直接执行，不使用 Superpowers |

#### 复杂度评分维度

- **关键词评分**: 系统/架构 (+3), 功能/API (+2), 修复/添加 (+1)
- **任务长度**: >20 词 (+2), >10 词 (+1)
- **范围评估**: 多文件/模块 (+2)
- **质量要求**: 需要测试 (+1)

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

## 🦸 Superpowers 智能判断

### 自动决策示例

```bash
# 复杂任务 - 自动启用
/ralph "实现用户认证系统"
# → 决策：启用 (creative 类型，复杂度 9 分)
# → 技能链：brainstorming → writing-plans → TDD → verification

# 简单任务 - 不启用
/ralph "什么是 JWT"
# → 决策：不启用 (简单查询，复杂度 0 分)
# → 直接执行

# Bug 修复 - 自动启用
/ralph "修复 CSRF 漏洞"
# → 决策：启用 (bugfix 类型)
# → 技能链：systematic-debugging → TDD → verification
```

### 手动覆盖

```bash
# 强制启用 Superpowers
/ralph --superpowers "任务"

# 强制禁用 Superpowers
/ralph --no-superpowers "任务"

# 显式自动判断 (默认)
/ralph --auto-superpowers "任务"
```

### 决策过程可视化

运行时会看到：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🦸 Superpowers 智能决策
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ 自动启用 Superpowers 模式
决策理由：auto_type:creative
任务类型：creative

将自动调度以下技能链:
  📋 brainstorming → 📝 writing-plans → 🧪 TDD → ✅ verification

→ 正在注入 Superpowers 技能...
```

---

## ⚙️ 配置

### 环境变量

```bash
# ~/.bashrc 或 ~/.zshrc
export RALPH_PATH="/path/to/ralph.sh"        # ralph.sh 路径
export RALPH_TOOL="opencode"                  # 默认工具
export RALPH_MAX_ITERATIONS="20"              # 默认迭代次数
export RALPH_SUPERPOWERS="auto"               # Superpowers 模式：auto/true/false
export RALPH_TMUX="true"                      # 使用 tmux
```

### 配置文件 (config.yaml.example)

```yaml
tool: opencode
max_iterations: 20
use_tmux: true
superpowers: auto  # auto/true/false
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

## 🎬 使用示例

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

### 代码审查

```bash
# 使用 opencode 进行代码审查
/ralph --tool opencode --superpowers "审查 src/modules/ 目录的代码质量"
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

### Superpowers 不生效

```bash
# 检查技能安装
ls -la ~/.config/opencode/skills/superpowers/

# 强制启用
/ralph --superpowers "任务"

# 查看决策过程
/ralph --auto-superpowers "复杂任务"
```

---

## 📊 技能架构

```
ralph-orchestration.sh
├── 参数解析
├── 工具选择 (keywords.conf)
├── 路径检测 (find_ralph)
├── Superpowers 智能评估 ← v2.1 新增
│   ├── 任务类型识别
│   ├── 复杂度评分
│   └── 自动决策
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

## 📚 相关文档

- **[RALPH-QUICKSTART.md](../../RALPH-QUICKSTART.md)** - 快速开始指南
- **[SUPERPOWERS-SMART-AUTO.md](../../docs/SUPERPOWERS-SMART-AUTO.md)** - Superpowers 智能判断详解
- **[SUPERPOWERS-GUIDE.md](../../docs/SUPERPOWERS-GUIDE.md)** - Superpowers 完整指南
- **[RALPH-ORCHESTRATION-GUIDE.md](../../docs/RALPH-ORCHESTRATION-GUIDE.md)** - 编排指南

---

## 📄 许可证

BSD-3-Clause

---

**版本**: 2.1.0  
**最后更新**: 2026-03-05  
**维护者**: Ralph Team
