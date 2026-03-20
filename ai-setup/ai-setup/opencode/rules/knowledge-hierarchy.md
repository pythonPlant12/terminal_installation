# Knowledge Hierarchy Policy

**Status**: AUTHORITATIVE for knowledge source-of-truth prioritization

**Last Updated**: 2026-03-08

---

## Source-of-Truth Priority Order

When knowledge sources conflict, resolve by this priority (highest first):

### 1. Code + Tests

Implementation is truth. Files: `scripts/`, `bin/`, `opencode/`, `test/`.

### 2. `.planning/*`

GSD lifecycle authority: project state, requirements, roadmaps, phase context, and verification artifacts.

### 3. `.sisyphus/*`

OmO orchestration state:

- `.sisyphus/plans/*` — durable execution plans
- `.sisyphus/notepads/*` — transient working memory
- `.sisyphus/evidence/*` — transient execution evidence

### 4. `knowledge/ai/*`

Durable AI learnings: patterns, gotchas, architecture.

### 5. `AGENTS.md`

Repository-level guidance: principles, style, boundaries.


---

## Conflict Resolution

When sources disagree: highest-priority source wins. Update lower-priority sources to match (if stale).

If both `.planning/*` and `.sisyphus/plans/*` exist for the same work:

- `.planning/*` owns lifecycle scope and upstream intent.
- `.sisyphus/plans/*` owns the OmO execution projection only.
- `knowledge/ai/*` captures reusable lessons only after the work is complete.

---

## Where to Write Knowledge

| Question | Destination |
|----------|-------------|
| Solved problem / pattern / gotcha? | `knowledge/ai/` |
| Code style / boundaries / principles? | `AGENTS.md` |
| Task-specific discovery (this session)? | `.sisyphus/notepads/` |
| Durable OmO execution plan? | `.sisyphus/plans/` |
| Operational phase state? | `.planning/phases/*/PLAN.md` |
| Bootstrap / runtime behavior? | Source code + tests |

---

## Integrity Rules

- Never commit transient state to `knowledge/ai/`.
- Never duplicate facts across tiers; update the canonical tier.
- Never treat `.sisyphus/notepads/*` or `.sisyphus/evidence/*` as lifecycle source-of-truth.
- Code is always correct; update docs to match code.
