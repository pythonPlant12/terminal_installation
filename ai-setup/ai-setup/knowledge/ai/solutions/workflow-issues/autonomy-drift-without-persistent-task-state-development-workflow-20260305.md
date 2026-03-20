---
schema_version: 2
module: Development Workflow
date: 2026-03-05
problem_type: workflow_issue
component: development-workflow
symptoms:
  - Autonomous work across many repos drifts when task state lives only in chat context
  - "Completion is declared without deterministic stop criteria in weak-spec, low-test flows"
  - Cross-repo reliability controls are unevenly enforced and hard to reason about end-to-end
root_cause: missing_workflow_step
resolution_type: workflow_improvement
severity: high
confidence: high
summary: "In this session, we needed high-confidence recommendations to improve autonomous execution in a complex 9-repo/submodule environment with sparse requirements and limited test coverage."
applies_when:
  - Autonomous work across many repos drifts when task state lives only in chat context
  - "Completion is declared without deterministic stop criteria in weak-spec, low-test flows"
  - Cross-repo reliability controls are unevenly enforced and hard to reason about end-to-end
verification_commands:
  - ai-setup-doctor --json
evidence_paths:
  - opencode/opencode.jsonc
  - opencode/skills/do-verify/scripts/detect_subrepos.zsh
  - .contract-map/contract-map.json
tags:
  - autonomous-reliability
  - multi-repo
  - submodules
  - task-state
  - completion-gates
status: active
---

# Troubleshooting: Autonomy Drift Without Persistent Task State


## Agent Card

- Use when: Autonomous work across many repos drifts when task state lives only in chat context
- Core fix: In this session, we needed high-confidence recommendations to improve autonomous execution in a complex 9-repo/submodule environment with sparse requirements and limited test coverage. The immediate failure mode ident...
- Avoid when: The failure pattern does not match.
- Verify with: `opencode/skills/do-verify/scripts/detect_subrepos.zsh`

## Problem

In this session, we needed high-confidence recommendations to improve autonomous execution in a complex 9-repo/submodule environment with sparse requirements and limited test coverage. The immediate failure mode identified was not a single code bug, but workflow drift: context-heavy sessions can lose plan continuity and still produce "done" outputs without deterministic completion checks.

## Environment

- Module: Development Workflow
- Affected components: `opencode/opencode.jsonc`, verification skills/hooks, CI workflows, subrepo discovery/verification flow
- Date: 2026-03-05

## Symptoms

- The system has strong local checks, but cross-repo reliability is not uniformly enforced in CI.
- Recursion and subrepo discovery are heuristic (`opencode/skills/do-verify/scripts/detect_subrepos.zsh`), which is brittle at larger graph scale.
- Native todo tooling is disabled while auto-compaction remains enabled (`opencode/opencode.jsonc`), increasing risk of context loss for long-running tasks.
- Session-level recommendations existed, but no persistent execution-state contract guaranteed that autonomous runs stay on track across context churn.

## What Didn't Work

**Attempted approach 1:** Rely on one-pass direct file scans for recommendations.
- **Why it failed:** It was not sufficiently exhaustive for a high-ambiguity, multi-repo reliability question.

**Attempted approach 2:** Treat existing checks as globally sufficient.
- **Why it failed:** Existing checks are strong in places but do not fully close the multi-repo/state-continuity gap.

**Attempted approach 3:** Use only conversation memory for planning continuity.
- **Why it failed:** Weak-spec workstreams need durable state outside transient context.

## Solution

We executed an exhaustive discovery pass (parallel explore + librarian agents, plus direct grep/glob/read and external references), then produced and prioritized five changes. The top five were:

1. Add a workspace repo graph + known-good pointer.
2. Make cross-repo verification a blocking CI matrix.
3. Add hard submodule drift gates and remove misleading recurse affordances.
4. Activate dormant contract gates (`phase-contracts.json`, `.contract-map/contract-map.json`) in CI.
5. Strengthen autonomous continuity with durable task state + deterministic completion/stop rules.

### Emphasis for follow-up planning

The user narrowed next work to item #5 only. The key actionable shape for #5 is:

- Persist task/progress state to disk (not only conversational context).
- Define deterministic stop/complete criteria that block "done" when readiness gates are unmet.
- Align continuity controls with existing policy and verification surfaces (doctor output, skills, hooks, and CI).

### Evidence snippets

```json
// opencode/opencode.jsonc (observed state)
"compaction": { "auto": true },
"permissions": {
  "todowrite": "deny",
  "todoread": "deny"
}
```

```bash
# Existing subrepo discovery is heuristic and depth-bounded
opencode/skills/do-verify/scripts/detect_subrepos.zsh
```

## Why This Works

The session reframed reliability as a control-system problem instead of a single fix. In weak-spec, low-test environments, autonomous quality depends on explicit state persistence, deterministic completion gates, and cross-repo verification boundaries. By first mapping present controls and then ranking gap-closing actions, we reduced risk of both overconfidence (premature done) and under-spec drift (loss of plan continuity).

## Prevention

- Treat task state as a first-class artifact (durable file-backed state) for long-running, multi-repo work.
- Gate completion on deterministic checks, not narrative confidence.
- Prefer blocking CI matrix verification for cross-repo changes.
- Keep contract checks active and mandatory where tests are sparse.
- Keep submodule/repo graph drift checks explicit and automated.

## Related Issues

- `knowledge/ai/solutions/workflow-issues/opencode-copy-only-sync-converged-bootstrap-update-development-workflow-20260222.md`
- `knowledge/ai/solutions/workflow-issues/config-sync-ordering-after-plugins-bootstrap-20260226.md`
- `knowledge/ai/solutions/documentation-gaps/current-installation-flow-phase-map-20260226.md`
- `knowledge/ai/solutions/build-errors/bootstrap-mise-command-not-found.md`
- `knowledge/ai/solutions/developer-experience/skill-inventory-system-opencode-20260301.md`

## Verification

- `opencode/skills/do-verify/scripts/detect_subrepos.zsh` -> confirm expected behavior
