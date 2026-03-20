---
name: create-actionable-task
description: Distill any input (Jira issue, spec doc, or raw description) into a concise developer-ready task brief (~25-40 lines). Use when producing ENG-NNN-actionable.md files, when a spec is too verbose to act on, or when you need to extract just what matters: problem, cause, solution, tests. Outputs nothing invented — no observability, no rollout plans, no padding.
input: Jira issue key, spec document path, or raw task description
output: Concise developer-ready task brief (25-40 lines) with problem, cause, solution, and tests
category: task-management
---

<objective>
Turn verbose input into a tight, actionable task file a developer can immediately act on.
Target: 25-40 lines total. Every line earns its place.
</objective>

<input_routing>
Determine source type before processing:

1. **Bare Jira key** (`ENG-NNN`, no `.md` suffix):
   - Use `jira-rca-intake` skill to fetch Jira issue, comments, linked issues, and attachments.
   - Use the resulting `Jira RCA Intake Pack` as source.

2. **File path** (`ENG-NNN.md`, `ENG-NNN-*.md`, or any path):
   - Read the file directly. Do not contact Jira.

3. **Raw description**:
   - Use text directly. Ask user for output filename before writing.
     </input_routing>

<density_calibration>

## The test: would a developer change their implementation based on this line?

- YES → keep it
- NO → cut it

## Anti-patterns to eliminate

- Restating the problem as a bullet (already in Problem section)
- "Consider logging..." / "Add telemetry..." when not in source
- Multiple bullets saying the same thing differently
- Aspirational test coverage ("ensure full coverage") vs concrete assertions
- Alternatives/rollout/observability unless explicitly required by source

## Good calibration example (ENG-1917 style)

```
# Problem
`minPlayers`/`maxPlayers` reach the inner iframe via a brittle outer-HTML cache path,
causing inconsistent enforcement on join/leave/disconnect.

# Technical details
- Init data does not carry `minPlayers`/`maxPlayers` directly; runtime reads them from outer HTML at launch.
- No centralized guard evaluates player-count thresholds across join, leave, and disconnect handlers.

# Proposed solution
- Add `minPlayers`/`maxPlayers` to READY payload and internal session config state.
- Retire outer-HTML cache dependency; keep fallback only if backward compat requires it.
- Centralize threshold guard used by all join/leave/disconnect handlers.
- Validate/coerce bounds (`min <= max`, non-negative) on receipt.

# Tests
- READY payload contains correct `minPlayers`/`maxPlayers` from game config.
- Join attempt at `maxPlayers + 1` triggers expected blocked-join path.
- Leave/disconnect below `minPlayers` triggers pause/constrained state.
- Legacy games without explicit config receive safe defaults and continue working.

# Technical notes
- Coordinate with ENG-234 for identical "below min" state-machine expectations.
- TBD: exact default values when config is missing/invalid.
```

</density_calibration>

<format>
Exactly these sections in this order:

# Problem

1-3 sentences. What is broken or missing and why it matters. No bullets.

# Technical details

1-4 bullets. Specific technical cause. File paths where they ground the claim.

# Proposed solution

3-8 bullets. What to change and where. Concrete, not abstract.

# Tests

2-5 bullets. Specific assertions: what scenario, what outcome. Never abstract goals.

# Technical notes (omit if empty)

0-4 bullets. Constraints, open questions, or cross-team dependencies needed before coding starts.
</format>

<process>
1. Apply `<input_routing>` to determine and load source content.
2. Extract the single core problem, specific technical cause, concrete fix, must-have tests.
3. Draft — then apply density check: cut every line that fails "would a developer change their implementation?"
4. Quality gate: no section > 8 bullets, total ≤ 45 lines, no section duplicates another.
5. Write to output file per `<output_naming>`.
6. Read back to confirm file exists, is non-empty, and is under 45 lines.
</process>

<output_naming>

- Bare Jira key `ENG-NNN` → `./<ENG-NNN>-actionable.md`
- File input `ENG-NNN.md` or `ENG-NNN-*.md` → derive key → `./<ENG-NNN>-actionable.md`
- Raw description → ask user for filename
  </output_naming>
