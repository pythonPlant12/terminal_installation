---
schema_version: 2
module: [Subsystem name]
date: [YYYY-MM-DD]
problem_type: [build_error|workflow_issue|developer_experience|documentation_gap|runtime_error|integration_issue|test_failure|security_issue|performance_issue|best_practice]
component: [bootstrap|phase-script|helper-script|cli-tool|opencode-config|opencode-hook|opencode-agent|opencode-skill|plugin-system|ci-workflow|auth-flow|migration-recovery|knowledge-system|development-workflow|documentation|tooling|shell-script|unknown]
symptoms:
  - [Observable signal 1]
root_cause: [config_error|missing_workflow_step|dependency_ordering|stale_documentation|missing_tooling|incomplete_setup|environment_mismatch|logic_error|integration_contract_drift|permission_gap|test_gap|observability_gap|scope_creep|version_drift|unclear_ownership|unknown_root_cause]
resolution_type: [code_fix|config_change|workflow_improvement|documentation_update|tooling_addition|dependency_update|environment_setup|guardrail_addition|test_fix|rollback]
severity: [critical|high|medium|low]
confidence: [high|medium|low]
summary: [One-sentence action-oriented fix summary]
applies_when:
  - [When this guidance applies]
verification_commands:
  - [Command to confirm fix]
evidence_paths:
  - [repo-relative/path]
tags:
  - [lowercase-tag]
avoid_when:
  - [Counter-signal where this should not be applied]
status: active
related_docs:
  - [workflow-issues/example-note.md]
---

# Troubleshooting: [Clear Problem Title]

## Agent Card

- Use when: [Primary trigger]
- Core fix: [Single decisive move]
- Avoid when: [Counter-signal]
- Verify with: `[command 1]`; `[command 2]`

## Problem

[1 short paragraph on what failed and impact]

## Root Cause

[1 short paragraph identifying the real cause, not symptoms]

## Solution

[Concise explanation of what changed and why]

```bash
[Essential commands only]
```

## Verification

- `[command]` -> [expected outcome]
- `[command]` -> [expected outcome]

## Prevention

- [Guardrail/check 1]
- [Guardrail/check 2]

## Related

- [relative/path/to/related-note.md]
