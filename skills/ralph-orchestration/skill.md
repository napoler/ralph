# Ralph Orchestration Skill

## Overview
Interactive task orchestration - analyzes user task description and automatically selects the most appropriate AI tool to execute via ralph.sh.

## Usage
```
/ralph <task description>
/ralph -t <tool> <task>
/ralph --tool <tool> --max <n> --project <path> <task>
```

## Parameters
- `-t`, `--tool`: AI tool (qwen, opencode, cline, kilocode, iflow, gemini, oracle)
- `-m`, `--max`: Max iterations (default: 10)
- `-p`, `--project`: Project directory
- `-y`, `--no-interactive`: Skip interactive confirmation
- `-l`, `--log`: Show execution log
- `-h`, `--help`: Show help

## Keywords
See `keywords.conf` for tool mapping rules.

## Example
```
/ralph 帮我修复登录 bug
/ralph -t cline 编写自动化脚本
/ralph --tool opencode --max 20 --project /path/to/project 实现用户登录
/ralph -y 代码审查
```

## Tool Selection Logic
1. If tool explicitly specified (-t/--tool), use it
2. Otherwise, match task keywords to tools (see keywords.conf)
3. If no match, use default tool (qwen with load balancing)

## Interactive Mode
If no tool is specified, skill will:
1. Display parsed task
2. Show auto-matched tool
3. Ask for confirmation or adjustment
4. Execute ralph.sh with selected parameters

Use `-y` flag to skip interactive mode.

## Configuration
- Config file: `config.yaml`
- Keywords: `keywords.conf`
- Log file: `~/.ralph/skill.log`

## Installation
```bash
cd /path/to/ralph-fork
bash skills/ralph-orchestration/install-skill.sh
```

## Installation (Manual)
```bash
cp -r skills/ralph-orchestration ~/.config/opencode/skills/
chmod +x ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh
```

## Alias (Optional)
Add to `~/.bashrc`:
```bash
alias ralph='bash ~/.config/opencode/skills/ralph-orchestration/ralph-orchestration.sh'
```

## Related Files
- `ralph-orchestration.sh` - Main script
- `install-skill.sh` - Installation script
- `config.yaml` - Configuration
- `keywords.conf` - Keyword to tool mapping
- `SKILL.md` - Detailed documentation