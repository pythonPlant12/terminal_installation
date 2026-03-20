---
name: pre-merge-shell-checklist
description: Enforce a mandatory pre-merge safety checklist for shell changes. Use when reviewing or preparing a merge that touches shell entrypoints or helpers (`*.sh`, `*.bash`, `*.zsh`, `bin/*`, `scripts/*`) and require explicit pass/fail results for interactive guard coverage, readonly name blacklist compliance, safe arithmetic patterns, and symlink-safe `ROOT_DIR` initialization.
input: Shell files changed in a PR or merge (*.sh, *.bash, *.zsh, bin/*, scripts/*)
output: Pass/fail checklist for interactive guards, readonly blacklist, safe arithmetic, and symlink-safe ROOT_DIR
category: code-quality
---

# Pre-Merge Shell Checklist

Run this skill as a hard merge gate for shell changes. Block merge when any required check fails.

## Required Workflow

1. Identify changed shell files.
2. Run all checks in [references/pre-merge-shell-checklist.md](references/pre-merge-shell-checklist.md).
3. Record each required check as `PASS` or `FAIL` with file paths and line numbers.
4. Return `BLOCK` if any check fails.
5. Suggest minimal remediation snippets for each failure.

## Output Format

Return results with this structure:

1. `Reviewed files`: list of shell files inspected.
2. `Checklist results`: one row per required check with `PASS`/`FAIL` and evidence.
3. `Merge decision`: `APPROVE` only when all checks pass; otherwise `BLOCK`.
4. `Fixes`: minimal code changes for each `FAIL`.

## References

- [Mandatory Pre-Merge Shell Checklist](references/pre-merge-shell-checklist.md)
