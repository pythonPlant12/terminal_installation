---
id: "XXXX"
status: pending
priority: p2
type: bug
agent_ready: false
parent: null
children: []
blocks: []
blocked_by: []
tags: []
effort: null
assigned_to: null
context_files: []
verified_by: null
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
---

# Brief Task Title

One sentence: what needs to happen and why it matters.

## Problem Statement

What is broken, missing, or needs improvement? State the impact.

Provide concrete evidence:
- Error message (verbatim, with stack trace if applicable)
- File path + line number where the issue originates
- Reproduction command or steps

**Example:**
> `UserService#find_by_email` at `app/services/user_service.rb:34` raises
> `NoMethodError: undefined method 'downcase' for nil:NilClass` when `email` is nil.
> Reproduction: `UserService.find_by_email(nil)` in rails console.

## Root Cause / Background

What investigation has already been done? What does the agent need to understand before touching anything?

- Root cause with file:line references
- Why the problem exists (design decision, missing guard, etc.)
- What the correct behavior should be and why

## Proposed Approach

The recommended path to resolution. Be specific about what changes, where, and why.

If genuinely uncertain between approaches, list them:

### Option A: [Name]
**Change:** What exactly changes (file, line, code)
**Pros:** …
**Cons:** …
**Effort:** xs / s / m

### Option B: [Name]
**Change:** …
**Pros:** …
**Cons:** …
**Effort:** …

**Recommendation:** Option A — [one-sentence rationale]

## Out of Scope

Explicitly state what should NOT be changed, even if it seems related:

- Do NOT touch `app/middleware/session.rb`
- Do NOT change the public interface of `UserService`
- Do NOT refactor other methods in the same file

## Acceptance Criteria

Each criterion must be a command to run or an observable state to verify.

- [ ] `bundle exec rails test test/services/user_service_test.rb` exits 0
- [ ] `UserService.find_by_email(nil)` returns `nil` (not raises)
- [ ] `UserService.find_by_email("")` returns `nil` (not raises)
- [ ] Add test case to `test/services/user_service_test.rb` asserting nil-email returns nil
- [ ] No new test failures introduced

## Technical Details

Affected files (with line numbers), related components, DB changes.

**Affected files:**
- `app/services/user_service.rb:34` — primary change location
- `test/services/user_service_test.rb` — add test case here

**Related components:**
- `AuthController` calls `UserService.find_by_email` (don't break callers)

**Database changes:**
- None

## Resources

- PR: #
- Related issue / task: #
- Error log / APM link:
- Documentation:

## Work Log

### YYYY-MM-DD — Initial Investigation

**By:** Claude Code / Developer Name

**Actions:**
- Identified root cause at `app/services/user_service.rb:34`
- Confirmed reproduction steps
- Drafted fix approach

**Learnings:**
- Key insight 1
- Key insight 2

---

*(Add more entries as work progresses)*

## Notes

Additional context, decisions, or reminders that don't fit above sections.
