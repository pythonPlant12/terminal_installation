---
name: agent-task-writer
description: AI-native hierarchical task database for managing work items that agents can execute autonomously. Use when creating, triaging, decomposing, or executing tasks stored as markdown files in a tasks/ directory. Specializes in writing AI-first task definitions with unambiguous acceptance criteria, hierarchical parent/child relationships, semantic frontmatter, and prompt engineering principles that make tasks self-sufficient for autonomous agent execution. Triggers on: "create a task", "add to task db", "decompose this work", "triage tasks", "what should I work on", "write a task for", "break this down into tasks".
input: Task description, Jira issue, spec doc, or work breakdown to convert into agent-executable task files
output: Rich markdown task files in tasks/ with semantic frontmatter, acceptance criteria, and full execution context for autonomous agents
category: task-management
---

# AI Task Database Skill

## Philosophy

A task written for a human is a reminder. A task written for an AI is a **complete execution context**.

The gap between these is the difference between "fix the login bug" and a task file that contains: the root cause, the affected files with line numbers, the exact acceptance criteria, the approach already investigated, the edge cases to handle, and the definition of done that can be verified without asking anyone.

This skill manages a file-based task database designed from the ground up for AI-native execution — where tasks are rich enough that an agent can pick one up cold and ship it without a single follow-up question.

## Quick Start

**Create a task:**
```bash
# Determine next ID
ls tasks/ | grep -oE '^[0-9]+' | sort -n | tail -1 | awk '{printf "%04d", $1+1}'

# Scaffold from template
cp opencode/skills/ai-task-db/assets/task-template.md tasks/0001-pending-p2-fix-auth-redirect.md
```

**Find work to do:**
```bash
# Ready + unblocked + highest priority
ls tasks/*-ready-p1-*.md tasks/*-ready-p2-*.md 2>/dev/null | head -5

# Show the full task
cat tasks/0001-ready-p1-fix-auth-redirect.md
```

**Decompose a large task into children:**
```bash
# Reference parent ID in child frontmatter
# parent: "0001"
```

## File Naming Convention

```
{id}-{status}-{priority}-{slug}.md
```

| Component | Values | Notes |
|-----------|--------|-------|
| `id` | `0001`, `0002`… | 4-digit, zero-padded, never reused |
| `status` | `pending` `ready` `in-progress` `complete` `cancelled` | Machine-parseable lifecycle |
| `priority` | `p1` `p2` `p3` | p1 = blocking/critical, p3 = nice-to-have |
| `slug` | kebab-case, ≤6 words | Identifies the task at a glance |

**Examples:**
```
0001-pending-p2-add-retry-logic-to-mailer.md
0002-ready-p1-fix-n-plus-1-query-in-users-index.md
0023-in-progress-p2-refactor-auth-middleware.md
0045-complete-p1-patch-xss-in-comment-renderer.md
```

## Frontmatter Schema

```yaml
---
id: "0001"
status: pending          # pending | ready | in-progress | complete | cancelled
priority: p2             # p1 | p2 | p3
type: bug                # bug | feature | refactor | chore | research | spike
agent_ready: false       # true = agent can execute autonomously without clarification
parent: null             # parent task ID if this is a subtask
children: []             # child task IDs decomposed from this task
blocks: []               # task IDs that cannot start until this completes
blocked_by: []           # task IDs that must complete before this can start
tags: []                 # semantic labels: [rails, auth, performance, security, ...]
effort: null             # xs | s | m | l | xl  (XS=<1h, S=1-4h, M=4-16h, L=16-40h, XL>40h)
assigned_to: null        # human name, "agent", or null
context_files: []        # key files agent must read before starting
verified_by: null        # who/what verifies completion (human | ci | agent-self)
created: "2026-02-27"
updated: "2026-02-27"
---
```

## AI-First Task Writing

The single most important property of a well-written task: **an agent reading it cold has zero need to ask a follow-up question.**

For detailed guidance on writing tasks that agents can execute autonomously, see [ai-first-writing.md](assets/ai-first-writing.md).

### The Five Requirements for Agent-Ready Tasks

A task is `agent_ready: true` only when it satisfies all five:

1. **Grounded** — Every claim cites a file path and line number, not a vague description.
2. **Scoped** — Exactly what to change is stated. What NOT to change is also stated.
3. **Verifiable** — Acceptance criteria are commands or observable states, not adjectives.
4. **Contextual** — `context_files` lists every file the agent needs to read first.
5. **Unambiguous** — No sentence admits two interpretations.

### Common Failure Modes

| Bad | Why it fails | Better |
|-----|-------------|--------|
| "Fix the login bug" | No location, no root cause, no definition of fixed | "Fix 401 returned for valid sessions: `app/middleware/auth.rb:83` checks `token_valid?` but never refreshes expired tokens. Refresh on 401 before re-checking." |
| "Improve performance" | No baseline, no target, no measurement method | "Reduce `GET /users` p95 latency from 800ms to <200ms. Root cause: N+1 on `user.posts`. Fix: eager-load with `includes(:posts)` in `UsersController#index:42`." |
| "Add tests" | No coverage target, no scenarios listed | "Add 8 unit tests to `test/models/user_test.rb` covering: empty name, name > 255 chars, email with unicode, duplicate email. Each must assert the specific error message returned." |
| "Refactor this" | No success state, ambiguous scope | "Extract `parse_csv` from `ImportService#run` (lines 45–102) into `CsvParser`. Public API: `CsvParser.new(io).parse → Array<Hash>`. No behavior changes. Existing tests must pass unchanged." |

## Hierarchy Model

Tasks can be decomposed into parent → child relationships. This enables both high-level planning and atomic execution.

```
0001-ready-p1-auth-overhaul.md          (parent, agent_ready: false)
├── 0002-ready-p1-add-token-refresh.md  (child, agent_ready: true)
├── 0003-ready-p2-migrate-session-db.md (child, agent_ready: true)
└── 0004-pending-p2-update-api-docs.md  (child, blocked_by: ["0002","0003"])
```

**Rules:**
- Parents with children are rarely `agent_ready: true` — they coordinate, children execute.
- Children inherit parent's `tags` unless overridden.
- A child's `priority` can be higher than the parent (fast-path a critical sub-step).
- Complete parent only after all children are `complete` or `cancelled`.

## Workflows

### Creating a New Task

1. Find next ID: `ls tasks/ | grep -oE '^[0-9]+' | sort -n | tail -1 | awk '{printf "%04d", $1+1}'`
2. Copy template: `cp opencode/skills/ai-task-db/assets/task-template.md tasks/{ID}-pending-{priority}-{slug}.md`
3. Fill **Problem Statement** — what is wrong or missing, and why it matters.
4. Fill **Root Cause / Background** — what investigation has already revealed.
5. Fill **Proposed Approach** — the recommended path; alternatives if genuinely uncertain.
6. Fill **Acceptance Criteria** — concrete, verifiable, command-level where possible.
7. Fill **context_files** — every file an agent must read before starting.
8. Set `agent_ready: true` only when the task passes the five requirements above.
9. Set status to `pending` (needs triage) or `ready` (pre-approved, can start now).

**Decide: todo or immediate action?**

| Create a task | Act immediately |
|--------------|-----------------|
| Work > 20 minutes | Work < 15 minutes |
| Requires planning or research | Solution is obvious |
| Has dependencies | No dependencies |
| Needs prioritization decision | User requests it now |
| Part of larger effort | Simple one-liner fix |

### Triage: Promoting Pending → Ready

```bash
# List pending
ls tasks/*-pending-*.md

# For each: read and decide
cat tasks/0001-pending-p2-*.md
```

During triage, fill:
- **Recommended Action** section (concrete plan)
- Adjust priority if initial assessment was off
- Set `agent_ready: true/false`
- Rename: `mv tasks/0001-pending-p2-slug.md tasks/0001-ready-p2-slug.md`
- Update frontmatter `status: ready`

**Triage decision rubric:**
- **Approve (→ ready):** Problem is real, approach is sound, effort is reasonable.
- **Defer (stay pending):** Real problem but wrong time — add a note why.
- **Reject (→ cancelled):** Not a real problem, or will be solved by other work.
- **Decompose:** Too large — break into children first, then approve children.

### Decomposing a Large Task

When a task is too large to be `agent_ready: true`:

1. Keep the parent task, set `agent_ready: false`.
2. Create child tasks (one per atomic unit of work).
3. Add child IDs to parent's `children: ["0002","0003"]`.
4. Add parent ID to each child's `parent: "0001"`.
5. Wire `blocked_by`/`blocks` chains between children if ordered.
6. Set each child to `agent_ready: true` when it passes the five requirements.

### Executing a Task (as Agent)

When you pick up a task to execute:

1. Read all files listed in `context_files`.
2. Confirm you understand the acceptance criteria — if anything is ambiguous, add a note to the task's Work Log and ask the user before proceeding (do not guess).
3. Change `status: in-progress` in the frontmatter, rename the file.
4. Execute the work.
5. Verify each acceptance criterion — run the exact commands if specified.
6. Add a Work Log entry: date, actions, test results, learnings.
7. Change `status: complete`, rename file.
8. Check `blocks` — notify or unblock downstream tasks.

### Updating Work Logs

Every session that touches a task adds a work log entry:

```markdown
### 2026-02-27 — Session Title

**By:** Claude Code / Marc

**Actions:**
- What changed (file:line references)
- Commands run and output
- Tests executed, results

**Learnings:**
- What worked, what didn't
- Gotchas discovered
- Patterns relevant to future work
```

### Completing a Task

1. All acceptance criteria checked off.
2. Work Log has final entry with evidence.
3. `status: complete`, rename file.
4. Check `blocks` array — are any downstream tasks now unblocked?
5. If this is a child task, check if all siblings are complete → complete parent.

## Quick Reference Commands

```bash
# Next available ID
ls tasks/ | grep -oE '^[0-9]+' | sort -n | tail -1 | awk '{printf "%04d", $1+1}'

# All agent-ready work, by priority
grep -l 'agent_ready: true' tasks/*-ready-*.md | sort

# Unblocked ready work (empty blocked_by)
grep -rL 'blocked_by:.*"' tasks/*-ready-*.md 2>/dev/null

# What is in-progress right now
ls tasks/*-in-progress-*.md 2>/dev/null

# Status counts
for s in pending ready in-progress complete cancelled; do
  count=$(ls tasks/*-${s}-*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "$s: $count"
done

# Find tasks blocking a given task
grep -l '"0001"' tasks/*.md | xargs grep -l 'blocks:'

# Find all children of a parent
grep -rl 'parent: "0001"' tasks/

# Search by tag
grep -rl 'auth' tasks/*.md | xargs grep -l 'tags:'

# Tasks by assignee
grep -rl 'assigned_to: agent' tasks/*-ready-*.md
```

## Relationship to Other Task Systems

| System | Purpose | Scope |
|--------|---------|-------|
| **ai-task-db** (this skill) | Persistent project task database | Cross-session, shared, hierarchical |
| **file-todos** skill | Lightweight markdown todos in `todos/` | Development/PR tracking, simpler schema |
| **TodoWrite tool** | In-memory agent session tracking | Single conversation, not persisted |
| **Jira / Linear** | Org-level issue tracking | External, team-wide |

Use ai-task-db when tasks need hierarchical decomposition, AI-execution metadata, or multi-session persistence with rich semantic routing. Use file-todos for lightweight PR/code-review tracking. Use TodoWrite for within-session agent steps.

## Reference Files

- [ai-first-writing.md](assets/ai-first-writing.md) — Deep guide on writing tasks agents can execute autonomously
- [task-template.md](assets/task-template.md) — Canonical task file template
