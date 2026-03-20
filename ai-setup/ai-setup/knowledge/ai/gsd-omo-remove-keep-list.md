# GSD / OmO / Compound: Remove vs Keep Audit List

Last updated: 2026-03-01

This document is an audit to support a future consolidation decision.
It lists major components across GSD, oh-my-opencode (OmO), and compound knowledge capture.
For each component: recommendation (KEEP/REMOVE), rationale, and (if REMOVE) exact file edits required.

Constraints used for recommendations:
- The combined ideal workflow (GSD lifecycle + OmO execution) is the default contract to preserve.
- Default to KEEP for anything in the combined ideal workflow without a clear OmO replacement.
- Repository reality: `opencode/opencode.jsonc` declares only the OmO plugin; GSD is a global package.

## 1) GSD components (commands + lifecycle state)

Component: `.planning/` (GSD state layer)
Recommendation: KEEP
rationale: Persistent lifecycle state is the main GSD advantage (anti context-rot; survives session resets); OmO `.sisyphus/` is not an equivalent replacement.
file edit: none

Component: `/gsd-new-project`
Recommendation: KEEP
rationale: Combined ideal workflow Phase 1 depends on this for structured init outputs (PROJECT/REQUIREMENTS/ROADMAP/STATE) that OmO does not currently generate.
file edit: none

Component: `/gsd-map-codebase`
Recommendation: KEEP
rationale: Combined ideal workflow explicitly includes it for brownfield mapping into `.planning/` (OmO `/init-deep` serves agent context, not project planning parity).
file edit: none

Component: `/gsd-discuss-phase`
Recommendation: KEEP
rationale: Combined ideal workflow depends on GSD decision capture to `.planning/CONTEXT.md`; OmO otherwise keeps decisions in conversation.
file edit: none

Component: `/gsd-plan-phase`
Recommendation: KEEP
rationale: Combined ideal workflow depends on per-phase planning + state writing; OmO Prometheus can be an alternative planner, but the persistent `.planning/` integration remains GSD-owned.
file edit: none

Component: `/gsd-verify-work`
Recommendation: KEEP
rationale: Combined ideal workflow depends on human-in-the-loop conversational UAT; OmO verification is task-level and automated, not goal-backward UAT.
file edit: none

Component: `/gsd-audit-milestone`
Recommendation: KEEP
rationale: Milestone lifecycle is a GSD-only capability; no OmO equivalent today.
file edit: none

Component: `/gsd-complete-milestone`
Recommendation: KEEP
rationale: Milestone archive/tag workflow is a GSD-only capability; removing it requires replacing milestone state management.
file edit: none

Component: `/gsd-new-milestone`
Recommendation: KEEP
rationale: Starts the next lifecycle loop; OmO has no milestone concept.
file edit: none

Component: `/gsd-execute-phase`
Recommendation: REMOVE
rationale: Combined ideal workflow uses OmO execution (`/start-work` with Atlas+Hephaestus) and does not require GSD-native execution; keeping both execution paths increases confusion.
file edit: Removal is package-level. If choosing to remove: stop installing and uninstall `get-shit-done-cc` globally.
file edit (repo): delete `scripts/install-gsd.zsh`; delete `scripts/remove-gsd.zsh`; delete `scripts/phases/93-remove-gsd.zsh`; delete `bin/gsd-config-recommended`.
file edit (repo): delete hooks `opencode/hooks/gsd-statusline.js` and `opencode/hooks/gsd-check-update.js` (and their template copies under `templates/hooks/`).
file edit (repo): in `opencode/opencode.jsonc`, remove `permission.external_directory["~/.config/opencode/get-shit-done/*"]`.
file edit (system): uninstall global package: `npm uninstall -g get-shit-done-cc` (or use `./scripts/remove-system.zsh --gsd`).

Component: `opencode/hooks/gsd-statusline.js`
Recommendation: REMOVE
rationale: Statusline adds convenience but is not part of the combined ideal workflow contract; it also couples UX to GSD update cache.
file edit: delete `opencode/hooks/gsd-statusline.js`.
file edit: delete `templates/hooks/gsd-statusline.js`.
file edit: remove any hook registration that calls it (if present) from the relevant runtime hook config.

Component: `opencode/hooks/gsd-check-update.js`
Recommendation: REMOVE
rationale: Background update checks are non-essential and can create noise; OmO does not depend on this.
file edit: delete `opencode/hooks/gsd-check-update.js`.
file edit: delete `templates/hooks/gsd-check-update.js`.
file edit: remove any SessionStart hook registration that calls it (if present) from the relevant runtime hook config.

## 2) OmO components (plugin + core agents)

Component: `oh-my-opencode@3.8.5` (OpenCode plugin)
Recommendation: KEEP
rationale: OmO is the execution+verification layer in the combined ideal workflow (Atlas+Hephaestus), and it supplies `/start-work` and the verification wave.
file edit: none

Component: `opencode/oh-my-opencode.json`
Recommendation: KEEP
rationale: Defines agent model routing and categories; removing it breaks the OmO runtime contract.
file edit: none

Component: OmO core agents (Sisyphus, Prometheus, Atlas, Hephaestus)
Recommendation: KEEP
rationale: These agents implement the execution loop and plan production used in the combined ideal workflow; no replacement layer exists in this repo.
file edit: none

Component: OmO supporting agents (Oracle, Librarian, Explore, Metis, Momus, Multimodal-Looker)
Recommendation: KEEP
rationale: These reduce execution risk (research, critique, debugging, media evidence); they are broadly useful and low-maintenance.
file edit: none

Component: OmO agent catalog (`opencode/agents/`)
Recommendation: KEEP
rationale: This repo depends on specialized review/research agents for quality gates and workflows.
file edit: none

If OmO were removed (not recommended):
- file edit: in `opencode/opencode.jsonc`, remove the `plugin` array entry `"oh-my-opencode@3.8.5"`.
- file edit: delete `opencode/oh-my-opencode.json`.
- file edit: delete `opencode/agents/` (all agent definition files) or archive them to a non-synced location.

## 3) Compound components (durable knowledge capture)

Component: `/do:compound` (command surface)
Recommendation: KEEP
rationale: Combined ideal workflow includes `/do:compound` as the durable capture step; it is the bridge from execution to canonical knowledge (`knowledge/ai/`).
file edit: none

Component: `knowledge/ai/` (knowledge tier)
Recommendation: KEEP
rationale: Success metrics depend on canonical knowledge location; removing this breaks the documented 3-layer model (Operate/Execute/Capture).
file edit: none

Component: Compound worthiness gate (only capture high-impact learnings)
Recommendation: KEEP
rationale: Success metrics show this prevents knowledge pollution; it is a quality safeguard, not a feature burden.
file edit: none

Component: `knowledge/ai/compound-skill-patches.md` (patch record)
Recommendation: KEEP
rationale: Documents the deployed compound skill patches and worthiness gate; serves as recovery evidence if the deployed files drift.
file edit: none

If compound were removed (not recommended):
- file edit: remove knowledge capture section from `README.md` (3-layer model references to `/do:compound`).
- file edit: remove knowledge capture section from `README.md` (3-layer model references to `/do:compound`).
- file edit: remove compound references from `knowledge/ai/README.md`.

## Notes on feasibility (important)

- GSD removal granularity: most GSD command surfaces come from the global `get-shit-done-cc` package; removing a single command is generally not supported without removing the package.
- OmO removal granularity: OmO is configured as a plugin entry in `opencode/opencode.jsonc`, so removal is straightforward but would require a replacement execution/verification layer.
