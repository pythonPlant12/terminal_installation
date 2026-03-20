---
name: skill-curator
description: Audit and maintain the skill inventory. Use when reviewing skill quality, checking for missing frontmatter, suggesting new categories, detecting skill gaps, or validating skill descriptions match behavior. Triggers on "audit skills", "check skill quality", "skill inventory health", "what skills exist", "improve skill descriptions".
input: Skill inventory file (skill-inventory.md), specific SKILL.md to audit, or gap analysis request
output: Audit report with actionable improvement suggestions, gap analysis, or relationship map
category: skill-authoring
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Skill Curator

Audit, maintain, and improve the skill inventory for agent-native skill discovery.

## Quick Start

Run the inventory generator first, then use this skill to audit quality:

```bash
ai-setup-skill-inventory --check    # Validate frontmatter completeness
ai-setup-skill-inventory --generate # Regenerate inventory
```

Then invoke this skill: `/skill-curator audit` or `/skill-curator gaps`

## Capabilities

### 1. Audit Skill Quality

Check all SKILL.md files against quality criteria:

**Frontmatter Completeness:**
- [ ] `name` — present, lowercase-with-hyphens, max 64 chars
- [ ] `description` — present, includes trigger phrases, max 1024 chars
- [ ] `input` — present, 1-2 sentences describing what skill expects
- [ ] `output` — present, 1-2 sentences describing what skill produces
- [ ] `category` — present, matches taxonomy (architecture-design, code-quality, documentation, frontend, git, integration, language-specific, project-knowledge, skill-authoring, task-management)

**Description Quality:**
- [ ] Includes "when to use" context (not just "what it does")
- [ ] Contains trigger keywords users would naturally say
- [ ] Specific enough to distinguish from similar skills
- [ ] Written in third person ("This skill should be used when...")

**I/O Contract Quality:**
- [ ] Input describes the expected artifact type (file path, issue key, text, etc.)
- [ ] Output describes concrete deliverables (files created, reports generated, etc.)
- [ ] Neither input nor output is vague ("various things", "helpful output")

### 2. Detect Gaps

Analyze what users ask for vs what skills exist:

**Method:**
1. Read `~/.config/opencode/skills/skill-inventory.md`
2. Review category distribution — are any categories thin?
3. Check for common workflows that span multiple skills but have no orchestrator
4. Look for skills that overlap significantly (candidates for merging)

**Report Format:**
```
## Gap Analysis

### Under-served categories
- [category]: only N skills, consider adding [suggestion]

### Missing orchestrations
- [workflow description]: requires [skill-a] → [skill-b] → [skill-c] but no single skill coordinates this

### Overlap candidates
- [skill-a] and [skill-b]: significant overlap in [area], consider merging
```

### 3. Map Relationships

Document which skills compose together:

**Known pipelines:**
- `jira-rca-intake` → `deep-root-cause-analysis` → `create-actionable-task`
- `brainstorming` → `document-review`
- `skill-creator` ↔ `create-agent-skills` (complementary)

**Discover new relationships by:**
1. Reading each skill's allowed-tools and checking if it spawns other skills
2. Checking if output of one skill matches input contract of another
3. Looking for skills that reference each other in their body text

### 4. Suggest Improvements

For each skill with quality issues, suggest specific edits:

```
## Improvement Suggestions

### [skill-name]
- **Issue**: Description too vague — "helps with documents"
- **Suggested**: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction."
- **Reason**: Original lacks trigger keywords and specificity
```

## Category Taxonomy Reference

| Category | Description | Example Skills |
|----------|-------------|----------------|
| architecture-design | System design, planning, requirements | agent-native-architecture, brainstorming |
| code-quality | Linting, validation, merge gates | contract-map, pre-merge-shell-checklist |
| documentation | Knowledge capture, compound docs | do-compound |
| frontend | Frontend UI/UX | frontend-design |
| git | Git workflow tools | git-worktree |
| integration | External service integration | agent-browser, rclone, gemini-imagegen |
| language-specific | Language/framework patterns | dhh-rails-style, dspy-ruby |
| project-knowledge | Project-local context | project-knowledge |
| skill-authoring | Creating and managing skills | skill-creator, create-agent-skills |
| task-management | Issue tracking, RCA, todos | jira-rca-intake, create-actionable-task |

## Workflow

1. **Always read inventory first**: `Read ~/.config/opencode/skills/skill-inventory.md`
2. **For audits**: iterate through each skill entry, check against quality criteria above
3. **For gaps**: analyze category distribution and cross-skill workflows
4. **For relationships**: trace skill references and I/O contract matches
5. **Report findings**: structured markdown with actionable suggestions
