---
type: prompt
description: Refine a JIRA ticket
argument-hint: <ISSUE_KEY>
tools:
  read: true
  write: true
  task: true
  question: true
disable-model-invocation: true
author: Marc Schaerer <https://github.com/dreamora>
---

<objective>
Refine a Jira issue into one Jira-ready markdown description block and save it to `./<ISSUE_KEY>.md`.
</objective>

<context>
Arguments: `$ARGUMENTS`

- Accept exactly one argument: `<ISSUE_KEY>` or `<ISSUE_KEY>.md`

Examples:

- `/refine-jira-ticket ENG-157`
- `/refine-jira-ticket ENG-157.md`
  </context>

<rules>
- Use Atlassian MCP Jira tools only.
- Do not update Jira.
- Use subagent `gsd-project-researcher` for analysis and drafting.
- Output must be concise, actionable, and relevant.
- Do not include telemetry or observability content.
- Do not repeat information across sections.
</rules>

<issue_type_template_map>

- `Epic` -> `Epic`
- `Story` -> `Story`
- `Task` -> `Task`
- `Sub-task` or `Subtask` -> `Sub-Task`
- `Bug` -> `Bug`
- `Spike` -> `Spike`

Normalization:

- Match case-insensitively; default to `Task` if unmapped.
  </issue_type_template_map>

<templates>
## Epic

# Goal

- What are we trying to achieve?

# Business Value

- Why does this matter?

# Scope

- What is included?
- What is explicitly NOT included?

# Success Metrics

- How do we know it’s done?

# Dependencies

- Other teams, tools, or services.

# Useful Resources

- Links, research, designs, docs.

## Story

# User Story

As a <type of user>
I want <capability>
So that <benefit>

# Acceptance Criteria

- [ ]

# Notes

# Useful Resources

## Task

# Objective

What needs to be done?

# Context

Why is this needed?

# Scope

- What is included?
- What is explicitly NOT included?

# Technical Details

- Tools, versions, constraints.

# Notes

...

# Useful Resources

- Figma, specs, API docs.

## Sub-Task

# Task Details

What exactly needs to be done?

# Parent Story

Link automatically via Jira.

# Technical Notes

- Libraries, endpoints, constraints.

# Checklist

- [ ] Implement
- [ ] Test
- [ ] Review

## Bug

# Environment

All the technical details need to be able to reproduce the issue
For example:

- Prod / Staging / Dev
- Browser / OS / Version

# Steps to Reproduce

1.
2.
3.

# Expected Result

What should happen?

# Actual Result

What actually happens?

# Attachments

Screenshots, logs, videos.

## Spike

# Question / Problem

What are we trying to learn or decide?

# Timebox

Maximum time allowed (e.g., 8 hours)

# Success Criteria

What output is expected?

- Recommendation?
- Feasibility?
- Estimate?

# Approach

Links, tools, experiments planned.

# Deliverables

- Summary of findings
- Pros / Cons
- Suggested next step
  </templates>

<error_policy>

- If Jira MCP returns one of these patterns, treat it as binary attachment decoding failure:
  - `Invalid file data`
  - `input[...].output[...].file_data`
  - `unsupported MIME type 'application/octet-stream'`
- Retry once in text-only mode (no attachment download calls).
- Keep attachment metadata only; skip binary attachment content.
- If retry fails, stop and report Jira retrieval failure.
  </error_policy>

<process>
1. Parse input
   - Read first token from `$ARGUMENTS` as `raw_issue_input`.
   - Require exactly one argument.
   - Strip trailing `.md` (case-insensitive) to produce `source_issue_key`.
   - Validate `source_issue_key` with `^[A-Z][A-Z0-9]+-[0-9]+$`.

1. Fetch Jira context
   - Fetch source issue with fields: `summary,description,status,issuetype,priority,labels,components,assignee,reporter,parent,subtasks,issuelinks,fixVersions,created,updated`.
   - Include comments (up to 50) and changelog when available.
   - Fetch parent/epic when present.
   - Fetch only directly relevant linked issues/subtasks.
   - Do not download binary attachments.

2. Handle MCP MIME errors
   - Apply `<error_policy>` when matching errors occur.

3. Select template
   - Map `issuetype.name` via `<issue_type_template_map>`.

4. Delegate analysis/drafting
   - Invoke Task with `subagent_type: "gsd-project-researcher"`.
   - Provide source issue payload, selected template skeleton, and attachment handling status.
   - Require exactly one output section: `Jira Ticket Block`.
   - Require these details embedded directly in template sections:
     - Problem and intended outcome
     - Scope (in/out)
     - Recommended approach plus one alternative with trade-offs
     - Impacted components and API/data changes
     - Risks and mitigations
     - Validation plan tied to acceptance criteria
     - Unknowns as `TBD` inline

5. Quality gate
   - Accept only one markdown block.
   - Ensure content is concise, actionable, non-duplicative.

6. Persist
   - Write only `Jira Ticket Block` to `./<source_issue_key>.md`.
   - Overwrite if exists.
   - Retry once on write failure.

7. Verify
   - Read `./<source_issue_key>.md`.
   - Confirm it is non-empty and contains a single Jira-ready markdown block.

8. Final deliverables
   - `Jira Ticket Block`
   - `Saved File`: `./<source_issue_key>.md`
     </process>
