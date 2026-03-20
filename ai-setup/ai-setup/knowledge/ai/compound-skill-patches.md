# Compound Skill Patches — Task 5 (2026-03-01)

## Summary

Updated all deployed compound skills to:
1. Migrate `docs/solutions/` → `knowledge/ai/solutions/` path references (Task 4 migration)
2. Add worthiness gate to `/do:compound` to filter trivial fixes
3. Add "HIGH-IMPACT" bar to compound-docs documentation threshold

All deployed files are outside the repo and will be lost on next `bootstrap --update`. This document preserves the patches for reapplication.

---

## Files Changed

### 1. `~/.config/opencode/skills/do-compound/SKILL.md`

**What changed:**
- Added "Worthiness Gate (REQUIRED - Before Phase 1)" section with 4-point criteria
- Updated all path references from `docs/solutions/` → `knowledge/ai/solutions/`
- Updated argument hint and input/output descriptions
- Rewrote description line to reference new path structure

**Key additions:**
```markdown
### Worthiness Gate (REQUIRED - Before Phase 1)

**SKIP compound documentation if:**
- Problem is trivial (obvious fix, no investigation needed)
- No research or debugging required
- Single attempt worked on first try
- Won't save future sessions significant time
- No architectural or cross-cutting implications

**Emit:** `ℹ️ Skipped — trivial fix, not worth documenting. Continue workflow.`

**PROCEED if ANY of these apply:**
1. Non-obvious finding requiring research/debugging
2. Multiple attempts or failure modes encountered
3. Saves future AI developers 30+ minutes of troubleshooting
4. Architectural/cross-cutting impact affecting multiple modules

If unsure, document it. High-impact solutions compound over time.
```

**Lines affected:** 3, 4, 12, 27, 83, 134–135, 159, 167–168, 178, 189 (total ~200 lines)

**Acceptance:** ✅ 1 worthiness gate, 12 `knowledge/ai` refs, 0 `docs/solutions` refs

---

### 2. `~/.config/opencode/skills/compound-docs/SKILL.md`

**What changed:**
- Updated all path references from `docs/solutions/` → `knowledge/ai/solutions/`
- Enhanced "Non-trivial problems only" section with "HIGH-IMPACT bar" subtitle
- Updated step 6 and step 7 mkdir/file creation paths
- Updated search commands in step 3
- Updated decision menu paths

**Key additions (Step 1):**
```markdown
**Non-trivial problems only — HIGH-IMPACT bar:**

- Multiple investigation attempts needed
- Tricky debugging that took time
- Non-obvious solution
- Future sessions would benefit significantly (30+ minute savings)
```

**Lines affected:** 14, 26, 98–99, 102–105, 188–191, 224–225, 273, 376, 482, 491 (total ~514 lines)

**Acceptance:** ✅ 17 `knowledge/ai` refs, 2 HIGH-IMPACT mentions, 0 `docs/solutions` refs

---

### 3. `~/.config/opencode/skills/compound-to-nearest-agents-learning/SKILL.md`

**What changed:**
- Updated all path references from `docs/solutions/` → `knowledge/ai/solutions/`
- Updated argument hint, input description, resolution order, and step documentation

**Lines affected:** 4, 9, 12, 23, 27, 35, 42–43, 45, 53 (total ~104 lines)

**Acceptance:** ✅ Path refs updated, function preserved

---

### 4. `~/.config/opencode/command/do:compound.md`

**What changed:**
- Updated argument hint from `docs/solutions/path.md` → `knowledge/ai/solutions/path.md`

**Lines affected:** 3 (total ~14 lines)

**Acceptance:** ✅ Path updated

---

### 5. `~/.config/opencode/skills/compound-docs/references/yaml-schema.md`

**What changed:**
- Updated category mapping from `docs/solutions/` → `knowledge/ai/solutions/` in all 12 entries (lines 53–64)

**Before:**
```markdown
- **build_error** → `docs/solutions/build-errors/`
```

**After:**
```markdown
- **build_error** → `knowledge/ai/solutions/build-errors/`
```

**Lines affected:** 53–64 (all 12 category mappings)

**Acceptance:** ✅ All mappings updated

---

### 6. `~/.config/opencode/skills/compound-docs/assets/resolution-template.md`

**What changed:**
- Updated path references in YAML frontmatter example (line 24)
- Updated related issues examples (line 88)

**Before:**
```markdown
[If any similar problems exist in docs/solutions/, link to them:]
```

**After:**
```markdown
[If any similar problems exist in knowledge/ai/solutions/, link to them:]
```

**Lines affected:** 24, 88 (total ~93 lines)

**Acceptance:** ✅ Path updated

---

## Acceptance Criteria Results

| Criterion | Check | Result |
|-----------|-------|--------|
| Worthiness gate in do-compound | `grep -c "Worthiness Gate"` | ✅ 1 |
| No `docs/solutions/` refs | `grep "docs/solutions"` in key files | ✅ 0 |
| `knowledge/ai` refs in do-compound | `grep -c "knowledge/ai"` | ✅ 12 |
| `knowledge/ai` refs in compound-docs | `grep -c "knowledge/ai"` | ✅ 17 |
| HIGH-IMPACT language | `grep -c "HIGH-IMPACT"` | ✅ 2 |

---

## Rationale

### Why Worthiness Gate?

Compound documentation should capture **high-impact** learnings, not trivial fixes. The gate prevents documentation bloat by filtering out:
- Obvious one-liners
- Single-attempt successes
- Fixes with no research value

### Why HIGH-IMPACT Bar?

Reinforces that compound skills target substantial problems. Markers throughout compound-docs emphasize that we document **interesting** failures, not routine work.

### Why Path Migration?

Task 4 migrated solution docs from `docs/solutions/` to `knowledge/ai/solutions/` to organize learnings alongside other AI knowledge (agents, rules, patterns). Deployed skills must reference the new location.

---

## Reapplication Instructions

If deployed files are lost (e.g., after `bootstrap --update`), reapply patches with:

```bash
# Copy updated SKILL.md files
cp <repo>/knowledge/ai/compound-skill-patches.md <dev workspace>

# Re-read this file and manually apply changes to ~/ files
# OR create a patch script that reads this file and applies sed/edit commands
```

---

## Testing Notes

No functionality changes — only:
- Path redirects (`docs/solutions/` → `knowledge/ai/solutions/`)
- Added gating logic (worthiness check before Phase 1)
- Enhanced documentation (HIGH-IMPACT language)

All 4-phase compound orchestration remains intact. Gate is **additive** — does not break or restructure existing phases.

---

## Next Steps

- **Task 6:** Update all references in repo source code (`opencode/skills/` source, not deployed)
- **Task 7:** Verify compound workflow end-to-end with new path structure
