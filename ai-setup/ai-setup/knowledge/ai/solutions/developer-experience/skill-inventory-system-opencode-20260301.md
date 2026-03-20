---
schema_version: 2
module: OpenCode Skill System
date: 2026-03-01
problem_type: developer_experience
component: development-workflow
symptoms:
  - Agents had no structured way to discover 28+ deployed skills
  - Only short descriptions in system prompt; no categories or I/O contracts
  - Skill relationships and dependencies were undocumented
  - No queryable inventory for agent reasoning about available skills
root_cause: missing_tooling
resolution_type: tooling_addition
severity: high
confidence: high
summary: "With 28+ skills deployed across ~/.config/opencode/skills/, agents (especially the orchestrator Sisyphus) had no structured way to select the right skills for task(load_skills=[...])."
applies_when:
  - Agents had no structured way to discover 28+ deployed skills
  - Only short descriptions in system prompt; no categories or I/O contracts
  - Skill relationships and dependencies were undocumented
verification_commands:
  - ai-setup-doctor --json
evidence_paths:
  - knowledge/ai/solutions/developer-experience/skill-inventory-system-opencode-20260301.md
tags:
  - skill-discovery
  - agent-infrastructure
  - frontmatter
  - inventory
  - taxonomy
status: active
---

# Skill Inventory System — Scalable Skill Discovery for Agents


## Agent Card

- Use when: Agents had no structured way to discover 28+ deployed skills
- Core fix: With 28+ skills deployed across `~/.config/opencode/skills/`, agents (especially the orchestrator Sisyphus) had no structured way to select the right skills for `task(load_skills=[...])`. The system prompt listing onl...
- Avoid when: The failure pattern does not match.
- Verify with: `ai-setup-doctor --json`

## Problem

With 28+ skills deployed across `~/.config/opencode/skills/`, agents (especially the orchestrator Sisyphus) had no structured way to select the right skills for `task(load_skills=[...])`. The system prompt listing only provided short `name` + `description` pairs — no categories, no I/O contracts, no relationship mapping, no quality signals.

**Symptoms observed:**
- Agents guessed which skills to load based on vague descriptions
- No way to query "which skills help with code review?"
- Skill pipelines (e.g., do-compound → compound-to-gsd-knowledge → compound-to-nearest-agents-learning) were invisible
- New skills couldn't be discovered without reading SKILL.md files manually

## Root Cause

SKILL.md frontmatter only supported `name` and `description` fields. No structured metadata existed for:
- **Categorization** — grouping skills by domain
- **I/O contracts** — what a skill expects and produces
- **Capability matching** — selecting skills for task delegation
- **Relationship mapping** — which skills compose together

OpenCode's discovery mechanism scans `**/SKILL.md` via glob and parses YAML frontmatter, but only `name` and `description` were populated.

## Solution

### 1. Frontmatter Extension (input/output/category)

Added three new fields to all 28 deployed SKILL.md files:

```yaml
---
name: brainstorming
description: This skill should be used before implementing...
input: Ambiguous feature request, design question, or unclear requirements
output: Structured brainstorm document with clarified requirements and approach options
category: architecture-design
---
```

**Implementation approach:** Created a batch update script that:
- Parses existing frontmatter with awk
- Injects `input`, `output`, `category` before the closing `---`
- Applies to both repo copies (`opencode/skills/`) and deployed copies (`~/.config/opencode/skills/`)
- Is idempotent (skips skills that already have `category`)

### 2. Category Taxonomy (10 categories)

| Category | Description | Count |
|----------|-------------|-------|
| architecture-design | System design, planning, requirements | 2 |
| code-quality | Linting, validation, merge gates | 4 |
| documentation | Knowledge capture, compound docs | 5 |
| frontend | Frontend UI/UX | 1 |
| git | Git workflow tools | 1 |
| integration | External service integration | 6 |
| language-specific | Language/framework patterns | 4 |
| project-knowledge | Project-local context | 1 |
| skill-authoring | Creating and managing skills | 3 |
| task-management | Issue tracking, RCA, todos | 5 |

### 3. Generator Script (bin/ai-setup-skill-inventory)

454-line zsh script with three modes:
- `--generate` — Scans SKILL.md files, produces `~/.config/opencode/skills/skill-inventory.md` grouped by category
- `--json` — Structured JSON output for programmatic consumption
- `--check` — Validates all skills have required frontmatter fields

**Key design decisions:**
- Pure awk frontmatter parsing (no YAML parser dependency)
- Follows existing `bin/*` conventions: `set -euo pipefail`, `ROOT_DIR`, `lib.zsh` helpers
- Idempotent and safe to rerun

### 4. Skill Curator Subagent (skill-curator)

127-line SKILL.md that enables:
- Quality audits against frontmatter checklist
- Gap detection in category coverage
- Relationship mapping between skills
- Description improvement suggestions

### 5. Bootstrap Integration

Added `run_step "skill inventory"` in `scripts/bootstrap.zsh` after config sync, so the inventory regenerates automatically during `./bootstrap.zsh`.

## Failed Attempts

1. **project-knowledge skill path**: Initially assumed `.agents/skills/project-knowledge/SKILL.md` existed in the repo — it doesn't. The skill only existed theoretically.

2. **do-compound placeholder**: The batch script skipped `do-compound` in `~/.config/` because it already had `category: <category>` (a placeholder from a previous partial attempt). Required manual fix.

3. **Generator script grep under set -e**: `grep` returns exit code 1 when no match, which kills the script under `set -e`. Fixed with `|| true` guards in the `get_field()` function.

4. **Over-scanning subdirectories**: The glob pattern initially picked up SKILL.md files inside `references/` subdirectories (61 files instead of 28). Fixed by restricting to `*/SKILL.md` (single level).

## Prevention

- **New skill template**: When creating skills with `skill-creator` or `create-agent-skills`, always include `input`, `output`, `category` in frontmatter
- **Validation gate**: Run `ai-setup-skill-inventory --check` during bootstrap to catch skills with missing metadata
- **Curator audits**: Periodically run `/skill-curator audit` to check quality and detect gaps

## Related

- `create-agent-skills` skill — References frontmatter best practices
- `skill-creator` skill — Guides skill creation workflow

## Verification

- `ai-setup-doctor --json` -> confirm expected behavior
