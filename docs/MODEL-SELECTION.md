# 模型选择功能说明

## 功能概述

Ralph 支持在使用 opencode 工具时指定使用的模型。模型名称格式为 `provider/model-name`。

## 使用方法

### 1. 命令行参数

```bash
# 使用 opencode + Qwen 3.5 Plus 模型执行任务
./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus -t "实现用户认证功能"

# 指定迭代次数
./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus --max 20 -t "开发 REST API"

# 使用其他模型
./ralph.sh --tool opencode --model bailian-coding-plan/glm-5 -t "任务描述"
./ralph.sh --tool opencode --model bailian-coding-plan/kimi-k2.5 -t "任务描述"
```

### 2. 配置文件

在 `ralph.conf` 中设置默认模型：

```bash
# 模型选择 (用于 opencode 等工具)
# 格式：provider/model-name
# 示例：RALPH_MODEL="bailian-coding-plan/qwen3.5-plus"
RALPH_MODEL="bailian-coding-plan/qwen3.5-plus"
```

设置后，使用 opencode 时会自动使用该模型，无需每次指定。

### 3. 环境变量

```bash
# 临时设置模型
RALPH_MODEL=bailian-coding-plan/qwen3.5-plus ./ralph.sh --tool opencode -t "任务描述"
```

## 优先级

模型设置的优先级（从高到低）：

1. **命令行参数** `--model` (最高优先级)
2. **环境变量** `RALPH_MODEL`
3. **配置文件** `ralph.conf` 中的 `RALPH_MODEL`
4. **默认值** (不指定模型)

## 可用模型

### 查看可用模型

```bash
# 列出所有可用模型
opencode models

# 查看特定提供商的模型
opencode models bailian-coding-plan
```

### 常用模型列表

#### Bailian Coding Plan (推荐)
```
bailian-coding-plan/qwen3.5-plus     # Qwen 3.5 Plus (推荐用于代码)
bailian-coding-plan/glm-5            # GLM-5
bailian-coding-plan/kimi-k2.5        # Kimi K2.5
bailian-coding-plan/MiniMax-M2.5     # MiniMax M2.5
```

#### Hunyuan (腾讯混元)
```
hunyuan/hunyuan-lite                 # 轻量版
hunyuan/hunyuan-pro                  # 专业版
hunyuan/hunyuan-standard             # 标准版
hunyuan/hunyuan-turbo                # 加速版
```

#### Iflow
```
iflowcn/deepseek-r1                  # DeepSeek R1
iflowcn/deepseek-v3                  # DeepSeek V3
iflowcn/qwen3-235b                   # Qwen3 235B
iflowcn/qwen3-max                    # Qwen3 Max
```

#### ModelScope
```
modelscope/qwen-max                  # Qwen Max
modelscope/qwen-plus                 # Qwen Plus
modelscope/qwen-turbo                # Qwen Turbo
```

#### Nvidia
```
nvidia/meta/llama-3.1-70b-instruct   # Llama 3.1 70B
nvidia/meta/llama-3.3-70b-instruct   # Llama 3.3 70B
nvidia/qwen/qwen3-235b-a22b          # Qwen3 235B
```

> 💡 **提示**: 使用 `opencode models` 查看完整模型列表（100+ 个模型）

## 模型名称格式

模型名称必须使用完整格式：`provider/model-name`

**正确示例** ✅:
```bash
./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus -t "任务"
./ralph.sh --tool opencode --model hunyuan/hunyuan-pro -t "任务"
```

**错误示例** ❌:
```bash
./ralph.sh --tool opencode --model qwen3.5 -t "任务"        # 缺少提供商
./ralph.sh --tool opencode --model qwen3.5-plus -t "任务"   # 缺少提供商
```

## 示例场景

### 场景 1: 临时使用特定模型

```bash
# 偶尔一次使用 Qwen 3.5 Plus
./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus -t "实现功能 X"
```

### 场景 2: 长期使用特定模型

```bash
# 在 ralph.conf 中设置
echo 'RALPH_MODEL="bailian-coding-plan/qwen3.5-plus"' >> ralph.conf

# 之后所有 opencode 任务都会使用 Qwen 3.5 Plus
./ralph.sh --tool opencode -t "任务 1"
./ralph.sh --tool opencode -t "任务 2"
```

### 场景 3: 不同任务使用不同模型

```bash
# 复杂代码任务使用 Qwen 3.5 Plus
./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus -t "实现完整的认证系统"

# 文本生成任务使用 GLM-5
./ralph.sh --tool opencode --model bailian-coding-plan/glm-5 -t "生成文档"

# 快速测试使用轻量模型
./ralph.sh --tool opencode --model hunyuan/hunyuan-lite -t "修复拼写错误"
```

### 场景 4: 根据提供商选择

```bash
# 使用 DeepSeek 模型（数学能力强）
./ralph.sh --tool opencode --model iflowcn/deepseek-r1 -t "算法优化"

# 使用 Llama 模型（通用能力强）
./ralph.sh --tool opencode --model nvidia/meta/llama-3.1-70b-instruct -t "代码审查"
```

## 注意事项

1. **模型格式**: 必须使用 `provider/model-name` 格式
2. **工具兼容性**: `--model` 参数仅对 opencode 工具有效
3. **模型可用性**: 确保指定的模型在你的环境中可用
4. **成本差异**: 不同模型的成本可能不同，请参考提供商定价
5. **性能差异**: 不同模型的性能和能力可能有差异

## 故障排查

### 问题：模型参数不生效

**检查清单**:

1. 确认使用的是 opencode 工具
   ```bash
   ./ralph.sh --tool opencode --model bailian-coding-plan/qwen3.5-plus -t "test"
   ```

2. 检查模型名称格式
   ```bash
   # 正确格式：provider/model-name
   bailian-coding-plan/qwen3.5-plus  ✅
   qwen3.5                          ❌ (缺少提供商)
   ```

3. 验证模型是否可用
   ```bash
   opencode models | grep qwen3.5
   ```

4. 检查是否有更高优先级的设置覆盖
   ```bash
   # 检查命令行、环境变量、配置文件
   echo "Env: $RALPH_MODEL"
   grep RALPH_MODEL ralph.conf
   ```

### 问题：找不到模型

**解决方案**:

```bash
# 1. 查看所有可用模型
opencode models

# 2. 查看特定提供商的模型
opencode models bailian-coding-plan

# 3. 搜索模型
opencode models | grep qwen
```

### 问题：模型调用失败

**可能原因**:

1. **API 密钥未配置** - 检查提供商的 API 密钥设置
2. **模型不可用** - 确认模型在你的区域可用
3. **配额限制** - 检查使用配额是否充足
4. **网络问题** - 检查网络连接和代理设置

**解决方法**:

```bash
# 检查 opencode 配置
opencode auth status

# 测试模型连接
opencode run "test" --model bailian-coding-plan/qwen3.5-plus
```

## 最佳实践

### 1. 根据任务类型选择模型

| 任务类型 | 推荐模型 | 理由 |
|---------|---------|------|
| 代码生成 | `bailian-coding-plan/qwen3.5-plus` | 代码能力强 |
| 代码审查 | `bailian-coding-plan/qwen3.5-plus` | 理解准确 |
| 文档编写 | `bailian-coding-plan/glm-5` | 文本流畅 |
| 算法优化 | `iflowcn/deepseek-r1` | 数学能力强 |
| 快速测试 | `hunyuan/hunyuan-lite` | 响应快，成本低 |

### 2. 成本管理

```bash
# 开发阶段使用经济型模型
RALPH_MODEL="hunyuan/hunyuan-lite"

# 生产环境使用高质量模型
RALPH_MODEL="bailian-coding-plan/qwen3.5-plus"
```

### 3. 测试不同模型

```bash
# 为同一任务测试不同模型
for model in "bailian-coding-plan/qwen3.5-plus" "bailian-coding-plan/glm-5" "hunyuan/hunyuan-pro"; do
    echo "Testing with $model..."
    ./ralph.sh --tool opencode --model "$model" -t "简单任务" --max 3
done
```

## 相关文档

- [opencode 官方文档](https://opencode.ai/docs)
- [opencode models 命令](https://opencode.ai/docs/cli/models)
- [README.md](../README.md) - 项目主文档
- [ralph.conf.example](../ralph.conf.example) - 配置文件示例

## 更新日志

### v2.1.1 (2026-03-09)

- ✅ 添加 `--model` 命令行参数
- ✅ 支持 `RALPH_MODEL` 环境变量
- ✅ 支持配置文件中的 `RALPH_MODEL` 设置
- ✅ 更新文档，使用正确的模型名称格式
- ✅ 添加常用模型列表和选择建议
