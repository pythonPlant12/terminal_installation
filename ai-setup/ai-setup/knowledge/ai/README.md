# knowledge/ai/

AI-maintained institutional knowledge. Machine-written, human-reviewed.

## Ownership

This directory is written by `/do:compound` and related compound skills.
Do not manually create files here without good reason.

## When to Write

High-impact learnings only:
- Incidents and non-obvious fixes
- Reusable patterns discovered through real work
- Architectural decisions with long-term impact

## When NOT to Write

- Simple typos or obvious fixes
- Transient state or one-off debug sessions
- Information already captured in `AGENTS.md` or `.planning/`

## Directory Structure

- `solutions/` — compound skill outputs (auto-generated)
  - `build-errors/` — build and compilation fixes
  - `developer-experience/` — tooling and workflow improvements
  - `patterns/` — reusable code and architecture patterns
  - `workflow-issues/` — process and workflow fixes

## Relationship to Other State

| Directory | Purpose |
|-----------|---------|
| `.planning/` | Operational project state (GSD exocortex) |
| `.sisyphus/` | Execution state (OmO orchestration) |
| `knowledge/ai/` | Durable AI learnings (this directory) |

See `opencode/rules/knowledge-hierarchy.md` for the full source-of-truth priority order.
