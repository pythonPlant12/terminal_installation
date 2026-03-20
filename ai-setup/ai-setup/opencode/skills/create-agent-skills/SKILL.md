---
name: create-agent-skills
description: Expert guidance for creating OpenCode skills and slash commands. Use when working with SKILL.md files, authoring new skills, improving existing skills, creating slash commands, or understanding skill structure and best practices.
input: Skill concept, existing SKILL.md to audit, or request for skill/command guidance
output: Complete SKILL.md with valid frontmatter, structured body, and best-practice compliance
category: skill-authoring
---

# Creating OpenCode Skills

This skill teaches how to create effective OpenCode skills. Reference existing skills in `opencode/skills/` as canonical examples.

## Skill System Overview

OpenCode uses a unified skill system. Skills live in `opencode/skills/{name}/SKILL.md` (repo source) and deploy to `~/.config/opencode/skills/{name}/SKILL.md`. There is no separate "commands" directory — skills are the only mechanism.

A skill directory can contain supporting files (references, scripts, templates) alongside the SKILL.md entry point.

## When To Create a Skill

**Create a skill** when:
- You have a repeatable workflow or procedure (deploy, commit, triage)
- Background knowledge the agent should auto-load when relevant
- Complex enough to benefit from progressive disclosure with reference files
- Need supporting reference files, scripts, or templates

## Standard Format

Use YAML frontmatter + markdown body with **standard markdown headings**:

```markdown
---
name: my-skill-name
description: What it does and when to use it
input: What the skill receives (concept, file, request)
output: What the skill produces (artifact, report, plan)
category: one-of-ten-categories
---

# My Skill Name

## Quick Start
Immediate actionable guidance...

## Instructions
Step-by-step procedures...

## Examples
Concrete usage examples...
```

## Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name. Lowercase letters, numbers, hyphens (max 64 chars). Defaults to directory name. |
| `description` | **Recommended** | What it does AND when to use it. Agent uses this for auto-discovery. Max 1024 chars. |
| `input` | **Yes** | What the skill receives. 1-2 sentences. Required per AGENTS.md. |
| `output` | **Yes** | What the skill produces. 1-2 sentences. Required per AGENTS.md. |
| `category` | **Yes** | One of the 10-category taxonomy. Required per AGENTS.md. |
| `argument-hint` | No | Hint shown during autocomplete. Example: `[issue-number]` |
| `disable-model-invocation` | No | Set `true` to prevent agent auto-loading. Use for manual workflows like `/deploy`, `/commit`. Default: `false`. |
| `user-invocable` | No | Set `false` to hide from `/` menu. Use for background knowledge. Default: `true`. |
| `allowed-tools` | No | Tools the agent can use without permission prompts. Example: `Read, Bash(git *)` |
| `model` | No | Model to use. Options: `haiku`, `sonnet`, `opus`. |
| `context` | No | Set `fork` to run in isolated subagent context. |
| `agent` | No | Subagent type when `context: fork`. Options: `Explore`, `Plan`, `general-purpose`, or custom agent name. |

### Required Frontmatter Fields

Per AGENTS.md, every skill MUST include `input`, `output`, and `category`:
- **`input`**: Derive from the skill's actual behavior — what does it receive? (1-2 sentences)
- **`output`**: Derive from the skill's actual behavior — what does it produce? (1-2 sentences)
- **`category`**: Must be one of: `architecture-design`, `code-quality`, `documentation`, `frontend`, `git`, `integration`, `language-specific`, `project-knowledge`, `skill-authoring`, `task-management`

Validate with: `ai-setup-skill-inventory --check`

### Invocation Control

| Frontmatter | User can invoke | Agent can invoke | When loaded |
|-------------|----------------|-------------------|-------------|
| (default) | Yes | Yes | Description always in context, full content loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, loads only when user invokes |
| `user-invocable: false` | No | Yes | Description always in context, loads when relevant |

**Use `disable-model-invocation: true`** for workflows with side effects: `/deploy`, `/commit`, `/triage-prs`. You don't want the agent deciding to deploy because your code looks ready.

**Use `user-invocable: false`** for background knowledge that isn't a meaningful user action: coding conventions, domain context, legacy system docs.

## Dynamic Features

### Arguments

Use `$ARGUMENTS` placeholder for user input. If not present in content, arguments are appended automatically.

```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.
```

Access individual args: `$ARGUMENTS[0]` or shorthand `$0`, `$1`, `$2`.

### Dynamic Context Injection

The `` !`command` `` syntax runs shell commands before content is sent to the agent:

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
---

## Context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`

Summarize this pull request...
```

### Running in a Subagent

Add `context: fork` to run in isolation. The skill content becomes the subagent's prompt. It won't have conversation history.

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files
2. Analyze the code
3. Summarize findings
```

## Directory Structure

Skills live in `opencode/skills/` (repo source) and deploy to `~/.config/opencode/skills/`:

```
opencode/skills/
├── my-skill/
│   ├── SKILL.md           # Entry point (required, overview + navigation)
│   ├── reference.md       # Detailed docs (loaded when needed)
│   ├── examples.md        # Usage examples (loaded when needed)
│   └── scripts/
│       └── helper.py      # Utility script (executed, not loaded)
├── another-skill/
│   └── SKILL.md
└── skill-inventory.md     # Auto-generated by ai-setup-skill-inventory
```

### Progressive Disclosure

Keep SKILL.md under 500 lines. Split detailed content into reference files.

Link from SKILL.md: `For API details, see [reference.md](reference.md).`

Keep references **one level deep** from SKILL.md. Avoid nested chains.

## Effective Descriptions

The description enables skill discovery. Include both **what** it does and **when** to use it.

**Good:**
```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

**Bad:**
```yaml
description: Helps with documents
```

## What Would You Like To Do?

1. **Create new skill** - Build from scratch
2. **Audit existing skill** - Check against best practices
3. **Add component** - Add workflow/reference/example
4. **Get guidance** - Understand skill design

## Creating a New Skill

### Step 1: Choose Type

Ask: Is this a manual workflow (deploy, commit, triage) or background knowledge (conventions, patterns)?

- **Manual workflow** → skill with `disable-model-invocation: true`
- **Background knowledge** → skill without `disable-model-invocation`
- **Complex with supporting files** → skill directory with references

### Step 2: Create the Skill

```markdown
---
name: my-skill
description: What it does. Use when [trigger conditions].
input: What this skill receives
output: What this skill produces
category: appropriate-category
---

# Skill Title

## Quick Start
[Immediate actionable example]

## Instructions
[Core guidance]

## Examples
[Concrete input/output pairs]
```

### Step 3: Add Reference Files (If Needed)

Link from SKILL.md to detailed content:
```markdown
For API reference, see [reference.md](reference.md).
For form filling guide, see [forms.md](forms.md).
```

### Step 4: Test With Real Usage

1. Test with actual tasks, not test scenarios
2. Invoke directly with `/skill-name` to verify
3. Check auto-triggering by asking something that matches the description
4. Refine based on real behavior

### Step 5: Validate Frontmatter

Run `ai-setup-skill-inventory --check` to verify all required fields are present.

## Audit Checklist

- [ ] Valid YAML frontmatter (`name` + `description`)
- [ ] Required fields present: `input`, `output`, `category`
- [ ] Description includes trigger keywords and is specific
- [ ] Uses standard markdown headings (not XML tags)
- [ ] SKILL.md under 500 lines
- [ ] `disable-model-invocation: true` if it has side effects
- [ ] `allowed-tools` set if specific tools needed
- [ ] References one level deep, properly linked
- [ ] Examples are concrete, not abstract
- [ ] Tested with real usage
- [ ] `ai-setup-skill-inventory --check` passes

## Anti-Patterns to Avoid

- **XML tags in body** - Use standard markdown headings
- **Vague descriptions** - Be specific with trigger keywords
- **Deep nesting** - Keep references one level from SKILL.md
- **Missing invocation control** - Side-effect workflows need `disable-model-invocation: true`
- **Too many options** - Provide a default with escape hatch
- **Missing required frontmatter** - Always include `input`, `output`, `category`
- **Guessing input/output** - Derive from the skill's actual behavior, not assumptions

## Reference Files

For detailed guidance, see:
- [official-spec.md](references/official-spec.md) - Official skill specification
- [best-practices.md](references/best-practices.md) - Skill authoring best practices

## Sources

- Existing skills in `opencode/skills/` — canonical examples of the format
- `AGENTS.md` — required frontmatter fields and category taxonomy
- `ai-setup-skill-inventory` — validation tooling
