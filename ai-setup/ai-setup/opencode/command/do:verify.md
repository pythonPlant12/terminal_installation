---
description: Verify correctness of all changes relative to a base branch/commit using targeted quality gates and deep safety skills dispatched by file type. Optionally enforce goal-backward completion against a ticket/task artifact checklist.
argument-hint: "[base-ref (default: main)] [--goal-artifact <repo-path>]"
tools:
  read: true
  bash: true
  task: true
  question: true
---

<skills>
- Load skill `do-verify` and execute it fully, passing `$ARGUMENTS` through (base ref plus optional `--goal-artifact`).
</skills>
