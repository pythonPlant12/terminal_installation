---
name: do-verify
description: >-
  Verify correctness of all changes relative to a base branch or commit by dispatching
  appropriate quality gates and agent-driven checks based on which file types changed.
  Classifies changed files, runs syntax gates, behavioral smoke checks, and dispatches
  deep safety skills in parallel. Produces a consolidated pass/fail report.
  Use when preparing to commit, before merging, or when the user asks to verify local changes.
  Triggers on /do:verify, "verify changes", "run quality gates", "check my changes".
argument-hint: "[base-ref (default: main)] [--goal-artifact <path>] [--no-recurse]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash
  - Task
  - Question
input: Changed files relative to a base branch/commit (auto-detected from git or explicitly provided via base ref argument)
output: Consolidated pass/fail verification report with syntax gates, behavioral checks, and deep safety audit results
category: code-quality
---

# do-verify Skill

Verify correctness of all changes relative to a base branch or commit. Dispatches appropriate quality gates and deep safety skills based on changed file types, then produces a consolidated pass/fail report.

## Overview

**Why verify?** No pre-commit hooks exist in this repo. This skill fills the gap by running all applicable quality gates before you commit or merge.

**What this skill does:**

1. Detects changed files relative to a base ref (default: `main`)
2. Runs deterministic syntax + behavioral gates via a shell script
3. Dispatches deep safety skills as parallel subagent tasks based on file classification
4. Assembles a consolidated report with per-gate pass/fail and exact command output

---

## Execution: Four-Phase Orchestration

### Phase 0: Sub-Repository Detection

Run the sub-repo detection script from repo root:

```bash
./opencode/skills/do-verify/scripts/detect_subrepos.zsh
```

The script scans up to 3 directory levels deep for folders and symlinks that are independent git repositories. A directory qualifies as a sub-repo only when its own `git rev-parse --show-toplevel` returns *itself* — this correctly excludes plain subdirectories of the enclosing repo.

For each sub-repo, the script detects the **default branch** without assuming a name, trying in order:
1. `refs/remotes/origin/HEAD` symbolic ref — fast, offline
2. `git config --get init.defaultBranch` — local/global config, offline
3. `git remote show origin` — network fallback

**Parse the output line by line.** Each line is colon-delimited:

| Status prefix | Meaning | Action |
|---|---|---|
| `NON_DEFAULT` | Current branch differs from detected default | Dispatch parallel verification task |
| `UNKNOWN_DEFAULT` | Cannot determine default branch | Log warning in report; skip verification |
| `ON_DEFAULT` | Sub-repo is on its default branch | No action needed |

**For each `NON_DEFAULT` line** (`NON_DEFAULT:<abs-path>:<current-branch>:<default-branch>`), fire a background verification task:

```
task(
  category="quick",
  run_in_background=true,
  description="Recursive verify: <relative-path-from-repo-root>",
  prompt="
    TASK: Verify changed files in the git sub-repository at '<abs-path>'.

    CONTEXT:
    - Sub-repo absolute path: <abs-path>
    - Current branch: <current-branch>
    - Default branch: <default-branch>
    - The current branch is NOT the default branch — verify all changes relative to it.

    STEPS:
    1. Collect changed files (deduplicate; keep only files that exist on disk):
       - git -C '<abs-path>' diff --name-only '<default-branch>'...HEAD 2>/dev/null
       - git -C '<abs-path>' diff --name-only --cached 2>/dev/null
       - git -C '<abs-path>' diff --name-only 2>/dev/null

    2. For each changed file, run the appropriate syntax gate:
       - *.zsh          → zsh -n '<abs-path>/<file>'
       - *.sh / *.bash  → bash -n '<abs-path>/<file>'
       - *.js           → node --check '<abs-path>/<file>'
       - *.json         → node -e \"JSON.parse(require('fs').readFileSync('<abs-path>/<file>','utf8'))\"
       - *.jsonc        → strip // comments and trailing commas, then JSON.parse
       - Other types    → no gate (skip)

    3. Report results:
       - List all changed files
       - Per-gate: PASS/FAIL with exact command and full stdout/stderr output
       - Verdict: PASS/FAIL (N/M gates passed)

    MUST DO: Run every applicable gate. Report exact exit codes and full output.
    MUST NOT DO: Skip gates. Modify any files. Make fixes.
  "
)
```

Save all background task handles. Collect results in Phase 3.

**If no `NON_DEFAULT` sub-repos are found**, skip Phase 0 dispatch and proceed directly to Phase 1.

---

### Phase 1: Deterministic Gates (Shell Script)

Run the gate runner script from repo root. Pass the base ref from `$ARGUMENTS` (default to `main` if empty).
If `--goal-artifact <path>` is provided, include it to activate deterministic goal-backward validation against the original ticket/task artifact.
The artifact path must resolve inside the current repository root:

```bash
base_ref="main"
goal_artifact=""

if [[ -n "${ARGUMENTS:-}" ]]; then
  # First non-flag token can be base ref (for backward compatibility)
  if [[ "${ARGUMENTS%% *}" != --* ]]; then
    base_ref="${ARGUMENTS%% *}"
  fi

  # Optional explicit goal artifact flag
  if [[ "$ARGUMENTS" == *"--goal-artifact"* ]]; then
    goal_artifact="$(printf '%s' "$ARGUMENTS" | sed -n 's/.*--goal-artifact[[:space:]]\([^[:space:]]\+\).*/\1/p')"
  fi
fi

if [[ -n "$goal_artifact" ]]; then
  ./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base "$base_ref" --goal-artifact "$goal_artifact"
else
  ./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base "$base_ref"
fi
```

**The script handles:**
- File detection via `git diff --name-only $base_ref...HEAD` (plus staged/unstaged/untracked)
- File classification into areas (atlassian, backup-recovery, bootstrap-core, opencode-config, shell-scripts, js-hooks, skill-files, general)
- Syntax gates: `zsh -n`, `bash -n`, `node --check`, JSONC parse validation
- Behavioral smoke checks: `opencode-atlassian-status`, `ai-setup-snapshot --list`, `ai-setup-doctor --json`
- Optional goal-backward gate: `verify_goal_artifact.py` requires all checklist items in artifact Acceptance Criteria to be checked
- Outputs a Markdown report AND a classification summary block at the end

**Capture the full script output.** Do NOT summarize — keep exact stdout/stderr for each gate.

Parse the `## Classification Summary` section at the end of the script output. It lists which file categories have changes — use this to determine which Phase 2 skills to dispatch.

---

### Phase 2: Deep Safety Skills (Parallel Agent Dispatch)

Based on the classification summary from Phase 1, dispatch applicable deep safety skills **in parallel** using `task()`.

<critical_requirement>
Only dispatch skills that match changed file categories. Do NOT dispatch all skills unconditionally.
Each subagent receives the list of changed files relevant to its domain.
</critical_requirement>

#### Dispatch Table

| Classification | Skill to Dispatch | Condition |
|---|---|---|
| `has_shell=true` | `pre-merge-shell-checklist` | Any `*.zsh`, `*.sh`, `*.bash`, `bin/*`, `scripts/*` changed |
| `has_phases=true` | `phase-contract-checklist` | Any `scripts/phases/*.zsh` changed |
| `has_config=true` | `contract-map` | `opencode/opencode.jsonc` or `.contract-map/*` changed |
| `has_bootstrap=true` | `bootstrap-parity-scorecard` | `bootstrap.zsh`, `scripts/bootstrap.zsh`, or `scripts/phases/*.zsh` changed |

#### Dispatch Pattern

For each applicable skill, fire a background task:

```
task(
  category="quick",
  load_skills=["<skill-name>"],
  run_in_background=true,
  description="Deep safety: <skill-name>",
  prompt="
    TASK: Run the <skill-name> skill against these changed files.
    CONTEXT: Base ref is <base_ref>. Changed files in this category: <file list>
    EXPECTED OUTCOME: Pass/fail report for each check in the skill's checklist.
    MUST DO: Run every check in the skill. Report exact findings.
    MUST NOT DO: Skip checks. Modify any files. Make fixes.
  "
)
```

Collect all background task results before proceeding to Phase 3.

**If no deep safety skills apply** (e.g., only docs changed), skip Phase 2 entirely.

---

### Phase 3: Consolidate and Report

Assemble the final verification report by merging:

1. **Phase 1 output** — syntax gates and behavioral smoke checks (verbatim from script)
2. **Phase 2 results** — deep safety skill findings (summarized per skill)

#### Final Report Format

```markdown
# Verification Report

**Base ref:** <base_ref>
**Changed files:** <count>
**Verification time:** <timestamp>

## Phase 1: Syntax & Behavioral Gates

<paste Phase 1 script output here verbatim>

## Phase 2: Deep Safety Audits

### pre-merge-shell-checklist: PASS/FAIL
<summary of findings>

### phase-contract-checklist: PASS/FAIL
<summary of findings>

### contract-map: PASS/FAIL
<summary of findings>

### bootstrap-parity-scorecard: PASS/FAIL
<summary of findings>

## Phase 0: Sub-Repository Checks

### <relative-path> (<current-branch> → default: <default-branch>): PASS/FAIL
<summary of changed files and gate results per sub-repo>

### Skipped (UNKNOWN_DEFAULT)
- `<path>` — Could not determine default branch; verification skipped.

*(Omit this section entirely if Phase 0 found no non-default sub-repos.)*


## Overall Verdict

**PASS** — All <N> gates passed.
or
**FAIL** — <N> of <M> gates failed. See details above.

### Goal-Backward Gate (when provided)

- If `--goal-artifact <path>` is supplied and the artifact gate fails, overall verdict MUST be FAIL.
- Artifact gate is deterministic: it checks that the artifact contains an Acceptance Criteria-style checklist and no unchecked items remain.
```

#### Verdict Rules

- If ANY Phase 1 gate failed → overall FAIL
- If ANY Phase 2 skill reported a FAIL → overall FAIL
- If all gates and skills pass → overall PASS
- If Phase 2 was skipped (no applicable skills) → verdict based on Phase 1 only
- If ANY sub-repo verification task returned FAIL → overall FAIL
- If a sub-repo had UNKNOWN_DEFAULT → note as WARN in report (not FAIL)
- If Phase 0 was skipped (no non-default sub-repos found) → verdict based on Phase 1 + 2 only

---

## Edge Cases

- **No changed files detected**: Report "No changes detected relative to <base_ref>. Nothing to verify." and exit cleanly.
- **Base ref doesn't exist**: The script will error. Report the error and suggest the user provide a valid base ref.
- **Behavioral gate fails due to missing credentials**: Mark as WARN (not FAIL) if the failure is auth-related (e.g., Atlassian token expired). Note: "Auth-related — not a code quality issue."
- **Deep safety skill times out**: Mark as INCONCLUSIVE and note the timeout. Do not block the overall report.
- **Sub-repo in UNKNOWN_DEFAULT state**: Cannot determine default branch (no remote, no config). Mark as WARN in report; do not fail the overall verdict. Note: "Default branch indeterminate — verification skipped for this sub-repo."
- **Sub-repo in detached HEAD state**: Skipped automatically by `detect_subrepos.zsh` (detached HEAD returns literal `HEAD` from `rev-parse --abbrev-ref`). Not reported in the verification output.
- **Deeply nested repos (beyond maxdepth 3)**: Not scanned by design — prevents runaway traversal into `node_modules` and similar deep trees.
- **Symlink pointing to an already-scanned repo**: The `pwd -P` canonicalization in `detect_subrepos.zsh` deduplicates these — each physical repo path is only reported once.

---

## Integration

- **Before committing**: Run `/do:verify` to catch issues before they enter history
- **Before merging**: Run `/do:verify origin/main` to verify against the merge target
- **In PR review**: Complements `/do:review` — verify runs gates, review runs code review agents
- **After refactoring**: Run `/do:verify` to ensure no regressions

### Pipeline Stage Gate (Practice 3)

`do-verify` serves as the **Execute → Verify** gate in sequential pipelines for both GSD and OmO surfaces (see `opencode/rules/sequential-pipelines.md`).

When used as a pipeline stage gate:

1. **Precondition**: The execute step must have completed (check marker via `step_done`)
2. **Gate run**: `./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base main`
3. **Post-gate**: If PASS, mark the verify step as done (`mark_done`). If FAIL, block pipeline progression.

```zsh
# Example: wiring do-verify as a pipeline stage gate
if ! step_done "gsd" "execute" "$phase"; then
  die "Cannot verify: execute step not complete for phase $phase"
fi

# Run verification
./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base main

# Only mark done if gate passed (exit 0)
mark_done "gsd" "verify" "$phase"
```

This ensures the pipeline cannot proceed to capture/completion without a deterministic pass from the verification gate.

```zsh
# Example: wiring do-verify as an OmO pipeline stage gate
if ! step_done "omo" "execute" "$plan_id"; then
  die "Cannot verify: execute step not complete for OmO plan $plan_id"
fi

./opencode/skills/do-verify/scripts/run_verify_gates.zsh --base main
mark_done "omo" "verify" "$plan_id"
```

In combined workflows, `/gsd-verify-work` remains the human-facing behavior/UAT step while `/do:verify` is the deterministic code-quality gate.
