# Changelog Discipline

**Status**: AUTHORITATIVE for changelog update enforcement in airconsole-ai-setup

**Last Updated**: 2026-03-06

---

## Scope

This rule applies **ONLY** when working in the `airconsole-ai-setup` repository (origin: `github.com/dreamora/ai-setup`). In other repositories, this rule does not apply.

To verify scope: check `git remote -v` for the origin URL, or verify `bootstrap.zsh` exists at the repo root.

---

## Trigger Paths

### Always-Trigger (any modification, creation, or deletion)

Changes to ANY of these paths require a CHANGELOG entry:

- `bin/*` — user-facing CLI tools
- `bootstrap.zsh` — main entrypoint
- `scripts/bootstrap.zsh` — bootstrap orchestrator
- `scripts/phases/*.zsh` — bootstrap phases
- `scripts/ensure-tools.zsh` — tool installation
- `opencode/opencode.jsonc` — OpenCode configuration
- `opencode/oh-my-opencode.json` — agent model assignments
- `opencode/hooks/*.js` — OpenCode hooks
- `Brewfile` — Homebrew dependencies

### Additions/Removals Only

Changes trigger only when files are **added** or **deleted** (not for edits/tweaks):

- `opencode/agents/*.md` — agent definitions
- `opencode/skills/*/SKILL.md` — skill definitions
- `opencode/rules/*.md` — rule policies

### Exempt (never triggers)

- `.github/workflows/*` — CI configuration
- `README.md`, `ai-guide.md`, `*.md` docs at repo root — docs-only
- `test/*` — test infrastructure
- `.planning/*`, `.sisyphus/*` — planning/orchestration state
- `knowledge/*` — internal AI learnings
- `assets/*` — images and static assets
- `AGENTS.md` — agent configuration (meta, not user-facing tool behavior)
- `scripts/helpers/*.zsh`, `scripts/lib.zsh` — internal helpers (use escape hatch if change has user-visible behavior impact)

---

## CHANGELOG Format Specification

### Required Format

Entries go under `## [Unreleased]` — **NEVER** under released version headers.

- The `## [Unreleased]` header must be exactly `## [Unreleased]` (case-sensitive, no trailing space, no date)
- If `## [Unreleased]` does not exist, create it at the top of the changelog (after the intro paragraph)

### Subsection Decision Tree

| Change type | Subsection |
|-------------|-----------|
| New feature or capability | `### Added` |
| Modification to existing behavior | `### Changed` |
| Bug fix | `### Fixed` |
| Removed feature or capability | `### Removed` |

If the needed subsection does not exist under `[Unreleased]`, create it.

### Entry Format

- Bullet format: `- <description of user-visible change>`
- Bold tool/file names: **\`tool-name\`**, **[file.md](file.md)**
- One entry per **logical change** (NOT one per file touched)
- If an existing `[Unreleased]` entry already describes the same logical change, update it rather than adding a duplicate

---

## Escape Hatch

If a trigger path is touched but the change has **no user-visible behavior impact** (e.g., comment-only fix, whitespace, internal refactor with identical external behavior):

1. The agent **MAY** skip the CHANGELOG entry
2. The agent **MUST** include `changelog: none (<reason>)` in the commit message body
3. The reason must be **specific**: `"internal comment cleanup"` ✅ — `"no behavior change"` ❌ (too vague)

---

## Enforcement

This is a **hard block**: an agent MUST NOT consider work complete or create a commit without either:

(a) A CHANGELOG entry under `## [Unreleased]` for every triggered path change, OR  
(b) An explicit `changelog: none (<reason>)` justification in the commit message

When orchestrated (multi-agent swarm), the agent making the final commit is responsible for ensuring CHANGELOG coverage for all changes in that commit.
