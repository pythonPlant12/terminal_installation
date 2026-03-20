---
schema_version: 2
module: Development Workflow
date: 2026-02-26
problem_type: workflow_issue
component: tooling
symptoms:
  - "OpenCode config sync (link_opencode.zsh) ran inside phase 05 (before plugin install in phase 06), so plugins could overwrite the repo config."
  - Phase 05 file was labelled 'config-conflicts' but its log line and code only did bin link setup — the config sync had already been removed but the file name and comment were stale.
  - "After a fresh bootstrap, opencode.json reflected plugin-state rather than the authoritative repo config."
root_cause: missing_workflow_step
resolution_type: workflow_improvement
severity: medium
confidence: high
summary: "scripts/link_opencode.zsh (the OpenCode config sync step) was invoked from inside scripts/phases/05-config-conflicts.zsh, which runs **before** plugin installation (phase 06)."
applies_when:
  - "OpenCode config sync (link_opencode.zsh) ran inside phase 05 (before plugin install in phase 06), so plugins could overwrite the repo config."
  - Phase 05 file was labelled 'config-conflicts' but its log line and code only did bin link setup — the config sync had already been removed but the file name and comment were stale.
  - "After a fresh bootstrap, opencode.json reflected plugin-state rather than the authoritative repo config."
verification_commands:
  - ./bootstrap.zsh
  - cat ~/.config/opencode/opencode.json | jq '.model'
  - ai-setup-doctor
evidence_paths:
  - scripts/link_opencode.zsh
  - scripts/phases/05-config-conflicts.zsh
  - scripts/bootstrap.zsh
  - ./bootstrap.zsh
  - opencode/opencode.jsonc
tags:
  - bootstrap
  - opencode-config
  - phase-ordering
  - link_opencode
  - config-sync
  - plugins
status: active
---

# Config Sync Ordering: link_opencode.zsh Must Run After Plugin Install


## Agent Card

- Use when: OpenCode config sync (link_opencode.zsh) ran inside phase 05 (before plugin install in phase 06), so plugins could overwrite the repo config.
- Core fix: `scripts/link_opencode.zsh` (the OpenCode config sync step) was invoked from inside `scripts/phases/05-config-conflicts.zsh`, which runs **before** plugin installation (phase 06). Because plugins can write to `~/.conf...
- Avoid when: The failure pattern does not match.
- Verify with: `./bootstrap.zsh`; `cat ~/.config/opencode/opencode.json | jq '.model' # should match repo value`

## Problem

`scripts/link_opencode.zsh` (the OpenCode config sync step) was invoked from inside
`scripts/phases/05-config-conflicts.zsh`, which runs **before** plugin installation
(phase 06). Because plugins can write to `~/.config/opencode/`, running config sync
before plugins meant the final state was plugin-driven, not repo-authoritative.

Additionally `scripts/phases/05-config-conflicts.zsh` still contained a comment and
call to `link_opencode.zsh` even after the intent shifted to bin-link-only, creating
a stale/misleading file that did more than its name implied.

## Environment

- Module: Development Workflow
- Affected files: `scripts/bootstrap.zsh`, `scripts/phases/05-config-conflicts.zsh`, `scripts/link_opencode.zsh`
- Date: 2026-02-26

## Symptoms

- After `./bootstrap.zsh`, `~/.config/opencode/opencode.json` could reflect
   plugin-managed state rather than the repo's `opencode/opencode.jsonc`.
- Phase 05 log said "Phase: Config reconciliation" but code only ran `link_bin.zsh`.
- Phase file name (`05-config-conflicts.zsh`) did not match its actual responsibility.

## What Didn't Work

**Attempted approach 1:** Keep config sync in phase 05 and run it before plugins.
- **Why it failed:** Plugin provisioning (phase 06) writes into `~/.config/opencode/`,
  clobbering the just-synced repo config — meaning repo authority was not actually
  enforced at end-of-bootstrap.

**Attempted approach 2:** Rely on the merge logic in `link_opencode.zsh` to recover repo keys.
- **Why it failed:** The merge was replaced with a clean copy-only approach; running it
  before plugins still left the window open for plugins to diverge the final state.

## Solution

Moved the `link_opencode.zsh` invocation out of phase 05 and into `scripts/bootstrap.zsh`
as an explicit orchestrator step **immediately after** phase 06 (plugin install):

```zsh
# scripts/bootstrap.zsh — run_mode() step order (relevant excerpt)

run_step "opencode plugins" ...  "$ROOT_DIR/scripts/phases/06-opencode-plugins.zsh"
COMPLETED_STEPS+=("opencode-plugins")

# NEW: config sync runs AFTER plugins so repo config always wins
run_step "sync opencode config" ...  "$ROOT_DIR/scripts/link_opencode.zsh"
COMPLETED_STEPS+=("sync-opencode-config")

run_step "integration verification" ...  "$ROOT_DIR/scripts/phases/07-verify-integrations.zsh"
```

Phase 05 was cleaned up to be bin-link-only:

```zsh
# scripts/phases/05-config-conflicts.zsh (before)
log "Phase: Config reconciliation"
"$ROOT_DIR/scripts/link_opencode.zsh"   # REMOVED
"$ROOT_DIR/scripts/link_bin.zsh"
ok "Config reconciliation complete"

# scripts/phases/05-config-conflicts.zsh (after)
log "Phase: Bin link setup"
"$ROOT_DIR/scripts/link_bin.zsh"
ok "Config reconciliation complete"
```

`link_opencode.zsh` itself was also simplified to a clean copy-only approach:

```zsh
# reconcile_json_with_repo_precedence() in scripts/link_opencode.zsh
# Simple copy-only: repo config is always authoritative.
cp "$repo_jsonc" "$out_jsonc"
node "$ROOT_DIR/scripts/reconcile_jsonc.js" --to-json "$repo_jsonc" "$out_json"
```

## Why This Works

1. Plugin install (phase 06) completes first — all plugin state is finalized.
2. `link_opencode.zsh` then runs with full repo-authority copy — no subsequent step
   overwrites the config.
3. Phase 05 now exclusively handles bin link setup — name and behavior match.
4. Phase ordering in the orchestrator is the single place to reason about execution order.

## Prevention

- Config sync steps that must be authoritative should always run **after** any step
  that writes to the same destination paths.
- When removing a responsibility from a phase, also update the phase log message and
  file comment to reflect the new scope — stale comments are a maintenance hazard.
- Verify ordering after bootstrap changes with:
   ```bash
   ./bootstrap.zsh
   cat ~/.config/opencode/opencode.json | jq '.model' # should match repo value
   ai-setup-doctor
   ```

## Related Issues

- `knowledge/ai/solutions/workflow-issues/opencode-copy-only-sync-converged-bootstrap-update-development-workflow-20260222.md`
- `knowledge/ai/solutions/documentation-gaps/current-installation-flow-phase-map-20260226.md`
- `knowledge/ai/solutions/patterns/critical-patterns.md`

## Verification

- `./bootstrap.zsh` -> confirm expected behavior
- `cat ~/.config/opencode/opencode.json | jq '.model' # should match repo value` -> confirm expected behavior
- `ai-setup-doctor` -> confirm expected behavior
