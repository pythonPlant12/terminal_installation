---
description: "Audit and improve AGENTS.md / CLAUDE.md / OpenCode agent configuration for any project. Use --interview for guided setup."
---

# Audit Agent Configuration

Analyze and improve the agent configuration for this project.

## Arguments

<args> $ARGUMENTS </args>

## Mode Selection

If args contain `--interview`:
→ Run the smart interview flow from the `agents-md-architect` skill's interview.md

Otherwise:
→ Run the automated audit workflow below.

## Automated Audit Workflow

Load the `agents-md-architect` skill for the complete framework, templates, and evaluation criteria.

### Phase 1: Discovery

Scan the project for all existing agent config files:
- AGENTS.md, CLAUDE.md, .claude/CLAUDE.md, .cursorrules, .cursor/rules/, .github/copilot-instructions.md
- opencode/opencode.jsonc, opencode/rules/, opencode/agents/, opencode/skills/
- .windsurfrules, .gemini

Also detect: language/framework, test runner, build system, risk profile, directory structure.

Present a discovery summary.

### Phase 2: Assessment

Evaluate each existing config against the 8-section framework from the skill:
1. Identity
2. Project Overview
3. Commands
4. Architecture & Conventions
5. Quality Gates
6. Boundaries
7. Navigation (retrieval index)
8. Uncertainty Protocol

Plus structural assessment: source-of-truth hierarchy, escalation path, file size, staleness.

Score each section: Strong (3) / Weak (2) / Missing (1) / N/A (0).

### Phase 3: Gap Analysis

Produce a prioritized report:
- Overall score (X/24)
- What's working well (with evidence)
- Critical gaps (high-weight, high-risk)
- Recommended improvements
- Nice-to-have optimizations

Ask the user which gaps to address.

### Phase 4: Recommendations

For each selected gap, propose exact content to add:
- Show the content as a diff or new section
- Explain why it helps (cite framework evidence)
- Note which file it goes in
- Flag content that should move OUT of root into rules/skills/

### Phase 5: Generation

After user approval, write the files:
- Show diff for existing files, full content for new files
- Confirm before each write
- Run post-generation checklist:
  - [ ] Root file under 200 lines
  - [ ] Quality gates include runnable commands
  - [ ] Navigation points to real files
  - [ ] No secrets in committed files
  - [ ] Source-of-truth hierarchy documented (if multiple configs)