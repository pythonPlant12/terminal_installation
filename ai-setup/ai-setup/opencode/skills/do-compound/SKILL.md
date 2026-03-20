---
name: do-compound
description: This skill should be used when capturing a recently solved problem as structured documentation and bridging it into agent-native knowledge. It orchestrates four parallel research subagents and assembles a single knowledge/ai/solutions/ file.
argument-hint: "[context hint | knowledge/ai/solutions/path.md | learned-location path]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
  - Question
input: Recently solved problem context, optional knowledge/ai/solutions path, or learned-location hint
output: Compact v2 solution doc with machine-usable frontmatter and an Agent Card, strict-lint verified and auto-committed
category: documentation
---

# do-compound Skill (v2)

Capture a solved problem as compact, agent-native knowledge.

## Core Output

1. `knowledge/ai/solutions/<category>/<filename>.md` (schema v2)

This skill writes one canonical document per learning and avoids per-step note spam.

## Quality Contract

Every generated doc must satisfy all rules:

1. Frontmatter validates against `schema.yaml` in this directory.
2. `## Agent Card` exists and is concise (4 bullets).
3. `verification_commands` and `evidence_paths` are non-empty and actionable.
4. `problem_type` maps to parent directory via `schema.yaml` `directory_mapping`.
5. Prefer compactness: target <=220 lines; warn when above.

## Worthiness Gate (Mandatory)

Skip documentation when all of these are true:

- The issue is trivial and fixed on first attempt.
- No reusable insight or guardrail emerges.
- Existing knowledge already covers it sufficiently.

Proceed when any of these are true:

- Non-obvious root cause or multi-step debugging.
- New reusable guardrail or prevention check.
- Cross-cutting impact in bootstrap, config, hooks, agents, or workflow.

The gate output must be explicit:

```yaml
worthiness_result:
  decision: proceed|skip
  rationale: <one sentence>
```

If `decision=skip`, return:

`ℹ️ Skipped — no durable learning beyond existing knowledge.`

## Execution Flow

### Phase 1: Parallel Research (Read-only)

Launch 4 subagents in parallel. They return structured text only.

#### Subagent 1 — Context Analyzer

- Extract v2 frontmatter fields from evidence.
- Normalize legacy values using `schema.yaml` `legacy_normalization`.
- Output a complete frontmatter block only.

#### Subagent 2 — Solution Extractor

- Extract: Problem, Root Cause, Solution, Verification, Prevention.
- Keep concise and avoid narrative fluff.
- Output markdown sections only.

#### Subagent 3 — Related Docs Finder

- Find relevant docs under `knowledge/ai/solutions/`.
- Return only valid relative paths that exist.
- Exclude missing links and stale references.

#### Subagent 4 — Retrieval/Compaction Reviewer

- Produce the 4-bullet Agent Card.
- Propose tags, applies_when, avoid_when, verification_commands.
- Flag verbosity risks.

### Phase 2: Assembly and Deduplication

1. Merge subagent outputs.
2. Validate frontmatter against `schema.yaml`.
3. Deduplicate before writing:
   - Search existing docs by `(problem_type, module, root_cause)`.
   - If a close match exists, update the existing note instead of creating a new one.
4. Generate filename format:
   - `[sanitized-symptom]-[module]-[YYYYMMDD].md`
   - lowercase, hyphens, max ~80 chars.
5. Choose category directory via `schema.yaml` `directory_mapping`.
6. Render the document from `assets/resolution-template.md`.

### Phase 3: Strict Lint Gate (BLOCKING)

After writing the doc, run:

```bash
python3 scripts/knowledge-solutions-v2.py lint --path "<doc-path>" --strict
```

**This is a hard gate.** Do NOT proceed to Phase 4 or emit completion output until the lint result shows:

```
errors=0  strict=true
```

If lint reports errors:

1. Read the error messages carefully.
2. Fix the document (frontmatter fields, enum values, directory mapping, missing sections).
3. Rerun the exact same lint command.
4. Repeat until `errors=0`.

Warnings (e.g., line count > 220) are acceptable — only `errors` block progress.

### Phase 4: Auto-Commit

After strict lint passes with `errors=0`:

1. Stage the document:

   ```bash
   git add "<doc-path>"
   ```

2. Commit with a structured message:

   ```bash
   git commit -m "docs: add compound knowledge doc for <topic-summary>"
   ```

   - `<topic-summary>` is a 3–8 word lowercase summary of the problem captured.
   - If the doc was an **update** (dedupe_action=updated), use `docs: update compound knowledge doc for <topic-summary>` instead.

3. Capture the commit hash from the output.

If the commit fails (e.g., nothing to commit, hook rejection), report the error in the completion output instead of the commit hash.

## Completion Output

Return only after Phase 3 lint passes AND Phase 4 commit succeeds:

```text
✓ Knowledge captured (v2)

source_file:    knowledge/ai/solutions/<category>/<filename>.md
schema_version: 2
dedupe_action:  created|updated
lint_result:    errors=0 warnings=<N> strict=true
commit:         <short-hash>
```
