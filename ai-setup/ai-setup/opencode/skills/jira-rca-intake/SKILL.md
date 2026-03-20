---
name: jira-rca-intake
description: Gather RCA-ready Jira context (issue data, comments, changelog, linked issues, and image attachment evidence). Use when starting root-cause analysis from a Jira issue key.
argument-hint: <ISSUE_KEY>
input: Jira issue key (e.g., ENG-123)
output: RCA evidence pack with issue data, comments, changelog, linked issues, and image attachments
category: task-management
---

# Jira RCA Intake

## Goal
Build one evidence pack from Jira before code investigation.

## Input
- Jira issue key (`ENG-123` or `ENG-123.md`)

## Workflow
1. Normalize input by stripping trailing `.md`, then validate issue key format.
2. Fetch issue fields: `summary,description,status,issuetype,priority,labels,components,assignee,reporter,parent,subtasks,issuelinks,fixVersions,attachment,created,updated`.
3. Fetch comments (limit 50) and changelog.
4. Fetch directly relevant parent/epic and linked issues.
5. Process image attachments (`png`, `jpg`, `jpeg`, `webp`, `gif`):
   - Download and read image content.
   - Extract browser-log evidence (errors, stack traces, request failures, timestamps, environment signals).
   - Keep extracted text plus attachment metadata.
6. Handle attachment decode failures:
   - Match: `Invalid file data`, `input[...].output[...].file_data`, `unsupported MIME type 'application/octet-stream'`.
   - Retry once in text-only mode.
   - If image evidence remains unreadable, ask user for missing log/trace text and stop.

## Output
Return one block named `Jira RCA Intake Pack` with:
- Issue snapshot
- Reproduction evidence
- Extracted attachment evidence
- Relevant linked/parent context
- Blocking data gaps (if any)

## Quality Bar
- Evidence only; no assumptions
- Concise and actionable
- No telemetry/observability additions
