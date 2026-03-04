# Ralph 流式超时问题解决方案

## 问题诊断

### 错误信息
```
[API Error: Streaming request timeout after 45s. Try reducing input length or increasing timeout in config.]
```

### 根本原因
- **不是 Ralph 的 bug**，而是 `@qwen-code/qwen-code` CLI 的内部限制
- 45 秒超时来自底层 HTTP 客户端或 API 提供商
- qwen CLI 没有提供修改超时的公开配置选项

---

## 已实施的解决方案

### ✅ 超时重试机制（v2.1.1）

**功能特性**：
- 自动检测流式超时错误
- 默认 **3 次重试**，超时时间递增（180s → 240s → 300s）
- 重试间隔 5 秒
- 仅对超时错误重试，其他错误直接返回

**代码位置**：`ralph.sh` 第 902-967 行

**日志示例**：
```
[Attempt 1/3] Executing with 180s timeout...
[Timeout] Attempt 1 timed out after 180s
[Timeout] Streaming timeout detected
[Retry] Will retry with 240s timeout after 5s delay...
[Attempt 2/3] Executing with 240s timeout...
[Success] Completed on attempt 2
```

---

## 使用方法

### 快速开始

```bash
# 方式 1：直接执行（自动重试）
./ralph.sh -t "开始发现项目中的缺陷代码进行修正"

# 方式 2：使用 opencode（推荐，更稳定）
./ralph.sh --tool opencode --max 20 -t "实现用户认证"

# 方式 3：使用配置文件
export RALPH_TOOL="opencode"
export RALPH_MAX_ITERATIONS="10"
./ralph.sh -t "任务描述"
```

### 自定义超时参数

```bash
# 增加超时时间和重试次数
export RALPH_TIMEOUT_SECONDS="300"  # 300 秒
export RALPH_MAX_RETRIES="5"         # 5 次重试

./ralph.sh -t "复杂任务"
```

---

## 最佳实践

### 1. 工具选择建议

| 场景 | 推荐工具 | 理由 |
|------|---------|------|
| 一般任务 | `opencode` | 更稳定，超时问题少 |
| 复杂功能 | `opencode` | 专为代码开发设计 |
| 脚本/CLI | `cline` | 终端专家 |
| 交互问题 | `kilocode` | 交互模式 |
| 简单查询 | `qwen` | 快速响应 |

### 2. 任务拆解原则

**❌ 避免大任务**：
```bash
./ralph.sh -t "实现完整的用户管理系统包括注册登录权限审计"
```

**✅ 拆解为小任务**：
```bash
./ralph.sh -t "实现用户注册功能：用户名、邮箱、密码"
./ralph.sh -t "实现用户登录功能：邮箱登录、JWT token"
./ralph.sh -t "实现权限管理：RBAC 角色权限检查"
```

### 3. 配置文件设置

创建 `ralph.conf`：
```bash
# 推荐配置：使用 opencode 作为默认工具
RALPH_TOOL="opencode"
RALPH_MAX_ITERATIONS="10"
RALPH_MAX_RETRIES="3"
RALPH_TIMEOUT_SECONDS="180"
RALPH_PROJECT_DIR="/path/to/project"
```

---

## 故障排查

### 问题 1：仍然超时

**症状**：重试 3 次后仍然超时

**解决**：
```bash
# 增加超时时间
export RALPH_TIMEOUT_SECONDS="300"
export RALPH_MAX_RETRIES="5"

# 或者切换到 opencode
./ralph.sh --tool opencode -t "任务"
```

### 问题 2：网络不稳定

**症状**：间歇性超时

**解决**：
```bash
# 使用稳定代理
export RALPH_PROXY="http://your-proxy:port"
./ralph.sh --proxy "$RALPH_PROXY" -t "任务"
```

### 问题 3：任务太长

**症状**：输入内容太长导致超时

**解决**：
1. 拆解任务
2. 提供简洁的上下文
3. 使用 `--scratch` 模式

```bash
./ralph.sh --scratch -t "简洁的任务描述"
```

---

## 技术细节

### 修改的文件

**`ralph.sh`**：
1. **行 902-967**：添加 `execute_with_retry()` 函数
2. **行 848-870**：修改 `execute_direct_task()` 使用重试
3. **行 716-723**：修改 `execute_task()` 使用重试

### 重试逻辑

```bash
execute_with_retry "$tool_cmd" "$log_file" "$max_retries" "$timeout_seconds"
# 默认：max_retries=3, timeout_seconds=180
```

**流程**：
1. 执行命令，使用 `timeout` 包装
2. 如果超时（exit code 124），检查是否是流式超时
3. 如果是流式超时，增加 60 秒后重试
4. 最多重试 3 次
5. 记录详细日志

### 测试脚本

```bash
# 运行测试
./test-timeout-retry.sh

# 语法检查
bash -n ralph.sh
```

---

## 总结

### 问题本质
qwen CLI 流式请求 45 秒超时限制，无法通过配置修改

### 解决方案
✅ **超时重试机制**：自动检测并重试，超时时间递增

### 推荐做法
1. **优先使用 opencode**（更稳定，超时问题少）
2. **拆解大任务** 为小任务（每个 < 10 分钟）
3. **使用重试机制** 处理偶发超时

### 下一步
- 监控超时频率
- 根据实际情况调整超时参数
- 考虑迁移到 opencode 作为默认工具

---

**版本**: ralph.sh v2.1.1  
**更新日期**: 2026-03-05  
**文档**: [docs/TIMEOUT-FIX.md](docs/TIMEOUT-FIX.md)
