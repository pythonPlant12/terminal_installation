# Agentic Pipeline Reliability — Design Principles

**Status**: AUTHORITATIVE for agent and pipeline design decisions

**Last Updated**: 2026-03-08

**Source**: External research synthesis (2026) — Inngest, Google Cloud, Anthropic, Panaversity, inference.sh

---

## Scope

These principles apply when **designing, extending, or reviewing** agents, skills, bootstrap phases, or multi-step pipelines in this repo. They encode proven patterns from production agentic systems.

---

## Practice 1: Durable Step Execution

**Rule**: Every multi-step pipeline must be restartable from the last completed step, not from scratch.

**In this repo**:
- Bootstrap phases (`scripts/phases/*.zsh`) already embody this: each phase is idempotent and checkpointed.
- Extend this to agent workflows: use marker files or `ai-setup-doctor --json` state as phase-completion sentinels.
- Never design a pipeline where the only recovery from partial failure is "rerun from the beginning and hope."

**Shell idiom**:
```zsh
local marker="${ROOT_DIR}/.state/phase-XX.done"
[[ -f "$marker" ]] && { ok "Phase XX already done, skipping"; return 0; }
# ... do the work ...
touch "$marker"
```

**Canonical reference**: https://inngest.com/blog/your-agent-needs-a-harness-not-a-framework

---

## Practice 2: Sequential Pipelines Over LLM Routing

**Rule**: Use deterministic, ordered steps for known workflows. Reserve LLM-driven routing ONLY for novel/adaptive decisions.

**In this repo**:
- Bootstrap phases run in explicit numbered order — this is correct.
- Agent pipelines (e.g., GSD `plan → execute → verify`) must follow a declared sequence, not let the LLM decide step order.
- If a workflow is well-understood, encode it as a sequential skill (ordered `Step` list), not a free-form agent prompt.

**Anti-pattern**: "Figure out what to do next based on the output" — replace with explicit conditional branches.

**Canonical reference**: https://agentfactory.panaversity.org/docs/Building-Custom-Agents/google-adk-reliable-agents/workflow-agents

---

## Practice 3: Hard Verification Gates (Not Vibe Checks)

**Rule**: Every pipeline stage must have a deterministic pass/fail gate before proceeding. No "looks good" assessments.

**In this repo**:
- The Quality Gates table in `AGENTS.md` is the canonical gate list — use it, extend it, never skip it.
- `ai-setup-doctor --json` is the deterministic gate for bootstrap completion. Parse its output; do not interpret its prose.
- Gate failures must block the pipeline and surface a specific, actionable error message.

**Gate command pattern**:
```bash
result=$(ai-setup-doctor --json)
if ! echo "$result" | jq -e '.status == "ok"' > /dev/null; then
  die "Health check failed — run ai-setup-doctor for details"
fi
```

**Canonical reference**: https://cloud.google.com/blog/topics/developers-practitioners/from-vibe-checks-to-continuous-evaluation-engineering-reliable-ai-agents

---

## Practice 4: Separate Critic / Judge Agents

**Rule**: A generator reviewing its own output is unreliable. Use a dedicated critic or judge for quality verification.

**In this repo**:
- Never have the same agent that wrote code also verify it is correct.
- For code review: use `agent-native-reviewer.md` or `code-simplicity-reviewer.md` as the critic — not the agent that generated the code.
- For skill design: use `skill-curator.md` to audit after `skill-creator.md` generates.
- In `/do:review`, the reviewer is explicitly separate from the author — maintain this pattern in all new commands.

**Anti-pattern**: "Review the code you just wrote and fix any issues."  
**Correct pattern**: Spawn a separate agent/skill with the critic role and the artifact as input.

**Canonical reference**: https://zencoder.ai/blog/multi-agent-verification-the-new-standard-for-ai-code-quality

---

## Practice 5: Human-in-the-Loop at Defined Checkpoints

**Rule**: For destructive or irreversible actions, suspend the pipeline and require explicit human confirmation before proceeding.

**In this repo**:
- Destructive bootstrap actions (e.g., overwriting Keychain entries, deleting snapshots) must prompt before executing.
- The pattern is already established: `warn` + prompt in interactive mode; `die` in non-interactive mode.
- Skills that modify system state should declare HITL checkpoints in their `## Steps` section.

**Shell idiom**:
```zsh
if [[ -t 0 ]]; then
  read -r "confirm?This will overwrite existing config. Continue? [y/N] "
  [[ "${confirm:l}" == "y" ]] || { log "Aborted."; return 0; }
else
  die "Cannot prompt in non-interactive mode — run manually to confirm."
fi
```

**Canonical reference**: https://docs.anthropic.com/en/agent-sdk/user-input

---

## Practice 6: Two-Tier Memory (Within-Run Pruning + Across-Run Compaction)

**Rule**: Manage context at two levels — prune within a session to fit the context window, compact across sessions into durable knowledge.

**In this repo**:
- Within a session: prune verbose tool outputs; summarize phase results into a few key facts.
- Across sessions: capture learnings via `/do:compound` → `knowledge/ai/solutions/`. This IS the compaction layer.
- `knowledge/ai/` must never accumulate transient session state — only crystallized, reusable patterns.
- `AGENTS.md § 7 Workflow Learnings` is the AGENTS.md tier of this two-tier system.

**Do NOT**:
- Commit session-specific scratch notes to `knowledge/ai/`.
- Rely on chat context surviving a session reset; write durable state to files.

**Canonical reference**: https://github.com/inngest/utah (two-tier pruning: `softTrim` + `hardClear`)

---

## Practice 7: Tool Idempotency as a Prerequisite

**Rule**: Every tool, script, or phase must be safe to call multiple times with identical results. This is a prerequisite for durable execution (Practice 1).

**In this repo**:
- This is already the stated policy in `AGENTS.md §  Operating Principles`.
- Concretely: check-before-write, use marker files, use `--no-clobber`, test for existence before creating.
- If a tool cannot be made idempotent, document its non-idempotent behavior explicitly and add a guard.

**Shell idiom**:
```zsh
# Check-before-write
if ! brew list --formula | grep -q "^${package}$"; then
  brew install "$package"
fi

# Marker-based skip
[[ -f "${marker}" ]] && return 0
```

**Canonical reference**: https://inference.sh/blog/agent-runtime/durable-execution

---

## Practice 8: Concurrency Control for Stateful Sessions

**Rule**: For stateful agent sessions keyed on a session ID, enforce singleton concurrency — cancel or queue duplicate runs on the same key.

**In this repo**:
- This applies when multiple invocations of a bootstrap phase or agent could run simultaneously.
- The simplest form: use a lockfile. Never allow two concurrent writers to the same state file.

**Shell idiom**:
```zsh
local lockfile="${ROOT_DIR}/.state/bootstrap.lock"
if ! mkdir "${lockfile}" 2>/dev/null; then
  die "Bootstrap already running (lockfile: ${lockfile}). Remove if stale."
fi
trap "rmdir '${lockfile}'" EXIT
```

**Canonical reference**: https://www.inngest.com/blog/your-agent-needs-a-harness-not-a-framework (singleton concurrency + cancel-on-preempt)

---

## Summary Table

| Practice | Mechanism | Canonical Source | Repo Touchpoint |
|----------|-----------|-----------------|-----------------|
| 1. Durable step execution | Marker files, idempotent phases | Inngest harness | `scripts/phases/*.zsh` |
| 2. Sequential pipelines | Numbered phases, explicit step order | Google ADK | GSD workflow skills |
| 3. Hard verification gates | `ai-setup-doctor --json`, quality gates table | Google Cloud | `AGENTS.md` Quality Gates |
| 4. Separate critic agents | Dedicated reviewer agents | Zencoder | `agents/agent-native-reviewer.md` |
| 5. HITL checkpoints | Interactive prompts before destructive actions | Anthropic Agent SDK | Bootstrap destructive phases |
| 6. Two-tier memory | `/do:compound` + `knowledge/ai/` | Inngest Utah | `knowledge/ai/solutions/` |
| 7. Tool idempotency | Check-before-write, marker files | inference.sh | All `scripts/phases/*.zsh` |
| 8. Concurrency control | Lockfiles for singleton sessions | Inngest harness | Multi-phase bootstrap |
