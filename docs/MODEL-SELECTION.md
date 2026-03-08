# 模型选择功能说明

## 功能概述

Ralph 现在支持在使用 opencode 工具时指定使用的模型，例如使用 qwen3.5 模型执行任务。

## 使用方法

### 1. 命令行参数

```bash
# 使用 opencode + qwen3.5 模型执行任务
./ralph.sh --tool opencode --model qwen3.5 -t "实现用户认证功能"

# 指定迭代次数
./ralph.sh --tool opencode --model qwen3.5 --max 20 -t "开发 REST API"

# 从 prd.json 执行任务
./ralph.sh --tool opencode --model qwen3.5
```

### 2. 配置文件

在 `ralph.conf` 中设置默认模型：

```bash
# 模型选择 (用于 opencode 等工具)
# 示例：RALPH_MODEL="qwen3.5"
RALPH_MODEL="qwen3.5"
```

设置后，使用 opencode 时会自动使用该模型，无需每次指定。

### 3. 环境变量

```bash
# 临时设置模型
RALPH_MODEL=qwen3.5 ./ralph.sh --tool opencode -t "任务描述"
```

## 优先级

模型设置的优先级（从高到低）：

1. **命令行参数** `--model` (最高优先级)
2. **环境变量** `RALPH_MODEL`
3. **配置文件** `ralph.conf` 中的 `RALPH_MODEL`
4. **默认值** (不指定模型)

## 支持的模型

支持的模型取决于你使用的 AI 工具。对于 opencode，常见的模型包括：

- `qwen3.5` - Qwen 3.5 模型
- `qwen3` - Qwen 3 模型
- 其他模型请参考 opencode 官方文档

## 示例场景

### 场景 1: 临时使用特定模型

```bash
# 偶尔一次使用 qwen3.5
./ralph.sh --tool opencode --model qwen3.5 -t "实现功能 X"
```

### 场景 2: 长期使用特定模型

```bash
# 在 ralph.conf 中设置
echo 'RALPH_MODEL="qwen3.5"' >> ralph.conf

# 之后所有 opencode 任务都会使用 qwen3.5
./ralph.sh --tool opencode -t "任务 1"
./ralph.sh --tool opencode -t "任务 2"
```

### 场景 3: 不同任务使用不同模型

```bash
# 复杂任务使用更强的模型
./ralph.sh --tool opencode --model qwen3.5 -t "实现完整的认证系统"

# 简单任务使用默认模型
./ralph.sh --tool opencode -t "修复拼写错误"
```

## 验证模型设置

```bash
# 查看当前配置
./ralph.sh --help | grep model

# 查看配置文件中的设置
grep RALPH_MODEL ralph.conf
```

## 注意事项

1. **模型可用性**: 确保指定的模型在你的环境中可用
2. **工具兼容性**: `--model` 参数目前仅对 opencode 工具有效
3. **模型名称**: 模型名称必须与 opencode 支持的名称完全匹配
4. **性能差异**: 不同模型的性能和能力可能有差异，请根据任务需求选择

## 故障排查

### 问题：模型参数不生效

**检查清单**:

1. 确认使用的是 opencode 工具
   ```bash
   ./ralph.sh --tool opencode --model qwen3.5 -t "test"
   ```

2. 检查模型名称是否正确
   ```bash
   # 查看 opencode 支持的模型列表
   opencode --help
   ```

3. 检查是否有更高优先级的设置覆盖
   ```bash
   # 检查命令行、环境变量、配置文件
   echo "Env: $RALPH_MODEL"
   grep RALPH_MODEL ralph.conf
   ```

### 问题：opencode 不支持 --model 参数

如果你的 opencode 版本不支持 `--model` 参数，请升级到最新版本：

```bash
npm install -g opencode
# 或
yarn global add opencode
```

## 相关文件

- `ralph.sh` - 主脚本（包含模型选择逻辑）
- `ralph.conf.example` - 配置文件示例
- `README.md` - 完整文档

## 更新日志

### v2.1.1 (2026-03-09)

- ✅ 添加 `--model` 命令行参数
- ✅ 支持 `RALPH_MODEL` 环境变量
- ✅ 支持配置文件中的 `RALPH_MODEL` 设置
- ✅ 更新文档和示例
