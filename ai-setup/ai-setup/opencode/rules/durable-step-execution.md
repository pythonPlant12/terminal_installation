# Durable Step Execution

**Status**: AUTHORITATIVE for pipeline step durability across GSD and OmO surfaces

**Last Updated**: 2026-03-08

**Implements**: Practice 1 from `agentic-pipeline-reliability.md`

---

## Scope

This rule applies when **designing, executing, or reviewing** any multi-step pipeline in this repo — including GSD command workflows (`plan-phase`, `execute-phase`, `quick`), OmO agent orchestration (Prometheus, Atlas, Hephaestus, Momus), bootstrap phases, and skill-driven pipelines.

---

## Rule

Every multi-step pipeline MUST be restartable from the last completed step, not from scratch. Steps record completion via marker files in `.state/`. A step that finds its marker present MUST skip gracefully.

---

## Marker Convention

### Directory

All markers live in `${ROOT_DIR}/.state/` (git-ignored, machine-local).

### Naming

```
{surface}-{step}-{id}.done
```

| Component | Values | Examples |
|-----------|--------|----------|
| `surface` | `gsd`, `omo`, `bootstrap`, `verify` | — |
| `step` | Step name or phase number | `plan`, `execute`, `verify`, `phase-07` |
| `id` | Unique identifier for this run | Branch name, phase name, timestamp | 

Examples:
- `gsd-plan-feature-auth.done`
- `omo-execute-wave-1.done`
- `bootstrap-phase-07.done`
- `verify-syntax-main.done`

### Lifecycle

1. **Check**: Before starting a step, check for the marker. If present, skip with `ok` message.
2. **Execute**: Run the step's work.
3. **Gate**: Run the step's verification gate (see Practice 3). Only proceed if gate passes.
4. **Mark**: Write the marker file AFTER the gate passes. Never before.
5. **Clear**: Markers are cleared when a new pipeline run starts with `--fresh`, or manually via `clear_markers()`.

**Critical**: Markers are written AFTER gates pass, never before. A step that fails its gate must NOT leave a marker.

---

## Shell Helpers

Use the shared functions from `scripts/lib.zsh`:

```zsh
# Check if step is already done
if step_done "gsd" "plan" "feature-auth"; then
  ok "Plan step already done, skipping"
  return 0
fi

# ... do the work ...
# ... run verification gate ...

# Mark step as complete (only after gate passes)
mark_done "gsd" "plan" "feature-auth"
```

```zsh
# Clear all markers for a surface (e.g., starting fresh)
clear_markers "gsd"

# Clear all markers (full reset)
clear_markers
```

---

## Durable Artifacts vs Machine-Local Markers

Practice 1 uses two different persistence layers:

- `.planning/*` — durable GSD lifecycle artifacts (discuss output, phase plans, verification notes).
- `.sisyphus/plans/*` — durable OmO execution plans when Atlas and Hephaestus are driving execution.
- `.state/*.done` — machine-local step markers used to resume known workflow stages.

Do not confuse these layers:

- Plans and context files are the human-readable workflow artifacts.
- Markers only record that a stage completed after its gate passed.
- OmO working memory (`.sisyphus/notepads/*`, `.sisyphus/evidence/*`) remains transient unless promoted elsewhere.

If a workflow uses `.sisyphus/plans/*`, that directory must stay trackable so the execution plan survives session resets and code review.

---

## GSD Surface

GSD commands MUST use markers for:
- Phase planning completion (`gsd-plan-{phase}.done`)
- Phase execution completion (`gsd-execute-{phase}.done`)
- Verification completion (`gsd-verify-{phase}.done`)

On `--fresh` or explicit reset, clear the surface's markers.

## OmO Surface

OmO agents (via `task()` dispatch) MUST use markers for:
- Wave completion in parallel execution (`omo-wave-{n}-{plan}.done`)
- Plan completion (`omo-plan-{plan-name}.done`)

Agents check markers via the shell helpers called from `Bash` tool invocations.

## Bootstrap Surface

Bootstrap phases already embody this pattern. The shared helpers formalize it:
- Each phase checks `step_done "bootstrap" "phase-{NN}" "{phase-name}"`
- Each phase marks `mark_done "bootstrap" "phase-{NN}" "{phase-name}"` on success

---

## Anti-Patterns

- ❌ Writing marker before running verification gate
- ❌ Using in-memory state instead of file markers (lost on context reset)
- ❌ Hardcoding marker paths instead of using `step_done`/`mark_done`
- ❌ Never clearing markers (stale markers block re-execution)
- ❌ Storing markers in git-tracked directories

---

## Stale Marker Recovery

If a pipeline is stuck because of a stale marker:

1. Identify the stale marker: `ls -la .state/`
2. Remove it: `rm .state/{surface}-{step}-{id}.done`
3. Or clear the surface: `clear_markers "{surface}"`
4. Rerun the pipeline

The `ai-setup-doctor` health check SHOULD warn about markers older than 24 hours.
