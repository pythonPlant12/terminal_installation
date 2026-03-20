---
name: minimal-targeted-gates
description: Auto-select and run a minimal, targeted quality gate set for changed files in airconsole-ai-setup, including shell syntax validation plus one behavior smoke check per changed area. Use when the user asks for focused validation of local changes with exact command outputs and pass/fail reporting.
input: Changed files in airconsole-ai-setup (auto-detected from git or explicitly provided)
output: Pass/fail gate report with exact command outputs for shell syntax validation and behavior smoke checks
category: code-quality
---

# Minimal Targeted Gates

Run a deterministic local gate pass for current changes and return exact command output in a paste-ready report.

## Workflow

1. Run from repo root:
   - `./opencode/skills/minimal-targeted-gates/scripts/run_targeted_gates.zsh`
2. Optionally scope to specific files:
   - `./opencode/skills/minimal-targeted-gates/scripts/run_targeted_gates.zsh scripts/phases/08-atlassian-login.zsh bin/opencode-atlassian-login`
3. Post the script output directly in the response.
4. Do not summarize away command output; keep exact stdout/stderr for each gate.

## Selection Rules

- Detect changed files from git when no file arguments are provided, limited to repo operational surfaces (`bootstrap.zsh`, `scripts/`, `bin/`, `opencode/`, `Brewfile`, `mise.toml`).
- Select syntax gates from changed files:
  - `*.zsh` -> `zsh -n <file>`
  - `*.sh` -> `bash -n <file>`
  - `bin/*` with shell shebang -> matching shell `-n`
  - `*.js` -> `node --check <file>`
- Enforce at least one shell syntax gate per changed area by adding one default shell syntax check when needed.
- Select one behavior smoke command per changed area:
  - `atlassian` -> `bin/opencode-atlassian-status`
  - `backup-recovery` -> `bin/ai-setup-snapshot --list`
  - `bootstrap-core`, `opencode-config`, `general` -> `bin/ai-setup-doctor --json`

## Output Contract

The script emits a Markdown report with:
- Changed files
- Selected syntax and behavior commands
- Per-command `PASS`/`FAIL`
- Exact command output in fenced code blocks
- Overall result and non-zero exit on failures
