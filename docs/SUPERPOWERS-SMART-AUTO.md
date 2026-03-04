# Superpowers 智能判断功能 - Ralph v2.1

## 🎯 核心改进

Ralph 现在可以**自动判断**是否需要启用 Superpowers 模式，无需手动指定参数。

---

## 🤖 智能决策系统

### 自动判断逻辑

当你运行 `/ralph "任务描述"` 时，系统会：

1. **识别任务类型**
   - creative (实现/开发/创建)
   - bugfix (修复/错误/问题)
   - refactor (重构/优化)
   - review (审查/分析)
   - documentation (文档)
   - testing (测试)
   - general (通用)

2. **评估任务复杂度** (多维度评分)

   **高复杂度模式 (+3 分)**:
   - 系统/架构/设计/framework/architecture/system
   - 集成/整合/integrate/integration
   - 多模块/多组件/multi-module/multi-component
   - 完整/end-to-end/full

   **中复杂度模式 (+2 分)**:
   - 功能/feature/module/component
   - API/接口/endpoint/service
   - 数据库/database/model/schema
   - 认证/auth/security/permission
   - 异步/async/concurrent/parallel

   **低复杂度模式 (+1 分)**:
   - 修复/fix/bug/error/issue
   - 添加/add/create/new
   - 更新/update/modify/change
   - 优化/optimize/improve/refactor
   - 脚本/script/tool/util

   **其他评估因素**:
   - 任务长度 >20 词 → +2 分
   - 任务长度 >10 词 → +1 分
   - 涉及多个文件/模块 → +2 分
   - 需要测试验证 → +1 分

3. **智能决策**

   | 决策 | 条件 | 行为 |
   |------|------|------|
   | ✅ **启用** | 任务类型=creative/bugfix/refactor | 自动注入 Superpowers 技能链 |
   | ✅ **启用** | 复杂度评分 ≥ 4 | 自动注入 Superpowers 技能链 |
   | ⚠️ **建议** | 复杂度评分 2-3 | 显示建议，不自动启用 |
   | ❌ **不启用** | 复杂度评分 < 2 | 直接执行，不使用 Superpowers |

---

## 📊 示例对比

### 示例 1: 复杂功能开发

```bash
/ralph "实现一个完整的用户认证系统，包括 JWT 令牌生成、刷新机制和权限管理"
```

**智能分析**:
- 任务类型：creative (创造性开发)
- 关键词：实现 (+1)、认证 (+2)、系统 (+3)
- 任务长度：>20 词 (+2)
- 需要测试 (+1)
- **总分：9 分** → ✅ **自动启用 Superpowers**

**技能链**:
```
📋 brainstorming → 📝 writing-plans → 🧪 TDD → ✅ verification
```

---

### 示例 2: Bug 修复

```bash
/ralph "修复登录时的 CSRF 验证错误，导致用户无法访问系统"
```

**智能分析**:
- 任务类型：bugfix (Bug 修复)
- 关键词：修复 (+1)、错误 (+1)
- **总分：2 分 + 任务类型** → ✅ **自动启用 Superpowers**

**技能链**:
```
🔍 systematic-debugging → 🧪 TDD → ✅ verification
```

---

### 示例 3: 简单查询

```bash
/ralph "帮我查找所有使用 auth_token 的地方"
```

**智能分析**:
- 任务类型：general (通用)
- 关键词：无复杂度加分项
- **总分：0 分** → ❌ **不启用 Superpowers**

**行为**: 直接执行搜索，不使用技能链

---

### 示例 4: 中等复杂度

```bash
/ralph "优化数据库查询性能"
```

**智能分析**:
- 任务类型：refactor (重构/优化)
- 关键词：优化 (+1)、数据库 (+2)
- **总分：3 分 + 任务类型** → ✅ **自动启用 Superpowers**

**技能链**:
```
📋 brainstorming → 📝 writing-plans → 🧪 TDD
```

---

## 🎮 手动覆盖

虽然默认是自动判断，但你仍然可以手动控制：

### 强制启用 Superpowers

```bash
/ralph --superpowers "简单任务但想用 Superpowers"
```

### 强制禁用 Superpowers

```bash
/ralph --no-superpowers "复杂任务但不想用 Superpowers"
```

### 显式使用自动判断 (默认)

```bash
/ralph --auto-superpowers "任务描述"
```

---

## 📈 决策过程可视化

运行任务时，你会看到：

```bash
$ /ralph "实现用户登录功能"

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

或者对于简单任务：

```bash
$ /ralph "什么是 CSRF"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🦸 Superpowers 智能决策
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ 任务较简单，使用标准模式
决策理由：simple:0

直接执行即可，如需使用 Superpowers 可添加 --superpowers 参数
```

---

## 🔧 配置选项

### 在 ralph.conf 中设置默认行为

```bash
# 默认启用自动判断 (推荐)
RALPH_SUPERPOWERS_MODE="auto"

# 或强制启用
RALPH_SUPERPOWERS_MODE="enabled"

# 或禁用
RALPH_SUPERPOWERS_MODE="disabled"
```

---

## 🎯 最佳实践

### ✅ 推荐做法

1. **让 Ralph 自动判断** - 默认行为适合 90% 的场景
2. **观察决策理由** - 了解为什么启用/不启用
3. **手动覆盖仅用于特殊情况** - 当你有特殊需求时

### ❌ 不推荐做法

1. 总是强制启用（会浪费时间）
2. 总是禁用（会错过质量保障）
3. 不看决策理由就直接覆盖

---

## 📊 效果对比

| 场景 | v2.0 (手动) | v2.1 (智能) | 改进 |
|------|-----------|-----------|------|
| 复杂功能开发 | 手动启用 | 自动启用 | ✅ 更方便 |
| Bug 修复 | 手动启用 | 自动启用 | ✅ 自动保障质量 |
| 简单查询 | 默认启用 | 自动禁用 | ✅ 节省时间 |
| 中等复杂度 | 默认启用 | 智能判断 | ✅ 灵活决策 |

---

## 🚀 立即体验

```bash
cd /mnt/data/dev/decentralized-box

# 测试复杂任务 (会自动启用)
./ralph.sh "实现用户认证系统"

# 测试简单任务 (会自动禁用)
./ralph.sh "什么是 JWT"

# 查看决策过程
./ralph.sh --superpowers "重构数据库模块"
```

---

## 📚 相关文档

- [Ralph Orchestration Skill](SKILL.md) - 技能详细文档
- [Superpowers Guide](docs/SUPERPOWERS-GUIDE.md) - Superpowers 完整指南
- [Ralph README](README.md) - Ralph 使用指南

---

**版本**: v2.1  
**最后更新**: 2026-03-05  
**改进**: 智能 Superpowers 自动判断
