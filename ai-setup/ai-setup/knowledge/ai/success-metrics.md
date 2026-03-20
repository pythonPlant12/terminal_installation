# Consolidation Success Metrics (gsd-omo-consolidation)

This document defines measurable success criteria for the gsd-omo-consolidation knowledge migration.
It is an audit record. Metrics are based on checked-in evidence files and repo measurements.

## Evidence Sources

- `.sisyphus/evidence/task-1-reference-inventory.txt` (baseline inventory)
- `.sisyphus/evidence/task-4-stale-refs-check.txt` (post-migration hygiene check)
- `.sisyphus/notepads/gsd-omo-consolidation/learnings.md` (task-by-task change log)
- `knowledge/ai/README.md` (knowledge directory contract)

## Knowledge Migration Metrics

| Metric | Baseline (before) | Current (measured) | Target (after) | How to measure |
|---|---:|---:|---:|---|
| Solution docs present in canonical location | 7 solution docs existed (Task 1 notes) | 7 files under `knowledge/ai/solutions/**/*.md` | 7 (no loss) | Count files under `knowledge/ai/solutions/` |
| Analysis meta-docs relocated to analysis area | 1 file existed in `docs/analysis/` (Task 1 notes) | 3 files under `docs/analysis/*.md` | 3 (1 prior + 2 moved) | Count files under `docs/analysis/` |
| Reference update scope captured | 42 references inventoried | 42 references updated across 8 files (Task 4 notes) | All inventoried references updated | Compare inventory lines to Task 4 notes |
| Stale legacy references in repo | Not measured pre-migration | 0 stale references (evidence file) | 0 | Run a repo-wide search for the legacy solutions path substring |

Notes:
- The baseline reference inventory is 42 lines of grep output.
- The post-migration stale check is a dedicated evidence artifact.

## Compound Worthiness Gate Metrics

These metrics confirm the system makes it easy to capture high-impact learnings, and hard to pollute durable knowledge with trivial fixes.

| Metric | Baseline (before) | Current (measured) | Target (after) | How to measure |
|---|---|---|---|---|
| Gate documented: when to write knowledge | Not measured pre-migration | Present in `knowledge/ai/README.md` | Yes | Verify `knowledge/ai/README.md` has explicit "When to Write" and "When NOT to Write" sections |
| High-impact language included | Not measured pre-migration | Present in `knowledge/ai/README.md` ("High-impact learnings only") | Yes | Confirm the README includes high-impact and exclusion criteria |
| Post-close compound capture enforced in workflow rules | Not measured pre-Task 6 | 3 rule files contain "Compound Capture After Task Close" | 3 | `grep` for the section header in `opencode/rules/` |
| Destination spelled out for compound outputs | Not measured pre-Task 6 | Destination path referenced as `knowledge/ai/solutions/` in the clause (Task 6 notes) | Yes | Verify the clause text includes the destination path |
| Trivial fixes explicitly excluded from capture | Not measured pre-Task 6 | Explicitly stated in the clause (Task 6 notes) | Yes | Verify the clause states trivial fixes are skipped |

## Reference Hygiene Metrics

| Metric | Baseline (before) | Current (measured) | Target (after) | How to measure |
|---|---:|---:|---:|---|
| Legacy path references that required migration | 42 references inventoried | 0 stale references (evidence file) | 0 stale | Use the stale-ref check evidence, plus repo-wide search for the legacy substring |
| Canonical knowledge directory referenced in top-level docs | Not measured pre-Task 7 | `README.md`: 2 matches for `knowledge/ai` | >= 1 | `grep -c "\\bknowledge/ai\\b" README.md` |
| Canonical knowledge directory referenced in agent navigation | Not measured pre-Task 7 | `AGENTS.md`: 2 matches for `knowledge/ai` | >= 1 | `grep -c "\\bknowledge/ai\\b" AGENTS.md` |

## Workflow Coherence Metrics

| Metric | Baseline (before) | Current (measured) | Target (after) | How to measure |
|---|---|---|---|---|
| 3-layer model documented (Operate, Execute, Capture) | Not measured pre-Task 7 | Present in `README.md` (Task 7 notes) | Yes | Verify `README.md` includes the 3-layer table |
| Knowledge hierarchy policy rule exists | Not measured pre-Task 2 | `opencode/rules/knowledge-hierarchy.md` created (Task 2 notes) | Yes | Confirm file exists and describes tier priority |
| AGENTS navigation updated for knowledge tier guidance | Not measured pre-Task 7 | Updated (Task 7 notes) | Yes | Confirm AGENTS navigation points to the knowledge hierarchy rule |

## Current Status Snapshot (from evidence)

- Baseline inventory: 42 references (evidence file)
- Post-migration stale reference check: 0 stale references (evidence file)
- Canonical solution docs: 7 files in `knowledge/ai/solutions/` (repo measurement)
