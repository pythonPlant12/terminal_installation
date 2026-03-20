---
name: bootstrap-parity-scorecard
description: >-
  Produce a deterministic scorecard verifying bootstrap/update step-order
  correctness, ~/.config/opencode artifact diffs, and ai-setup-doctor --json
  before/after regressions. Use when validating bootstrap convergence after
  phase ordering or config-sync changes. Triggers on "parity check",
  "bootstrap scorecard", "phase audit", "convergence verification".
input: Repository with bootstrap.zsh phases
output: Markdown scorecard with per-check PASS/FAIL, exact command output, and overall parity result
category: code-quality
---

# Bootstrap Parity Scorecard

Deterministic scorecard for `./bootstrap.zsh` convergence verification.

## Workflow

1. Run from repo root:
   - `./opencode/skills/bootstrap-parity-scorecard/scripts/run_parity_scorecard.zsh`
2. Static-only mode (Check 1 only, no bootstrap execution):
   - `./opencode/skills/bootstrap-parity-scorecard/scripts/run_parity_scorecard.zsh --skip-bootstrap`
3. Post the script output directly in the response. Do not summarize away command output; keep exact stdout/stderr for each check.

## Checks

### Check 1: Step Order Verification

Parses `run_mode()` in `scripts/bootstrap.zsh`, extracts `run_step` call order, and verifies:
- Canonical ordering is maintained.
- Guard constraint: `sync opencode config` appears after `opencode plugins`.
- Phase files referenced by each step exist on disk.
- No stale phase files remain (e.g. `05-config-conflicts.zsh`).

### Check 2: Artifact Diff (~/.config/opencode)

Snapshots key files and directory listings before and after a bootstrap run:
- Config files: `opencode.json`, `opencode.jsonc`, `oh-my-opencode.json`.
- Directory listings: `skills/`, `rules/`, `hooks/`, `agents/`, `command/`.
- Reports changes, additions, and removals.

### Check 3: Doctor JSON Before/After

Captures `ai-setup-doctor --json` before and after bootstrap:
- Compares tool statuses (ready/needs_setup/unavailable).
- Compares summary counts.
- Flags any regressions (tool went from ready to non-ready).

## Output Contract

The script emits a Markdown report with:
- Section per check with `PASS`/`FAIL`.
- Exact command output in fenced code blocks.
- Overall result and non-zero exit on failures.

## Parity Gate Coverage

Maps to the 5 parity gates from `docs/plans/2026-02-26-feat-installer-make-wrapper-mode-parity-plan.md`:

| Gate | Covered By | Notes |
|------|-----------|-------|
| Gate 1: Idempotency | Checks 2 + 3 | Detect state drift across runs |
| Gate 2: Interactive/Non-Interactive | — | Tested by manual verification |
| Gate 3: Auth/Keychain | — | Tested by `opencode-atlassian-status` |
| Gate 4: Retry/Diagnostic | — | Tested by `run_step` behavior checks |
| Gate 5: Operational CLI | Check 3 | Doctor surface parity |
