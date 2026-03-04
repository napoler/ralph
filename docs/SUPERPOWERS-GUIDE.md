# Superpowers 高效开发指南

> **版本**: 1.0.0  
> **最后更新**: 2026-03-04  
> **适用范围**: 所有使用 OpenCode/Sisyphus 的开发任务

---

## 📖 目录

- [核心理念](#核心理念)
- [技能总览](#技能总览)
- [标准开发工作流](#标准开发工作流)
- [技能详解](#技能详解)
- [实战场景](#实战场景)
- [最佳实践](#最佳实践)
- [常见错误](#常见错误)
- [快速参考](#快速参考)

---

## 🎯 核心理念

### 为什么需要 Superpowers?

**问题**: 传统开发流程中的常见陷阱

| 陷阱 | 后果 | Superpowers 解决方案 |
|------|------|---------------------|
| 冲动编码 | 设计缺陷、返工 | Brainstorming 强制设计先行 |
| 测试后补 | 测试覆盖不足、bug 潜伏 | TDD 强制测试先行 |
| 盲目调试 | 浪费时间、引入新 bug | Systematic Debugging 找根因 |
| 感觉良好 | 交付质量不稳定 | Verification 强制证据 |
| 上下文丢失 | 重复工作、token 浪费 | Session Continuity 保留上下文 |

### 核心原则

```
✅ 证据优于断言 (Evidence Before Assertions)
✅ 测试先于实现 (Test Before Implementation)
✅ 设计先于编码 (Design Before Coding)
✅ 根因先于修复 (Root Cause Before Fix)
✅ 连续优于重启 (Continuity Over Fresh Start)
```

### 思维模式转变

**❌ 传统思维**:
```
想法 → 写代码 → 测试 → 修复 → 完成
```

**✅ Superpowers 思维**:
```
想法 → Brainstorming(设计) → Writing-Plans(计划) → 
TDD(测试→失败→实现→通过) → Verification(验证) → 
Review(审查) → Finish(完成)
```

---

## 🧰 技能总览

### 14 个核心技能

| 技能 | 触发条件 | 核心作用 |
|------|----------|---------|
| **brainstorming** | 任何创造性工作前 | 将想法转化为完整设计 |
| **writing-plans** | 设计确认后，编码前 | 将设计拆解为原子任务 |
| **test-driven-development** | 任何功能实现/Bug 修复 | 测试驱动的开发循环 |
| **systematic-debugging** | 遇到任何 Bug/异常 | 系统化根因分析 |
| **verification-before-completion** | 声称完成前 | 提供实际验证证据 |
| **requesting-code-review** | 代码完成后 | 两阶段代码审查 |
| **receiving-code-review** | 接收审查意见时 | 有效处理审查反馈 |
| **finishing-a-development-branch** | 任务完成后 | 验证/合并/清理 |
| **executing-plans** | 按计划执行任务 | 逐步执行写作计划 |
| **subagent-driven-development** | 并行执行任务 | 委托子代理执行 |
| **dispatching-parallel-agents** | 多独立任务 | 并行分发任务 |
| **using-git-worktrees** | 新功能开发 | 隔离开发环境 |
| **writing-skills** | 创建/编辑技能 | 编写技能文档 |
| **using-superpowers** | 开始任何对话 | 理解如何使用技能 |

### 技能分类

**流程技能** (决定 HOW approach):
- brainstorming
- systematic-debugging
- test-driven-development
- verification-before-completion

**计划技能** (决定 WHAT & WHEN):
- writing-plans
- executing-plans

**协作技能** (团队工作流):
- requesting-code-review
- receiving-code-review
- finishing-a-development-branch

**委托技能** (并行执行):
- subagent-driven-development
- dispatching-parallel-agents

**工具技能** (环境管理):
- using-git-worktrees
- writing-skills

---

## 🔄 标准开发工作流

### 完整流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    用户提出需求                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  1. BRAINSTORMING (设计确认)                                │
│  - 探索项目上下文                                            │
│  - 提问澄清问题 (一次一个)                                   │
│  - 提出 2-3 种方案                                             │
│  - 展示设计并获取批准                                        │
│  - 保存设计文档 → docs/plans/                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. WRITING-PLANS (任务拆解)                                │
│  - 将设计拆解为 2-5 分钟的原子任务                               │
│  - 每个任务包含：精确文件路径、测试代码、实现代码、验证命令  │
│  - 保存计划文档                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. EXECUTING-PLANS / TDD (逐步实现)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 对于每个任务：RED-GREEN-REFACTOR 循环                   │  │
│  │  RED: 编写失败测试                                      │  │
│  │  → 验证失败                                            │  │
│  │  GREEN: 最小实现                                       │  │
│  │  → 验证通过                                            │  │
│  │  REFACTOR: 重构优化                                    │  │
│  │  → 提交                                                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. VERIFICATION-BEFORE-COMPLETION (验证)                   │
│  - 运行所有测试                                              │
│  - 类型检查                                                  │
│  - 代码质量检查                                              │
│  - 提供实际证据                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. REQUESTING-CODE-REVIEW (审查)                           │
│  - 自我审查                                                  │
│  - 请求用户审查                                              │
│  - 处理审查意见                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6. FINISHING-A-DEVELOPMENT-BRANCH (完成)                   │
│  - 验证所有验收标准                                          │
│  - 清理临时文件                                              │
│  - 合并到主分支                                              │
│  - 清理工作树                                                │
└─────────────────────────────────────────────────────────────┘
```

### 时间分配指南

| 阶段 | 占比 | 说明 |
|------|------|------|
| Brainstorming | 15% | 设计确认，避免返工 |
| Writing-Plans | 10% | 任务拆解，清晰路径 |
| TDD Implementation | 50% | 测试驱动实现 |
| Verification | 10% | 验证质量 |
| Review & Finish | 15% | 审查合并 |

---

## 📚 技能详解

### 1. Brainstorming (头脑风暴)

**核心格言**: *"未经设计确认，禁止写一行代码"*

#### 触发条件（满足任一必须使用）
- ✅ 新功能开发
- ✅ 新组件/模块创建
- ✅ 修改现有行为
- ✅ 架构调整
- ✅ 技术选型

#### 工作流程

```
1. 探索项目上下文
   - 检查文件结构
   - 阅读文档
   - 查看最近的提交
   ↓
2. 提问澄清问题（一次一个）
   - 目的：为什么要做这个？
   - 约束：有哪些技术限制？
   - 成功标准：如何衡量完成？
   ↓
3. 提出 2-3 种方案
   - 方案 A：优缺点 + 适用场景
   - 方案 B：优缺点 + 适用场景
   - 你的推荐 + 理由
   ↓
4. 展示设计
   - 架构设计
   - 组件交互
   - 数据流
   - 错误处理
   - 测试策略
   ↓
5. 编写设计文档
   - 保存到 docs/plans/YYYY-MM-DD-<topic>-design.md
   - 提交到 git
   ↓
6. 调用 writing-plans 技能（这是唯一的下一步！）
```

#### 使用示例

```typescript
task(
  category="quick",
  load_skills=["superpowers/brainstorming"],
  description="设计用户认证系统",
  prompt=`
    [CONTEXT]: 我需要为 REST API 添加 JWT 认证功能，项目使用 Express 框架
    
    [GOAL]: 设计一个安全的认证系统，支持登录/注册/token 刷新
    
    [REQUIREMENTS]:
    1. 必须先探索现有代码库的 auth 模式
    2. 提问澄清问题（一次一个，使用选择题格式）
    3. 提出 2-3 种技术方案并对比
    4. 展示设计架构并获取批准
    5. 保存到 docs/plans/2026-03-04-auth-design.md
    6. 调用 writing-plans 技能
  `
)
```

#### 设计文档模板

```markdown
# 用户认证系统设计

**日期**: 2026-03-04  
**作者**: [Your Name]  
**状态**: 已批准

## 1. 问题定义

需要为 REST API 实现用户认证功能，支持：
- 用户注册（邮箱 + 密码）
- 用户登录（JWT Token）
- Token 刷新机制

## 2. 架构设计

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│  Express │────▶│  JWT Auth│
│          │◀────│  Middleware    │  Service │
└──────────┘     └──────────┘     └──────────┘
                      │
                      ▼
               ┌──────────┐
               │ Database │
               └──────────┘
```

## 3. 组件设计

### 3.1 JWT 工具模块
- 文件：`src/auth/jwt.ts`
- 功能：token 生成、验证、刷新

### 3.2 认证中间件
- 文件：`src/middleware/auth.ts`
- 功能：token 验证、用户注入

### 3.3 认证路由
- 文件：`src/routes/auth.ts`
- 端点：POST /login, POST /register, POST /refresh

## 4. 数据模型

```typescript
interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
}

interface JWTPayload {
  userId: string;
  email: string;
  iat: number;
  exp: number;
}
```

## 5. 安全考虑

- 密码使用 bcrypt 加密（salt rounds: 10）
- JWT secret 从环境变量读取
- Token 过期时间：access(15min), refresh(7d)

## 6. 测试策略

- 单元测试：JWT 工具函数
- 集成测试：登录/注册流程
- E2E 测试：完整认证流程

---

**批准记录**:
- [ ] 架构设计 ✅
- [ ] 组件设计 ✅
- [ ] 安全考虑 ✅
```

---

### 2. Writing-Plans (编写计划)

**核心格言**: *"计划中包含完整代码，不是'添加验证'这样的描述"*

#### 触发条件
- ✅ Brainstorming 完成后（强制）
- ✅ 有多步骤任务需要实现
- ✅ 任务涉及 2+ 文件

#### 计划文档结构

```markdown
# [功能名称] 实现计划

> **For Agent:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [一句话描述要构建什么]

**Architecture:** [2-3 句话说明方法]

**Tech Stack:** [关键技术/库]

---

### Task 1: [组件名称]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**
```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**
Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**
```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**
Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**
```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

---

### Task 2: [下一个组件]
...
```

#### 关键原则

| 原则 | 说明 | 示例 |
|------|------|------|
| **精确文件路径** | 必须是完整路径 | `src/auth/jwt.ts` ✅ |
| **完整代码** | 计划中包含完整代码 | 不是"添加验证" ❌ |
| **精确命令** | 包含期望输出 | `pytest ...` Expected: PASS |
| **技能引用** | 使用 @ 语法 | `@superpowers:test-driven-development` |
| **原子任务** | 每个任务 2-5 分钟 | 一个函数/方法 |
| **TDD 循环** | 每个任务都遵循 | RED→GREEN→REFACTOR |

---

### 3. Test-Driven-Development (测试驱动开发)

**核心格言**: *"如果没看着测试失败，就不知道测试是否正确"*

#### 触发条件（强制）
- ✅ 新功能实现
- ✅ Bug 修复
- ✅ 重构
- ✅ 行为变更

#### RED-GREEN-REFACTOR 循环

```
┌─────────────────────────────────────────────────────────┐
│ RED: 编写失败测试                                        │
│ - 一个行为                                               │
│ - 清晰的测试名称                                         │
│ - 真实代码（避免 mock）                                  │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ 验证失败（MANDATORY）                                    │
│ - 运行测试                                               │
│ - 确认失败                                               │
│ - 失败原因是预期的（功能缺失，不是笔误）                 │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ GREEN: 最小实现                                          │
│ - 只写让当前测试通过的代码                               │
│ - 不要过度设计                                           │
│ - 不要添加当前测试不需要的功能                           │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ 验证通过（MANDATORY）                                    │
│ - 运行测试                                               │
│ - 确认通过                                               │
│ - 其他测试仍通过                                         │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ REFACTOR: 重构优化                                       │
│ - 消除重复                                               │
│ - 改进命名                                               │
│ - 提取助手函数                                           │
│ - 保持测试绿色                                           │
└─────────────────────────────────────────────────────────┘
```

#### 好测试 vs 坏测试

| 质量 | ✅ 好测试 | ❌ 坏测试 |
|------|----------|----------|
| **最小** | 一件事 | `test('validates email and domain and whitespace')` |
| **清晰** | 名称描述行为 | `test('test1')` |
| **展示意图** | 演示期望的 API |  obscures what code should do |
| **真实** | 测试真实代码 | 测试 mock 行为 |

#### 使用示例

```typescript
task(
  category="quick",
  load_skills=["superpowers/test-driven-development"],
  description="TDD 实现 JWT token 生成",
  prompt=`
    [CONTEXT]: 实现 JWT 认证工具函数
    
    [GOAL]: 生成和验证 JWT token
    
    [REQUIREMENTS]:
    1. 必须遵循 RED-GREEN-REFACTOR 循环
    2. 先写测试，看着失败
    3. 写最小实现
    4. 验证通过
    5. 重构优化
    6. 提供验证证据（pytest 输出）
    
    [DOWNSIDE]: 我将基于验证结果决定是否继续
  `
)
```

---

### 4. Systematic-Debugging (系统化调试)

**核心格言**: *"修复之前先找根因"*

#### 触发条件
- ✅ 任何 Bug
- ✅ 测试失败
- ✅ 意外行为
- ✅ 性能问题
- ✅ 构建失败

#### 4 阶段调试流程

**阶段 1: 根因调查（在尝试任何修复之前）**

```
1. 仔细阅读错误信息
   - 不要跳过错误或警告
   - 阅读完整的堆栈跟踪
   - 注意行号、文件路径、错误代码

2. 一致地复现
   - 能可靠触发吗？
   - 确切步骤是什么？
   - 每次都发生吗？

3. 检查最近的变更
   - 什么变更可能导致这个？
   - Git diff，最近的提交
   - 新依赖、配置变更

4. 收集证据（多组件系统）
   - 在每个组件边界添加诊断
   - 记录进入组件的数据
   - 记录离开组件的数据
   - 验证环境/配置传播

5. 追踪数据流
   - 坏值从哪里来？
   - 谁用坏值调用了这个？
   - 继续向上追踪直到找到源头
```

**阶段 2: 模式分析**

```
1. 找到工作示例
   - 在代码库中找类似的正常工作代码
   - 什么工作与 broken 的相似？

2. 与参考对比
   - 完全阅读参考实现
   - 不要略读——读每一行
   - 完全理解模式后再应用

3. 识别差异
   - 工作和 broken 之间有什么不同？
   - 列出每个差异，无论多小
   - 不要假设"那应该不重要"

4. 理解依赖
   - 这个组件需要什么其他组件？
   - 什么设置、配置、环境？
   - 它做什么假设？
```

**阶段 3: 假设和测试**

```
1. 形成单一假设
   - 清楚说明："我认为 X 是根因，因为 Y"
   - 写下来
   - 要具体，不要模糊

2. 最小化测试
   - 做最小的可能变更来测试假设
   - 一次一个变量
   - 不要一次修复多个东西

3. 验证后继续
   - 有效？→ 阶段 4
   - 无效？→ 形成新假设
   - 不要在顶部添加更多修复

4. 当你不知道时
   - 说"我不理解 X"
   - 不要假装知道
   - 寻求帮助
   - 更多研究
```

**阶段 4: 实现**

```
1. 创建失败测试用例
   - 最简单的复现
   - 自动化测试（如果可能）
   - 修复前必须有

2. 实现单一修复
   - 解决识别的根因
   - 一次一个变更
   - 没有"顺便"改进

3. 验证修复
   - 测试现在通过了？
   - 没有其他测试失败？
   - 问题真正解决了？

4. 如果修复无效
   - 停止
   - 计数：尝试了多少修复？
   - 如果 < 3: 回到阶段 1
   - 如果 ≥ 3: 质疑架构
```

#### 使用示例

```typescript
task(
  category="quick",
  load_skills=["superpowers/systematic-debugging"],
  description="调试登录 500 错误",
  prompt=`
    [CONTEXT]: 用户报告登录时返回 500 错误
    
    [GOAL]: 找到根本原因并修复
    
    [REQUIREMENTS]:
    1. 必须遵循 systematic-debugging 4 阶段流程
    2. 先收集错误日志和复现步骤
    3. 检查最近的代码变更
    4. 形成假设并最小化测试
    5. 找到根因后修复
    6. 添加测试防止复发
    
    [DOWNSTREAM]: 我将基于调试结果决定下一步
  `
)
```

---

### 5. Verification-Before-Completion (完成前验证)

**核心格言**: *"证据先于断言，总是"*

#### 触发条件
- ✅ 声称任务完成前
- ✅ 声称 Bug 已修复前
- ✅ 声称测试通过前
- ✅ 提交/PR 前

#### 铁律

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

如果在这条消息中没有运行验证命令，就不能声称它通过。

#### 门函数

```
BEFORE 声称任何状态或表达满意:

1. IDENTIFY: 什么命令证明这个声称？
2. RUN: 执行完整命令（新鲜的、完整的）
3. READ: 完整输出，检查退出码，计数失败
4. VERIFY: 输出是否确认声称？
   - 如果 NO: 用证据说明实际状态
   - 如果 YES: 用证据说明声称
5. ONLY THEN: 做出声称

跳过任何步骤 = 说谎，不是验证
```

#### 常见声称与所需证据

| 声称 | 需要 | 不充分 |
|------|------|--------|
| 测试通过 | 测试命令输出：0 失败 | 之前的运行、"应该通过" |
| Linter 干净 | Linter 输出：0 错误 | 部分检查、推断 |
| 构建成功 | 构建命令：exit 0 | Linter 通过、日志看起来好 |
| Bug 已修复 | 测试原始症状：通过 | 代码已改、假设已修复 |
| 回归测试有效 | Red-green 循环验证 | 测试通过一次 |
| Agent 完成 | VCS diff 显示变更 | Agent 报告"成功" |
| 需求满足 | 逐行检查清单 | 测试通过 |

#### 使用示例

```typescript
task(
  category="quick",
  load_skills=["superpowers/verification-before-completion"],
  description="验证认证功能完成",
  prompt=`
    [CONTEXT]: 完成了用户认证功能实现
    
    [GOAL]: 验证所有功能正常工作
    
    [REQUIREMENTS]:
    1. 运行所有单元测试并提供输出
    2. 运行类型检查并提供输出
    3. 运行代码质量检查并提供输出
    4. 手动测试登录/注册流程
    5. 提供实际证据（截图/日志）
    6. 检查所有验收标准是否满足
  `
)
```

#### 验证报告模板

```markdown
## ✅ 任务完成验证

### 测试结果
| 测试类型 | 状态 | 证据 |
|---------|------|------|
| 单元测试 | ✅ 通过 (45/45) | 见下方输出 |
| 类型检查 | ✅ 通过 | 见下方输出 |
| 代码质量 | ✅ 通过 | 见下方输出 |
| 功能验证 | ✅ 通过 | 见下方截图 |

### 验证命令与输出

#### 单元测试
```bash
$ pytest tests/auth/ -v
============================= test session starts ==============================
collected 45 items
tests/auth/test_jwt.py::test_generate_token PASSED
tests/auth/test_jwt.py::test_verify_token PASSED
...
============================= 45 passed in 2.34s ===============================
```

#### 类型检查
```bash
$ mypy src/auth/
Success: no issues found in 5 source files
```

#### 代码质量
```bash
$ ruff check src/auth/
All checks passed!
```

### 完成度
- 功能实现：100%
- 测试覆盖：95%
- 质量达标：是
```

---

## 🎬 实战场景

### 场景 1: 开发新功能（完整流程）

**背景**: 为 REST API 添加 JWT 认证功能

**步骤 1: 设计（Brainstorming）**

```typescript
task(
  category="quick",
  load_skills=["superpowers/brainstorming"],
  description="设计用户认证系统",
  prompt=`
    [CONTEXT]: 我需要为 Express REST API 添加 JWT 认证功能
    
    [GOAL]: 设计一个安全的认证系统，支持登录/注册/token 刷新
    
    [REQUIREMENTS]:
    1. 必须先探索现有代码库的 auth 模式
    2. 提问澄清问题（一次一个）
    3. 提出 2-3 种技术方案并对比
    4. 展示设计架构并获取批准
    5. 保存到 docs/plans/2026-03-04-auth-design.md
    6. 调用 writing-plans 技能
  `
)
// → 输出：docs/plans/2026-03-04-auth-design.md
```

**步骤 2: 计划（Writing-Plans）**

```typescript
task(
  session_id="ses_auth_brainstorm",  // 继续使用同一会话
  load_skills=["superpowers/writing-plans"],
  description="编写认证系统实现计划",
  prompt=`
    [CONTEXT]: 设计已批准，需要编写详细的实现计划
    
    [GOAL]: 将设计拆解为 2-5 分钟的原子任务
    
    [REQUIREMENTS]:
    1. 每个任务包含精确文件路径
    2. 每个任务包含完整的测试代码
    3. 每个任务包含完整的实现代码
    4. 每个任务包含验证命令和期望输出
    5. 遵循 TDD 循环
    6. 保存到 specs/tasks/SPECKIT-001-tasks.md
  `
)
// → 输出：specs/tasks/SPECKIT-001-tasks.md
```

**步骤 3: 实现（并行委托）**

```typescript
// 并行执行多个独立任务
task(
  category="deep",
  load_skills=["superpowers/test-driven-development"],
  run_in_background=true,
  description="实现 JWT 工具函数"
)
task(
  category="deep",
  load_skills=["superpowers/test-driven-development"],
  run_in_background=true,
  description="实现认证中间件"
)
task(
  category="deep",
  load_skills=["superpowers/test-driven-development"],
  run_in_background=true,
  description="实现登录处理器"
)
task(
  category="deep",
  load_skills=["superpowers/test-driven-development"],
  run_in_background=true,
  description="实现注册处理器"
)

// 继续其他工作，完成后收集结果
```

**步骤 4: 验证**

```typescript
task(
  session_id="ses_auth_implementation",
  load_skills=["superpowers/verification-before-completion"],
  description="验证认证功能",
  prompt=`
    [CONTEXT]: 所有认证功能已实现
    
    [GOAL]: 验证所有功能正常工作
    
    [REQUIREMENTS]:
    1. 运行所有单元测试并提供输出
    2. 运行类型检查并提供输出
    3. 运行代码质量检查并提供输出
    4. 手动测试登录/注册流程
    5. 提供实际证据
  `
)
```

**步骤 5: 审查**

```typescript
task(
  session_id="ses_auth_implementation",
  load_skills=["superpowers/requesting-code-review"],
  description="代码审查",
  prompt=`
    [CONTEXT]: 认证功能已完成并验证
    
    [GOAL]: 进行代码审查
    
    [REQUIREMENTS]:
    1. 自我审查（使用 checklist）
    2. 识别潜在问题
    3. 请求用户审查
    4. 准备处理审查意见
  `
)
```

**步骤 6: 完成**

```typescript
task(
  session_id="ses_auth_implementation",
  load_skills=["superpowers/finishing-a-development-branch"],
  description="完成分支并合并",
  prompt=`
    [CONTEXT]: 认证功能已通过审查
    
    [GOAL]: 合并到主分支
    
    [REQUIREMENTS]:
    1. 验证所有测试通过
    2. 验证所有验收标准满足
    3. 清理临时文件
    4. 合并到主分支
    5. 清理工作树
  `
)
```

---

### 场景 2: 修复 Bug

**背景**: 用户报告登录时返回 500 错误

**步骤 1: 调试**

```typescript
task(
  category="quick",
  load_skills=["superpowers/systematic-debugging"],
  description="调试登录 500 错误",
  prompt=`
    [CONTEXT]: 用户报告登录时返回 500 错误
    
    [GOAL]: 找到根本原因并修复
    
    [REQUIREMENTS]:
    1. 收集错误日志和复现步骤
    2. 检查最近的代码变更
    3. 形成假设并最小化测试
    4. 找到根因后修复
    5. 添加测试防止复发
  `
)
```

**步骤 2: TDD 修复**

```typescript
task(
  session_id="ses_bug_debug",
  load_skills=["superpowers/test-driven-development"],
  description="TDD 修复登录错误",
  prompt=`
    [CONTEXT]: 根因已找到 - JWT 验证逻辑有 bug
    
    [GOAL]: 修复 JWT 验证逻辑
    
    [REQUIREMENTS]:
    1. 先写复现 bug 的测试
    2. 看着测试失败
    3. 修复 bug
    4. 看着测试通过
    5. 验证其他测试仍通过
  `
)
```

**步骤 3: 验证**

```typescript
task(
  session_id="ses_bug_debug",
  load_skills=["superpowers/verification-before-completion"],
  description="验证修复",
  prompt=`
    [CONTEXT]: Bug 已修复
    
    [GOAL]: 验证修复有效
    
    [REQUIREMENTS]:
    1. 运行所有相关测试
    2. 验证原始症状消失
    3. 验证没有引入新 bug
    4. 提供实际证据
  `
)
```

---

### 场景 3: 重构代码

**背景**: 重构认证模块以提高可维护性

**步骤 1: 理解现有代码**

```typescript
task(
  subagent_type="explore",
  run_in_background=true,
  description="探索现有认证模块",
  prompt=`
    [CONTEXT]: 准备重构认证模块
    
    [GOAL]: 理解现有实现和模式
    
    [REQUEST]:
    1. 找出所有认证相关的文件
    2. 识别现有测试覆盖情况
    3. 找出代码质量问题
    4. 识别依赖关系
    
    返回文件路径和模式描述
  `
)
```

**步骤 2: 设计重构方案**

```typescript
task(
  category="quick",
  load_skills=["superpowers/brainstorming"],
  description="设计重构方案",
  prompt=`
    [CONTEXT]: 认证模块需要重构以提高可维护性
    
    [GOAL]: 设计重构方案，保持向后兼容
    
    [REQUIREMENTS]:
    1. 分析现有代码结构
    2. 识别改进点
    3. 提出重构方案
    4. 评估风险
    5. 设计回滚策略
  `
)
```

**步骤 3: 计划**

```typescript
task(
  session_id="ses_refactor_design",
  load_skills=["superpowers/writing-plans"],
  description="编写重构计划",
  prompt=`
    [CONTEXT]: 重构方案已批准
    
    [GOAL]: 将重构拆解为安全的小步骤
    
    [REQUIREMENTS]:
    1. 每个步骤都保持测试通过
    2. 每个步骤都可独立回滚
    3. 包含回滚计划
    4. 包含验证步骤
  `
)
```

**步骤 4: 执行（保持测试通过）**

```typescript
task(
  session_id="ses_refactor_plan",
  load_skills=["superpowers/test-driven-development", "superpowers/executing-plans"],
  description="重构认证模块",
  prompt=`
    [CONTEXT]: 按计划执行重构
    
    [GOAL]: 重构认证模块
    
    [REQUIREMENTS]:
    1. 每个步骤前确保测试通过
    2. 每个步骤后验证测试仍通过
    3. 小步前进
    4. 随时准备回滚
  `
)
```

---

## 💡 最佳实践

### 1. 技能组合拳

**标准组合**:

```typescript
// 新功能开发
load_skills=[
  "superpowers/brainstorming",
  "superpowers/writing-plans",
  "superpowers/test-driven-development"
]

// Bug 修复
load_skills=[
  "superpowers/systematic-debugging",
  "superpowers/test-driven-development"
]

// 完整开发流程
load_skills=[
  "superpowers/brainstorming",
  "superpowers/writing-plans",
  "superpowers/test-driven-development",
  "superpowers/verification-before-completion",
  "superpowers/requesting-code-review"
]
```

### 2. Session Continuity（会话连续性）

**❌ 错误**:

```typescript
// 每次启动新会话，丢失上下文
task(category="quick", load_skills=["superpowers/writing-plans"], ...)
task(category="quick", load_skills=["superpowers/test-driven-development"], ...)
```

**✅ 正确**:

```typescript
// 使用 session_id 继续，保留上下文
const sessionId = "ses_abc123";

task(
  session_id=sessionId,
  load_skills=["superpowers/writing-plans"],
  description="编写计划"
)

task(
  session_id=sessionId,
  load_skills=["superpowers/test-driven-development"],
  description="实现功能"
)
```

**优势**:
- 🚀 节省 70%+ token
- 🧠 Subagent 保留所有上下文
- ⚡ 无需重新读取文件
- 🎯 知道之前尝试过什么

### 3. Parallel Delegation（并行委托）

```typescript
// 并行执行多个独立任务
const tasks = [
  "实现用户模型",
  "实现认证中间件",
  "实现登录处理器",
  "实现注册处理器"
];

tasks.forEach(taskDesc => {
  task(
    category="deep",
    load_skills=["superpowers/test-driven-development"],
    run_in_background=true,
    description=taskDesc
  );
});

// 继续其他工作，完成后收集结果
```

### 4. 验证驱动开发

```typescript
// 每个任务完成后立即验证
task(
  session_id="ses_xxx",
  load_skills=["superpowers/verification-before-completion"],
  description="验证 JWT 功能"
);

// 验证失败？立即修复
task(
  session_id="ses_xxx",
  load_skills=["superpowers/systematic-debugging"],
  description="修复验证失败"
);
```

### 5. 技能触发检查清单

在开始任何任务前，问自己：

```
[] 这是创造性工作吗？（新功能/组件/修改）
    → YES: 使用 brainstorming

[] 有多步骤任务吗？
    → YES: 使用 writing-plans

[] 要实现功能吗？
    → YES: 使用 test-driven-development

[] 遇到 Bug 吗？
    → YES: 使用 systematic-debugging

[] 要声称完成吗？
    → YES: 使用 verification-before-completion

[] 代码完成了吗？
    → YES: 使用 requesting-code-review
```

---

## ⚠️ 常见错误

### 错误 1: "这个太简单不需要设计"

**❌ 错误**:
```typescript
// 跳过 brainstorming，直接写代码
task(category="quick", description="添加 todo 功能", ...)
```

**✅ 正确**:
```typescript
// 所有项目都需要设计确认
task(
  category="quick",
  load_skills=["superpowers/brainstorming"],
  description="设计 todo 功能"
)
```

**后果**: 设计缺陷、返工、浪费时间

---

### 错误 2: 先写代码后写测试

**❌ 错误**:
```typescript
// 先实现功能
function add(a, b) {
  return a + b;
}

// 后补测试
test('adds numbers', () => {
  expect(add(1, 2)).toBe(3);
});
```

**✅ 正确**:
```typescript
// 先写失败测试
test('adds numbers', () => {
  expect(add(1, 2)).toBe(3);
});
// → 失败：function not defined

// 再写最小实现
function add(a, b) {
  return a + b;
}
// → 测试通过
```

**后果**: 测试覆盖不足、bug 潜伏、技术债务

---

### 错误 3: Debugging 直接改代码

**❌ 错误**:
```typescript
// 看到错误直接尝试修复
if (error) {
  // 尝试这个...
  return null;
}
// 不行，再试那个...
```

**✅ 正确**:
```typescript
// 阶段 1: 根因调查
// - 阅读错误信息
// - 复现问题
// - 检查最近变更
// - 收集证据

// 阶段 2: 模式分析
// - 找到工作示例
// - 对比差异

// 阶段 3: 假设和测试
// - 形成假设
// - 最小化测试

// 阶段 4: 实现修复
```

**后果**: 浪费时间、引入新 bug、问题复发

---

### 错误 4: "应该没问题"就交付

**❌ 错误**:
```typescript
// 声称完成
"功能已完成，应该没问题"
```

**✅ 正确**:
```typescript
// 运行验证
$ pytest tests/ -v
============================= 45 passed ==============================

// 提供证据
"功能已完成，验证通过：
- 单元测试：45/45 通过
- 类型检查：通过
- 代码质量：通过"
```

**后果**: 交付质量不稳定、信任丧失

---

### 错误 5: 跳过技能直接用

**❌ 错误**:
```typescript
// 不使用技能，直接开始工作
task(description="实现功能", ...)
```

**✅ 正确**:
```typescript
// 1% 可能适用就必须用技能
task(
  load_skills=["superpowers/brainstorming"],
  description="设计功能"
)
```

**后果**: 失去结构化思考、质量下降

---

## 📊 快速参考

### 技能选择决策树

```
用户请求
  ↓
是创造性工作吗？（新功能/组件/修改行为）
  ├─ YES → BRAINSTORMING → WRITING-PLANS → TDD
  └─ NO → 继续
      ↓
是 Bug 或异常行为吗？
  ├─ YES → SYSTEMATIC-DEBUGGING → TDD
  └─ NO → 继续
      ↓
是实现功能吗？
  ├─ YES → TDD
  └─ NO → 继续
      ↓
是声称完成吗？
  ├─ YES → VERIFICATION-BEFORE-COMPLETION
  └─ NO → 继续
      ↓
是代码完成后吗？
  ├─ YES → REQUESTING-CODE-REVIEW
  └─ NO → 继续
      ↓
是任务完成后吗？
  ├─ YES → FINISHING-A-DEVELOPMENT-BRANCH
  └─ NO → 无需技能
```

### 技能触发条件速查表

| 场景 | 必须使用的技能 |
|------|---------------|
| 新功能开发 | brainstorming → writing-plans → TDD |
| Bug 修复 | systematic-debugging → TDD |
| 重构 | brainstorming → writing-plans → TDD |
| 技术选型 | brainstorming |
| 声称完成 | verification-before-completion |
| 代码审查 | requesting-code-review |
| 合并分支 | finishing-a-development-branch |
| 多任务并行 | dispatching-parallel-agents |
| 隔离开发 | using-git-worktrees |

### 验证命令速查

```bash
# 单元测试
pytest tests/ -v
pytest tests/unit/ -v
pytest tests/integration/ -v

# 类型检查
mypy src/
tsc --noEmit

# 代码质量
ruff check src/
eslint src/
black --check src/

# 构建
npm run build
python -m build
go build ./...

# 测试覆盖率
pytest --cov=. --cov-report=html
```

### Prompt 模板

**Brainstorming**:
```
[CONTEXT]: [任务背景]
[GOAL]: [具体目标]
[REQUIREMENTS]:
1. 探索项目上下文
2. 提问澄清问题（一次一个）
3. 提出 2-3 种方案
4. 展示设计并获取批准
5. 保存设计文档
6. 调用 writing-plans 技能
```

**Writing-Plans**:
```
[CONTEXT]: [设计已批准]
[GOAL]: [拆解为原子任务]
[REQUIREMENTS]:
1. 每个任务包含精确文件路径
2. 每个任务包含完整代码
3. 每个任务包含验证命令
4. 遵循 TDD 循环
5. 保存计划文档
```

**TDD**:
```
[CONTEXT]: [实现背景]
[GOAL]: [具体功能]
[REQUIREMENTS]:
1. RED: 编写失败测试
2. 验证失败
3. GREEN: 最小实现
4. 验证通过
5. REFACTOR: 重构优化
6. 提供验证证据
```

**Verification**:
```
[CONTEXT]: [工作已完成]
[GOAL]: [验证功能]
[REQUIREMENTS]:
1. 运行所有测试并提供输出
2. 运行类型检查并提供输出
3. 运行代码质量检查并提供输出
4. 验证所有验收标准
5. 提供实际证据
```

---

## 🎯 总结

### 核心价值

| 价值 | 说明 |
|------|------|
| **强制结构化思考** | 避免冲动编码，减少返工 |
| **测试驱动** | 所有代码都有测试保护 |
| **系统调试** | 找到根因而非表面修复 |
| **验证交付** | 提供证据而非感觉 |
| **会话连续** | 保留上下文，节省资源 |

### 使用口诀

> "创意之前先 Brainstorm，实现之前先 Writing-Plans，
> 代码之前先 TDD，调试之前先 Systematic，
> 完成之前先 Verification，合并之前先 Review。"

### 下一步

1. **打印此文档** - 放在桌边随时参考
2. **练习标准流程** - 从简单任务开始
3. **检查技能使用** - 每次任务前检查清单
4. **持续改进** - 记录经验教训，优化流程

---

**文档版本**: 1.0.0  
**最后更新**: 2026-03-04  
**维护者**: [Your Team]  
**反馈**: [Feedback Channel]
