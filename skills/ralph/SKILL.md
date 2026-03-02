---
name: ralph
description: "Convert PRDs to prd.json format for the Ralph autonomous agent system with SPECKit support. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json."
user-invocable: true
---

# Ralph PRD Converter (SPECKit Edition)

Converts existing PRDs to the prd.json format that Ralph uses for autonomous execution, with SPECKit integration.

---

## SPECKit Integration

Each story now includes:

```json
{
  "spec": {
    "research": "检查现有代码结构",
    "plan": "添加priority字段",
    "implementation": "执行并验证"
  }
}
```

The RPI (Research-Plan-Implement) pattern helps agents work systematically.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description]",
  "spec": {
    "constitution": [
      "Spec-Driven Development: 规范先于代码",
      "Small Iterations: 每个任务可在一轮迭代内完成",
      "Verified: 每个验收标准必须可自动化验证",
      "CI Green: 保持持续集成通过"
    ],
    "dependencies": {
      "database": "required|optional",
      "testing": "recommended|optional",
      "browser": "optional"
    }
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "spec": {
        "research": "What to investigate",
        "plan": "Implementation steps",
        "implementation": "How to verify"
      },
      "acceptanceCriteria": [
        "Criterion 1 (verifiable)",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration.**

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic

### Too big (split these):
- "Build the entire dashboard" → Split into schema, queries, UI, filters

---

## RPI Pattern

Each story should have clear RPI steps:

1. **Research** - Study existing code patterns
2. **Plan** - Define implementation steps  
3. **Implement** - Write code and verify

---

## Acceptance Criteria Rules

- Must be **verifiable** (not vague)
- Always include `"Typecheck passes"` as final criterion
- Frontend stories include `"Verify in browser using dev-browser skill"`

### Good:
- "Add `status` column to tasks table"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"

### Bad:
- "Works correctly"
- "Good UX"
- "Handles edge cases"

---

## Example

**Input:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.
- Toggle pending/in-progress/done
- Filter list by status
- Show status badge
```

**Output prd.json:**
```json
{
  "project": "TaskApp",
  "branchName": "ralph/task-status",
  "description": "Task Status Feature",
  "spec": {
    "constitution": [
      "Spec-Driven Development",
      "Small Iterations",
      "Verified",
      "CI Green"
    ]
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "spec": {
        "research": "检查现有schema和migration工具",
        "plan": "创建migration添加status字段",
        "implementation": "执行migration"
      },
      "acceptanceCriteria": [
        "Add status column with type pending|in_progress|done",
        "Migration runs successfully",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
```

---

## Checklist Before Saving

- [ ] Stories are small enough for one iteration
- [ ] Each story has RPI in spec
- [ ] Every story has "Typecheck passes"
- [ ] UI stories have browser verification
- [ ] Acceptance criteria are verifiable