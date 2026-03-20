---
schema_version: 2
module: Development Workflow
date: 2026-02-22
problem_type: workflow_issue
component: tooling
symptoms:
  - OpenCode setup depended on linking behavior that could couple repo and user config state.
  - "`--bootstrap` and `--update` followed different manifest behavior, producing drift."
  - Plugin availability could diverge from the repo-declared plugin list.
root_cause: missing_workflow_step
resolution_type: workflow_improvement
severity: medium
confidence: high
summary: "Setup convergence was inconsistent. Linking strategies, mode-specific behavior, and plugin provisioning could produce different local outcomes depending on machine history and run mode."
applies_when:
  - OpenCode setup depended on linking behavior that could couple repo and user config state.
  - "`--bootstrap` and `--update` followed different manifest behavior, producing drift."
  - Plugin availability could diverge from the repo-declared plugin list.
verification_commands:
  - ai-setup-doctor --json
evidence_paths:
  - ./bootstrap.zsh
tags:
  - opencode
  - bootstrap
  - update
  - plugins
  - copy-only-sync
  - deterministic-install
status: active
---

# Troubleshooting: OpenCode Copy-Only Sync and Converged Bootstrap/Update


## Agent Card

- Use when: OpenCode setup depended on linking behavior that could couple repo and user config state.
- Core fix: Setup convergence was inconsistent. Linking strategies, mode-specific behavior, and plugin provisioning could produce different local outcomes depending on machine history and run mode.
- Avoid when: The failure pattern does not match.
- Verify with: `ai-setup-doctor --json`

## Problem
Setup convergence was inconsistent. Linking strategies, mode-specific behavior, and plugin provisioning could produce different local outcomes depending on machine history and run mode.

## Environment
- Module: Development Workflow
- Affected Component: bootstrap phases and setup tooling
- Date: 2026-02-22

## Symptoms
- OpenCode config management risked user-state coupling when links were used.
- `./bootstrap.zsh` did not always converge through the same steps in all code paths.
- Repo-declared OpenCode plugin expectations did not always match installed local cache state.

## What Didn't Work

**Attempted Solution 1:** Treating setup as primarily link-driven.
- **Why it failed:** Linking couples mutable files and can create brittle feedback between repo content and user config state.

**Attempted Solution 2:** Keeping separate bootstrap/update manifest behavior.
- **Why it failed:** Divergent branches increase drift and reduce predictability of reruns.

**Attempted Solution 3:** Relying on implicit plugin installation only.
- **Why it failed:** It did not provide deterministic, repo-driven verification of installed plugins.

## Solution

Align setup around deterministic convergence:

**Code changes** (key excerpts):
```zsh
# scripts/link_opencode.zsh
rsync -a --ignore-existing "$OPENCODE_SRC_DIR/" "$OPENCODE_DST_DIR/"
```

```zsh
# scripts/phases/02-dependencies.zsh
# run the same convergence path for both modes
brew bundle check ... || brew bundle install --file "$ROOT_DIR/Brewfile" --no-upgrade
mise install
```

```zsh
# scripts/phases/06-opencode-plugins.zsh
retry_with_backoff 3 2 "OpenCode config plugin install" -- "$ROOT_DIR/scripts/install-opencode-plugins.zsh"
```

```zsh
# scripts/install-opencode-plugins.zsh
# parse plugin specs from opencode/opencode.jsonc and install to ~/.cache/opencode
bun add "${plugin_specs[@]}"
```

## Why This Works
The workflow now has a single convergence model:
1. OpenCode config is reconciled copy-only, preserving existing user files.
2. Bootstrap/update converge manifests the same way to reduce branch drift.
3. Plugin install is explicitly driven by repo-declared plugin specs and verified locally.

## Prevention
- Keep setup idempotent and convergence-based; avoid separate behavior branches unless required.
- Keep OpenCode sync copy-only (`--ignore-existing`) to protect user-local overrides.
- Verify plugin reconciliation after changes with:
  - `./scripts/install-opencode-plugins.zsh`
  - `./scripts/phases/06-opencode-plugins.zsh`
  - `ai-setup-doctor`

## Related Issues

- `knowledge/ai/solutions/patterns/critical-patterns.md`
- `docs/plans/2026-02-22-feat-optional-recovery-cli-and-gsd-install-flags-plan.md`

## Verification

- `ai-setup-doctor --json` -> confirm expected behavior
