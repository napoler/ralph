# Ralph 项目目录结构规范

> **统一规范：所有 Ralph 相关文件都在 `ralph/` 目录下**

## 标准目录结构

```
ralph-fork/
├── .claude/
│   └── skills/                   # Claude Code 技能目录
│       ├── ralph/                # Ralph 技能
│       └── ralph-orchestration/  # Ralph 编排技能
├── docs/                         # 项目文档
├── ralph/                        # Ralph 主目录 ✓
│   ├── ralph.sh                  # 主脚本入口
│   ├── ralph.conf                # 主配置文件
│   ├── install.sh                # 安装脚本
│   ├── cron-tasks-optimized.conf # Cron 任务配置
│   ├── generate-specs.sh         # SPEC 生成器
│   ├── STRUCTURE.md              # 目录结构规范
│   └── specs/                    # 自动生成的规格文档
├── test/                         # 测试脚本
├── CLAUDE.md                     # Claude 配置
├── AGENTS.md                     # Agent 配置
└── README.md                     # 项目说明
```

## 文件用途

| 路径 | 用途 | 必需 |
|------|------|------|
| `ralph/ralph.sh` | 主脚本入口 | ✓ |
| `ralph/ralph.conf` | 主配置文件 | ✓ |
| `ralph/install.sh` | 安装脚本 | ✓ |
| `ralph/generate-specs.sh` | SPEC 生成器 | ✓ |
| `ralph/cron-tasks-optimized.conf` | Cron 配置 | ○ |
| `ralph/STRUCTURE.md` | 目录规范文档 | ✓ |
| `.claude/skills/ralph/` | Ralph 技能 | ○ |
| `.claude/skills/ralph-orchestration/` | 编排技能 | ○ |

## 已删除的冗余内容

| 路径 | 删除原因 |
|------|----------|
| `install.sh` (根目录) | 与 `ralph/install.sh` 重复 |
| `ralph.conf` (根目录) | 配置应在 `ralph/` 目录内 |
| `ralph.sh` (根目录) | 脚本应在 `ralph/` 目录内 |
| `skills/` (根目录) | 非标准位置，应使用 `.claude/skills/` |
| `archive/` | 空目录 |
| `specs/` (根目录) | 与 `ralph/specs/` 重复 |
| `flowchart/` | 无关的前端项目 |

## 安装脚本说明

`ralph/install.sh` 用于将 Ralph 安装到其他项目：

```bash
# 安装到当前目录
cd /path/to/project
/path/to/ralph-fork/ralph/install.sh .

# 或指定目标目录
/path/to/ralph-fork/ralph/install.sh /path/to/my-project
```

安装内容：
1. 复制核心文件到目标项目的 `ralph/` 目录
2. 安装 skills 到目标项目的 `.claude/skills/` 目录
3. 自动配置项目路径

## Cron 任务配置

编辑 `ralph/cron-tasks-optimized.conf` 后安装：

```bash
crontab ralph/cron-tasks-optimized.conf
```

## 技能管理

技能位于 `.claude/skills/` 目录：

- `ralph/` - Ralph 基础技能
- `ralph-orchestration/` - Ralph 编排技能

每个技能包含：
- `install-skill.sh` - 技能安装脚本
- `skill.md` / `SKILL.md` - 技能说明
- `config.yaml` - 配置文件
- `keywords.conf` - 关键词配置

---

最后更新：2026-03-10
