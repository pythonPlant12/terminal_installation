---
name: deep-root-cause-analysis
description: Perform in-depth root cause analysis using Jira intake evidence plus repository code/tests. Use after Jira intake is complete.
input: Jira RCA intake evidence pack plus access to repository code and tests
output: Root cause analysis block with verifiable code and test references
category: task-management
---

# Deep Root Cause Analysis

## Goal
Produce one `Root Cause Analysis Block` grounded in verifiable code and test references.

## Prerequisite
- `Jira RCA Intake Pack` is available and not missing critical evidence.
- If intake has unresolved evidence gaps, ask user for missing data before analysis.

## Workflow
1. Map symptoms and evidence to candidate code paths.
2. Inspect implementation and tests to confirm actual behavior.
3. Isolate root cause using code-backed proof.
4. Propose a concrete technical fix.
5. Define specific tests to add.
6. Define specific regression tests to add.
7. Evaluate 1-3 alternatives with concise trade-offs.

## Output
Return exactly one block named `Root Cause Analysis Block` with this order:
1. `# Problem Summary`
2. `# Root Cause`
3. `# Evidence`
4. `# Proposed Technical Solution`
5. `# Tests to Add`
6. `# Regression Tests to Add`
7. `# Alternatives Considered`
8. `# Open Questions`

## Hard Requirements
- Every non-trivial claim must include `(ref: path:line)`.
- No assumptions without code/test evidence.
- `Tests to Add` and `Regression Tests to Add` must include: target, scenario, assertion, and file to add/update.
- `Alternatives Considered` must contain 1-3 options only.
- Keep output concise, actionable, and non-duplicative.
- No telemetry/observability additions.
