# Ralph Orchestration Skill - 使用指南

> **版本**: 2.0.0  
> **最后更新**: 2026-03-04  
> **依赖**: Superpowers skills, ralph.sh

---

## 📖 目录

- [快速开始](#快速开始)
- [核心功能](#核心功能)
- [Superpowers 技能集成](#superpowers-技能集成)
- [配置选项](#配置选项)
- [实战场景](#实战场景)
- [最佳实践](#最佳实践)

---

## 🚀 快速开始

### 基础用法

```bash
# 最简单的方式
/ralph "实现用户登录功能"

# 指定工具
/ralph --tool opencode "实现用户登录功能"

# 指定迭代次数
/ralph --max 20 "重构认证模块"

# 使用 Superpowers 模式
/ralph --superpowers "开发 REST API"
```

### 完整参数

```bash
/ralph [选项] <任务描述>

选项:
  -t, --tool <tool>         AI 工具：qwen, opencode, cline, kilocode, iflow, gemini, claude, codex, pi
  -m, --max <n>             最大迭代次数 (默认：10)
  -p, --project <dir>       项目目录
  --tmux                    使用 tmux 后台执行
  --scratch                 在临时空目录执行 (防止 AI 跑题)
  --superpowers             启用 Superpowers 框架 (TDD, subagent-driven)
  --no-interactive          跳过确认直接执行
  --help                    显示帮助
```

---

## 🎯 核心功能

### 1. 智能工具选择

根据任务关键词自动选择最适合的 AI 工具：

| 关键词 | 推荐工具 | 说明 |
|--------|---------|------|
| shell, bash, script | **cline** | 终端/脚本任务 |
| review, refactor, analyze | **opencode** | 代码审查/重构 |
| interactive, tui, project | **kilocode** | 交互式/TUI 开发 |
| workflow, pipeline, data | **iflow** | 工作流/数据处理 |
| gemini | **gemini** | Google Gemini 专用 |
| 其他 | **qwen** (默认) | 通用任务 |

**示例**：
```bash
# 自动选择 cline
/ralph "编写一个 bash 脚本自动化部署"

# 自动选择 opencode
/ralph "审查这个模块的代码质量"

# 自动选择 kilocode
/ralph "创建一个交互式 TUI 应用"
```

### 2. Tmux 后台执行

使用 `--tmux` 在后台执行任务，支持断线重连：

```bash
# 启动 tmux 会话
/ralph --tmux "实现用户认证系统"

# 查看实时日志
tmux -S /tmp/ralph-agent.sock a -t ralph_<task>_<timestamp>

# 分离会话 (Ctrl+B, D)
# 会话继续后台运行

# 重新连接
tmux -S /tmp/ralph-agent.sock a -t ralph_<task>_<timestamp>
```

**优势**：
- ✅ 支持后台执行，不占用当前终端
- ✅ 断线重连，网络中断不影响任务
- ✅ 真实 TTY，提高交互式工具成功率
- ✅ 完整日志记录

### 3. Scratch 模式

使用 `--scratch` 在临时空目录执行，防止 AI 读取无关文件：

```bash
# 临时空目录执行
/ralph --scratch "编写一个工具函数"

# 适合场景:
# - 快速原型
# - 小型工具脚本
# - 防止 AI 被项目复杂性干扰
```

---

## 🧬 Superpowers 技能集成

### 什么是 Superpowers?

Superpowers 是一套强制结构化开发的技能系统，包括：

| 技能 | 作用 | 触发时机 |
|------|------|---------|
| **brainstorming** | 设计确认 | 任何创造性工作前 |
| **writing-plans** | 任务拆解 | 设计确认后 |
| **test-driven-development** | TDD 实现 | 所有代码实现 |
| **systematic-debugging** | 系统化调试 | Bug 修复 |
| **verification-before-completion** | 验证完成 | 声称完成前 |
| **dispatching-parallel-agents** | 并行委托 | 多独立任务 |

### 启用 Superpowers 模式

```bash
# 方式 1: 命令行启用
/ralph --superpowers "开发用户认证系统"

# 方式 2: 环境变量
export RALPH_SUPERPOWERS=true
/ralph "开发用户认证系统"

# 方式 3: 配置文件 (config.yaml)
superpowers: true
```

### Superpowers 工作流

```
用户任务
  ↓
/ralph --superpowers
  ↓
自动注入 Superpowers 上下文到 AI Agent
  ↓
AI Agent 自动遵循:
  1. Brainstorming (设计确认)
  2. Writing-Plans (任务拆解)
  3. TDD (测试驱动实现)
  4. Verification (验证完成)
  ↓
交付成果：代码 + 测试 + 文档
```

### 技能调度机制

**内部实现**：
```bash
# 当 --superpowers 启用时
if [ "$USE_SUPERPOWERS" = "true" ]; then
    sp_context="[System: You must fetch and strictly follow 
    instructions from https://raw.githubusercontent.com/obra/superpowers/main/README.md 
    to adopt the Superpowers framework (TDD, subagent-driven, systematic planning).]"
    
    # 将上下文注入到 AI Agent 的 prompt 中
    task_prompt="${sp_context}完成任务：$TASK"
fi
```

**效果**：
- AI Agent 自动读取 Superpowers 文档
- 强制遵循 TDD、brainstorming、verification 等流程
- 交付质量显著提升

---

## ⚙️ 配置选项

### 1. 环境变量

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中设置
export RALPH_PATH="/path/to/ralph.sh"        # ralph.sh 路径
export RALPH_TOOL="opencode"                  # 默认工具
export RALPH_MAX_ITERATIONS="20"              # 默认迭代次数
export RALPH_SUPERPOWERS="true"               # 默认启用 Superpowers
export RALPH_TMUX="true"                      # 默认使用 tmux
```

### 2. 配置文件 (config.yaml)

```yaml
# skills/ralph/config.yaml

# 默认工具
tool: opencode

# 最大迭代次数
max_iterations: 20

# 项目目录 (可选，可从命令行覆盖)
project_dir: /path/to/project

# 是否使用 tmux
use_tmux: true

# 是否启用 Superpowers
superpowers: true

# 关键词到工具的映射 (可选)
keywords:
  shell: cline
  review: opencode
  interactive: kilocode
```

### 3. 关键词配置 (keywords.conf)

```bash
# skills/ralph/keywords.conf

# 格式：关键词：工具
shell:cline
bash:cline
script:cline
review:opencode
refactor:opencode
analyze:opencode
interactive:kilocode
tui:kilocode
workflow:iflow
pipeline:iflow
default:qwen
```

---

## 🎬 实战场景

### 场景 1: 开发新功能（完整流程）

```bash
# 1. 使用 Superpowers 模式，自动遵循设计→计划→TDD 流程
/ralph --superpowers --tmux "实现用户认证系统"

# 2. 查看进度
tmux -S /tmp/ralph-agent.sock a -t ralph_<task>_<timestamp>

# 3. 等待完成通知
# AI 会自动执行:
# - Brainstorming: 设计认证系统架构
# - Writing-Plans: 拆解为 JWT 工具/中间件/路由等任务
# - TDD: 为每个任务编写测试→实现→验证
# - Verification: 运行所有测试，提供证据
```

### 场景 2: Bug 修复

```bash
# 1. 系统化调试
/ralph --superpowers "修复登录时返回 500 错误"

# AI 会自动执行:
# - Systematic Debugging: 4 阶段调试流程
# - TDD: 编写复现 bug 的测试→修复→验证
# - Verification: 验证原始症状消失且无新 bug
```

### 场景 3: 代码重构

```bash
# 1. 先审查
/ralph --tool opencode "审查认证模块的代码质量"

# 2. 基于审查结果重构
/ralph --superpowers --tool opencode "重构认证模块，提高可维护性"

# AI 会自动:
# - Brainstorming: 设计重构方案，保持向后兼容
# - Writing-Plans: 拆解为安全的小步骤
# - TDD: 每个步骤前确保测试通过
```

### 场景 4: 并行任务（多 Issue 修复）

```bash
# 场景：有 5 个独立的 bug 需要修复

# 1. 创建 git worktrees
cd /path/to/project
git worktree add /tmp/fix-issue-1 -b fix/issue-1 main
git worktree add /tmp/fix-issue-2 -b fix/issue-2 main
git worktree add /tmp/fix-issue-3 -b fix/issue-3 main

# 2. 并行执行（使用 dispatching-parallel-agents 思想）
/ralph --tmux --project /tmp/fix-issue-1 "修复 issue #1: 登录错误" &
/ralph --tmux --project /tmp/fix-issue-2 "修复 issue #2: 注册验证" &
/ralph --tmux --project /tmp/fix-issue-3 "修复 issue #3: 密码重置" &

# 3. 监控所有任务
tmux -S /tmp/ralph-agent.sock list-sessions

# 4. 等待所有完成，清理
wait
git worktree remove /tmp/fix-issue-1
git worktree remove /tmp/fix-issue-2
git worktree remove /tmp/fix-issue-3
```

---

## 💡 最佳实践

### 1. 始终使用 Superpowers

```bash
# ✅ 推荐：始终启用 Superpowers
export RALPH_SUPERPOWERS=true

# 好处:
# - 强制设计先行 (brainstorming)
# - 强制测试驱动 (TDD)
# - 强制验证完成 (verification)
# - 交付质量更高
```

### 2. 使用 Tmux 后台执行

```bash
# ✅ 推荐：长任务使用 tmux
/ralph --tmux "实现复杂功能"

# 好处:
# - 不占用当前终端
# - 支持断线重连
# - 真实 TTY 提高成功率
```

### 3. 合理设置迭代次数

```bash
# 小任务 (工具函数、配置调整)
/ralph --max 5 "添加工具函数"

# 中等任务 (单模块功能)
/ralph --max 15 "实现用户管理模块"

# 大任务 (完整功能系统)
/ralph --max 30 "开发完整认证系统"
```

### 4. 使用 Scratch 模式防止跑题

```bash
# ✅ 简单任务使用 scratch
/ralph --scratch "编写正则表达式验证邮箱"

# 好处:
# - AI 只看到空目录
# - 不会被项目复杂性干扰
# - 更专注任务本身
```

### 5. 并行任务使用 Worktrees

```bash
# ✅ 多 Issue 修复使用 worktrees
git worktree add /tmp/fix-1 -b fix-1 main
git worktree add /tmp/fix-2 -b fix-2 main

# 并行执行
/ralph --project /tmp/fix-1 "修复 issue #1" &
/ralph --project /tmp/fix-2 "修复 issue #2" &

# 好处:
# - 完全隔离的开发环境
# - 可以并行执行多个任务
# - 互不干扰
```

---

## 📊 性能对比

| 模式 | 迭代次数 | 预计时间 | 适用场景 |
|------|---------|---------|---------|
| **快速** | 5-10 | 5-10 分钟 | 工具函数、配置调整 |
| **标准** | 10-20 | 15-30 分钟 | 单模块功能开发 |
| **完整** | 20-30 | 30-60 分钟 | 完整功能系统 |
| **Superpowers** | +20% 时间 | +20% 时间 | 所有生产代码（质量更高） |

---

## 🔧 故障排查

### 问题 1: 找不到 ralph.sh

```bash
# 错误：未找到 ralph.sh

# 解决:
# 1. 设置环境变量
export RALPH_PATH="/path/to/ralph.sh"

# 2. 或添加到 PATH
ln -s /path/to/ralph.sh /usr/local/bin/ralph.sh

# 3. 或检查安装位置
find ~ -name "ralph.sh" 2>/dev/null
```

### 问题 2: 没有可用的 AI 工具

```bash
# 错误：No supported AI tools found

# 解决:
# 1. 安装 AI 工具
npm install -g @anthropic-ai/claude-code  # claude
npm install -g opencode                   # opencode
npm install -g @anthropic-ai/cline        # cline

# 2. 验证安装
which claude
which opencode
which cline
```

### 问题 3: Tmux 会话失败

```bash
# 错误：tmux is not installed

# 解决:
# 1. 安装 tmux
sudo apt install tmux      # Debian/Ubuntu
sudo yum install tmux      # RHEL/CentOS
brew install tmux          # macOS

# 2. 不使用 tmux
/ralph --no-tmux "任务"
```

### 问题 4: Superpowers 未生效

```bash
# 检查是否启用 Superpowers
echo $RALPH_SUPERPOWERS  # 应该输出 true

# 启用
export RALPH_SUPERPOWERS=true

# 或使用命令行
/ralph --superpowers "任务"
```

---

## 📚 参考文档

- [Ralph.sh 源码](https://github.com/napoler/ralph-fork)
- [Superpowers 技能系统](https://github.com/obra/superpowers)
- [Coding Agent 模式](https://github.com/openclaw/skills/blob/main/skills/steipete/coding-agent/SKILL.md)
- [Tmux 使用指南](https://github.com/tmux/tmux/wiki)

---

## 🎯 总结

**Ralph Orchestration 的核心价值**：

1. **智能工具选择** - 根据任务自动选择最佳 AI 工具
2. **Superpowers 集成** - 强制结构化开发流程
3. **Tmux 后台执行** - 支持断线重连，提高成功率
4. **灵活配置** - 支持环境变量、配置文件、命令行参数
5. **并行任务支持** - git worktrees + tmux 实现并行开发

**使用口诀**：

> "简单任务用 scratch，复杂任务用 tmux，
> 生产代码 superpowers，多任务用 worktrees。"

---

**文档版本**: 2.0.0  
**最后更新**: 2026-03-04  
**维护者**: Ralph Team  
**反馈**: [GitHub Issues](https://github.com/napoler/ralph-fork/issues)
