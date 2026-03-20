---
type: prompt
description: Root cause analysis for a JIRA ticket
argument-hint: <ISSUE_KEY>
tools:
  read: true
  write: true
  question: true
model: openai/gpt-5.3-codex
small_model: github-copilot/claude-haiku-4.5
reasoningEffort: high
textVerbosity: low
author: Marc Schaerer <https://github.com/dreamora>
---

<objective>
Use a Jira issue as input context, perform in-depth codebase root cause analysis, and produce one Jira-ready markdown block saved to `./<ISSUE_KEY>-root-cause-analysis.md`.
</objective>

<context>
Arguments: `$ARGUMENTS`

- Accept exactly one argument: `<ISSUE_KEY>` or `<ISSUE_KEY>.md`
- Example: `/root-cause-analysis ENG-157`
</context>

<rules>
- Use Jira issue data as starting context; analysis must be grounded in repository code and tests.
- Do not update Jira.
- Run in Orchestrator mode.
- Cover all relevant repositories/subdirectories for the issue. For ENG-366 class issues this explicitly includes: `./airconsole-unity-android-plugin`, `./airconsole-unity-plugin`, `./airconsole-api`, `./airconsole-appengine`, `./airconsole-player`.
- You may spawn multiple small-model research agents in parallel for quick high-level mapping, but final conclusions must be synthesized and verified by direct code reads in Orchestrator.
- Before conclusions, read applicable `AGENTS.md` files and any `compound-engineering.local.md` context files in covered repositories.
- Output exactly one markdown block named `Root Cause Analysis Block`.
- Keep output concise, actionable, non-duplicative, and without telemetry/observability content.
- No assumptions: every non-trivial claim must include a verifiable reference in `(ref: path:line)` format.
</rules>

<skills>
- Load skill `jira-rca-intake` for Jira context + attachment evidence gathering.
- Load skill `deep-root-cause-analysis` for in-depth code/test RCA and final block structure.
</skills>

<attachment_policy>
- If image attachments exist (`png`, `jpg`, `jpeg`, `webp`, `gif`), download and process them for technical evidence.
- Extract browser log text, stack traces, request/response errors, timestamps, and environment details when visible.
- If image evidence cannot be read, ask the user for missing evidence before RCA and stop.
</attachment_policy>

<error_policy>
- Treat these as attachment decode failures:
  - `Invalid file data`
  - `input[...].output[...].file_data`
  - `unsupported MIME type 'application/octet-stream'`
- Retry once in text-only mode.
- If image evidence is still unreadable, ask the user for:
  - console log text
  - stack trace text
  - screenshot transcription of key errors
  - reproduction timestamp/environment
- Do not proceed with RCA until this is provided.
</error_policy>

<process>
1. Parse input
   - Read exactly one token from `$ARGUMENTS` as `raw_issue_input`.
   - Strip trailing `.md` (case-insensitive) to get `source_issue_key`.
   - Validate `source_issue_key` against `^[A-Z][A-Z0-9]+-[0-9]+$`.

2. Fetch Jira context
   - Apply `jira-rca-intake` skill workflow.
   - Fetch issue fields: `summary,description,status,issuetype,priority,labels,components,assignee,reporter,parent,subtasks,issuelinks,fixVersions,attachment,created,updated`.
   - Include comments (limit 50) and changelog when available.
   - Fetch directly relevant parent/epic and linked issues only.

3. Search institutional knowledge (MANDATORY)
   - Extract keywords from the Jira issue: module names, component types, error symptoms, technical terms.
   - Invoke `learnings-researcher` with these keywords: `Task learnings-researcher("<summary + key symptoms>")`
   - Review results before proceeding — if relevant past solutions exist, incorporate them into the RCA hypothesis before code investigation.
   - Explicit "no matches" is a valid outcome; document it in `# Open Questions`.

4. Process image attachments
   - Identify image attachments from metadata.
   - Download and process image evidence.
   - If image processing fails, apply `<error_policy>`, ask the user, and stop.

5. Perform in-depth RCA in Orchestrator
   - Apply `deep-root-cause-analysis` skill workflow.
   - First run a high-level parallel reconnaissance across all relevant repos/subdirectories (small-model agents allowed), then verify each critical claim with direct code/test reads.
   - Explicitly include cross-repo handoff boundaries (producer -> bridge -> persistence -> consumer).
   - Research relevant implementation and test code paths before conclusions.
   - Correlate Jira evidence with code/test behavior.
   - Produce one `Root Cause Analysis Block` with sections in this exact order:
     - `# Problem Summary`
     - `# Root Cause`
     - `# Evidence`
     - `# Proposed Technical Solution`
     - `# Tests to Add`
     - `# Regression Tests to Add`
     - `# Alternatives Considered`
     - `# Open Questions`
   - `Tests to Add` and `Regression Tests to Add` must list concrete cases: target, scenario, assertion, and file to add/update.
   - `Alternatives Considered` must include 1-3 options with concise trade-offs.

6. Quality gate
   - Reject output if claims lack code/test refs, sections are duplicated, alternatives are not 1-3, or tests are not concrete.

7. Persist output
   - Write only `Root Cause Analysis Block` to `./<source_issue_key>-root-cause-analysis.md`.
   - Overwrite if exists.
   - Retry write once on failure.

8. Verify
   - Read the file and confirm it exists, is non-empty, and contains exactly one block.

9. Deliverables
   - `Root Cause Analysis Block`
   - Saved file: `./<source_issue_key>-root-cause-analysis.md`
</process>
