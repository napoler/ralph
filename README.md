# Ralph v2.1 - 智能 AI Agent 编排系统

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/napoler/ralph-fork)
[![Superpowers](https://img.shields.io/badge/superpowers-v2.1 智能判断-green.svg)](docs/SUPERPOWERS-SMART-AUTO.md)

Ralph 是一个自治 AI Agent 循环系统，通过 **SPECKit** 规范驱动开发、**RPI** 模式和**智能 Superpowers** 自动判断，持续运行直到所有 PRD 任务完成。

## ✨ v2.1 新特性

### 🤖 Superpowers 智能判断

Ralph 现在可以**自动判断**是否需要启用 Superpowers 模式来提高开发质量：

- ✅ **复杂任务** (实现/开发/修复) → 自动启用 Superpowers 技能链
- ❌ **简单任务** (查询/帮助) → 直接执行，节省时间

**智能决策基于**:
- 任务类型识别 (creative/bugfix/refactor等)
- 多维度复杂度评分 (关键词/长度/范围)
- 自动阈值判断

[📖 详细说明](docs/SUPERPOWERS-SMART-AUTO.md)

## 🚀 快速开始

### 方式 1: 直接任务模式 (推荐)

```bash
# 单个任务执行
./ralph.sh --task "实现用户认证功能"
./ralph.sh -t "修复 CSRF 漏洞"

# 指定工具和迭代次数
./ralph.sh --tool opencode --max 20 -t "开发 REST API"

# 使用 Superpowers (自动判断)
./ralph.sh --tool opencode -t "实现完整的用户管理系统"
```

### 方式 2: PRD 项目管理模式

```bash
# 1. 创建 PRD
cp prd.json.example prd.json
vim prd.json  # 编辑任务

# 2. 运行 Ralph (自动执行所有任务)
./ralph.sh

# 3. 执行所有任务
./ralph.sh run

# 4. 查看状态
./ralph.sh status
```

## 📋 命令行参数

### 基本参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--tool` | | AI 工具 | qwen |
| `--max` | `-m` | 最大迭代次数 | 10 |
| `--task` | `-t` | 直接任务描述 | - |
| `--project` | `-p` | 项目目录 | 配置值 |
| `--proxy` | | 代理地址 | 配置值 |
| `--model` | | 模型名称 (用于 opencode) | - |

### Superpowers 参数

### Superpowers 参数

| 参数 | 说明 |
|------|------|
| `--superpowers` | 强制启用 Superpowers 技能链 |
| `--auto-superpowers` | 自动判断 (默认) |
| `--no-superpowers` | 禁用 Superpowers |

### 执行模式

| 参数 | 说明 |
|------|------|
| `--tmux` | 后台 tmux 会话执行 |
| `--scratch` | 临时空目录隔离执行 |
| `--no-load-balance` | 禁用负载均衡 |

### 命令

| 命令 | 说明 |
|------|------|
| `status` | 显示任务状态 |
| `run` | 执行 prd.json 中所有任务 |
| `spec` | 生成 SPEC 文档 |

## 🎯 Superpowers 智能决策示例

| 任务 | 自动决策 | 理由 |
|------|---------|------|
| "实现用户认证系统" | ✅ 启用 | creative 类型 + 复杂度 9 分 |
| "修复 CSRF 漏洞" | ✅ 启用 | bugfix 类型 |
| "优化数据库查询" | ✅ 启用 | refactor 类型 + 复杂度 3 分 |
| "什么是 JWT" | ❌ 不启用 | 简单查询，复杂度 0 分 |
| "查找所有 token 使用" | ❌ 不启用 | 简单任务，复杂度 0 分 |

## 📦 配置文件 (ralph.conf)

```bash
# 项目目录 (必须)
RALPH_PROJECT_DIR="/mnt/data/dev/decentralized-box"

# 默认 AI 工具
RALPH_TOOL="qwen"

# 最大迭代次数
RALPH_MAX_ITERATIONS="10"

# 启用负载均衡
RALPH_LOAD_BALANCE="true"

# 模型选择 (用于 opencode 等工具)
# 示例：RALPH_MODEL="qwen3.5"
RALPH_MODEL=""

# 日志目录
RALPH_LOAD_BALANCE="true"

# 日志目录
RALPH_LOG_DIR="/mnt/data/dev/tmp/ralph-$(date +%Y%m%d)/logs"

# 基础分支
RALPH_BASE_BRANCH="dev"
```

## 🛠️ 多工具支持

Ralph 支持 6 种 AI 工具，自动负载均衡：

| 工具 | 用途 | 适用场景 |
|------|------|----------|
| **qwen** | 通用代码生成 | 默认工具，适合大多数任务 |
| **opencode** | 专业代码开发 | 复杂功能、代码审查、重构 |
| **cline** | CLI/终端编码 | 脚本编写、自动化任务 |
| **kilocode** | 交互式编码 | 交互式问题解决 |
| **iflow** | 工作流/数据处理 | CI/CD、数据处理、部署 |
| **gemini** | Google AI | 需要 Google AI 能力的任务 |

## 🔧 安装

### 快速安装

```bash
# 1. 克隆项目
git clone https://github.com/napoler/ralph-fork.git
cd ralph-fork

# 2. 配置
cp ralph.conf.example ralph.conf
vim ralph.conf  # 编辑项目路径

# 3. 创建 PRD (可选)
cp prd.json.example prd.json

# 4. 运行
./ralph.sh -t "你的第一个任务"
```

### 技能安装

```bash
# 安装 Ralph Orchestration Skill
cd skills/ralph-orchestration
bash install-skill.sh

# 在 OpenCode/Claude Code 中使用
/ralph "任务描述"
```

## 📚 文档

- **[快速开始](RALPH-QUICKSTART.md)** - 5 分钟快速上手
- **[Superpowers 智能判断](docs/SUPERPOWERS-SMART-AUTO.md)** - v2.1 新功能详解
- **[Superpowers 指南](docs/SUPERPOWERS-GUIDE.md)** - 完整技能系统文档
- **[编排指南](docs/RALPH-ORCHESTRATION-GUIDE.md)** - 高级使用和配置

## 📊 工作流程

```
1. 加载配置 → 2. 解析参数 → 3. 智能判断 Superpowers
                                      ↓
7. 提交代码 ← 6. 验证结果 ← 5. 执行任务 (智能技能链)
    ↓
8. 更新进度 → 9. 下一轮迭代
```

## 🎯 SPECKit 规范驱动

Ralph 遵循 SPECKit 四阶段流程：

1. **Specify** - 规范定义：明确需求和验收标准
2. **Plan** - 技术方案：设计架构和实现方案
3. **Tasks** - 任务分解：拆解为可执行的小任务
4. **Implement** - 代码实现：逐步实现并验证

## 🔄 RPI 模式

每个任务分三阶段：

1. **Research** 🔬 - 研究代码结构和现有模式
2. **Plan** 📋 - 制定实现计划和验证方法
3. **Implement** ⚡ - 编写代码、测试和文档

## 📁 项目结构

```
ralph-fork/
├── ralph.sh              # 主脚本 (v2.1)
├── ralph.conf            # 配置文件
├── ralph.conf.example    # 配置示例
├── prd.json.example      # PRD 模板
├── generate-specs.sh     # SPEC 生成器
├── README.md             # 本文档
├── RALPH-QUICKSTART.md   # 快速开始指南
├── docs/
│   ├── SUPERPOWERS-SMART-AUTO.md  # Superpowers 智能判断
│   ├── SUPERPOWERS-GUIDE.md       # Superpowers 完整指南
│   ├── RALPH-ORCHESTRATION-GUIDE.md # 编排指南
│   └── plans/                     # 设计文档
├── skills/
│   ├── ralph/                     # Ralph 技能
│   ├── ralph-orchestration/       # 编排技能
│   └── prd/                       # PRD 技能
├── specs/
│   ├── active/          # 当前规格
│   ├── archive/         # 归档规格
│   └── templates/       # 规格模板
└── archive/             # 运行历史
```

## 🐛 故障排查

### 问题 1: "All tasks completed!" 但没有执行

**原因**: 没有 prd.json 且没有使用 `--task` 参数

**解决**:
```bash
./ralph.sh --task "任务描述"
```

### 问题 2: "prd.json not found"

**原因**: 使用了 prd.json 模式但文件不存在

**解决**:
```bash
cp prd.json.example prd.json
# 或使用直接任务模式
./ralph.sh -t "任务描述"
```

### 问题 3: Superpowers 不生效

**检查**:
```bash
# 确认技能已安装
ls -la ~/.config/opencode/skills/superpowers/

# 查看决策过程
./ralph.sh --superpowers -t "任务"
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

```bash
# Fork 项目
git clone https://github.com/your/ralph-fork.git

# 创建功能分支
git checkout -b feature/your-feature

# 提交代码
git commit -m "feat: add your feature"

# 推送
git push origin feature/your-feature
```

## 📄 许可证

BSD-3-Clause

## 🙏 致谢

- [Ralph Method](https://ghuntley.com/ralph) - Geoffrey Huntley
- [Superpowers](https://github.com/obra/superpowers) - Obra
- 所有贡献者

---

**版本**: v2.1.0  
**最后更新**: 2026-03-05  
**状态**: ✅ 生产就绪
