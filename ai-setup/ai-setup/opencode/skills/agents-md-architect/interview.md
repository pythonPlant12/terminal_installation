# Smart Interview Questions

Guided interview for generating agent config from scratch. Questions are grouped by phase with skip logic to avoid asking what's already known.

## Interview Design Principles

1. **Ask one question at a time** — never batch multiple questions
2. **Prefer multiple choice** when natural options exist
3. **Smart filtering** — skip questions answered by existing config or project detection
4. **Accept "skip" and "not decided"** without pushing
5. **Summarize after each phase** — let user course-correct early
6. **Exit early** — "is this enough to generate?" after each phase

## Pre-Interview: Auto-Detection

Before asking anything, detect what you can automatically:

```
Detectable from project files:
- Language/framework → package.json, Gemfile, pyproject.toml, go.mod, Cargo.toml
- Commands → package.json scripts, Makefile, Taskfile, justfile
- Directory structure → ls/tree
- Test framework → test config files, test directories
- Linter/formatter → .eslintrc, .prettierrc, pyproject.toml, .rubocop.yml
- CI/CD → .github/workflows/, .gitlab-ci.yml, Jenkinsfile
- Risk signals → .env.example, credentials helpers, infra/ directory
```

**Skip rule:** If a question is fully answered by auto-detection, skip it and note what was detected. Ask for confirmation only if detection is ambiguous.

---

## Phase 1: Quick Context (5 questions, ~2 min)

**Purpose:** Establish identity, purpose, and risk profile. Almost never skippable.

### Q1: Project Purpose
```
"What does this project do, in one sentence?"
```
- Skip if: README.md first paragraph is clear and user confirms it
- Maps to: Section 2 (Project Overview)

### Q2: Agent Role
```
"What role should the AI agent play in this project?"
options:
  - "Full-stack engineer" — writes features, fixes bugs, writes tests
  - "Code reviewer" — reviews PRs, suggests improvements, doesn't write code
  - "DevOps/infra assistant" — manages config, scripts, deployment
  - "Specialized contributor" — works on one area (frontend, backend, data)
```
- Skip if: Identity section already exists in config
- Maps to: Section 1 (Identity)

### Q3: Operating Principles
```
"When making decisions, what should the agent prioritize? Pick your top 3."
options (multiselect):
  - "Safety and reversibility"
  - "Type safety and correctness"
  - "Performance"
  - "Code simplicity and readability"
  - "Test coverage"
  - "User experience"
  - "Minimal changes / surgical edits"
  - "Following existing patterns exactly"
  - "Speed of delivery"
```
- Maps to: Section 1 (Identity — operating principles)

### Q4: Risk Profile
```
"What's the worst thing an agent could accidentally do in this project?"
options:
  - "Break the build" — standard code project, low risk
  - "Corrupt data or state" — database/state management, medium risk
  - "Expose credentials or secrets" — auth/infra, high risk
  - "Break production for users" — deployed service, high risk
  - "Damage local environment" — provisioning/config tool, high risk
```
- Auto-detect clues: .env files, Keychain helpers, deploy scripts, infra/ directory
- Maps to: Section 6 (Boundaries), Section 8 (Uncertainty Protocol) — calibrates depth

### Q5: Team Context
```
"Who else works on this codebase with AI tools?"
options:
  - "Just me"
  - "Small team (2-5)"
  - "Large team (5+)"
  - "Open source / public contributors"
```
- Maps to: Config format choice (personal vs committed), CLAUDE.local.md need

**After Phase 1:** Summarize detected + answered context. Ask: "Continue to working style questions, or is this enough to generate a basic config?"

---

## Phase 2: Working Style (5-8 questions, ~3 min)

**Purpose:** Define quality bar, boundaries, and uncertainty handling.

### Q6: Quality Bar
```
"How thorough should the agent be by default?"
options:
  - "Fast and practical" — ship quickly, fix later
  - "Balanced" — good quality, reasonable speed
  - "Thorough" — comprehensive, well-tested, well-documented
```
- Maps to: Section 5 (Quality Gates) depth

### Q7: Quality Criteria
```
"What makes code 'done' in this project? Select all that apply."
options (multiselect):
  - "Tests pass"
  - "Type checker passes"
  - "Linter passes"
  - "Manual review before merge"
  - "CI pipeline passes"
  - "Documentation updated"
  - "No new warnings"
```
- Skip if: CI config or test config already detected
- Maps to: Section 5 (Quality Gates)

### Q8: Hard Boundaries
```
"What should the agent NEVER do? List your dealbreakers."
```
- Free text — most projects have 3-7 hard blocks
- Seed with detected risks: "I noticed [.env files / deploy scripts / credential helpers]. Should I add 'never read/output secrets' as a boundary?"
- Maps to: Section 6 (Boundaries)

### Q9: Uncertainty Handling
```
"When the agent is unsure about something, what should it do?"
options:
  - "Ask me before proceeding"
  - "Make a best guess and note the assumption"
  - "Depends on the risk" — ask for high-risk, guess for low-risk
```
- Maps to: Section 8 (Uncertainty Protocol)

### Q10: Assumption Rules
```
"Is there anything the agent should NEVER assume without checking first?"
```
- Free text — examples: "database state", "auth status", "external service availability"
- Seed with risk profile: high-risk projects get prompted for more
- Maps to: Section 8 (Uncertainty Protocol)

**After Phase 2:** Summarize. Ask: "Continue to project specifics, or generate now?"

---

## Phase 3: Project Specifics (5-10 questions, ~3 min)

**Purpose:** Architecture, conventions, and navigation. Most can be auto-detected.

### Q11: Directory Map
```
"Here's the directory structure I detected:
[show top-level directories]
Should I use this as the architecture reference, or do you want to describe it differently?"
```
- Heavy auto-detection, light confirmation
- Maps to: Section 4 (Architecture)

### Q12: Naming Conventions
```
"What naming conventions does this project follow?"
options:
  - "Auto-detect from existing code (Recommended)"
  - "Let me describe them"
```
- If auto-detect: scan 5-10 files, infer patterns, confirm
- Maps to: Section 4 (Conventions)

### Q13: Key Patterns
```
"Are there specific patterns or architectural decisions agents should follow?"
```
- Free text — e.g., "use server actions not API routes", "service objects for business logic"
- Maps to: Section 4 (Key Patterns)

### Q14: Navigation Points
```
"When an agent needs to understand a specific area, where should they look?
I'll start with what I detected — add or correct:"
[Auto-generated list of key files/directories]
```
- Maps to: Section 7 (Navigation)

### Q15: Source of Truth
```
"If config files give conflicting instructions, what's the priority order?"
```
- Only ask if multiple config files detected
- Maps to: Source-of-Truth Hierarchy

**After Phase 3:** Summarize. Ask: "Continue to deep dive (skills, escalation), or generate now?"

---

## Phase 4: Deep Dive (optional, 5-15 questions, ~5 min)

**Purpose:** Skills, templates, escalation paths. Only for mature projects or thorough setup.

### Q16: Repeated Tasks
```
"What tasks do you find yourself explaining to the agent repeatedly?"
```
- These become skill candidates
- Maps to: Skill creation recommendations

### Q17: Escalation Path
```
"When the agent learns something new about the project, where should it be captured?"
options:
  - "Add to AGENTS.md directly"
  - "Create a rule file"
  - "Depends on type — I'll set up a system" (generates escalation template)
```
- Maps to: Escalation Path section

### Q18: Config Formats
```
"Which AI tools does your team use?"
options (multiselect):
  - "Claude Code"
  - "OpenCode"
  - "Cursor"
  - "GitHub Copilot"
  - "Other"
```
- Determines which output formats to generate
- Maps to: Multi-format output selection

---

## Post-Interview: Generation

1. Present full summary (8-12 bullets)
2. Propose file structure
3. Show each file's content for review
4. Write files after approval
5. Run post-generation checklist (verify references exist, file sizes OK, no secrets)
