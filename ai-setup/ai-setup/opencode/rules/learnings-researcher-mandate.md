# Institutional Knowledge Retrieval — Mandatory Policy

**Status**: AUTHORITATIVE — always-loaded policy rule

**Last Updated**: 2026-03-07

---

## Rule

**Before starting any of the following tasks, invoke `learnings-researcher` to search `knowledge/ai/solutions/` for relevant past solutions:**

- Implementing a new feature or capability
- Fixing a bug or debugging a problem
- Performing root cause analysis
- Planning a phase or designing an approach for a known-problem domain

This is non-negotiable. The `learnings-researcher` agent is fast (< 30 seconds for typical knowledge bases) and prevents repeated mistakes.

---

## Why This Exists

`knowledge/ai/solutions/` accumulates solutions to non-obvious problems, performance traps, integration gotchas, and workflow issues. Without retrieval, these learnings are invisible — agents repeat the same investigations and make the same mistakes.

---

## How to Invoke

```
Task learnings-researcher(<concise description of the feature, bug, or domain>)
```

Example: Before implementing Stripe payment handling:
```
Task learnings-researcher("Stripe subscription handling in payments module")
```

Example: Before debugging a performance issue:
```
Task learnings-researcher("slow query performance in brief generation")
```

---

## Fallback Guard

If you are about to write implementation code or a root cause analysis and have **not yet invoked `learnings-researcher`** in this session for this task:

1. **Stop.**
2. Invoke `learnings-researcher` now with the relevant keywords.
3. Review results.
4. Proceed only after reviewing results (even if no matches are found — an explicit "no matches" is a valid outcome).

---

## Exemptions

This rule does **not** apply to:

- Pure documentation edits with no implementation impact
- Refactoring that is structurally identical to existing patterns (e.g., renaming)
- Quality gate runs (`/do:verify`, lint, syntax checks)
- Capturing learnings after solving a problem (`/do:compound`)

---

## Reference

- Agent definition: `opencode/agents/learnings-researcher.md`
- Knowledge base: `knowledge/ai/solutions/`
- Integration in `/do:review`: `opencode/command/do:review.md` (lines 118–120)
