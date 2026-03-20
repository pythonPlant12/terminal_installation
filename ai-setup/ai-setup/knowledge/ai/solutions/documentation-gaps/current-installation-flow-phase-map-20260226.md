---
schema_version: 2
module: Development Workflow
date: 2026-02-26
problem_type: documentation_gap
component: bootstrap
symptoms:
  - Installation behavior is distributed across multiple phase and helper scripts.
  - Phase responsibilities are clear in code but not centralized in one concise reference.
root_cause: stale_documentation
resolution_type: documentation_update
severity: low
confidence: high
summary: Centralize bootstrap execution order and lifecycle side effects into one compact map so agents can reason quickly without scanning many scripts.
applies_when:
  - You need the current bootstrap sequence and side effects in one place.
  - "A change touches phase ordering, readiness checks, or setup lifecycle behavior."
verification_commands:
  - zsh -n scripts/bootstrap.zsh
  - ai-setup-doctor --json
evidence_paths:
  - scripts/bootstrap.zsh
  - scripts/link_opencode.zsh
  - scripts/phases/01-preflight.zsh
  - scripts/phases/02-dependencies.zsh
  - scripts/phases/03-tools.zsh
  - scripts/phases/05-bin-link-setup.zsh
  - scripts/phases/06-opencode-plugins.zsh
  - scripts/phases/07-verify-integrations.zsh
  - scripts/phases/08-atlassian-login.zsh
  - scripts/phases/11-verify-readiness.zsh
tags:
  - bootstrap
  - installation
  - phases
  - orchestration
  - readiness
  - recovery
  - migration
avoid_when:
  - You need deep implementation details for a single phase script.
status: active
related_docs:
  - ../workflow-issues/config-sync-ordering-after-plugins-bootstrap-20260226.md
  - ../workflow-issues/bootstrap-phantom-tool-checks-and-scope-creep-20260307.md
---

# Current Installation Flow (Code-Split Phase Map)

## Agent Card

- Use when: You need exact bootstrap order and operational side effects quickly.
- Core fix: Follow `scripts/bootstrap.zsh` as orchestrator source of truth, then map each phase script by purpose and blocking behavior.
- Avoid when: You are only debugging one specific phase implementation detail.
- Verify with: `zsh -n scripts/bootstrap.zsh`; `ai-setup-doctor --json`

## Problem

Bootstrap behavior is spread across many phase files plus orchestrator-level steps. Without a concise map, ordering bugs and scope drift are harder to detect.

## Scope

This map captures the **current default bootstrap flow** from `scripts/bootstrap.zsh`, plus lifecycle-adjacent paths that influence installation behavior.

## Canonical Bootstrap Sequence (Current)

1. `scripts/phases/01-preflight.zsh`
   - Gate: macOS and required base tools.
   - Blocking: yes.

2. `scripts/phases/02-dependencies.zsh`
   - Converges Brew + mise dependencies.
   - Blocking: yes.

3. `scripts/phases/03-tools.zsh`
   - Ensures `opencode`, `codex`, `copilot` CLIs are present.
   - Blocking: yes.

4. `scripts/phases/05-bin-link-setup.zsh`
   - Links `bin/*` into `~/.local/bin` with conflict handling.
   - Blocking: yes.

5. `scripts/phases/06-opencode-plugins.zsh`
   - Installs plugin dependencies and compound plugin.
   - Blocking: yes.

6. `scripts/link_opencode.zsh` (orchestrator step)
   - Syncs repo OpenCode config to user config path.
   - Blocking: yes.

7. `bin/ai-setup-skill-inventory --generate` (orchestrator step)
   - Regenerates skill inventory after sync.
   - Blocking: yes.

8. `scripts/phases/07-verify-integrations.zsh`
   - Presence checks for integrations.
   - Blocking: no (warn-oriented).

9. `scripts/phases/08-atlassian-login.zsh`
   - Provision/validate Atlassian credentials if MCP is enabled.
   - Blocking: context-dependent; may skip in non-interactive mode.

10. `scripts/phases/11-verify-readiness.zsh`
    - Consolidated readiness report.
    - Blocking: no (status reporting).

11. `scripts/phases/12-snapshot-creation.zsh` (optional)
    - Runs only when `AIRCONSOLE_AUTO_SNAPSHOT=1`.
    - Blocking: no.

12. `scripts/phases/04-summary.zsh` (final summary)
    - Emits final status and next action.

## Notes on Disabled Steps

- `scripts/phases/09-codex-login.zsh` and `scripts/phases/10-copilot-login.zsh` exist but are currently commented out in orchestrator flow.

## Adjacent Lifecycle Paths

- Export/migration: `scripts/phases/13-migration-export.zsh` via `bin/ai-setup-export`.
- Remove path: `scripts/phases/90-remove-preflight.zsh`, `scripts/phases/92-remove-compound.zsh`, `scripts/phases/93-remove-gsd.zsh` via `bin/ai-setup-remove`.

## Operational CLIs Relevant to Installation

- `ai-setup-doctor` for health/readiness.
- `ai-setup-snapshot`, `ai-setup-rollback`, `ai-setup-export`, `ai-setup-import` for recovery/migration lifecycle.
- Atlassian auth helpers (`opencode-atlassian-*`, `mcp-atlassian-opencode`) for integration status.

## Why This Works

Keeping this map aligned to `scripts/bootstrap.zsh` gives one compact reference for ordering decisions, blocking behavior, and side effects. It reduces repeated repo-wide scanning and makes phase-order regressions easier to catch during reviews.

## Verification

- `zsh -n scripts/bootstrap.zsh` -> bootstrap orchestrator parses cleanly.
- `ai-setup-doctor --json` -> readiness report remains healthy after ordering/config changes.

## Related

- `knowledge/ai/solutions/workflow-issues/config-sync-ordering-after-plugins-bootstrap-20260226.md`
- `knowledge/ai/solutions/workflow-issues/bootstrap-phantom-tool-checks-and-scope-creep-20260307.md`
