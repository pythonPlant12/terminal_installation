#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

create_injection_block() {
  local block_file="$1"

  cat > "$block_file" <<'EOF'

### Institutional Knowledge Check (MANDATORY)
Before proceeding, invoke `learnings-researcher` to surface relevant past solutions:
Task(prompt="Search knowledge/ai/solutions/ for: {context_keywords}", subagent_type="learnings-researcher")
Review results. Incorporate relevant findings before proceeding.

EOF
}

patch_workflow_file() {
  local file_path="$1"
  local anchor_text="$2"
  local insert_position="$3"
  local temp_dir="$4"

  if [[ ! -f "$file_path" ]]; then
    warn "Target missing, skipping: $file_path"
    return 0
  fi

  if grep -qF 'Institutional Knowledge Check (MANDATORY)' "$file_path" && \
     grep -qF 'subagent_type="learnings-researcher"' "$file_path"; then
    log "Already patched, skipping: $file_path"
    return 0
  fi

  local anchor_match
  anchor_match="$(grep -nF -m 1 "$anchor_text" "$file_path" || true)"
  if [[ -z "$anchor_match" ]]; then
    warn "Anchor not found, skipping: $file_path"
    return 0
  fi

  local anchor_line insert_after_line
  anchor_line="${anchor_match%%:*}"
  insert_after_line="$anchor_line"

  if [[ "$insert_position" == "before" ]]; then
    if (( anchor_line <= 1 )); then
      warn "Cannot inject before first line, skipping: $file_path"
      return 0
    fi
    insert_after_line=$((anchor_line - 1))
  fi

  local block_file
  block_file="$temp_dir/patch-gsd-learnings-block.$$"

  create_injection_block "$block_file"
  sed -i '' "${insert_after_line}r ${block_file}" "$file_path"

  ok "Patched: $file_path"
}

main() {
  require_cmd grep
  require_cmd sed

  local temp_dir
  temp_dir="$(mktemp -d)" || die "Failed to create temp directory"
  [[ -d "$temp_dir" ]] || die "Temp directory not created: $temp_dir"
  trap "rm -rf '${temp_dir}'" EXIT INT TERM

  local workflows_dir="$HOME/.config/opencode/get-shit-done/workflows"

  patch_workflow_file "$workflows_dir/plan-phase.md" '### Spawn gsd-phase-researcher' 'before' "$temp_dir"
  patch_workflow_file "$workflows_dir/execute-phase.md" '</required_reading>' 'after' "$temp_dir"
  patch_workflow_file "$workflows_dir/quick.md" '</required_reading>' 'after' "$temp_dir"
  patch_workflow_file "$workflows_dir/research-phase.md" '## Step 4: Spawn Researcher' 'before' "$temp_dir"

  ok 'Done patching GSD workflows.'
}

main "$@"
