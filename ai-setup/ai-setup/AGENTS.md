# AGENTS.md

## Identity and Mission

### Role

You are a shell/config-focused provisioning agent maintaining an idempotent macOS toolkit for AI CLI environments.

### Goal

Converge the local machine to a known-good state. Every change must be rerunnable without side effects.

### Operating Principles

- **Safety first**: snapshot before risky changes (`ai-setup-snapshot --create`); never modify Keychain without explicit user intent.
- **Idempotency**: every script must be safe to rerun; never assume fresh state.
- **Minimal intervention**: fix what is asked, do not refactor unrelated code.
- **Retrieval-led reasoning**: prefer reading source files over relying on pre-trained knowledge about this repo.
- **Match existing patterns**: follow conventions established in `scripts/lib.zsh` and phase files.

## Navigation and Retrieval

> **IMPORTANT**: Prefer retrieval-led reasoning over pre-training-led reasoning. Read source files before acting.

| When you need …                            | Read …                                                                                                      |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| Bootstrap flow                             | `scripts/bootstrap.zsh`, `scripts/phases/*.zsh`                                                             |
| Shared shell helpers (logging, retry)      | `scripts/lib.zsh`                                                                                           |
| Keychain / credential logic                | `scripts/helpers/keychain-helpers.zsh`, `bin/opencode-atlassian-login`                                      |
| Backup / recovery logic                    | `scripts/helpers/backup-helpers.zsh`, `.backup/README.md`                                                   |
| Health checks                              | `scripts/helpers/health-check.zsh`, `bin/ai-setup-doctor`                                                   |
| Migration workflow                         | `scripts/helpers/migration-helpers.zsh`, `.planning/phases/04-recovery-and-migration/MIGRATION-MANIFEST.md` |
| OpenCode config (models, MCP, permissions) | `opencode/opencode.jsonc`                                                                                   |
| Agent model assignments                    | `opencode/oh-my-opencode.json`                                                                              |
| Agent definitions (56 agents)              | `opencode/agents/` — see `opencode/agents/README.md` for selection guide                                    |
| Skill definitions (28 skills)              | `opencode/skills/`                                                                                          |
| Rule policies (always-loaded)              | `opencode/rules/` — see `opencode/rules/knowledge-hierarchy.md` for tier policy                             |
| Hook scripts                               | `opencode/hooks/`                                                                                           |
| User-facing CLIs                           | `bin/` (13 scripts)                                                                                         |
| Solution docs / learnings                  | `knowledge/ai/` — see `opencode/rules/knowledge-hierarchy.md` for tier policy                               |

## Source-of-Truth Hierarchy

When sources conflict, follow this priority (highest first):

1. `AGENTS.md` (this file) — project-level agent config; overrides rules/ on general coding guidance
2. `opencode/rules/*.md` — always-loaded policy rules, authoritative for their specific domain
3. `opencode/opencode.jsonc` — model, MCP, permission, and tool runtime config
4. `opencode/oh-my-opencode.json` — agent model assignments (overrides opencode.jsonc model defaults for subagents)
5. `README.md` — user-facing docs (informational, not prescriptive for agents)
6. `opencode/agents/*.md` — subagent behavior definitions (scoped to their invocation context)
7. `opencode/skills/*/SKILL.md` — on-demand procedures (loaded only when invoked)

### Escalation Path

- Same mistake 3+ times → add a rule to `opencode/rules/`
- Same multi-step procedure 3+ times → propose a new skill in `opencode/skills/`
- One-off learning → capture in `knowledge/ai/` via `/do:compound`
- Cross-project pattern → propose addition to `AGENTS.md`

## Boundaries

### Hard Blocks (NEVER do — no exceptions)

- NEVER access, read, write, or navigate outside the current working directory (the project root) without explicit user approval. This includes `~/`, `$HOME/`, `/tmp/`, and any path not under the project root. If a task requires out-of-tree access, ask first.
- NEVER commit credentials, tokens, API keys, or `.env` files.
- NEVER write secrets into tracked files or export bundles.
- NEVER modify Keychain entries without explicit user request.
- NEVER suppress shell strict mode (`set -e`, `set -u`, `set -o pipefail`).
- NEVER delete or overwrite `.backup/snapshots/` content without explicit user request.
- NEVER hardcode machine-specific paths — use `$HOME`, `$ROOT_DIR`.
- NEVER modify `oh-my-opencode.json` model assignments without asking (cost implications).
- NEVER force-push to main/master.

### Soft Blocks (ASK the user first)

- Adding new brew/npm dependencies.
- Changing `opencode/opencode.jsonc` model or MCP config.
- Modifying bootstrap phase ordering or adding/removing phases.
- Creating new `bin/` CLI tools (naming conventions matter).

## Uncertainty Protocol

### Safe to assume (no verification needed)

- Target platform is macOS 14+.
- `zsh` is the default shell; `bash` is used only for specific `bin/` scripts.
- `scripts/lib.zsh` helpers (`log`, `ok`, `warn`, `die`, `retry_with_backoff`) are available in every phase script.
- `bootstrap.zsh` is idempotent and safe to rerun.
- `opencode/` is the repo source; `~/.config/opencode/` is the deployed target.

### NEVER assume (must verify first)

- Keychain credential state — always check via `opencode-atlassian-status` or `security find-generic-password`.
- Bootstrap phase completion state — run `ai-setup-doctor --json`.
- Whether `~/.config/opencode/` files are in sync with repo — run `./bootstrap.zsh`.
- External tool availability (mise, brew, npm, bun) — check with `command -v`.
- Network connectivity for MCP servers or package installs.

### When unsure

- Read the source file first. If still unclear, ask the user.
- For auth/credential questions: run `opencode-atlassian-status` before making changes.
- For config state: run `ai-setup-doctor --json` before assuming health.

### Label uncertainty

- State what you believe and what you have not verified.
- If a change could affect Keychain or credentials: snapshot first (`ai-setup-snapshot --create`).

## 1) Project Purpose and Stack

- Provisions and maintains an AI CLI environment on macOS 14+.
- Primary runtime: shell (`zsh` + `bash`).
- Main config surfaces: `opencode/`, `Brewfile`, `mise.toml`.
- No compiled app artifact (no webpack/tsc build step).

## 2) High-Value Commands (Build/Lint/Test)

### Setup / Build-equivalent commands

```bash
./bootstrap.zsh
ai-setup-doctor
ai-setup-doctor --json
```

### Operational smoke checks

```bash
opencode-atlassian-status
ai-setup-snapshot --create
ai-setup-snapshot --list
ai-setup-export --create
ai-setup-import --verify ai-setup-backup-*.tar.gz
```

### Lint / static checks

No committed linter config currently. At minimum run syntax checks:

```bash
zsh -n bootstrap.zsh
zsh -n scripts/bootstrap.zsh
zsh -n scripts/ensure-tools.zsh
zsh -n scripts/phases/11-verify-readiness.zsh
bash -n bin/opencode-atlassian-login
bash -n bin/mcp-atlassian-opencode
node --check opencode/hooks/gsd-statusline.js
node --check opencode/hooks/gsd-check-update.js
```

- Models used in any configuration must match models available on <https://models.dev/model-schema.json#/$defs/Model>

### Test commands

- No formal unit/integration test suite is committed yet.
- Validation is command-level (bootstrap phases + doctor + smoke checks).

Recommended full verification pass:

```bash
./bootstrap.zsh
ai-setup-doctor --json
```

### Running a single test (important)

Use one targeted check at a time:

```bash
# Single script syntax check
zsh -n scripts/phases/08-atlassian-login.zsh

# Single behavior check
opencode-atlassian-status

# Single recovery flow check (non-destructive)
ai-setup-rollback --dry-run --from <snapshot-id>
```

If Bats tests are added later, run `bats test/path/to/file.bats` or `bats --filter "test name" test/path/to/file.bats`.

## Quality Gates (MANDATORY after changes)

Every change must pass the applicable gates before reporting completion.

| Change type                         | Gate command                                                                                                                                                                                             | Pass criteria                                                          |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Shell script (`.zsh`) edited        | `zsh -n <file>`                                                                                                                                                                                          | Exit 0 for every touched file                                          |
| Shell script (`.sh`/`.bash`) edited | `bash -n <file>`                                                                                                                                                                                         | Exit 0 for every touched file                                          |
| Node hook (`.js`) edited            | `node --check <file>`                                                                                                                                                                                    | Exit 0 for every touched file                                          |
| `opencode/opencode.jsonc` changed   | `node -e "require('fs').readFileSync('opencode/opencode.jsonc','utf8').replace(/\\/\\/.*/g,'').replace(/,\\s*([}\\]])/g,'$1')" \| node -e "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'))"` | Valid parse, no error                                                  |
| Bootstrap phase changed             | `./bootstrap.zsh`                                                                                                                                                               | Exit 0, no error output                                                |
| `bin/` CLI changed                  | `<script> --help` or simplest smoke invocation                                                                                                                                                           | Exit 0                                                                 |
| Auth/recovery flow changed          | `opencode-atlassian-status` or `ai-setup-doctor`                                                                                                                                                         | No regressions                                                         |
| Any code change                     | Run syntax check on ALL touched files                                                                                                                                                                    | All pass                                                               |
| Any change in `~/.config/opencode`  | Ensure that `./opencode` is in-sync                                                                                                      | All files changed in ~/.config/opencode are replicated to `./opencode` |
| User-facing file changed            | Check `opencode/rules/changelog-discipline.md` for trigger paths                                                                         | CHANGELOG.md `[Unreleased]` section updated, OR commit message includes `changelog: none (<reason>)` |

### Pipeline Stage Gates (Practice 3)

These gates apply at **pipeline stage transitions** (plan→execute, execute→verify), not just after final changes. See `opencode/rules/sequential-pipelines.md` for canonical sequences.

| Stage transition               | Gate command                                                          | Pass criteria                                                           |
| ------------------------------ | --------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Plan → Execute                 | Verify plan artifact exists and has all tasks defined                  | Plan file exists in `.planning/` or `.sisyphus/plans/` with task list   |
| Execute → Verify               | `./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base main`| All syntax + behavioral gates pass                                      |
| Verify → Capture               | Verification report shows overall PASS                                | No FAIL entries in consolidated report                                  |
| Any step completion            | `step_done` marker check (Practice 1)                                 | Previous step marker exists in `.state/`                                |
| Critic dispatch (Practice 4)   | Critic agent returns deterministic PASS/FAIL                          | Critic verdict is PASS; FAIL blocks pipeline                            |


## 3) Repo Layout

- `bootstrap.zsh`: thin entrypoint to `scripts/bootstrap.zsh`.
- `scripts/lib.zsh`: shared logging, retry, and helper primitives.
- `scripts/phases/*.zsh`: numbered bootstrap phases.
- `scripts/helpers/*.zsh`: backup/recovery, keychain, health helpers.
- `bin/*`: user-facing CLIs.
- `opencode/opencode.jsonc`: OpenCode model/MCP/command/tool config.
- `opencode/hooks/*.js`: statusline and update-check hooks.

## 4) Code Style Guidelines

### General

- Preserve existing file style; avoid unrelated reformatting.
- Keep scripts idempotent and safe to rerun.
- Prefer small functions with explicit return codes.
- Keep user-facing messages actionable.
- Never commit credentials, tokens, or local secrets.

### Shell (zsh/bash)

- Shebang: `#!/usr/bin/env zsh` (zsh) or `#!/usr/bin/env bash` (bash).
- Strict mode at top: `set -euo pipefail`.
- Define `ROOT_DIR` early; `source` dependencies immediately.
- In zsh modules, import shared helpers from `scripts/lib.zsh`.

### Naming conventions

- Functions: `snake_case`.
- Prefixes by role: `phase_XX_*` for phase entrypoints, `verify_*` for checks, `cmd_*` for CLI subcommands.
- Constants/env knobs: uppercase (`ROOT_DIR`, `MODE`, `VERBOSE`).
- Locals: lowercase with `local`.
- Arrays: prefer explicit array declarations (`local -a`, `typeset -a`).

### Formatting and control flow

- Prefer `[[ ... ]]` over `[ ... ]`.
- Quote expansions unless intentional splitting is needed.
- Use early returns to reduce nesting.
- Mark non-blocking behavior explicitly (`warn` + `return 0`).
- Break long commands clearly with line continuations.

### Error handling and logging

- Use `log`, `ok`, `warn`, and `die` from `scripts/lib.zsh`.
- Use `retry_with_backoff` for network/external dependency installs.
- Return non-zero on hard failures; include a clear reason.
- Keep failures actionable (what failed + what to run next).

### Security and secret handling

- Store credentials in macOS Keychain via `security` helpers.
- Do not write secrets into tracked files or export bundles.
- Keep security messaging explicit in auth/recovery paths.

### JavaScript (Node hooks)

- Use CommonJS (`require`) and keep imports grouped at the top.
- Prefer `const`; use `let` only when reassignment is required.
- Follow existing style: single quotes and semicolons.
- Hooks must fail safely; avoid breaking CLI UX on non-critical errors.

## 5) Cursor/Copilot Rule Files

Checked in this repository:

- `.cursorrules`: not present.
- `.cursor/rules/`: not present.
- `.github/copilot-instructions.md`: not present.

Implication: use this file, `README.md`, and established code patterns as primary guidance.

## 6) Change Discipline for Agents

- Make minimal, targeted edits.
- Do not refactor unrelated files in focused tasks.
- Reuse helpers instead of duplicating logic.
- Run syntax/smoke checks for touched scripts.
- For auth/recovery changes, run at least one command-level smoke check.
- Update CHANGELOG.md for user-facing changes (see `opencode/rules/changelog-discipline.md` for trigger paths and escape hatch).

## 7) Workflow Learnings (2026-02)

- `/do:compound` is the canonical capture flow for solved-problem knowledge into `knowledge/ai/solutions/`.
- OpenCode auto-compaction does not reliably execute custom `/compact` command pipelines; set `compaction.auto=false` and use explicit `/compact` for deterministic capture.

### Autonomy Reliability (2026-03)

- In weak-spec, low-test, multi-repo work, keep task state in durable files (not only chat context) and block completion on deterministic verification gates.

### Skill Inventory (2026-03)

- All SKILL.md files must include `input`, `output`, `category` frontmatter fields — run `ai-setup-skill-inventory --check` to validate.
- The 10-category taxonomy is: architecture-design, code-quality, documentation, frontend, git, integration, language-specific, project-knowledge, skill-authoring, task-management.
- When creating new skills, derive `input`/`output` from the skill's actual behavior, not guesses. Keep each to 1-2 sentences.
- `ai-setup-skill-inventory --generate` regenerates `~/.config/opencode/skills/skill-inventory.md` — runs automatically during `bootstrap --update`.

### Agentic Pipeline Reliability (2026-03)

- Eight concrete practices for reliable AI pipelines are encoded in `opencode/rules/agentic-pipeline-reliability.md` — read it before designing agents, skills, or multi-step bootstrap phases.
- Key invariants: durable step execution (marker files), sequential pipelines over LLM routing, hard verification gates (`ai-setup-doctor --json`), separate critic agents, HITL checkpoints before destructive actions, two-tier memory (`/do:compound` + `knowledge/ai/`), tool idempotency, and lockfile-based concurrency control.
- Practices 1-4 are enforced via dedicated rules: `durable-step-execution.md` (marker files in `.state/`), `sequential-pipelines.md` (canonical step ordering), Pipeline Stage Gates in the Quality Gates table above (hard verification), and `critic-separation.md` (generator-critic separation). Shared shell helpers: `step_done()`, `mark_done()`, `clear_markers()` in `scripts/lib.zsh`.

## Landing the Plane (Session Completion)

**When ending a work session**, follow these steps to leave the repo in a clean state.

A task is **done** when all related changes are committed and `git status` shows nothing pending — no unstaged edits, no untracked files from your work, no forgotten stashes.

### Commit Policy (MANDATORY — NO EXCEPTIONS)

**Always commit when work is complete. Never ask. Never say "ready to commit if you'd like".** Committing is part of completing the task, not an optional extra step.

- After every completed task: `git add -A && git commit -m "<message>"`
- After every commit: `git pull --rebase && git push`
- If push fails: resolve and retry. If unresolvable, note it in the handoff.
- Do NOT wait for the user to say "commit" — just do it.

**Recommended workflow:**

1. **File issues for remaining work** — create issues for anything that needs follow-up.
2. **Run quality gates** (if code changed) — tests, linters, builds.
3. **Update issue status** — close finished work, update in-progress items.
4. **Update CHANGELOG.md** — if any user-facing files were modified (see `opencode/rules/changelog-discipline.md` for trigger paths), add an entry under `## [Unreleased]` with the appropriate subsection (`### Added`, `### Changed`, `### Fixed`, or `### Removed`). If no user-facing change, include `changelog: none (<reason>)` in the commit message body.
5. **Commit all changes** — stage and commit everything related to your work:

   ```bash
   git add -A
   git commit -m "<concise message>"
   git status  # Should show clean working tree — nothing pending
   ```

6. **Push to remote** — always push immediately after committing:

   ```bash
   git pull --rebase
   git push
   ```

7. **Clean up** — clear stashes, prune remote branches.
8. **Hand off** — provide context for next session.

**Guidelines:**

- When debugging and analyzing problems, you are also granted READ ONLY access to ~/.config/opencode and ~/.cache/opencode.
- If push fails, try to resolve and retry. If it cannot be resolved, note it in the handoff.
