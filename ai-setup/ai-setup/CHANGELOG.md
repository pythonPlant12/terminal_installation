<!-- markdownlint-disable MD024 -->

# Releases

Release notes follow the [keep a changelog](https://keepachangelog.com/en/1.1.0/) format.

## [Unreleased]

### Added

## [v0.1.7] - 2026-03-09

### Added
- **`agentic-pipeline-reliability` rule**: New rule `opencode/rules/agentic-pipeline-reliability.md` encodes 8 concrete practices for reliable AI pipelines (durable step execution, sequential pipelines, hard verification gates, separate critic agents, HITL checkpoints, two-tier memory, tool idempotency, concurrency control), synthesized from 2026 production agentic system research.
- **Hybrid GSD/OmO workflow contract**: `.sisyphus/README.md` and `.sisyphus/plans/README.md` now define OmO durable plan state, how it relates to `.planning/`, and where transient OmO evidence/notepads belong.
- **Pipeline reliability rules (Practices 1-4)**: Three new rules enforce agentic pipeline reliability across GSD and OmO surfaces — `durable-step-execution.md` (restartable pipelines via marker files in `.state/`), `sequential-pipelines.md` (deterministic step ordering with canonical sequences for GSD, OmO, and combined workflows), and `critic-separation.md` (generator-critic separation with tiered dispatch). Shared shell helpers (`step_done`, `mark_done`, `clear_markers`) added to `scripts/lib.zsh`. Pipeline stage gates added to AGENTS.md Quality Gates table.

- **Reliability contract gates**: added repo-owned `phase-contracts.json`, `.contract-map/contract-map.json`, local schema docs in `docs/specs/`, `scripts/verify_phase_contracts.py`, `scripts/verify_todos.py`, and `.github/workflows/reliability-gates.yml` so phase drift, supported config contract drift, and repo todo schema violations can be caught in CI without writing into `~/.config/opencode` or GSD-managed state.

- **Repo todo contract**: added `todos/README.md` to establish a repo-local durable task-state schema for markdown todos, explicitly separating it from GSD lifecycle state in `.planning/` and plugin/session state under `~/.config/opencode`.

- **Syntax Gate CI** (`.github/workflows/syntax-gate.yml`): new workflow runs on every PR and push to `main`, checking `zsh -n` for all `scripts/**/*.zsh` and zsh `bin/` scripts, `bash -n` for bash `bin/` scripts, `node --check` for `opencode/hooks/*.js`, and JSONC validity for `opencode/opencode.jsonc`. Catches syntax errors before they reach the bootstrap CI job.

- **`learnings-researcher` mandatory policy**: New rule `opencode/rules/learnings-researcher-mandate.md` enforces invoking `learnings-researcher` before implementing features, fixing bugs, or performing root cause analysis. The mandate is also added to `.github/copilot-instructions.md` (global prompt) and hardwired into the `/root-cause-analysis` command as step 3 of its process.
- Support for GPT-5.4
- Workflow documentation: detailed command usage guide in **[ai-guide.md](ai-guide.md)**, plus onboarding playbooks in **[human-centric-onboarding.md](human-centric-onboarding.md)** and **[ai-centric-onboarding.md](ai-centric-onboarding.md)**.
- **Docker Desktop prerequisite messaging**: bootstrap phases 07, 08, and 11 now prominently warn when Docker Desktop is missing (required for Atlassian MCP). Missing Docker is non-blocking but shown clearly with install URL and next steps.
- **`ai-setup-doctor`** now reports Docker Desktop availability as a dedicated health check item in both human and JSON output (`--json` includes a `docker` entry in `tools`).
- **`uv`** added to `Brewfile` so `uvx` (used by `mcp-atlassian-opencode`) is auto-installed via `brew bundle`.
- **GSD workflow enforcement**: bootstrap now patches the four GSD workflows (`plan-phase`, `execute-phase`, `quick`, `research-phase`) to invoke `learnings-researcher` for institutional knowledge before proceeding, via `scripts/helpers/patch-gsd-learnings.zsh`.
- **`ai-setup-doctor` learnings-researcher checks**: two new health checks verify that (1) `learnings-researcher-mandate.md` is deployed to `~/.config/opencode/rules/`, and (2) GSD workflows are patched.


### Improved
- `/do:compound` skill is now more efficient in collecting, processing and compacting worthy learnings.


### Fixed
- **`scripts/link_bin.zsh`**: Removed unsafe `source ~/.zshrc` from bootstrap. Instead, a warning message instructs the user to run `source ~/.zshrc` or open a new terminal after PATH is updated in their shell config.
- **Bootstrap rsync convergence**: `scripts/link_opencode.zsh` now force-deploys repo-owned OpenCode assets (`rules/`, `command/`, `agents/`, `hooks/`) on every bootstrap run, replacing the previous `--ignore-existing` behaviour that left stale installed copies in place.
- **`ai-setup-doctor`**: Docker Desktop check is now skipped in CI environments (`CI=true`), preventing false `unavailable` failures in GitHub Actions.


### Removed
- **Claude Code hook registration** (`scripts/ensure-omo-gitignore-hook.zsh`): removed erroneous bootstrap step that attempted to register an OpenCode hook into Claude Code's `~/.claude/settings.json`. This project does not support or integrate with Claude Code; the `omo-gitignore-init` hook lifecycle is owned by the `oh-my-opencode` plugin.


### Changed
- OpenCode native todo reading and writing capabilities are reactivated. This allows AI agents to use OpenCode's built-in todo management features to keep the human in the loop and enable the agent to stay on track with the human's priorities.
- **`./bootstrap.zsh` simplified**: removed `--bootstrap`, `--update`, and `-v`/`--verbose` flags. Run `./bootstrap.zsh` with no arguments to install or update — it always runs in full bootstrap mode with verbose output.
- **Workflow reliability alignment across GSD and OmO**: `.gitignore`, `opencode/hooks/omo-gitignore-init.js`, the dedicated Practices 1-4 rules, `opencode/skills/do-verify/SKILL.md`, and the onboarding/guide docs now share the same durable-state, stage-gate, plan-critic, and separate-judge contract. `.planning/*` remains lifecycle authority, `.sisyphus/plans/*` is the OmO execution projection, transient OmO state stays ignored, and `.state/` is the machine-local marker layer.


## [0.1.6] - 2026-03-05

### Added

- **Syntax Gate CI** (`.github/workflows/syntax-gate.yml`): new workflow runs on every PR and push to `main`, checking `zsh -n` for all `scripts/**/*.zsh` and zsh `bin/` scripts, `bash -n` for bash `bin/` scripts, `node --check` for `opencode/hooks/*.js`, and JSONC validity for `opencode/opencode.jsonc`. Catches syntax errors before they reach the bootstrap CI job.

- Optional Firebase MCP definitions in `opencode/opencode.jsonc` (disabled by default).
- Usage guide and cheat sheet in **[ai-guide.md](ai-guide.md)** covering the human-first loop (planning focused), the AI-first loop (agent orchestration), plus verification guidance.
- **`mobile-architect`** agent and routing added to the **`orchestrating-swarms`** skill (mobile artifact detection + Domain 8 fallback chain), with matching entries in the agent catalog.
- **`/do:verify`** now supports recursive git sub-repo detection via `opencode/skills/do-verify/scripts/detect_subrepos.zsh` and can dispatch verification for non-default sub-repos.
- New **`scripts/release.zsh`** — CHANGELOG-driven release automation that stamps release headers and creates versioned git tags, with optional `--tag-postfix` (e.g. `-ndream`).
- **Changelog discipline rule** (`opencode/rules/changelog-discipline.md`) — AI agents must now update CHANGELOG.md when modifying user-facing files (`bin/*`, bootstrap phases, `opencode/` config, `Brewfile`), with an explicit escape hatch for non-behavioral changes.

### Changed

- Minor additions to **[README.md](README.md)**.
- Bootstrap phase 06 simplified by folding GSD install/update into `scripts/phases/06-opencode-plugins.zsh` (removes the separate `06a-gsd` phase).
- `omo-gitignore-init` hook now auto-adds `.planning/` to `.gitignore` to keep local GSD planning state out of version control.
- `omo-gitignore-init` hook now uses granular gitignore rules instead of blanket directory ignores: `.sisyphus/` tracks `plans/` while ignoring ephemeral state; `.planning/` only ignores execution state (`STATE.md`, `config.json`, `debug/`) while tracking architecture docs. Migrates old broad patterns automatically.

## [0.1.5] - 2026-03-03

### Added

- **Syntax Gate CI** (`.github/workflows/syntax-gate.yml`): new workflow runs on every PR and push to `main`, checking `zsh -n` for all `scripts/**/*.zsh` and zsh `bin/` scripts, `bash -n` for bash `bin/` scripts, `node --check` for `opencode/hooks/*.js`, and JSONC validity for `opencode/opencode.jsonc`. Catches syntax errors before they reach the bootstrap CI job.

- GitHub Actions workflow to run `./bootstrap.zsh --bootstrap` on macOS 15.
- CI post-bootstrap verification via `ai-setup-doctor --json` (asserts `summary.unavailable == 0`) and checks that `~/.config/opencode/opencode.jsonc` was synced.

### Changed

- Bootstrap no longer depends on `mise`; installs Bun via the official installer and installs Node via Homebrew only when missing.
- Non-verbose setup now prints explicit "already installed" confirmations with tool versions.
- Snapshot/export manifests now record Bun version (instead of mise tool inventory).
- Upgraded `oh-my-opencode` plugin to `3.10.0`.

## [0.1.4] - 2026-03-03

### Added

- **Syntax Gate CI** (`.github/workflows/syntax-gate.yml`): new workflow runs on every PR and push to `main`, checking `zsh -n` for all `scripts/**/*.zsh` and zsh `bin/` scripts, `bash -n` for bash `bin/` scripts, `node --check` for `opencode/hooks/*.js`, and JSONC validity for `opencode/opencode.jsonc`. Catches syntax errors before they reach the bootstrap CI job.

- Expanded **[ai-onboarding.md](ai-onboarding.md)** with human-first (GSD) and AI-first (OmO) loops, including mermaid diagrams and a first-week playbook.
- Streamlined **[README.md](README.md)** with a bootstrap phase table, CLI quick reference, and OpenCode launch commands.

### Changed

- Updated **[ai-workflow.md](ai-workflow.md)** to match the current command set (GSD + OmO: `/gsd-discuss-phase`, `/start-work`, `/do:compound`) and remove stale `/workflows:*` references.

## [0.1.3] - 2026-03-03

### Added

- **Syntax Gate CI** (`.github/workflows/syntax-gate.yml`): new workflow runs on every PR and push to `main`, checking `zsh -n` for all `scripts/**/*.zsh` and zsh `bin/` scripts, `bash -n` for bash `bin/` scripts, `node --check` for `opencode/hooks/*.js`, and JSONC validity for `opencode/opencode.jsonc`. Catches syntax errors before they reach the bootstrap CI job.

- Non-verbose bootstrap now surfaces step status lines (✅/⚠️/❌), making auth/health outcomes visible without `--verbose`.
- Atlassian login emits clear non-interactive status indicators (skipped when disabled; actionable warning when credentials are missing).

### Changed

- Bootstrap step runner now always emits step output so status-line filtering works consistently across verbose and non-verbose modes.
