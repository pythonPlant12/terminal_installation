# Writing Tasks That AI Agents Can Execute Autonomously

This reference covers the craft of writing tasks that are self-sufficient for agent execution — tasks where the agent never needs to ask a clarifying question.

## The Core Insight

When a human reads "fix the auth bug," they fill in the gaps from memory, Slack context, and shared understanding. When an agent reads it, there are no gaps to fill — the agent either finds the answer in the task, or it halts and asks.

Every missing piece of context is a tax on execution quality. Write tasks that pay the tax upfront.

---

## The Five Requirements Expanded

### 1. Grounded — Every claim cites evidence

Every statement about behavior, location, or impact must include a pointer an agent can verify.

**Not grounded:**
> The user service has a bug where it doesn't handle null emails correctly.

**Grounded:**
> `UserService#find_by_email` at `app/services/user_service.rb:34` calls `.downcase` on the email parameter without a nil guard. Passing `nil` raises `NoMethodError: undefined method 'downcase' for nil:NilClass`. Reproduction: `UserService.find_by_email(nil)`.

The grounded version gives the agent: file path, line number, method name, error message, and a reproduction step. Zero inference required.

---

### 2. Scoped — State what to change AND what not to change

Ambiguous scope is the most common failure mode. Agents will either over-correct (touching things they shouldn't) or under-correct (stopping short of the real fix).

**Unscoped:**
> Clean up the authentication module.

**Scoped:**
> Refactor `AuthMiddleware` in `app/middleware/auth.rb` only. Specifically:
> - Extract the token parsing logic (lines 45–67) into a private method `parse_bearer_token`.
> - Extract the expiry check (lines 89–103) into `token_expired?(token)`.
> - Do NOT change the public interface (`call`, `valid_token?`).
> - Do NOT touch `app/middleware/session.rb` or any controller.
> - Existing tests in `test/middleware/auth_test.rb` must pass without modification.

---

### 3. Verifiable — Acceptance criteria must be commands or observable states

"Works correctly" is not a criterion. "Returns 200 for valid tokens and 401 for expired tokens" is a criterion you can verify with curl.

**Bad criteria:**
- [ ] Login works properly
- [ ] Performance is good
- [ ] Error handling is improved

**Good criteria:**
- [ ] `curl -H "Authorization: Bearer $VALID_TOKEN" localhost:3000/api/me` returns `200 OK`
- [ ] `curl -H "Authorization: Bearer $EXPIRED_TOKEN" localhost:3000/api/me` returns `401 {"error":"token_expired"}`
- [ ] `bundle exec rails test test/middleware/auth_test.rb` exits 0 with 0 failures
- [ ] `GET /users` p95 latency < 200ms measured via `ab -n 100 -c 10 http://localhost:3000/users`

Each criterion is a command an agent can run and a result it can observe. No interpretation needed.

---

### 4. Contextual — List every file the agent must read

An agent starting cold needs a reading list. The `context_files` frontmatter field is that list. Being explicit here saves the agent from either guessing (risky) or doing broad exploration (slow).

**Include in context_files:**
- The primary file being changed
- Files that call into it (to understand impact)
- Test files (to understand expected behavior)
- Config files that affect the behavior
- Related models/schemas if data shapes matter
- Prior implementations for pattern reference

**Example:**
```yaml
context_files:
  - app/middleware/auth.rb           # Primary target
  - app/middleware/session.rb        # Sibling, don't break
  - app/controllers/application_controller.rb  # Calls auth middleware
  - test/middleware/auth_test.rb     # Defines expected behavior
  - config/initializers/jwt.rb       # JWT config and key setup
```

---

### 5. Unambiguous — No sentence admits two interpretations

Read every sentence aloud and ask: "Could this mean two different things?" If yes, rewrite it.

**Ambiguous:**
> Update the error messages to be more helpful.

What does "more helpful" mean? Which messages? Helpful to whom? In what language?

**Unambiguous:**
> Change the English error strings in `app/services/auth_service.rb` (lines 78, 94, 112) from generic HTTP status text to user-actionable messages:
> - `"Unauthorized"` → `"Your session has expired. Please sign in again."`
> - `"Forbidden"` → `"You don't have permission to access this resource."`
> - `"Bad Request"` → `"Invalid authentication token format."`
> Do not change the HTTP status codes or the JSON key names.

---

## Task Types and Their Patterns

Different task types have different failure modes. Know what to include.

### Bug Fix Tasks

Essential sections:
- **Steps to reproduce** — exact commands or UI steps
- **Expected behavior** — what should happen
- **Actual behavior** — what is happening (include error message verbatim)
- **Root cause** — where in the code and why
- **Minimal fix scope** — change only what's broken

Template pattern:
```markdown
**Reproduces with:**
bundle exec rails test test/services/user_service_test.rb:45

**Error:**
NoMethodError: undefined method 'downcase' for nil:NilClass
  app/services/user_service.rb:34:in `find_by_email'

**Root cause:**
Line 34 lacks nil guard before calling `.downcase`.

**Fix:**
Add `return nil if email.nil?` before line 34.
Do not change the return type or error handling for invalid formats.
```

### Feature Tasks

Essential sections:
- **User story** — who needs this and why
- **Exact behavior** — inputs → outputs, with examples
- **API contract** — method signatures, HTTP endpoints, return shapes
- **Edge cases** — what should happen for each, explicitly
- **What not to build** — out-of-scope items that might seem natural to include

### Refactor Tasks

Essential sections:
- **Before state** — current structure (file, lines, method names)
- **After state** — target structure (same granularity)
- **Invariants** — what must not change (public API, test suite, behavior)
- **Mechanical steps** — ordered sequence of atomic moves
- **Validation gate** — tests to run between steps

### Research / Spike Tasks

Essential sections:
- **Question to answer** — the specific decision this unblocks
- **Constraints** — what the answer must be compatible with
- **Output format** — what to produce (ADR, recommendation, PoC, benchmark)
- **Time box** — maximum effort before reporting partial findings
- **Disqualifying conditions** — what would rule out an approach

---

## Decomposition Patterns

When a task is too large to be `agent_ready: true`, decompose it. Here are proven patterns:

### Sequential Decomposition

Each child must complete before the next starts.

```
Parent: Migrate users table to new schema
  Child 1: Write reversible migration (blocked_by: nothing)
  Child 2: Dual-write during transition (blocked_by: [Child 1])
  Child 3: Backfill existing rows (blocked_by: [Child 2])
  Child 4: Remove old columns (blocked_by: [Child 3])
```

### Parallel Decomposition

Children are independent; parent completes when all children do.

```
Parent: Add observability to payment flow
  Child 1: Add metrics to PaymentService (independent)
  Child 2: Add metrics to WebhookService (independent)
  Child 3: Add metrics to ReconciliationJob (independent)
  Child 4: Create Grafana dashboard (blocked_by: [1,2,3])
```

### Layer Decomposition

Split by system layer (data, logic, API, UI).

```
Parent: Add two-factor authentication
  Child 1: DB migration + model (data layer)
  Child 2: TOTP logic + service (domain layer)
  Child 3: API endpoints (interface layer)
  Child 4: UI components (presentation layer)
  Child 5: Integration tests (cross-cutting)
```

### When NOT to Decompose

- Task is already under 4 hours and has clear scope → keep it atomic.
- Decomposition creates artificial boundaries that make testing harder → keep integrated.
- All sub-steps are so tightly coupled they'd always be done in the same session → keep unified.

---

## agent_ready: true Checklist

Before setting `agent_ready: true`, verify:

```
□ Every file mentioned exists and the line numbers are current
□ Reproduction steps run without error (for bugs)
□ Acceptance criteria are commands or observable states
□ context_files lists every file needed (no surprises)
□ Scope has explicit "do not change" statements
□ No pronoun ambiguity ("it", "this", "them" without clear referent)
□ Effort estimate is plausible for the stated scope
□ blocked_by list is accurate (nothing missing)
□ No external decisions required (API keys, env vars exist, product choices made)
```

If any box is unchecked, do not set `agent_ready: true`. Write the missing information first.

---

## Anti-Patterns to Avoid

### The Assumption Grenade

Writing a task assuming the reader has the context you have right now. In 2 weeks, you won't. An agent never will.

Fix: Write as if handing to someone who just joined the project today.

### The Adjective Acceptance Criterion

"The UI should be responsive." "Performance should be acceptable." "Error handling should be robust."

These are aspirations, not criteria. Every acceptance criterion must be falsifiable.

Fix: Replace adjectives with measurements, thresholds, or test commands.

### The Implicit Boundary

Not stating where the task ends. The agent will either stop too early or keep going past the intended scope.

Fix: Write an explicit "Out of scope" or "Do NOT" section listing the natural extensions that should not be done.

### The Stale Pointer

File paths and line numbers that are correct when written but drift as the codebase evolves.

Fix: Always include the function/method name alongside line numbers. When executing, verify the pointer before acting.

### The God Task

A single task that encompasses a whole epic. These are never `agent_ready: true` and create coordination overhead.

Fix: Decompose ruthlessly. A task is correctly scoped if a skilled agent can complete it in one session.

---

## Example: Full Transformation

**Before (human-readable, not agent-ready):**
```
Fix the slow dashboard loading issue. Users have been complaining.
```

**After (agent-ready):**
```markdown
---
id: "0042"
status: ready
priority: p1
type: bug
agent_ready: true
context_files:
  - app/controllers/dashboard_controller.rb
  - app/models/user.rb
  - app/models/post.rb
  - app/views/dashboard/index.html.erb
  - test/controllers/dashboard_controller_test.rb
effort: s
---

# Fix N+1 Query Causing Slow Dashboard Load

## Problem Statement

`GET /dashboard` takes 1.8–2.4 seconds p95 for users with >50 posts.
Customer SLA is 500ms p95. This is causing active churn (3 support tickets in 7 days).

## Root Cause

`DashboardController#index` (line 18) loads `current_user.posts`, then the view
iterates `post.author` for each post, triggering a SELECT per post.

**Reproduction:**
```ruby
# In rails console with a user who has 50+ posts:
require 'benchmark'
user = User.find(1)
Benchmark.measure { user.posts.map(&:author) }
# => ~0.8s with 51 queries
```

**Verified with:**
```
bundle exec rails test test/controllers/dashboard_controller_test.rb
# All passing — no existing N+1 test
```

## Proposed Approach

Add `includes(:author)` to the posts query in `DashboardController#index:18`.

Change line 18 from:
```ruby
@posts = current_user.posts.order(created_at: :desc).limit(20)
```
to:
```ruby
@posts = current_user.posts.includes(:author).order(created_at: :desc).limit(20)
```

Do NOT touch the view or any other controller action.

## Acceptance Criteria

- [ ] `bundle exec rails test test/controllers/dashboard_controller_test.rb` exits 0
- [ ] Add test to `test/controllers/dashboard_controller_test.rb` that asserts
      `GET /dashboard` issues ≤3 SQL queries (use `assert_queries(3)`)
- [ ] Manual verification: `GET /dashboard` for user with 50 posts completes in
      <300ms locally (`curl -o /dev/null -s -w "%{time_total}" http://localhost:3000/dashboard`)

## Work Log

### 2026-02-27 — Investigation

**By:** Claude Code

**Actions:**
- Identified N+1 with `bullet` gem output in development log
- Verified root cause in `DashboardController#index:18`
- Confirmed fix is one-line change

**Learnings:**
- `bullet` gem is configured in development but not test env
- `assert_queries` helper available in `test/test_helper.rb`
```
