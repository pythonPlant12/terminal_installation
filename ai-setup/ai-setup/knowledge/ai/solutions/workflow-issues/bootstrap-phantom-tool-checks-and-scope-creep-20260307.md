---
schema_version: 2
module: Bootstrap Pipeline
date: 2026-03-07
problem_type: workflow_issue
component: tooling
symptoms:
  - Claude Code not detected — skipping ~/.claude/settings.json hook registration logged during every bootstrap run
  - "ai-setup-doctor reports Docker as unavailable in CI, failing GitHub Actions pipeline assertion (summary.unavailable != 0)"
root_cause: config_error
resolution_type: config_change
severity: medium
confidence: high
summary: "Two bootstrap pipeline issues caused spurious warnings and CI failures: (1) a script registered OpenCode hooks into Claude Code config — a product this project does not support,..."
applies_when:
  - Claude Code not detected — skipping ~/.claude/settings.json hook registration logged during every bootstrap run
  - "ai-setup-doctor reports Docker as unavailable in CI, failing GitHub Actions pipeline assertion (summary.unavailable != 0)"
verification_commands:
  - CI=true ai-setup-doctor --json | jq '.summary.unavailable'
  - CI=true ai-setup-doctor --json | jq '.tools.docker.status'
  - ai-setup-doctor --json | jq '.tools.docker.status'
  - grep -r '~/.claude\|~/.cursor\|\.vscode.*settings' scripts/ bin/ --include="*.zsh" --include="*.bash"
  - grep -r 'command -v' bin/ai-setup-doctor scripts/helpers/health-check.zsh | grep -v 'CI='
evidence_paths:
  - scripts/bootstrap.zsh
  - bin/ai-setup-doctor
  - scripts/ensure-omo-gitignore-hook.zsh
tags:
  - bootstrap
  - ci
  - github-actions
  - docker
  - opencode-hooks
  - scope-creep
status: active
related_docs:
  - ./config-sync-ordering-after-plugins-bootstrap-20260226.md
  - ../documentation-gaps/current-installation-flow-phase-map-20260226.md
  - ./opencode-copy-only-sync-converged-bootstrap-update-development-workflow-20260222.md
---

# Troubleshooting: Bootstrap Phantom Tool Checks and Product Scope Creep


## Agent Card

- Use when: Claude Code not detected — skipping ~/.claude/settings.json hook registration logged during every bootstrap run
- Core fix: Two bootstrap pipeline issues caused spurious warnings and CI failures: (1) a script registered OpenCode hooks into Claude Code config — a product this project does not support, and (2) the health check reported Docke...
- Avoid when: The failure pattern does not match.
- Verify with: `CI=true ai-setup-doctor --json | jq '.summary.unavailable'  # → 0`; `CI=true ai-setup-doctor --json | jq '.tools.docker.status'  # → "skipped"`

## Problem

Two bootstrap pipeline issues caused spurious warnings and CI failures: (1) a script registered OpenCode hooks into Claude Code config — a product this project does not support, and (2) the health check reported Docker Desktop as unavailable in GitHub Actions runners, failing the CI unavailability assertion.

## Environment

- Module: Bootstrap Pipeline (`scripts/bootstrap.zsh`, `bin/ai-setup-doctor`)
- Affected Component: Bootstrap phase runner, health check CLI
- Platform: macOS 14+ (local), GitHub Actions `macos-15` (CI)
- Date: 2026-03-07

## Symptoms

- Every bootstrap run logged: `Claude Code not detected — skipping ~/.claude/settings.json hook registration`
- GitHub Actions CI pipeline failed with non-zero exit from `ai-setup-doctor --json` because `summary.unavailable > 0` (Docker Desktop absent on runner)
- Local runs unaffected (Docker Desktop typically installed, Claude Code warning was non-fatal)

## What Didn't Work

**Problem 1 — Claude Code hook registration:**

**Attempted Solution 1:** Add a guard to only run the script if Claude Code was installed.
- **Why it failed:** The script should never run at all. The hooks are OpenCode's responsibility, managed by the `oh-my-opencode` plugin. Guarding doesn't fix the fundamental scope error.

**Attempted Solution 2:** Modify the hook to detect and handle both Claude Code and OpenCode protocols.
- **Why it failed:** Conflates two separate systems and adds unnecessary complexity. This project explicitly does not support Claude Code.

**Problem 2 — Docker check in CI:**

**Attempted Solution 1:** Set `unavailable=0` forcibly in CI.
- **Why it failed:** Masks real problems; a truly unavailable tool should still be reported.

**Attempted Solution 2:** Remove Docker check entirely.
- **Why it failed:** Docker is required for Atlassian MCP in local environments. The check is valid locally — only the CI context needed special handling.

## Solution

### Fix 1: Remove Claude Code hook registration

Removed the erroneous bootstrap step entirely:

1. Deleted `scripts/ensure-omo-gitignore-hook.zsh` (77 lines)
2. Removed the `run_step` invocation from `scripts/bootstrap.zsh`

The `oh-my-opencode` plugin manages the hook lifecycle automatically — no manual registration needed.

**Code changes:**

```zsh
# Before (scripts/bootstrap.zsh, lines 153-157):
  run_step \
    "omo-gitignore hook" \
    "Ensure omo-gitignore-init hook is registered and rerun ./bootstrap.zsh --$SELECTED_MODE." \
    "./bootstrap.zsh --$SELECTED_MODE" \
    "$ROOT_DIR/scripts/ensure-omo-gitignore-hook.zsh"

# After:
# (step removed entirely — plugin owns hook lifecycle)
```

### Fix 2: Skip Docker check in CI environments

Added a `CI=true` guard to both `format_status_human()` and `format_status_json()` in `bin/ai-setup-doctor`:

```zsh
# Before:
  if command -v docker >/dev/null 2>&1; then
    docker_available=0
  else
    docker_available=1
  fi

# After:
  if [[ "${CI:-}" == "true" ]]; then
    docker_available="skip"
  elif command -v docker >/dev/null 2>&1; then
    docker_available=0
  else
    docker_available=1
  fi
```

The "skip" state:
- Does not increment `summary.unavailable`
- Reports `"status": "skipped"` in JSON output
- Uses `vlog` (verbose-only) for human output
- Local (non-CI) behavior is unchanged

**Verification:**

```bash
# CI mode — Docker skipped, unavailable stays 0
CI=true ai-setup-doctor --json | jq '.summary.unavailable'  # → 0
CI=true ai-setup-doctor --json | jq '.tools.docker.status'  # → "skipped"

# Local mode — unchanged behavior
ai-setup-doctor --json | jq '.tools.docker.status'  # → "ready" or "unavailable"
```

## Why This Works

**Problem 1 root cause:** A script was created assuming Claude Code integration was needed, but this project is OpenCode-only. The `omo-gitignore-init.js` hook uses OpenCode's stdin protocol (`cwd`/`session_id`), not Claude Code's hook interface. The `oh-my-opencode` plugin owns hook registration — manual registration into `~/.claude/settings.json` was both incorrect and unnecessary.

**Problem 2 root cause:** The health check used binary logic (available/unavailable) without accounting for environments where a tool is expectedly absent. GitHub Actions `macos-15` runners don't include Docker Desktop. The CI pipeline assertion (`summary.unavailable == 0`) correctly enforces that all required tools are present — but Docker isn't required in CI.

By introducing a third state (`"skip"`), we distinguish between "not needed in this environment" (CI) and "missing but needed" (local). The pipeline assertion now passes because skipped tools don't count as unavailable.

## Prevention

### Product Integration Gating

When creating scripts that interact with product-specific config directories (`~/.claude/`, `~/.cursor/`, `~/.config/<product>/`):

1. **Verify product is in-scope**: Read AGENTS.md § Project Purpose. This project integrates with OpenCode only.
2. **Check plugin ownership**: If a plugin (like `oh-my-opencode`) already manages the lifecycle, don't duplicate with manual scripts.
3. **Code review signal**: Any script touching `~/.claude/` or other unsupported product paths should be flagged immediately.

### CI-Aware Health Checks

When adding tool availability checks to `ai-setup-doctor` or health helpers:

1. **Declare CI behavior upfront**: Each check should document whether it's mandatory or optional in CI.
2. **Use three-state logic**: `ready` / `unavailable` / `skipped` — not just binary available/absent.
3. **Guard with `CI=true`**: GitHub Actions, GitLab CI, and similar set `CI=true`. Use `[[ "${CI:-}" == "true" ]]` to detect.
4. **Don't mask real failures**: Skipped checks should be logged transparently, not silently dropped.

### Detection Patterns

```bash
# Find scripts touching unsupported product config
grep -r '~/.claude\|~/.cursor\|\.vscode.*settings' scripts/ bin/ --include="*.zsh" --include="*.bash"

# Find tool checks missing CI guard
grep -r 'command -v' bin/ai-setup-doctor scripts/helpers/health-check.zsh | grep -v 'CI='
```

### Code Review Checklist for Bootstrap Changes

- [ ] No product scope creep (no integrations for unsupported products)
- [ ] Health checks declare CI behavior (skip/warn/fail)
- [ ] New checks use `[[ "${CI:-}" == "true" ]]` guard if not mandatory in CI
- [ ] Error messages differentiate local vs. CI context

## Related Issues

- See also: [config-sync-ordering-after-plugins-bootstrap-20260226.md](config-sync-ordering-after-plugins-bootstrap-20260226.md) — Phase ordering fix: config sync must run after plugin install (related bootstrap sequencing issue)
- See also: [current-installation-flow-phase-map-20260226.md](../documentation-gaps/current-installation-flow-phase-map-20260226.md) — Complete bootstrap phase map (documents hook registration, phase sequencing, and tool checks)
- See also: [opencode-copy-only-sync-converged-bootstrap-update-development-workflow-20260222.md](opencode-copy-only-sync-converged-bootstrap-update-development-workflow-20260222.md) — Convergence and install-ordering context for bootstrap behavior

## Verification

- `CI=true ai-setup-doctor --json | jq '.summary.unavailable'  # → 0` -> confirm expected behavior
- `CI=true ai-setup-doctor --json | jq '.tools.docker.status'  # → "skipped"` -> confirm expected behavior
- `ai-setup-doctor --json | jq '.tools.docker.status'  # → "ready" or "unavailable"` -> confirm expected behavior
