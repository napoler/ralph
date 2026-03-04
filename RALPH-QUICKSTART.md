# Ralph v2.1 快速开始指南

> 5 分钟快速上手 Ralph 智能 AI Agent 编排系统

## 🎯 两种使用模式

### 模式 1: 直接任务模式 (适合单个任务)

```bash
# 基本用法
./ralph.sh --task "任务描述"
./ralph.sh -t "任务描述"  # 简写

# 指定工具
./ralph.sh --tool opencode -t "实现用户认证"

# 指定迭代次数
./ralph.sh --max 20 -t "复杂功能开发"

# 组合使用
./ralph.sh --tool opencode --max 30 -t "实现完整的 REST API"
```

### 模式 2: PRD 项目管理模式 (适合多任务项目)

```bash
# 1. 创建 PRD 文件
cp prd.json.example prd.json

# 2. 编辑 prd.json 添加任务
vim prd.json

# 3. 运行 Ralph (自动执行所有任务)
./ralph.sh

# 4. 或执行 run 命令
./ralph.sh run

# 5. 查看状态
./ralph.sh status
```

## 🦸 Superpowers 智能模式

Ralph v2.1 默认启用**智能 Superpowers 判断**：

### 自动决策

```bash
# 复杂任务 - 自动启用 Superpowers
./ralph.sh -t "实现用户认证系统"
# → 自动调用：brainstorming → writing-plans → TDD → verification

# 简单任务 - 直接执行
./ralph.sh -t "查找所有 TODO 注释"
# → 直接执行搜索，不使用技能链
```

### 手动覆盖

```bash
# 强制启用 Superpowers
./ralph.sh --superpowers -t "任务"

# 强制禁用 Superpowers
./ralph.sh --no-superpowers -t "任务"

# 显式自动判断 (默认)
./ralph.sh --auto-superpowers -t "任务"
```

## 🛠️ 常用工具选择

| 任务类型 | 推荐工具 | 示例 |
|---------|---------|------|
| 通用开发 | qwen (默认) | `./ralph.sh -t "添加日志功能"` |
| 复杂功能 | opencode | `./ralph.sh --tool opencode -t "实现 OAuth2"` |
| 脚本编写 | cline | `./ralph.sh --tool cline -t "编写备份脚本"` |
| 代码审查 | opencode | `./ralph.sh --tool opencode -t "审查 src/目录"` |
| 数据处理 | iflow | `./ralph.sh --tool iflow -t "数据迁移"` |

## 📋 完整参数列表

```bash
./ralph.sh [选项] [命令]

基本选项:
  -t, --task <描述>     直接任务描述
  --tool <工具>         AI 工具：qwen/opencode/cline/kilocode/iflow
  -m, --max <次数>      最大迭代次数 (默认：10)
  -p, --project <目录>  项目目录
  --proxy <地址>        代理地址

Superpowers 选项:
  --superpowers         强制启用 Superpowers
  --auto-superpowers   自动判断 (默认)
  --no-superpowers     禁用 Superpowers

执行模式:
  --tmux               后台 tmux 会话
  --scratch            临时空目录隔离
  --no-load-balance    禁用负载均衡

命令:
  status               显示任务状态
  run                  执行所有 PRD 任务
  spec                 生成 SPEC 文档
  -h, --help           显示帮助
```

## 🎮 实战示例

### 示例 1: Bug 修复

```bash
./ralph.sh --tool opencode -t "修复登录时的 CSRF 验证错误，导致用户无法访问系统"
```

**预期行为**:
1. 识别为 bugfix 类型
2. 自动启用 Superpowers
3. 调用 systematic-debugging → TDD → verification
4. 找到根因并修复
5. 添加测试防止复发

### 示例 2: 功能开发

```bash
./ralph.sh --tool opencode --max 30 -t "实现用户注册功能，包括邮箱验证和密码强度检查"
```

**预期行为**:
1. 识别为 creative 类型
2. 自动启用 Superpowers
3. 调用 brainstorming → writing-plans → TDD → verification
4. 分步骤实现功能
5. 完整测试覆盖

### 示例 3: 简单查询

```bash
./ralph.sh -t "查找所有使用 auth_token 的地方"
```

**预期行为**:
1. 识别为简单任务 (复杂度 0 分)
2. 不启用 Superpowers
3. 直接执行搜索

## ⚙️ 配置 (可选)

编辑 `ralph.conf`:

```bash
# 项目目录
RALPH_PROJECT_DIR="/path/to/your/project"

# 默认工具
RALPH_TOOL="opencode"

# 最大迭代次数
RALPH_MAX_ITERATIONS="20"

# 日志目录
RALPH_LOG_DIR="/path/to/logs"
```

## 📊 执行流程

```
1. 读取配置
   ↓
2. 解析参数
   ↓
3. 智能判断 Superpowers ← v2.1 新功能
   ↓
4. 选择 AI 工具 (负载均衡)
   ↓
5. 创建工作树 (git worktree)
   ↓
6. 执行任务
   ↓
7. 验证结果
   ↓
8. 提交代码
   ↓
9. 更新进度
```

## 🐛 常见问题

### Q: 显示 "All tasks completed!" 但没有执行

**A**: 需要使用 `--task` 参数或创建 `prd.json`

```bash
./ralph.sh --task "任务描述"
```

### Q: 显示 "prd.json not found"

**A**: 创建 prd.json 或使用直接任务模式

```bash
# 方式 1: 创建 PRD
cp prd.json.example prd.json

# 方式 2: 使用直接任务模式
./ralph.sh -t "任务描述"
```

### Q: Superpowers 没有生效

**A**: 检查任务复杂度，或强制启用

```bash
./ralph.sh --superpowers -t "任务"
```

### Q: 执行超时

**A**: 任务太大，拆分成小任务或增加超时

```bash
# 拆分任务
./ralph.sh -t "实现用户登录"
./ralph.sh -t "实现用户注册"
./ralph.sh -t "实现密码重置"

# 或增加迭代次数
./ralph.sh --max 30 -t "大任务"
```

## 📚 进阶文档

- **[README.md](README.md)** - 完整功能说明
- **[Superpowers 智能判断](docs/SUPERPOWERS-SMART-AUTO.md)** - v2.1 新特性详解
- **[Superpowers 指南](docs/SUPERPOWERS-GUIDE.md)** - 技能系统完整文档
- **[编排指南](docs/RALPH-ORCHESTRATION-GUIDE.md)** - 高级配置和使用

## 🎯 最佳实践

1. **任务粒度**: 每个任务应该能在 1-3 轮迭代内完成
2. **明确描述**: 任务描述越具体，结果越好
3. **让 Ralph 判断**: 默认启用智能 Superpowers 判断
4. **使用 TMux**: 长时间任务使用 `--tmux` 后台执行
5. **及时验证**: 每轮迭代后检查进度

## 🚀 开始你的第一个任务

```bash
cd /path/to/your/project
./ralph.sh -t "实现一个简单的功能"
```

**祝你编码愉快！** 🎉

---

**版本**: v2.1.0  
**最后更新**: 2026-03-05
