---
name: agents-md-architect
description: Audit, design, and generate AGENTS.md / CLAUDE.md / OpenCode agent configuration for any project. Use when setting up agent context files, improving existing agent configurations, onboarding a brownfield project for AI-assisted development, or reviewing agent config quality. Triggers on "audit agent config", "improve AGENTS.md", "setup CLAUDE.md", "agent configuration", "project agent setup", or when a project lacks proper agent context files.
input: Project directory to audit (defaults to current), or --interview for guided setup
output: Gap analysis report with prioritized recommendations, then generated/updated config files after approval
category: architecture-design
---

# Agent Config Architect

Audit, design, and generate agent configuration files for any project. Supports AGENTS.md (universal), CLAUDE.md (Claude Code), and OpenCode config (rules/ + opencode.jsonc).

This skill encodes best practices from:
- Vercel's eval data (AGENTS.md achieving 100% pass rate vs 53% baseline)
- The CLAUDE.md masterclass framework (Identity, Output, Quality, Boundaries, Navigation)
- Industry patterns from 60,000+ repositories using agent config files

## When to Use

**Use this skill when:**
- Setting up a new project for AI-assisted development
- Improving an existing AGENTS.md or CLAUDE.md that feels ineffective
- Onboarding a brownfield project — agents keep making the same mistakes
- Auditing agent config quality before a team adopts AI tooling
- Migrating between tools (e.g., .cursorrules to AGENTS.md)

**Skip this skill when:**
- The project already has a well-structured, recently-audited config
- You just need to add a single rule (edit the file directly)

## Execution Workflow

### Phase 1: Discovery

Scan the project to find all existing agent configuration:

**Files to detect:**
```
AGENTS.md                    # Universal agent context
CLAUDE.md                    # Claude Code project-level
.claude/CLAUDE.md            # Claude Code alt location
.claude/CLAUDE.local.md      # Claude Code local overrides
.cursorrules                 # Cursor rules
.cursor/rules/*.md           # Cursor rules directory
.github/copilot-instructions.md  # GitHub Copilot
opencode/opencode.jsonc      # OpenCode config
opencode/rules/*.md          # OpenCode rules
opencode/agents/*.md         # OpenCode agent definitions
opencode/skills/*/SKILL.md   # OpenCode skills
.windsurfrules               # Windsurf rules
.gemini                      # Gemini config
```

**Project signals to collect:**
- Primary language/framework (detect from package.json, Gemfile, pyproject.toml, go.mod, Cargo.toml, etc.)
- Test runner and commands (detect from scripts, Makefile, etc.)
- Build system (detect from config files)
- Existing README.md (for project context)
- Directory structure depth and conventions
- CI/CD configuration (for command references)
- Risk profile: Does the project touch credentials, infrastructure, user data, or production systems?

**Output a discovery summary:**
```markdown
## Discovery Summary
- **Project type**: [language/framework]
- **Risk profile**: [low/medium/high] — [reason]
- **Existing agent configs**: [list of found files with line counts]
- **Missing configs**: [list of expected but absent files]
- **Config age**: [last modified dates of existing configs]
```

### Phase 2: Assessment

Evaluate each existing config file against the 8-section best-practice framework. See [framework.md](framework.md) for the complete evaluation criteria.

**The 8 sections to evaluate:**

| # | Section | What It Provides | Weight |
|---|---------|-----------------|--------|
| 1 | Identity | Role, goal, operating principles | Medium |
| 2 | Project Overview | Stack, purpose, one-paragraph context | High |
| 3 | Commands | Build, test, lint, dev commands | High |
| 4 | Architecture & Conventions | Code organization, naming, patterns | High |
| 5 | Quality Gates | Pass/fail verification criteria | High |
| 6 | Boundaries | What agents must NOT do | Medium |
| 7 | Navigation | "When you need X, read Y" retrieval index | High |
| 8 | Uncertainty Protocol | What to never assume, how to handle unknowns | Medium-High (scales with risk) |

**Plus structural assessment:**
- Source-of-truth hierarchy (when files conflict, what wins?)
- Escalation path (when does a learning become a rule vs. skill?)
- File size and bloat (>200 lines in root file = likely needs splitting)
- Staleness signals (references to deprecated tools, old patterns)

**Score each section:**
- **Strong** (3): Present, specific, actionable
- **Weak** (2): Present but vague or incomplete
- **Missing** (1): Not present at all
- **N/A** (0): Not applicable for this project type

### Phase 3: Gap Analysis

Produce a prioritized gap report. Use AskUserQuestion to confirm priorities before proceeding.

**Report structure:**
```markdown
## Agent Config Audit Report

### Overall Score: [X/24] — [Poor/Fair/Good/Excellent]

### What's Working Well
- [List strengths with specific evidence]

### Critical Gaps (fix first)
- [Missing/weak sections with HIGH weight and HIGH risk impact]
- For each: what's missing, why it matters, effort to fix

### Recommended Improvements (fix next)
- [Missing/weak sections with MEDIUM weight]
- For each: what's missing, why it matters, effort to fix

### Nice-to-Have
- [Low-weight improvements, structural optimizations]

### Format-Specific Notes
- [AGENTS.md]: [recommendations]
- [CLAUDE.md]: [recommendations if applicable]
- [OpenCode]: [recommendations if applicable]

### Source-of-Truth Hierarchy
- [Proposed or assessed hierarchy]
```

Ask: "Here's the audit report. Which gaps would you like me to address? I can generate the changes for your review."

### Phase 4: Recommendations

For each gap the user wants addressed, propose specific content:

**For each recommendation:**
1. Show the exact content to add (as a diff or new section)
2. Explain why it helps (cite framework evidence)
3. Note where it goes (which file, which section)
4. Flag any content that should move OUT of the root file into rules/skills/

**Key principles for generated content:**
- Keep root file (AGENTS.md/CLAUDE.md) compact — under 200 lines
- Offload heavy content to rules/, context/, or skills/ directories
- Be specific to THIS project (not generic advice)
- Include the "prefer retrieval-led reasoning" instruction
- Match the project's existing tone and style
- Never include credentials, secrets, or environment-specific paths in committed files

### Phase 5: Generation

After user approval, write the files. For each file:

1. If file exists: show a diff of changes, ask for confirmation
2. If file is new: show full content, ask for confirmation
3. Write the file
4. Verify the file is syntactically valid (YAML frontmatter, markdown structure)

**For OpenCode projects, also consider:**
- Whether new rules/ files are needed
- Whether opencode.jsonc needs config changes
- Whether existing agents/ or skills/ need updates

**Post-generation checklist:**
- [ ] Root agent config file updated/created
- [ ] Source-of-truth hierarchy documented
- [ ] Quality gates include at least one runnable command
- [ ] Navigation section points to real files that exist
- [ ] No secrets or machine-specific paths in committed files
- [ ] File is under 200 lines (or split plan documented)

## Interview Mode (--interview)

When invoked with --interview, run a guided interview instead of automated audit.

**Smart filtering rules:**
- Skip questions already answered by existing config files
- Skip output/delivery format questions for code-only projects
- Skip audience questions for internal tooling
- Group related questions to reduce fatigue
- Accept "skip" or "not decided" without pushing

See [interview.md](interview.md) for the complete question bank and skip logic.

**Interview phases:**
1. **Quick context** (5 questions) — Identity, purpose, stack, risk, team size
2. **Working style** (5-8 questions) — Quality bar, boundaries, uncertainty handling
3. **Project specifics** (5-10 questions) — Commands, architecture, conventions
4. **Deep dive** (optional, 5-15 questions) — Skills, templates, escalation paths

After each phase, summarize findings and ask: "Continue to the next phase, or is this enough to generate?"

## Multi-Format Output

When generating, detect which formats are needed:

**AGENTS.md (universal):**
- Always generate. This is the tool-agnostic standard.
- Include all 8 framework sections applicable to the project.
- See [templates.md](templates.md) for the base template.

**CLAUDE.md (Claude Code):**
- Generate if the project uses Claude Code (detect from .claude/ directory or user request).
- Follows Claude Code's 3-level hierarchy: project → user → local.
- Project-level CLAUDE.md should import from rules/ and context/ via references.

**OpenCode config:**
- Generate if opencode.jsonc exists or user requests it.
- Create rules/ files for policy content.
- Reference existing agents/ and skills/ where applicable.

## Anti-Patterns to Detect and Fix

| Anti-Pattern | Detection Signal | Fix |
|---|---|---|
| **Too vague** | "Use best practices", "Follow conventions" | Replace with specific, named conventions |
| **Too long** | Root file >200 lines | Split into rules/, context/, skills/ |
| **Stale references** | Commands or paths that don't exist | Verify all referenced files/commands exist |
| **Missing commands** | No build/test/lint commands listed | Detect from package.json, Makefile, etc. |
| **No quality gates** | No verification criteria | Add pass/fail criteria tied to real commands |
| **Assumed context** | No uncertainty protocol in high-risk project | Add explicit "never assume" rules |
| **Duplicate configs** | AGENTS.md + CLAUDE.md + .cursorrules with overlapping content | Consolidate into AGENTS.md as single source of truth |
| **Generic content** | Could apply to any project | Rewrite with project-specific details |
| **Security leak** | Secrets, tokens, or env values in config | Remove and add boundary rule |
| **No hierarchy** | Multiple config files, no stated priority | Add source-of-truth hierarchy |

## Evidence Base

**Vercel eval data (Jan 2026):**
- AGENTS.md (passive context): 100% pass rate across Build/Lint/Test
- Skills (on-demand retrieval): 53-79% pass rate
- Key insight: passive context eliminates the agent's "should I look this up?" decision point
- Compression technique: 40KB docs → 8KB pipe-delimited index, same 100% pass rate

**Framework principles:**
- "Prefer retrieval-led reasoning over pre-training-led reasoning" — one line, measurable impact
- Identity section reduces improvisation by anchoring agent behavior
- Quality gates with pass/fail criteria enable agent self-verification
- Navigation indexes let agents find docs without full context loading
- Uncertainty protocols are critical for high-risk projects (infra, credentials, production)

For the complete framework with scoring criteria, see [framework.md](framework.md).
For templates by format, see [templates.md](templates.md).
For the interview question bank, see [interview.md](interview.md).
