# Agent Config Templates

Ready-to-adapt templates for each supported format. Fill in `[placeholders]` with project-specific details.

## AGENTS.md — Universal Template

```markdown
# AGENTS.md

## Agent Identity

You are [role description — e.g., "a full-stack engineer working on a Next.js SaaS app"].
[Goal — e.g., "Prioritize type safety, test coverage, and user experience."]
[Operating principles — 2-3 bullets about how to handle uncertainty, prioritize work, etc.]

IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for all tasks in this repo. Read actual source files rather than relying on assumptions.

## Project Overview

[One paragraph: what the project is, what it does, and why it exists.]

- **Language**: [e.g., TypeScript 5.x]
- **Framework**: [e.g., Next.js 16 with App Router]
- **Package manager**: [e.g., pnpm]
- **Runtime**: [e.g., Node.js 22+]
- **Database**: [e.g., PostgreSQL via Drizzle ORM]

## Commands

- `[dev command]` — Start dev server
- `[build command]` — Production build
- `[test all command]` — Run all tests
- `[test single command] -- [path]` — Run a single test file
- `[lint command]` — Lint check
- `[format command]` — Format code
- `[migrate command]` — Run database migrations (if applicable)

## Architecture & Conventions

### Directory Structure
- `[src/app/]` — [purpose]
- `[src/components/]` — [purpose]
- `[src/lib/]` — [purpose]
- `[src/server/]` — [purpose]

### Naming Conventions
- [Files: e.g., "PascalCase for components, camelCase for utilities"]
- [Functions: e.g., "camelCase, prefix handlers with `handle`"]
- [Types: e.g., "PascalCase, suffix props with `Props`"]

### Key Patterns
- [Pattern 1: e.g., "Use server actions for mutations, not API routes"]
- [Pattern 2: e.g., "Named exports only, no default exports"]
- [Pattern 3: e.g., "All DB queries through src/server/db/"]

## Quality Gates (MANDATORY after changes)

- [Type of change] → `[command]` must [pass criteria]
- [Type of change] → `[command]` must [pass criteria]
- [Type of change] → `[command]` must [pass criteria]
- Any code change → `[test command]` must pass (new failures = your bug)

## Boundaries

### Hard Blocks (NEVER do)
- [e.g., "NEVER modify migration files after they've been committed"]
- [e.g., "NEVER add dependencies without asking first"]
- [e.g., "NEVER suppress type errors with `as any` or `@ts-ignore`"]
- [e.g., "NEVER read or output contents of .env files"]

### Soft Blocks (ASK first)
- [e.g., "ASK before refactoring code unrelated to current task"]
- [e.g., "ASK before changing public API interfaces"]

## Navigation

When you need to understand:
- [Topic 1] → read `[file path]`
- [Topic 2] → read `[file path]`
- [Topic 3] → read `[file path]`
- [Topic 4] → read `[file path]`
- [API docs / framework docs] → read `[docs/ path or external link]`

## Uncertainty Protocol

- **Safe to assume:** [e.g., "dev server runs on localhost:3000", "tests use Vitest"]
- **NEVER assume:** [e.g., "database state", "auth status", "env variable values"]
- **When unsure:** [e.g., "Read the source file first. If still unclear, ask."]
- **Label uncertainty:** [e.g., "State what you believe and what you haven't verified"]

## Source-of-Truth Hierarchy

When files conflict:
1. [Most authoritative] — overrides all below
2. [Second] — overrides below
3. [Third] — general guidance
```

---

## CLAUDE.md — Claude Code Template

```markdown
# CLAUDE.md

## Identity
You are [role]. [Goal in one sentence.]
[2-3 operating principles as bullets.]

## Commands
- `[dev]` — Start dev server
- `[build]` — Production build
- `[test]` — Run all tests
- `[test single]` — Run single test
- `[lint]` — Lint

## Conventions
- [Key convention 1]
- [Key convention 2]
- [Key convention 3]

## Rules
- NEVER [hard block 1]
- NEVER [hard block 2]
- NEVER [hard block 3]
- Always [positive rule 1]
- Always [positive rule 2]

## Navigation
- [Topic]: @[path/to/file.md]
- [Topic]: @[path/to/file.md]
- Rules: @rules/
- Quality checks: @rules/quality.md
- Boundaries: @rules/boundaries.md
```

**Companion files for CLAUDE.md projects:**
```
project/
├── CLAUDE.md              # Compact: identity + commands + conventions + navigation
├── .claude/
│   └── CLAUDE.local.md    # Machine-specific overrides (never committed)
├── rules/
│   ├── quality.md         # Quality gates and verification criteria
│   └── boundaries.md      # Detailed boundary rules
└── context/
    ├── architecture.md    # Detailed architecture docs
    └── glossary.md        # Domain-specific terminology
```

---

## OpenCode — Rules Template

For OpenCode projects, agent config is split across multiple surfaces:

**AGENTS.md** (project root) — same as universal template above.

**opencode/rules/[topic].md** — for policy content that should always load:

```markdown
# [Topic] Rules

**Status**: [AUTHORITATIVE / STANDARD]
**Last Updated**: [date]

---

## Core Rules

1. [Rule with specific, verifiable criteria]
2. [Rule with specific, verifiable criteria]
3. [Rule with specific, verifiable criteria]

## Rationale

[Why these rules exist — what problems they prevent]

## Enforcement

- [How to verify compliance]
- [What to do on violation]
```

---

## Escalation Path Template

Add this to any format when the project has ongoing AI-assisted development:

```markdown
## When to Codify vs. Fix Inline

- Same mistake 3+ times → add a rule to [rules location]
- Same multi-step procedure 3+ times → propose a new skill in [skills location]
- One-off learning → capture in knowledge/ai/ or commit message
- Cross-project pattern → propose addition to shared agent config template
```

---

## Compression Template (for large doc indexes)

When referencing >10KB of documentation, use pipe-delimited format:

```markdown
## Documentation Index

[Docs Index]|root: ./docs

|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning

|01-getting-started:{installation.md,quickstart.md,first-project.md}
|02-architecture:{overview.md,patterns.md,data-model.md}
|03-api:{rest-endpoints.md,graphql-schema.md,authentication.md}
|04-deployment:{docker.md,kubernetes.md,ci-cd.md}
```

This gives agents a roadmap of available docs without loading full content. They read specific files on demand. Vercel demonstrated this approach maintains 100% task accuracy while reducing context from 40KB to 8KB.
