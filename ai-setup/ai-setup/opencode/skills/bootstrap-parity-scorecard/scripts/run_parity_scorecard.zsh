#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

BOOTSTRAP_SCRIPT="$ROOT_DIR/scripts/bootstrap.zsh"
DOCTOR_CMD="$ROOT_DIR/bin/ai-setup-doctor"
OPENCODE_DST_DIR="$HOME/.config/opencode"
SKIP_BOOTSTRAP=false
total=0
failed=0

TMPDIR_SCORECARD="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SCORECARD"' EXIT

typeset -a CANONICAL_STEPS=(
  "preflight"
  "reconcile manifests"
  "ensure tools"
  "bin link setup"
  "opencode plugins"
  "sync opencode config"
  "integration verification"
  "atlassian login"
  "codex login"
  "copilot login"
  "verify readiness"
  "verify authentication"
)

typeset -A STEP_TO_PHASE=(
  [preflight]="scripts/phases/01-preflight.zsh"
  ["reconcile manifests"]="scripts/phases/02-manifests.zsh"
  ["ensure tools"]="scripts/phases/03-tools.zsh"
  ["bin link setup"]="scripts/phases/05-bin-link-setup.zsh"
  ["opencode plugins"]="scripts/phases/06-opencode-plugins.zsh"
  ["sync opencode config"]="scripts/link_opencode.zsh"
  ["integration verification"]="scripts/phases/07-verify-integrations.zsh"
  ["atlassian login"]="scripts/phases/08-atlassian-login.zsh"
  ["codex login"]="scripts/phases/09-codex-login.zsh"
  ["copilot login"]="scripts/phases/10-copilot-login.zsh"
  ["verify readiness"]="scripts/phases/11-verify-readiness.zsh"
  ["verify authentication"]="scripts/ensure-auth.sh"
)

typeset -a STALE_PHASE_FILES=(
  "scripts/phases/05-config-conflicts.zsh"
)

typeset -a CONFIG_FILES=(
  "opencode.json"
  "opencode.jsonc"
  "oh-my-opencode.json"
)

typeset -a CONFIG_DIRS=(
  "skills"
  "rules"
  "hooks"
  ".agents"
  "command"
)

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --skip-bootstrap)
        SKIP_BOOTSTRAP=true
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: run_parity_scorecard.zsh [--skip-bootstrap]

Options:
  --skip-bootstrap   Run only Check 1 (static step-order checks).
  -h, --help         Show this help.
EOF
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

extract_run_step_names() {
  sed -n '/^run_mode()/,/^}/p' "$BOOTSTRAP_SCRIPT" \
    | grep -A1 'run_step \\' \
    | grep '^\s*"' \
    | sed 's/.*"\(.*\)".*/\1/' \
    | grep -v '^snapshot creation$' || true
}

check_canonical_ordering() {
  local -a actual_steps
  local i expected actual max_len

  actual_steps=("${(@f)$(extract_run_step_names)}")
  max_len=${#CANONICAL_STEPS[@]}
  if (( ${#actual_steps[@]} > max_len )); then
    max_len=${#actual_steps[@]}
  fi

  for (( i = 1; i <= max_len; i++ )); do
    expected="${CANONICAL_STEPS[$i]:-(missing)}"
    actual="${actual_steps[$i]:-(missing)}"
    if [[ "$expected" != "$actual" ]]; then
      echo "Canonical order mismatch at index $i"
      echo "Expected: $expected"
      echo "Actual:   $actual"
      return 1
    fi
  done

  echo "Canonical order matches expected sequence (${#CANONICAL_STEPS[@]} steps)."
  return 0
}

check_guard_constraint() {
  local -a actual_steps
  local i
  local plugins_idx=0
  local sync_idx=0

  actual_steps=("${(@f)$(extract_run_step_names)}")

  for (( i = 1; i <= ${#actual_steps[@]}; i++ )); do
    if [[ "${actual_steps[$i]}" == "opencode plugins" ]]; then
      plugins_idx=$i
    fi
    if [[ "${actual_steps[$i]}" == "sync opencode config" ]]; then
      sync_idx=$i
    fi
  done

  if (( plugins_idx == 0 || sync_idx == 0 )); then
    echo "Missing required steps: plugins_idx=$plugins_idx, sync_idx=$sync_idx"
    return 1
  fi

  if (( plugins_idx >= sync_idx )); then
    echo "Guard ordering failed: opencode plugins (index $plugins_idx) must come before sync opencode config (index $sync_idx)."
    return 1
  fi

  if ! grep -q 'Keep config sync after plugin provisioning' "$BOOTSTRAP_SCRIPT"; then
    echo "Guard comment missing: Keep config sync after plugin provisioning"
    return 1
  fi

  echo "Guard constraint holds: plugins index $plugins_idx < sync index $sync_idx and guard comment exists."
  return 0
}

check_phase_file_parity() {
  local step path stale_path
  local ok=0

  for step in ${(k)STEP_TO_PHASE}; do
    path="$ROOT_DIR/${STEP_TO_PHASE[$step]}"
    if [[ -f "$path" ]]; then
      echo "EXISTS  $step -> ${STEP_TO_PHASE[$step]}"
    else
      echo "MISSING $step -> ${STEP_TO_PHASE[$step]}"
      ok=1
    fi
  done

  for stale_path in "${STALE_PHASE_FILES[@]}"; do
    if [[ -f "$ROOT_DIR/$stale_path" ]]; then
      echo "STALE PRESENT $stale_path"
      ok=1
    else
      echo "STALE ABSENT  $stale_path"
    fi
  done

  if (( ok == 0 )); then
    return 0
  fi
  return 1
}

run_check_1() {
  local output rc

  echo ""
  echo "## Check 1: Step Order Verification"

  total=$((total + 1))
  output="$(check_canonical_ordering 2>&1)"
  rc=$?
  if (( rc == 0 )); then
    echo "### PASS Canonical Ordering"
  else
    echo "### FAIL Canonical Ordering"
    failed=$((failed + 1))
  fi
  echo '```text'
  [[ -n "$output" ]] && echo "$output" || echo "(no output)"
  echo '```'

  total=$((total + 1))
  output="$(check_guard_constraint 2>&1)"
  rc=$?
  if (( rc == 0 )); then
    echo "### PASS Guard Constraint"
  else
    echo "### FAIL Guard Constraint"
    failed=$((failed + 1))
  fi
  echo '```text'
  [[ -n "$output" ]] && echo "$output" || echo "(no output)"
  echo '```'

  total=$((total + 1))
  output="$(check_phase_file_parity 2>&1)"
  rc=$?
  if (( rc == 0 )); then
    echo "### PASS Phase File Parity"
  else
    echo "### FAIL Phase File Parity"
    failed=$((failed + 1))
  fi
  echo '```text'
  [[ -n "$output" ]] && echo "$output" || echo "(no output)"
  echo '```'
}

snapshot_config_artifacts() {
  local outdir="$1"
  local config_file config_path dir safe_name

  mkdir -p "$outdir"

  for config_file in "${CONFIG_FILES[@]}"; do
    config_path="$OPENCODE_DST_DIR/$config_file"
    if [[ -f "$config_path" ]]; then
      shasum -a 256 "$config_path" > "$outdir/${config_file}.sha256"
    else
      echo "MISSING" > "$outdir/${config_file}.sha256"
    fi
  done

  for dir in "${CONFIG_DIRS[@]}"; do
    safe_name="${dir//\//_}"
    safe_name="${safe_name//./_}"
    if [[ -d "$OPENCODE_DST_DIR/$dir" ]]; then
      ls -1 "$OPENCODE_DST_DIR/$dir" 2>/dev/null | sort > "$outdir/${safe_name}.listing"
    else
      : > "$outdir/${safe_name}.listing"
    fi
  done
}

diff_config_artifacts() {
  local before_dir="$1"
  local after_dir="$2"
  local config_file before_file after_file before_state after_state
  local dir safe_name before_listing after_listing unchanged_count
  local -a added removed

  echo "### Config File Hashes"
  for config_file in "${CONFIG_FILES[@]}"; do
    before_file="$before_dir/${config_file}.sha256"
    after_file="$after_dir/${config_file}.sha256"
    before_state="$(<"$before_file")"
    after_state="$(<"$after_file")"

    if [[ "$before_state" == "MISSING" && "$after_state" != "MISSING" ]]; then
      echo "- $config_file: NEW"
    elif [[ "$before_state" != "MISSING" && "$after_state" == "MISSING" ]]; then
      echo "- $config_file: REMOVED"
    elif [[ "$before_state" == "$after_state" ]]; then
      echo "- $config_file: UNCHANGED"
    else
      echo "- $config_file: CHANGED"
    fi
  done

  echo ""
  echo "### Directory Listing Diffs"
  for dir in "${CONFIG_DIRS[@]}"; do
    safe_name="${dir//\//_}"
    safe_name="${safe_name//./_}"
    before_listing="$before_dir/${safe_name}.listing"
    after_listing="$after_dir/${safe_name}.listing"

    added=("${(@f)$(comm -13 "$before_listing" "$after_listing")}")
    removed=("${(@f)$(comm -23 "$before_listing" "$after_listing")}")
    unchanged_count="$(comm -12 "$before_listing" "$after_listing" | wc -l | tr -d ' ')"

    echo "- $dir"
    echo "  unchanged: $unchanged_count"
    if (( ${#added[@]} > 0 )); then
      local entry
      for entry in "${added[@]}"; do
        [[ -n "$entry" ]] && echo "  + $entry"
      done
    fi
    if (( ${#removed[@]} > 0 )); then
      local entry
      for entry in "${removed[@]}"; do
        [[ -n "$entry" ]] && echo "  - $entry"
      done
    fi
  done
}

run_check_2() {
  local before_dir="$1"
  local after_dir="$2"
  local bootstrap_exit_code="$3"
  local output

  echo ""
  echo "## Check 2: Artifact Diff (~/.config/opencode)"
  total=$((total + 1))

  output="$(diff_config_artifacts "$before_dir" "$after_dir" 2>&1)"
  if [[ "$bootstrap_exit_code" -eq 0 ]]; then
    echo "### PASS Artifact Diff"
  else
    echo "### FAIL Artifact Diff"
    failed=$((failed + 1))
  fi

  echo '```text'
  [[ -n "$output" ]] && echo "$output" || echo "(no output)"
  echo '```'
}

capture_doctor_json() {
  local outfile="$1"
  "$DOCTOR_CMD" --json > "$outfile" 2>/dev/null || true
  return 0
}

diff_doctor_json() {
  local before_file="$1"
  local after_file="$2"
  local line tool status before_status after_status verdict
  local regressions=0

  local -A before_map
  local -A after_map
  local -a before_lines
  local -a after_lines
  local -aU all_tools

  before_lines=("${(@f)$(jq -r '.tools | to_entries[] | "\(.key):\(.value.status)"' "$before_file" 2>/dev/null | sort || true)}")
  after_lines=("${(@f)$(jq -r '.tools | to_entries[] | "\(.key):\(.value.status)"' "$after_file" 2>/dev/null | sort || true)}")

  for line in "${before_lines[@]}"; do
    tool="${line%%:*}"
    status="${line#*:}"
    [[ -n "$tool" ]] || continue
    before_map["$tool"]="$status"
    all_tools+=("$tool")
  done

  for line in "${after_lines[@]}"; do
    tool="${line%%:*}"
    status="${line#*:}"
    [[ -n "$tool" ]] || continue
    after_map["$tool"]="$status"
    all_tools+=("$tool")
  done

  echo "| Tool | Before | After | Verdict |"
  echo "|------|--------|-------|---------|"

  for tool in "${all_tools[@]}"; do
    before_status="${before_map[$tool]:-missing}"
    after_status="${after_map[$tool]:-missing}"

    if [[ "$before_status" == "$after_status" ]]; then
      verdict="UNCHANGED"
    elif [[ "$before_status" == "ready" && "$after_status" != "ready" ]]; then
      verdict="REGRESSED"
      regressions=$((regressions + 1))
    elif [[ "$before_status" != "ready" && "$after_status" == "ready" ]]; then
      verdict="IMPROVED"
    else
      verdict="CHANGED"
    fi

    echo "| $tool | $before_status | $after_status | $verdict |"
  done

  echo ""
  echo "Summary before:"
  jq '.summary' "$before_file" 2>/dev/null || echo "null"
  echo "Summary after:"
  jq '.summary' "$after_file" 2>/dev/null || echo "null"

  if (( regressions == 0 )); then
    return 0
  fi
  return 1
}

run_check_3() {
  local before_json="$1"
  local after_json="$2"
  local output rc

  echo ""
  echo "## Check 3: Doctor JSON Before/After"
  total=$((total + 1))

  output="$(diff_doctor_json "$before_json" "$after_json" 2>&1)"
  rc=$?
  if (( rc == 0 )); then
    echo "### PASS Doctor JSON Before/After"
  else
    echo "### FAIL Doctor JSON Before/After"
    failed=$((failed + 1))
  fi

  echo '```text'
  [[ -n "$output" ]] && echo "$output" || echo "(no output)"
  echo '```'
}

print_header() {
  echo "# Bootstrap Parity Scorecard"
  echo ""
  echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

print_overall() {
  echo ""
  if (( failed == 0 )); then
    echo "## Overall: PASS ($total/$total)"
    return 0
  fi

  echo "## Overall: FAIL ($failed failed, $((total - failed)) passed)"
  return 1
}

main() {
  parse_args "$@"
  print_header
  run_check_1

  if [[ "$SKIP_BOOTSTRAP" == false ]]; then
    capture_doctor_json "$TMPDIR_SCORECARD/doctor_before.json"
    snapshot_config_artifacts "$TMPDIR_SCORECARD/before"

    local bootstrap_exit=0
    "$ROOT_DIR/bootstrap.zsh" || bootstrap_exit=$?

    snapshot_config_artifacts "$TMPDIR_SCORECARD/after"
    capture_doctor_json "$TMPDIR_SCORECARD/doctor_after.json"

    run_check_2 "$TMPDIR_SCORECARD/before" "$TMPDIR_SCORECARD/after" "$bootstrap_exit"
    run_check_3 "$TMPDIR_SCORECARD/doctor_before.json" "$TMPDIR_SCORECARD/doctor_after.json"
  else
    echo ""
    echo "## Checks 2 and 3: Skipped (--skip-bootstrap)"
    echo ""
    echo "Run without --skip-bootstrap to include artifact diff and doctor comparison."
  fi

  print_overall
}

main "$@"
