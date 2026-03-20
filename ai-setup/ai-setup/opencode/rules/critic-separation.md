# Separate Critic / Judge Agents

**Status**: AUTHORITATIVE for generator-critic separation across GSD and OmO surfaces

**Last Updated**: 2026-03-08

**Implements**: Practice 4 from `agentic-pipeline-reliability.md`

---

## Scope

This rule applies when **any agent or command generates output that requires quality verification**. This includes code generation, plan creation, architecture decisions, skill/rule authoring, and documentation.

---

## Rule

A generator reviewing its own output is unreliable. Every generated artifact MUST be verified by a separate critic agent or deterministic gate — never by the agent that produced it.

---

## Critic Dispatch Table

| Artifact Type | Generator | Critic | Dispatch Method |
|---------------|-----------|--------|-----------------|
| **Plan** (PLAN.md, architecture) | Prometheus, `/gsd-plan-phase` | Momus or Oracle | `task(subagent_type="momus", ...)` |
| **Execution result** (multi-file change) | Atlas, Hephaestus, `/gsd-execute-phase` | `/do:verify` gate + optional `/do:review` on a green diff | `task(load_skills=["do-verify"], ...)` |
| **Code** (single file) | Any agent | `code-simplicity-reviewer` | `task(subagent_type="momus", ...)` |
| **Skill definition** | `skill-creator` | `skill-curator` | `task(load_skills=["skill-curator"], ...)` |
| **Rule file** | Any agent | Manual review or Momus | `task(subagent_type="momus", ...)` |
| **Shell script** | Any agent | Deterministic gate (`zsh -n` / `bash -n`) | Bash tool directly |
| **Trivial change** (comment, typo) | Any agent | Deterministic gate only | Quality Gates table |

---

## Tiered Critic Approach

### Tier 1: Full Critic (Plans, Architecture, Multi-file Changes)

Dispatch a dedicated critic agent. The critic receives:
- The generated artifact
- The original requirement/goal
- Instructions to evaluate correctness, completeness, and adherence to patterns

```
task(
  subagent_type="momus",
  description="Critic review: plan for phase X",
  prompt="
    ROLE: You are the critic. Review this plan for correctness and completeness.
    ARTIFACT: [path to plan]
    ORIGINAL GOAL: [requirement]
    EVALUATE: correctness, completeness, adherence to repo patterns, risk.
    OUTPUT: PASS/FAIL with specific findings.
    MUST NOT: Modify the artifact. Only evaluate.
  "
)
```

### Tier 2: Light Critic (Single Files, Minor Changes)

Use `code-simplicity-reviewer` or a quick Momus pass:

```
task(
  subagent_type="momus",
  description="Light review: single file change",
  prompt="
    Review this change for correctness and simplicity.
    FILE: [path]
    DIFF: [changes]
    OUTPUT: PASS/FAIL with specific findings.
  "
)
```

### Tier 3: Gate-Only (Trivial, Deterministic)

For changes verifiable by deterministic gates (syntax checks, schema validation), no critic agent is needed. The Quality Gates table in `AGENTS.md` is sufficient.

---

## Critic Availability

### If Critic Agent Is Unavailable

1. **Do NOT skip verification.** Fall back to the next tier:
   - Full critic unavailable → use light critic
   - Light critic unavailable → use deterministic gates + flag for human review
2. **Log the fallback**: Note in the verification report that a lower tier was used.

### Cost Management

- Full critic dispatch (Momus/Oracle) should be reserved for high-impact changes
- Light critic is appropriate for most code changes
- Gate-only is appropriate for syntax/schema-only changes
- When in doubt, use light critic (Tier 2) as the default

---

## Enforcement Points

### GSD Surface

- `/gsd-plan-phase`: After plan generation, dispatch Momus critic before marking plan as complete
- `/gsd-execute-phase`: After execution, run a separate verify surface (`/gsd-verify-work` and/or `/do:verify`) before completion
- `/gsd-verify-work`: This is the behavior critic step — it must be a separate invocation from execute
- `/do:review`: Optional deeper review after behavior is green; never a replacement for verification gates

### OmO Surface

- Prometheus (plans): Momus or Oracle reviews the plan before Atlas executes it
- Atlas/Hephaestus (execution): `/do:verify` is the deterministic judge after execution; `/do:review` can add a deeper critic pass once behavior is green
- Never have Atlas review or approve its own output — always dispatch a separate critic or gate

---

## Anti-Patterns

- ❌ "Review the code you just wrote and fix any issues" — the generator cannot objectively evaluate its own output
- ❌ Skipping critic dispatch because "the change is simple" — use Tier 3 (gate-only) instead of skipping
- ❌ Having the same agent generate and then self-approve in the same turn
- ❌ Using `task()` with the same `session_id` for both generation and review (shared context biases the critic)

---

## Integration with Other Practices

- **Practice 1 (Durable Steps)**: Critic review is a step that gets its own marker (`{surface}-critic-{artifact}.done`)
- **Practice 2 (Sequential Pipelines)**: Critic step comes AFTER generation, BEFORE the next pipeline stage
- **Practice 3 (Hard Gates)**: Critic output must be deterministic PASS/FAIL, not "looks good"
