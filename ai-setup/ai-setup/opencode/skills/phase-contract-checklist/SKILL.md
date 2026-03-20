---
name: phase-contract-checklist
description: Enforce explicit phase contracts and merge-gating drift checks for phase-based workflows. Use when a repository has ordered phase steps (for example scripts/phases/*.zsh) and needs every phase to declare inputs, outputs, side effects, and order constraints while failing CI if labels, file names, or behavior markers drift.
input: Repository with ordered phase steps (scripts/phases/*.zsh) and optional phase-contracts.json
output: Contract validation report checking inputs, outputs, side effects, and order constraints per phase
category: code-quality
---

# Phase Contract Checklist

Enforce a contract per phase and block merge on drift. Treat contract metadata as a first-class API for each phase step.

## Implement Workflow

1. Create `phase-contracts.json` at repository root using [Contract Schema](references/contract-schema.md).
2. Add annotations in each phase file:
   - `# PHASE_ID: <two-digit id>`
   - `# PHASE_LABEL: <slug>`
3. Set `behavior_markers` in each contract entry to short stable tokens that must appear in the phase file (function names, command ids, key strings).
4. Copy `scripts/verify_phase_contracts.py` from this skill into the repository and run it in CI.

## Enforced Rules

- Require every phase to declare non-empty `inputs`, `outputs`, `side_effects`, and `must_run_after`.
- Require `id`, `label`, and `script` to be unique.
- Require `script` file name to match `<id>-<label>.zsh` (or `.sh`).
- Require `PHASE_ID` and `PHASE_LABEL` annotations in the phase file to match contract values.
- Require each `behavior_markers` token to appear in phase file contents.
- Require all `must_run_after` ids to exist and be numerically lower than current phase id.

## Merge Gate Setup

Add a CI step that fails on any contract violation:

```bash
python3 scripts/verify_phase_contracts.py --contracts phase-contracts.json
```

If the check fails, do not merge until the contract file, phase labels, file names, and behavior markers are aligned.

## Update Rules

- Update `phase-contracts.json` and phase annotations in the same PR as behavior changes.
- If behavior changes but labels stay the same, update `behavior_markers` so drift is still detectable.
- Treat `must_run_after` as dependency declarations, not prose.

## References

- [Contract Schema](references/contract-schema.md)
- `scripts/verify_phase_contracts.py`
