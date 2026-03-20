# Capability Matrix: GSD, OmO, Compound

Last updated: 2026-03-01

This file is an audit and safety reference. It documents what capabilities each major workflow component provides today, plus rollback procedures to restore functionality after any future removal or accidental breakage.

## Scope and Definitions

- GSD: get-shit-done-cc and its `/gsd-*` command suite. Core value is lifecycle orchestration plus file-based state in `.planning/`.
- OmO: oh-my-opencode agent orchestration (Sisyphus, Prometheus, Atlas, Hephaestus, supporting agents). Core value is execution quality and verification.
- Compound: `/do:compound` and related skills. Core value is durable knowledge capture into `knowledge/ai/`.


## Combined Ideal Flow (do not break)

This is the intended hybrid lifecycle that keeps the strengths of both systems.

1. Project init (GSD)
   - Run `/gsd-new-project` for structured questioning, research, and roadmap scaffolding.
   - Optionally run `/gsd-map-codebase` for brownfield analysis.
   - Persistent outputs live in `.planning/` (for example: `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`).

2. Per-phase loop (GSD orchestration + OmO execution)
   - `/gsd-discuss-phase N` captures decisions to `.planning/CONTEXT.md`.
   - `/gsd-plan-phase N` produces a plan for the phase (or Prometheus can generate `.sisyphus/plans/*` using the captured context).
   - `/start-work` runs OmO execution: Atlas reads the plan, delegates tasks to Hephaestus (fresh context per task), then verifies results (LSP, manual review, QA), accumulates notepad learnings, and runs a final review wave.
   - `/gsd-verify-work N` performs conversational UAT. If UAT fails, generate fix plans and re-execute.
   - `/do:compound` captures durable learnings and outcomes to `knowledge/ai/`.

3. Milestone lifecycle (GSD)
   - `/gsd-audit-milestone` validates definition-of-done.
   - `/gsd-complete-milestone` archives and tags the release.
   - `/gsd-new-milestone` starts the next cycle.

## Capability Matrix

Columns:
- Component: the command, agent, skill, or workflow surface.
- Type: command, agent, skill, policy, state, or bootstrap step.
- Capability: what it provides.
- Current State: where it lives and how it is used.
- Rollback Procedure: how to restore it (including which bootstrap step/phase re-provisions it when applicable).

| Component | Type | Capability | Current State | Rollback Procedure |
|---|---|---|---|---|
| `.planning/` | State (GSD) | Persistent lifecycle state and anti context-rot exocortex | Git-tracked project state for GSD lifecycle | Restore from git history/remote; rerun `/gsd-*` commands to regenerate missing files; avoid replacing with `.sisyphus/` state |
| `/gsd-new-project` | Command (GSD) | Project init: structured interview, research, requirements, roadmap | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc: `npx get-shit-done-cc@latest --opencode --global`; verify command files exist in `~/.config/opencode/command/` |
| `/gsd-map-codebase` | Command (GSD) | Brownfield mapping into `.planning/` docs | Deployed command in `~/.config/opencode/command/` | Same as above; if outputs missing, rerun command (it should regenerate `.planning/codebase/*`) |
| `/gsd-discuss-phase` | Command (GSD) | Capture phase decisions into `.planning/CONTEXT.md` | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/CONTEXT.md` from git if it was committed |
| `/gsd-plan-phase` | Command (GSD) | Phase plan generation with optional research and plan checks | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; if delegating planning to OmO, keep GSD for state writing |
| `/gsd-execute-phase` | Command (GSD) | Execute plan tasks in wave order (GSD-native executor) | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; if replacing execution with OmO, keep this as optional fallback only |
| `/gsd-verify-work` | Command (GSD) | Conversational UAT and fix-plan loop | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; preserve user-facing UAT prompts in `.planning/` |
| `/gsd-progress` | Command (GSD) | State-aware routing to next action based on `.planning/` | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/STATE.md` if routing breaks |
| `/gsd-debug` | Command (GSD) | Scientific debugging with persistent checkpoints | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/debug/*` from git if present |
| `/gsd-audit-milestone` | Command (GSD) | Milestone audit before archive | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/` milestone state from git |
| `/gsd-complete-milestone` | Command (GSD) | Archive milestone state and prepare next | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; if archive artifacts are missing, recover from git tags/branches |
| `/gsd-new-milestone` | Command (GSD) | Initialize next milestone cycle | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; rerun to regenerate baseline milestone files |
| `/gsd-add-phase` | Command (GSD) | Append a phase to roadmap | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `ROADMAP.md` from git if needed |
| `/gsd-insert-phase` | Command (GSD) | Insert urgent work between phases | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `ROADMAP.md` from git |
| `/gsd-remove-phase` | Command (GSD) | Remove future phase and renumber | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; if removal was mistaken, recover `ROADMAP.md` from git |
| `/gsd-settings` | Command (GSD) | Configure workflow toggles and defaults | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/config.json` from git or recreate via command |
| `/gsd-set-profile` | Command (GSD) | Switch model/cost profile for GSD agents | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; verify `.planning/config.json` and the selected profile |
| `/gsd-update` | Command (GSD) | Update GSD installation and show changelog | Deployed command in `~/.config/opencode/command/` | If update breaks: reinstall get-shit-done-cc via `npx get-shit-done-cc@latest --opencode --global`; confirm `npm list -g get-shit-done-cc` |
| `/gsd-help` | Command (GSD) | Help and usage reference | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-health` | Command (GSD) | Diagnose `.planning/` health and repair | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore `.planning/` from git if repair is risky |
| `/gsd-quick` | Command (GSD) | Quick tasks with GSD guarantees (skips optional agents) | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-reapply-patches` | Command (GSD) | Reapply local modifications after an update | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; if patches are missing, recover from git branches/stashes/backups |
| `/gsd-research-phase` | Command (GSD) | Standalone phase research | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-list-phase-assumptions` | Command (GSD) | Surface planner assumptions before planning | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-plan-milestone-gaps` | Command (GSD) | Create phases to close milestone audit gaps | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-add-tests` | Command (GSD) | Generate tests for completed phase | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-check-todos` | Command (GSD) | List pending todos and select one | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-add-todo` | Command (GSD) | Capture idea/task as a todo | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `/gsd-pause-work` | Command (GSD) | Create context handoff mid-phase | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; restore handoff docs from git if tracked |
| `/gsd-resume-work` | Command (GSD) | Resume work from prior session using state files | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; ensure `.planning/STATE.md` and `.continue-here.md` exist |
| `/gsd-cleanup` | Command (GSD) | Archive completed milestone directories | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc; recover archived files from git if needed |
| `/gsd-join-discord` | Command (GSD) | Community link helper | Deployed command in `~/.config/opencode/command/` | Reinstall get-shit-done-cc |
| `opencode/oh-my-opencode.json` | Config (OmO) | Core agent model routing for OmO | Repo file synced into user OpenCode config | Rollback: restore from git; rerun `./bootstrap.zsh` (steps: `opencode plugins` then `sync opencode config`) |
| `oh-my-opencode@3.8.5` | Plugin (OmO) | OmO orchestrator runtime and core commands (for example `/start-work`) | Declared in `opencode/opencode.jsonc` plugin list | Rollback: rerun `./bootstrap.zsh` to re-provision plugin cache (bootstrap step `opencode plugins`, phase 06) |
| `Sisyphus` | Agent (OmO) | Main interaction agent, delegates and drives completion | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` to sync |
| `Prometheus` | Agent (OmO) | Planner: interview, research, produce wave plan | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Atlas` | Agent (OmO) | Orchestrator: reads plan, delegates, verifies each result | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Hephaestus` | Agent (OmO) | Execution worker: implements atomic tasks with fresh context | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Oracle` | Agent (OmO) | Debugging and architecture consultation | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Librarian` | Agent (OmO) | Documentation lookup and deep reading | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Explore` | Agent (OmO) | Fast search and lightweight repo exploration | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Metis` | Agent (OmO) | Plan consultant | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Momus` | Agent (OmO) | Plan critic | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `Multimodal-Looker` | Agent (OmO) | Image/PDF interpretation for evidence and UI diffs | Defined in `opencode/oh-my-opencode.json` | Rollback: restore config file from git; rerun `./bootstrap.zsh` |
| `opencode/agents/*` | Agent catalog (OmO) | Specialized subagents (56 definitions) for review, research, QA, etc. | Repo directory synced into user OpenCode config | Rollback: restore from git; rerun `./bootstrap.zsh` (bootstrap step `sync opencode config`) |
| `/start-work` | Command (OmO) | Execute OmO plan pipeline (Atlas execution loop) | Provided by OmO plugin runtime | Rollback: ensure `oh-my-opencode` plugin is installed and `opencode/oh-my-opencode.json` is synced; rerun `./bootstrap.zsh` |
| `/ulw-loop` | Command (OmO) | Continuous execution until completion (ultrawork loop) | Built-in OmO loop command | Rollback: ensure OmO plugin installed; rerun `./bootstrap.zsh` |
| `/handoff` | Command (OmO) | Session handoff summary (less structured than `.planning/` state) | Built-in command | Rollback: ensure OmO plugin installed; rerun `./bootstrap.zsh` |
| `/do:compound` | Command (Compound) | Capture a solved problem as durable knowledge in `knowledge/ai/` | Deployed command in `~/.config/opencode/command/` plus repo skills | Rollback: restore `opencode/skills/do-compound/`; rerun `./bootstrap.zsh` (sync opencode config, skill inventory generation) |
| `do-compound` | Skill (Compound) | Orchestrated capture: research, assemble doc, bridge learning | `opencode/skills/do-compound/` is deployed by OpenCode skill sync | Rollback: restore skill directory from git; rerun `./bootstrap.zsh` (bootstrap step `skill inventory` and `sync opencode config`) |
| `compound-docs` (merged into `do-compound`) | Skill (Compound) | Schema, templates, and references — now part of `do-compound/` | Merged; no longer a standalone skill | Rollback: restore from git at commit before merge; rerun `./bootstrap.zsh` |
| `knowledge/ai/` | Knowledge layer (Compound) | Durable AI knowledge storage (canonical) | Repo directory, human reviewed | Rollback: restore from git; re-run `/do:compound` to regenerate missing docs where possible |

| `scripts/remove-gsd.zsh` | Removal (GSD) | Uninstall global `get-shit-done-cc` npm package | Used by removal phases | Rollback: reinstall with `npx get-shit-done-cc@latest --opencode --global` (same as `scripts/install-gsd.zsh`) |

## Rollback Notes (cross-cutting)

- Keychain credentials are not restored by reinstall. Use the relevant login flows (for example: `opencode-atlassian-login`) after rollback.
- For config breakage, the safest recovery path is usually:
  1. `ai-setup-snapshot --create`
  2. `./bootstrap.zsh`
  3. `ai-setup-doctor --json`
