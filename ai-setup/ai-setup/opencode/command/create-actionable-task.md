---
name: create-actionable-task
description: Distill a Jira issue, spec doc, or raw description into a concise actionable task file. Use when you need a tight, developer-ready task brief — no padding, no invented requirements, just what matters.
argument-hint: <ISSUE_KEY or file path or description>
tools:
  read: true
  write: true
  question: true
  task: true
disable-model-invocation: true
author: Marc Schaerer <https://github.com/dreamora>
model: openai/gpt-5.3-codex
small_model: github-copilot/claude-haiku-4.5
reasoningEffort: high
textVerbosity: low
---

<skills>
- Load skill `create-actionable-task` for output format, density rules, and quality gate.
- Load skill `jira-rca-intake` when input is a bare Jira key (e.g. `ENG-58`) — use it to fetch Jira context before writing.
</skills>

<input_routing>
Determine input type from `$ARGUMENTS` before any action:

1. **Bare Jira key** (`ENG-NNN`, matches `^[A-Z][A-Z0-9]+-[0-9]+$` with no `.md`):
   - Apply `jira-rca-intake` skill to fetch issue, comments, linked issues, and attachments from Jira.
   - Use the resulting `Jira RCA Intake Pack` as the source for the actionable task.

2. **File path** (`ENG-NNN.md`, `ENG-NNN-*.md`, or any other file path):
   - Read the file directly. Do not fetch from Jira.
   - Use file contents as the source for the actionable task.

3. **Raw description** (anything else):
   - Use the text directly as source.
   - Ask the user for an output filename before writing.
</input_routing>

<codebase_research>
After obtaining source content, spawn parallel subagents to ground the brief in actual repository code.
Each subagent uses model `openai/gpt-5.3-codex`, `reasoningEffort: medium`, `textVerbosity: low`.
Subagents are read-only: tools `read`, `grep`, `glob`, `bash` only — no write, no task.

Spawn all agents simultaneously (`run_in_background: true`) with these scopes:

**Agent 1 — Entry points & affected code**
Prompt: Given the issue description `{SOURCE_SUMMARY}`, find the files and functions most likely involved.

- Grep for identifiers, class names, error strings from the issue.
- Glob for files matching the affected feature area.
- Return: file paths + function/class names + line refs in `(ref: path:line)` format.
- Max 8 refs. Skip test files.

**Agent 2 — Data flow & call chain**
Prompt: Trace the call chain from entry point(s) found in Agent 1 through any middleware, services, or models.

- Read key implementation files. Follow function calls one level deep.
- Return: ordered call chain as `caller → callee (ref: path:line)`. Max 6 hops.

**Agent 3 — Existing tests**
Prompt: Find existing tests that cover the affected area from Agent 1.

- Glob `**/*.test.*`, `**/*.spec.*`, `**/test/**`, `**/tests/**`.
- Return: test file paths + test names + assertions relevant to the issue. Max 6 refs.

**Agent 4 — Related modules & cross-cutting concerns**
Prompt: Identify any config, constants, types, or shared utilities referenced by the affected code from Agent 1.

- Read imports/requires in affected files. Glob for config/constants files.
- Return: file paths + exported symbols relevant to the issue. Max 6 refs.

Collect all four results before proceeding. If an agent returns nothing useful, note it and continue.
Distill findings into a `## Codebase Context` appendix (max 12 lines, all refs in `(ref: path:line)` format).
This appendix is input to the brief — do not paste it verbatim into the output file.
</codebase_research>

<process>
1. Parse `$ARGUMENTS` and apply `<input_routing>` to obtain the source content.
2. Apply `<codebase_research>`: spawn 4 parallel subagents, collect results, build `## Codebase Context`.
3. Apply `create-actionable-task` skill: extract problem, root cause, solution, tests — incorporating codebase refs.
4. Draft all sections, then apply density check — cut every line that fails "would a developer change their implementation?"
5. Apply quality gate (from skill): reject if any section > 8 bullets, total > 45 lines, or sections duplicate each other.
6. Write output file per `<output_naming>` in the skill.
7. Read it back and confirm it is under 45 lines and all sections are present.
</process>
