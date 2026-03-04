# Ralph 超时问题修复说明

## 问题描述

在使用 `./ralph.sh --task` 命令执行任务时，遇到 **Streaming request timeout after 45s** 错误：

```
[API Error: Streaming request timeout after 45s. Try reducing input length or increasing timeout in config.]
```

### 根本原因

这是 `@qwen-code/qwen-code` CLI 内部的流式请求超时问题，不是 Ralph 脚本的 bug。

**技术细节**：
- 超时发生在 qwen CLI 内部（`cli.js:392159` 和 `cli.js:439250`）
- 45 秒超时来自底层 HTTP 客户端或 API 提供商的限制
- qwen CLI 没有提供禁用流式或修改超时的命令行选项
- 配置文件中提到的 `contentGenerator.timeout` 没有公开的修改方式

---

## 解决方案

### 方案 1：超时重试机制（已实现 ✅）

在 `ralph.sh` 中添加了**智能超时重试机制**：

**特性**：
- 自动检测流式超时错误
- 默认 3 次重试，每次超时时间递增（180s → 240s → 300s）
- 重试间隔 5 秒，避免频繁请求
- 仅对超时错误重试，其他错误直接返回

**配置参数**：
```bash
execute_with_retry "$tool_cmd" "$log_file" $max_retries $timeout_seconds
# 默认：max_retries=3, timeout_seconds=180
```

**日志输出示例**：
```
[Attempt 1/3] Executing with 180s timeout...
[Timeout] Attempt 1 timed out after 180s
[Timeout] Streaming timeout detected
[Retry] Will retry with 240s timeout after 5s delay...
[Attempt 2/3] Executing with 240s timeout...
[Success] Completed on attempt 2
```

---

### 方案 2：切换到 opencode 工具（推荐）

如果 qwen 持续超时，可以使用 **opencode** 代替：

```bash
# 使用 opencode 执行任务
./ralph.sh --tool opencode --task "你的任务"

# 设置默认工具为 opencode（配置文件）
echo 'RALPH_TOOL="opencode"' >> ralph.conf
```

**opencode 优势**：
- 更稳定，超时问题更少
- 专为代码开发设计
- 更好的项目上下文理解

---

### 方案 3：使用 tmux 后台模式

后台执行可以规避部分超时问题：

```bash
./ralph.sh --tmux --task "你的任务"

# 查看执行日志
tmux -a -t ralph_your_task
```

---

## 使用方法

### 基本使用

```bash
# 直接执行任务（带超时重试）
./ralph.sh -t "开始发现项目中的缺陷代码进行修正"

# 指定工具和迭代次数
./ralph.sh --tool opencode --max 20 -t "实现用户认证"

# 使用配置文件
export RALPH_TOOL="opencode"
export RALPH_MAX_ITERATIONS="10"
./ralph.sh -t "任务描述"
```

### 配置超时参数

在 `ralph.conf` 中添加：

```bash
# 超时重试配置
RALPH_MAX_RETRIES="3"        # 最大重试次数
RALPH_TIMEOUT_SECONDS="180"  # 初始超时时间（秒）
```

---

## 故障排查

### 问题 1：仍然超时

**症状**：重试 3 次后仍然超时

**解决**：
```bash
# 增加超时时间和重试次数
export RALPH_TIMEOUT_SECONDS="300"  # 300 秒
export RALPH_MAX_RETRIES="5"         # 5 次重试

./ralph.sh -t "任务"
```

### 问题 2：任务太长导致超时

**症状**：复杂任务总是超时

**解决**：
1. 拆解任务为小任务
2. 使用 opencode 代替 qwen
3. 提供明确的范围限制

```bash
# ❌ 不好的长任务
./ralph.sh -t "实现完整的用户管理系统包括注册登录权限"

# ✅ 拆解为小任务
./ralph.sh -t "实现用户注册功能"
./ralph.sh -t "实现用户登录功能"
./ralph.sh -t "实现权限管理模块"
```

### 问题 3：网络不稳定

**症状**：间歇性超时，重试后成功

**解决**：
```bash
# 使用代理（如果适用）
export RALPH_PROXY="http://192.168.123.194:20171"
./ralph.sh --proxy "$RALPH_PROXY" -t "任务"
```

---

## 代码变更

### 修改的文件

**`ralph.sh`**：
1. 添加 `execute_with_retry()` 函数（行 902-967）
2. 修改 `execute_direct_task()` 使用超时重试（行 848-870）
3. 修改 `execute_task()` 使用超时重试（行 716-723）

### 测试命令

```bash
# 语法检查
bash -n ralph.sh

# 测试超时重试
./ralph.sh -t "测试任务" --max 2
```

---

## 最佳实践

### 1. 选择合适的工具

| 任务类型 | 推荐工具 | 理由 |
|---------|---------|------|
| 通用代码任务 | `qwen` | 默认工具，适合大多数场景 |
| 复杂功能开发 | `opencode` | 更稳定，专为开发设计 |
| 脚本/自动化 | `cline` | CLI 专家 |
| 交互式问题 | `kilocode` | 交互模式 |

### 2. 任务描述优化

```bash
# ❌ 模糊、范围太大
./ralph.sh -t "优化系统性能"

# ✅ 具体、范围明确
./ralph.sh -t "优化数据库查询：为 users 表的 email 字段添加索引"
```

### 3. 使用配置文件

在项目根目录创建 `ralph.conf`：

```bash
# 项目配置
RALPH_PROJECT_DIR="/path/to/project"

# 工具配置
RALPH_TOOL="opencode"  # 使用更稳定的工具

# 超时配置
RALPH_MAX_RETRIES="3"
RALPH_TIMEOUT_SECONDS="180"

# 迭代次数
RALPH_MAX_ITERATIONS="10"
```

---

## 总结

**问题本质**：qwen CLI 流式请求 45 秒超时限制

**已实施解决**：
- ✅ 超时重试机制（3 次，180s 递增）
- ✅ 智能错误检测（仅重试超时错误）
- ✅ 详细日志输出

**推荐方案**：
1. **优先使用 opencode** 代替 qwen（更稳定）
2. **拆解大任务** 为小任务（< 10 分钟完成）
3. **使用超时重试** 处理偶发超时

---

**更新日期**: 2026-03-05  
**版本**: ralph.sh v2.1.1（带超时重试）
