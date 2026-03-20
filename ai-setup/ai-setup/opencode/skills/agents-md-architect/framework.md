# Best-Practices Framework for Agent Configuration

Complete evaluation framework for auditing and generating agent config files (AGENTS.md, CLAUDE.md, OpenCode rules).

## The 8-Section Framework

### Section 1: Identity

**Purpose:** Anchor agent behavior so it stops improvising role and tone.

**What to include:**
- Role definition (1 sentence): What the agent IS in this project
- Goal statement (1 sentence): The outcome the agent optimizes for
- Operating principles (2-5 bullets): How the agent prioritizes and handles ambiguity

**Evaluation criteria:**
- **Strong (3):** All three elements present, specific to this project (not generic)
- **Weak (2):** Role defined but vague, or generic operating principles
- **Missing (1):** No identity section at all

**Examples by project type:**

*Provisioning toolkit:*
> You are maintaining an idempotent macOS provisioning toolkit.
> Prioritize safety, reversibility, and minimal intervention.
> Never modify credentials; never break existing installations on rerun.

*Web application:*
> You are a full-stack engineer on a Next.js SaaS application.
> Prioritize user experience, type safety, and test coverage.
> Default to server components; use client components only for interactivity.

*CLI tool:*
> You are building a developer CLI in Rust.
> Prioritize performance, clear error messages, and backward compatibility.
> Never break existing command interfaces without explicit deprecation.

**When to skip:** Very small scripts or single-file utilities where context is self-evident.

---

### Section 2: Project Overview

**Purpose:** Eliminate stack guesswork on first interaction.

**What to include:**
- One paragraph: what the project is and what it does
- Tech stack: language, framework, major dependencies
- Runtime requirements: Node version, Python version, OS constraints

**Evaluation criteria:**
- **Strong (3):** Specific stack, versions, and purpose in <5 lines
- **Weak (2):** Present but vague ("a web app using JavaScript")
- **Missing (1):** No project overview

**Detection shortcut:** If README.md has a clear first paragraph, reference or adapt it rather than duplicating.

---

### Section 3: Commands

**Purpose:** Prevent agents from guessing or running wrong scripts.

**What to include:**
- Dev server start command
- Build / compile command
- Test command (all tests + single test)
- Lint / format command
- Migration / seed commands (if applicable)
- Deployment command (if safe to reference)

**Evaluation criteria:**
- **Strong (3):** 4+ commands listed, including single-test invocation
- **Weak (2):** Only 1-2 commands, or missing single-test command
- **Missing (1):** No commands section

**Detection shortcut:** Parse `package.json` scripts, `Makefile` targets, `Gemfile` tasks, `pyproject.toml` scripts.

---

### Section 4: Architecture & Conventions

**Purpose:** Make agents follow YOUR patterns, not generic best practices.

**What to include:**
- Directory structure (key directories and their purposes)
- Naming conventions (files, functions, classes, variables)
- Import/export patterns (default vs named, absolute vs relative)
- Key patterns (service objects, form objects, middleware, etc.)
- Testing patterns (where tests live, naming, frameworks)

**Evaluation criteria:**
- **Strong (3):** Directory map + naming rules + 2+ specific patterns
- **Weak (2):** Directory map only, or very generic rules
- **Missing (1):** No architecture section

**Key principle:** Conventions should be observable in the actual codebase. Don't document aspirational conventions — document what actually exists.

---

### Section 5: Quality Gates

**Purpose:** Enable agent self-verification with pass/fail criteria.

**What to include:**
- For each type of change, the command to run and what "pass" looks like
- Mandatory gates (must pass before considering work done)
- Optional gates (nice to have, can note pre-existing failures)

**Format:**
```markdown
## Quality Gates (MANDATORY after changes)
- Shell script edited → `zsh -n <file>` must exit 0
- TypeScript changed → `npm run typecheck` must exit 0
- Any code change → `npm test` must pass (new failures = your bug)
- Config changed → restart dev server and verify no parse errors
```

**Evaluation criteria:**
- **Strong (3):** 3+ gates with specific commands and pass/fail criteria
- **Weak (2):** Mentions testing but no specific commands or criteria
- **Missing (1):** No verification criteria at all

**Why this matters (evidence):** Agents without quality gates ship untested changes 40-60% of the time. With explicit gates, this drops to <10%.

---

### Section 6: Boundaries

**Purpose:** Prevent drift and reduce risk from well-intentioned but harmful actions.

**What to include:**
- Things agents must NEVER do (hard blocks)
- Things agents must ASK about before doing (soft blocks)
- Security boundaries (never read .env, never output tokens, etc.)
- Scope boundaries (never refactor unrelated code during a fix)

**Evaluation criteria:**
- **Strong (3):** 5+ specific boundaries, including security rules
- **Weak (2):** 1-2 generic boundaries
- **Missing (1):** No boundaries section

**Calibrate to risk profile:**
- **Low risk** (static site, docs): 2-3 boundaries sufficient
- **Medium risk** (web app, API): 5-7 boundaries
- **High risk** (infra, credentials, production): 8+ boundaries including explicit security rules

---

### Section 7: Navigation (Retrieval Index)

**Purpose:** Tell agents WHERE to find information instead of hoping they search correctly.

**What to include:**
- "When you need X, read Y" mappings for key knowledge areas
- Pointer to docs/ or context/ for heavy reference material
- Explicit "prefer retrieval-led reasoning" instruction

**Format:**
```markdown
## Navigation
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning.

- Auth flow → read `src/auth/README.md`
- Database schema → read `db/schema.sql`
- API conventions → read `docs/api-guide.md`
- Deployment process → read `docs/deploy.md`
```

**Evaluation criteria:**
- **Strong (3):** 5+ retrieval mappings + explicit retrieval-led instruction
- **Weak (2):** General file references without specific "when you need X" framing
- **Missing (1):** No navigation section

**Evidence (Vercel, Jan 2026):**
- Passive retrieval index → 100% pass rate on Build/Lint/Test
- No retrieval context → 53% baseline
- On-demand skills → 53-79% (agent often doesn't invoke them)

**Compression technique for large docs:**
Use pipe-delimited format for doc indexes over 10KB:
```
[Docs Index]|root: ./docs
|01-getting-started:{installation.md,quickstart.md}
|02-architecture:{overview.md,patterns.md,conventions.md}
```

---

### Section 8: Uncertainty Protocol

**Purpose:** Define how agents handle missing information — critical for high-risk projects.

**What to include:**
- What agents can safely assume without asking
- What agents must NEVER assume (must verify first)
- How to label uncertainty in outputs
- Escalation: when to stop and ask the user

**Evaluation criteria:**
- **Strong (3):** All four elements present, calibrated to project risk
- **Weak (2):** Some guidance but incomplete
- **Missing (1):** No uncertainty handling

**Calibrate to risk profile:**
- **Low risk:** Brief note ("ask if unsure") — score 2 is acceptable
- **Medium risk:** Explicit "never assume" list for key areas
- **High risk:** Comprehensive protocol with verification commands

---

## Structural Assessment (Beyond the 8 Sections)

### Source-of-Truth Hierarchy

When multiple config files exist, document which one wins on conflict.

**Template:**
```markdown
## Source-of-Truth Hierarchy (when files conflict)
1. [Most authoritative file] — overrides everything below
2. [Second file] — overrides below
3. [Third file] — general guidance
```

**Scoring:**
- **Present:** Config files list their priority explicitly
- **Missing:** Multiple config files exist with no stated priority

### Escalation Path

When should a learning become a rule vs. a skill vs. a one-off fix?

**Template:**
```markdown
## When to Codify vs. Fix
- Same mistake 3+ times → add a rule
- Same multi-step procedure 3+ times → create a skill
- One-off learning → document in knowledge/ai/ or commit message
```

### File Size and Modularity

- Root file should be under 200 lines
- Heavy content belongs in rules/, context/, or skills/
- Each rule file should cover one topic
- Reference files from root file, don't inline everything

---

## Scoring Summary

| Score Range | Rating | Meaning |
|-------------|--------|---------|
| 20-24 | Excellent | Comprehensive, specific, well-maintained |
| 15-19 | Good | Solid foundation, minor gaps |
| 10-14 | Fair | Key sections present but vague or incomplete |
| 5-9 | Poor | Major gaps, agents are largely flying blind |
| 0-4 | Critical | Effectively no agent configuration |

## Format-Specific Guidance

### AGENTS.md (Universal)
- Tool-agnostic — works with Cursor, Claude Code, Copilot, OpenCode, Aider, etc.
- Single source of truth when multiple tools are used
- Place in project root
- Standard markdown, no special syntax required

### CLAUDE.md (Claude Code)
- Claude Code-specific hierarchy: `~/.claude/CLAUDE.md` (user) → `./CLAUDE.md` (project) → `.claude/CLAUDE.local.md` (local)
- Local file for machine-specific overrides (never committed)
- Can reference files with @-syntax (e.g., `@docs/architecture.md`)
- Merged with — not replacing — Claude Code's system prompt

### OpenCode Config
- Config in `opencode.jsonc` (models, MCP, permissions, tools)
- Rules in `opencode/rules/*.md` (policy content, always loaded)
- Agents in `opencode/agents/*.md` (subagent definitions)
- Skills in `opencode/skills/*/SKILL.md` (on-demand procedures)
- AGENTS.md still respected as passive context
