---
schema_version: 2
module: Knowledge Capture System
date: 2026-03-07
problem_type: developer_experience
component: knowledge-system
symptoms:
  - do-compound output expectations lived in prose but not in an enforced schema
  - existing solution notes drifted in field names, section shape, and compactness
  - Agent Card placement and related-doc links were inconsistent across the corpus
  - knowledge cleanup and migration required manual review instead of deterministic tooling
root_cause: integration_contract_drift
resolution_type: tooling_addition
severity: medium
confidence: high
summary: Define a v2 contract and strict linter for do-compound so solution docs stay compact, deduplicated, and machine-readable.
applies_when:
  - You are capturing a new solved problem with do-compound.
  - Legacy solution docs need migration to the current schema.
  - A knowledge note needs strict validation before commit.
  - You suspect an existing note duplicates the same root cause and component.
verification_commands:
  - python3 scripts/knowledge-solutions-v2.py lint --path knowledge/ai/solutions/developer-experience/do-compound-schema-drift-knowledge-capture-system-20260307.md --strict
  - python3 scripts/knowledge-solutions-v2.py lint --strict
evidence_paths:
  - opencode/skills/do-compound/schema.yaml
  - opencode/skills/do-compound/SKILL.md
  - opencode/skills/do-compound/assets/resolution-template.md
  - scripts/knowledge-solutions-v2.py
  - knowledge/ai/solutions/documentation-gaps/current-installation-flow-phase-map-20260226.md
tags:
  - do-compound
  - schema-v2
  - knowledge-capture
  - compact-docs
  - linting
  - deduplication
avoid_when:
  - The fix is trivial and already covered by an existing note.
  - The issue is environment-specific and does not produce a reusable guardrail.
status: active
related_docs:
  - ./skill-inventory-system-opencode-20260301.md
  - ../workflow-issues/autonomy-drift-without-persistent-task-state-development-workflow-20260305.md
---

# Troubleshooting: do-compound schema drift in knowledge capture

## Agent Card

- Use when: New solution notes drift in frontmatter, structure, or compactness.
- Core fix: Enforce schema v2 with `scripts/knowledge-solutions-v2.py` and write notes against the do-compound template.
- Avoid when: The learning is trivial or already covered by a matching note.
- Verify with: `python3 scripts/knowledge-solutions-v2.py lint --path knowledge/ai/solutions/developer-experience/do-compound-schema-drift-knowledge-capture-system-20260307.md --strict`; `python3 scripts/knowledge-solutions-v2.py lint --strict`

## Problem

Before this migration, `do-compound` described the desired output but did not enforce it. The existing solutions corpus had mixed field names, inconsistent `## Agent Card` placement, stale or fragile related links, and at least one note that exceeded the compactness target by a wide margin. That made agent retrieval less predictable and forced manual cleanup when the knowledge contract changed.

## Root Cause

The knowledge system relied on an implicit contract spread across `opencode/skills/do-compound/SKILL.md`, hand-maintained notes, and operator memory. Without a declarative schema plus a linter, the skill, template, migration logic, and stored notes drifted apart without a deterministic way to detect or repair the mismatch.

## Solution

Define the contract in `opencode/skills/do-compound/schema.yaml`, align the skill and template to that contract, and use `scripts/knowledge-solutions-v2.py` to migrate and lint notes.

- `schema.yaml` declares required fields, optional fields, enums, directory mapping, and legacy normalization rules.
- `SKILL.md` now requires a worthiness gate, four read-only research passes, deduplication by `(problem_type, module, root_cause)`, and strict linting before completion.
- `resolution-template.md` places the Agent Card immediately after the H1 so agents can read the fast path first.
- `knowledge-solutions-v2.py migrate` normalizes legacy notes, inserts the Agent Card safely, filters `evidence_paths`, and keeps reruns idempotent.
- `knowledge-solutions-v2.py lint --strict` blocks missing fields, bad enums, directory mismatches, and missing related-doc targets, while still warning when a note exceeds the compactness budget.

```bash
python3 scripts/knowledge-solutions-v2.py migrate --path knowledge/ai/solutions/<category>/<file>.md
python3 scripts/knowledge-solutions-v2.py lint --path knowledge/ai/solutions/<category>/<file>.md --strict
```

## Failed Attempts

- Relying on prose-only guidance in the skill let field names and section layouts drift over time.
- Treating compactness as a soft preference allowed oversized notes to stay in the corpus.
- Allowing loosely filtered evidence references made `evidence_paths` less useful for repo-local retrieval.

## Verification

- `python3 scripts/knowledge-solutions-v2.py lint --path knowledge/ai/solutions/developer-experience/do-compound-schema-drift-knowledge-capture-system-20260307.md --strict` -> confirms this note satisfies schema v2.
- `python3 scripts/knowledge-solutions-v2.py lint --strict` -> confirms the full solutions corpus remains clean after adding the note.

## Prevention

- Always run strict lint before finalizing a new solution note.
- Reuse the schema enums and template instead of copying older notes by hand.
- Search existing notes by `(problem_type, module, root_cause)` before creating a new file.
- Keep the Agent Card directly after the title and keep the note within the compactness budget.

## Related

- `./skill-inventory-system-opencode-20260301.md`
- `../workflow-issues/autonomy-drift-without-persistent-task-state-development-workflow-20260305.md`
