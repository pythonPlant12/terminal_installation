# Sequential Pipelines Over LLM Routing

**Status**: AUTHORITATIVE for pipeline step ordering across GSD and OmO surfaces

**Last Updated**: 2026-03-08

**Implements**: Practice 2 from `agentic-pipeline-reliability.md`

---

## Scope

This rule applies when **designing, executing, or reviewing** any multi-step workflow in this repo. It covers GSD command workflows, OmO agent orchestration, bootstrap phases, and skill-driven pipelines.

---

## Rule

Use deterministic, ordered steps for known workflows. Reserve LLM-driven routing ONLY for novel/adaptive decisions where the path cannot be pre-determined.

---

## Canonical Sequences

### GSD Command Surface

```
discuss → plan → execute → verify → capture
```

| Step | Command | Precondition |
|------|---------|--------------|
| `discuss` | `/gsd-discuss-phase` | Phase number exists in ROADMAP |
| `plan` | `/gsd-plan-phase` | Discuss step completed (or `--skip-discuss`) |
| `execute` | `/gsd-execute-phase` | Plan exists with all tasks defined and critic approval has passed |
| `verify` | `/gsd-verify-work` or `/do:verify` | Execute step completed |
| `capture` | `/do:compound` | Verify step passed |

### OmO Agent Surface

```
Prometheus (plan) → Atlas (execute) → Momus (verify) → compound (capture)
```

| Step | Agent | Precondition |
|------|-------|--------------|
| `plan` | Prometheus | Task/goal defined |
| `execute` | Atlas / Hephaestus | Plan exists in `.sisyphus/plans/` and critic approval has passed |
| `verify` | Momus / do-verify skill | Execution completed |
| `capture` | `/do:compound` | Verification passed |

### Combined (GSD orchestrating OmO)

```
GSD(discuss) → [GSD(plan) or Prometheus(plan)] → Atlas(execute) → [gsd-verify-work and/or do-verify] → do:compound
```

The handoff contract: GSD discuss produces durable lifecycle context in `.planning/` → exactly one plan authority is chosen for the next stage → a separate critic approves the plan → Atlas executes the selected plan → verification runs on a separate surface before capture.

**Single-authority rule:**

- `.planning/*` owns lifecycle scope, requirements, and roadmap state.
- `.sisyphus/plans/*` may project that state into an OmO execution plan.
- Never keep two competing plan artifacts as independent authorities.

### Bootstrap Surface

```
Phase 01 → 02 → ... → 11 (numbered, explicit order)
```

Already correctly implemented. Each phase has a number; `scripts/bootstrap.zsh` sources them in order.

---

## Precondition Enforcement

Before starting any step, verify its precondition is met:

1. **Check marker** (Practice 1): Has the previous step's marker been written?
2. **Check artifact**: Does the expected input artifact exist? (e.g., plan file for execute step)
3. **Check critic approval**: Has the required plan critic step passed before execution begins?
4. **Fail fast**: If precondition is not met, report which step must complete first.

```zsh
# Example: execute requires plan
if ! step_done "gsd" "plan" "$phase"; then
  die "Cannot execute phase $phase: planning step not complete. Run /gsd-plan-phase $phase first."
fi

if ! step_done "gsd" "critic" "$phase"; then
  die "Cannot execute phase $phase: plan critic step not complete. Run the required plan review first."
fi
```

---

## Dual-Plan Prohibition

If a GSD phase plan exists and Prometheus produces an OmO plan, the OmO plan must reference the upstream `.planning/*` artifact it was derived from.

Allowed:

- GSD discuss/context in `.planning/` + OmO execution plan in `.sisyphus/plans/`
- GSD-only lifecycle where execution stays within `/gsd-*`
- OmO-only execution where `.planning/*` is absent

Not allowed:

- Maintaining divergent GSD and OmO plans as separate authorities
- Skipping the handoff artifact and relying on chat context alone

---

## When LLM Routing Is Acceptable

LLM-driven step selection is acceptable ONLY when:

1. The workflow is genuinely novel (no established sequence exists)
2. The decision requires understanding content that cannot be pre-classified
3. The routing decision is logged for audit

Even in these cases, the LLM should select from a **finite set of pre-defined next steps**, not invent arbitrary actions.

---

## Anti-Patterns

- ❌ "Figure out what to do next based on the output" — replace with explicit conditional branches
- ❌ Letting the LLM skip steps because "it seems unnecessary"
- ❌ Running verify before execute completes
- ❌ Running capture before verify passes
- ❌ Allowing parallel execution of sequential steps (plan and execute simultaneously)

---

## Handoff Contract

When transitioning between surfaces (GSD → OmO or vice versa), the handoff must include:

1. **Source**: Which surface/step produced this output
2. **Artifact**: Path to the output artifact (plan file, verification report, etc.)
3. **Next step**: Which surface/step should consume this artifact
4. **Preconditions met**: Confirmation that all preconditions for the next step are satisfied
