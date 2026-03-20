#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT_DIR"

# --- Configuration ---
BASE_REF="main"
GOAL_ARTIFACT=""

# --- Parse arguments ---
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_REF="$2"
      shift 2
      ;;
    --goal-artifact)
      GOAL_ARTIFACT="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: run_verify_gates.zsh [--base <ref>] [--goal-artifact <path>] [file ...]"
      echo ""
      echo "  --base <ref>            Base branch or commit to diff against (default: main)"
      echo "  --goal-artifact <path>  Markdown artifact with Acceptance Criteria checklist"
      echo "  file ...                Explicit file list (skips git detection)"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# --- Data structures ---
typeset -aU changed_files
typeset -aU changed_areas
typeset -aU syntax_commands
typeset -aU behavior_commands
typeset -aU all_commands
typeset -A has_shell_syntax_for_area
typeset -A status_by_command
typeset -A output_by_command

# Classification flags (used by SKILL.md to decide which deep skills to dispatch)
typeset has_shell=false
typeset has_phases=false
typeset has_config=false
typeset has_bootstrap=false
typeset has_js=false
typeset has_docs=false
typeset has_skills=false

# Track files per classification for the summary
typeset -aU shell_files
typeset -aU phase_files
typeset -aU config_files
typeset -aU bootstrap_files
typeset -aU js_files
typeset -aU doc_files
typeset -aU skill_files

# --- Helpers ---

is_relevant_repo_path() {
  local file="$1"
  case "$file" in
    bootstrap.zsh|scripts/*|bin/*|opencode/*|Brewfile|mise.toml|AGENTS.md|README.md|docs/*|templates/*|knowledge/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_changed_files() {
  local line

  # Changes between base ref and HEAD
  if git rev-parse --verify "$BASE_REF" &>/dev/null; then
    while IFS= read -r line; do
      if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
        changed_files+=("$line")
      fi
    done < <(git diff --name-only "$BASE_REF"...HEAD 2>/dev/null || git diff --name-only "$BASE_REF" HEAD 2>/dev/null || true)
  fi

  # Also include staged changes not yet committed
  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git diff --name-only --cached 2>/dev/null || true)

  # Also include unstaged changes
  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git diff --name-only 2>/dev/null || true)

  # Also include untracked files
  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git ls-files --others --exclude-standard 2>/dev/null || true)
}

classify_area() {
  local file="$1"
  if [[ "$file" == *atlassian* || "$file" == bin/mcp-atlassian-opencode || "$file" == scripts/phases/08-atlassian-login.zsh ]]; then
    echo "atlassian"
    return
  fi

  if [[ "$file" == *snapshot* || "$file" == *export* || "$file" == *import* || "$file" == *rollback* || "$file" == scripts/phases/12-snapshot-creation.zsh || "$file" == scripts/phases/13-migration-export.zsh || "$file" == scripts/helpers/* ]]; then
    echo "backup-recovery"
    return
  fi

  if [[ "$file" == bootstrap.zsh || "$file" == scripts/bootstrap.zsh || "$file" == scripts/lib.zsh || "$file" == scripts/ensure-tools.zsh || "$file" == Brewfile || "$file" == mise.toml ]]; then
    echo "bootstrap-core"
    return
  fi

  if [[ "$file" == opencode/opencode.jsonc || "$file" == opencode/oh-my-opencode.json || "$file" == .contract-map/* ]]; then
    echo "opencode-config"
    return
  fi

  if [[ "$file" == scripts/phases/*.zsh ]]; then
    echo "bootstrap-phases"
    return
  fi

  if [[ "$file" == scripts/*.zsh ]]; then
    echo "bootstrap-core"
    return
  fi

  if [[ "$file" == opencode/* ]]; then
    echo "opencode-general"
    return
  fi

  echo "general"
}

classify_file_type() {
  local file="$1"

  # Shell files
  if [[ "$file" == *.zsh || "$file" == *.sh || "$file" == *.bash ]]; then
    has_shell=true
    shell_files+=("$file")
  elif [[ "$file" == bin/* ]] && [[ -f "$file" ]]; then
    local first_line
    first_line="$(head -n 1 "$file" 2>/dev/null || true)"
    if [[ "$first_line" == *zsh* || "$first_line" == *bash* || "$first_line" == *sh* ]]; then
      has_shell=true
      shell_files+=("$file")
    fi
  fi

  # Phase files
  if [[ "$file" == scripts/phases/*.zsh ]]; then
    has_phases=true
    phase_files+=("$file")
  fi

  # Config files
  if [[ "$file" == opencode/opencode.jsonc || "$file" == opencode/oh-my-opencode.json || "$file" == .contract-map/* ]]; then
    has_config=true
    config_files+=("$file")
  fi

  # Bootstrap files
  if [[ "$file" == bootstrap.zsh || "$file" == scripts/bootstrap.zsh || "$file" == scripts/phases/*.zsh || "$file" == scripts/lib.zsh || "$file" == scripts/ensure-tools.zsh ]]; then
    has_bootstrap=true
    bootstrap_files+=("$file")
  fi

  # JS files
  if [[ "$file" == *.js ]]; then
    has_js=true
    js_files+=("$file")
  fi

  # Documentation files
  if [[ "$file" == *.md && "$file" != opencode/skills/*/SKILL.md && "$file" != opencode/agents/*.md ]]; then
    has_docs=true
    doc_files+=("$file")
  fi

  # Skill files
  if [[ "$file" == opencode/skills/*/SKILL.md || "$file" == opencode/skills/*/scripts/* ]]; then
    has_skills=true
    skill_files+=("$file")
  fi
}

detect_shell_lint_for_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  if [[ "$file" == *.zsh ]]; then
    echo "zsh -n $file"
    return
  fi

  if [[ "$file" == *.sh || "$file" == *.bash ]]; then
    echo "bash -n $file"
    return
  fi

  if [[ "$file" == bin/* ]]; then
    local first_line
    first_line="$(head -n 1 "$file" 2>/dev/null || true)"
    if [[ "$first_line" == *zsh* ]]; then
      echo "zsh -n $file"
      return
    fi
    if [[ "$first_line" == *bash* ]]; then
      echo "bash -n $file"
      return
    fi
  fi
}

detect_js_lint_for_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if [[ "$file" == *.js ]]; then
    echo "node --check $file"
  fi
}

detect_jsonc_validation() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if [[ "$file" == *.jsonc ]]; then
    # Strip comments and trailing commas, then parse
    echo "node -e \"const fs=require('fs');const c=fs.readFileSync('$file','utf8').replace(/\\/\\/.*/g,'').replace(/,\\s*([}\\]])/g,'\$1');JSON.parse(c);console.log('Valid JSONC')\""
  elif [[ "$file" == *.json ]]; then
    echo "node -e \"JSON.parse(require('fs').readFileSync('$file','utf8'));console.log('Valid JSON')\""
  fi
}

default_shell_lint_for_area() {
  local area="$1"
  case "$area" in
    atlassian)
      echo "bash -n bin/opencode-atlassian-login"
      ;;
    backup-recovery)
      echo "zsh -n scripts/phases/12-snapshot-creation.zsh"
      ;;
    bootstrap-core|bootstrap-phases)
      echo "zsh -n scripts/bootstrap.zsh"
      ;;
    opencode-config|opencode-general)
      echo "zsh -n scripts/bootstrap.zsh"
      ;;
    *)
      echo "zsh -n bootstrap.zsh"
      ;;
  esac
}

behavior_for_area() {
  local area="$1"
  case "$area" in
    atlassian)
      echo "bin/opencode-atlassian-status"
      ;;
    backup-recovery)
      echo "bin/ai-setup-snapshot --list"
      ;;
    bootstrap-core|bootstrap-phases|opencode-config|opencode-general|general)
      echo "bin/ai-setup-doctor --json"
      ;;
  esac
}

collect_commands() {
  local file area shell_cmd js_cmd jsonc_cmd default_cmd beh_cmd

  for file in "${changed_files[@]}"; do
    area="$(classify_area "$file")"
    changed_areas+=("$area")
    classify_file_type "$file"

    shell_cmd="$(detect_shell_lint_for_file "$file")"
    if [[ -n "$shell_cmd" ]]; then
      syntax_commands+=("$shell_cmd")
      has_shell_syntax_for_area["$area"]="1"
    fi

    js_cmd="$(detect_js_lint_for_file "$file")"
    [[ -n "$js_cmd" ]] && syntax_commands+=("$js_cmd")

    jsonc_cmd="$(detect_jsonc_validation "$file")"
    [[ -n "$jsonc_cmd" ]] && syntax_commands+=("$jsonc_cmd")
  done

  for area in "${changed_areas[@]}"; do
    if [[ -z "${has_shell_syntax_for_area["$area"]:-}" ]]; then
      default_cmd=""
      default_cmd="$(default_shell_lint_for_area "$area")"
      if [[ -n "$default_cmd" ]]; then
        syntax_commands+=("$default_cmd")
        has_shell_syntax_for_area["$area"]="1"
      fi
    fi
    beh_cmd=""
    beh_cmd="$(behavior_for_area "$area")"
    [[ -n "$beh_cmd" ]] && behavior_commands+=("$beh_cmd")
  done

  if [[ -n "$GOAL_ARTIFACT" ]]; then
    behavior_commands+=("python3 opencode/skills/do-verify/scripts/verify_goal_artifact.py --artifact ${(q)GOAL_ARTIFACT}")
  fi
}

run_and_capture() {
  local command="$1"
  local output exit_code

  set +e
  output="$({ eval "$command"; } 2>&1)"
  exit_code=$?
  set -e

  status_by_command["$command"]="$exit_code"
  output_by_command["$command"]="$output"
}

print_report() {
  local file command exit_code output
  local total=0
  local failed=0

  echo "# Verification Gate Report"
  echo ""
  echo "**Base ref:** \`$BASE_REF\`"
  if [[ -n "$GOAL_ARTIFACT" ]]; then
    echo "**Goal artifact:** \`$GOAL_ARTIFACT\`"
  fi
  echo "**Timestamp:** $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo ""

  echo "## Changed Files (${#changed_files[@]})"
  if [[ "${#changed_files[@]}" -eq 0 ]]; then
    echo "- (none)"
  else
    for file in "${changed_files[@]}"; do
      echo "- \`$file\`"
    done
  fi

  echo ""
  echo "## Selected Syntax Gates"
  if [[ "${#syntax_commands[@]}" -eq 0 ]]; then
    echo "- (none)"
  else
    for command in "${syntax_commands[@]}"; do
      echo "- \`$command\`"
    done
  fi

  echo ""
  echo "## Selected Behavior Gates"
  if [[ "${#behavior_commands[@]}" -eq 0 ]]; then
    echo "- (none)"
  else
    for command in "${behavior_commands[@]}"; do
      echo "- \`$command\`"
    done
  fi

  all_commands=("${syntax_commands[@]}" "${behavior_commands[@]}")

  echo ""
  echo "## Gate Results"
  for command in "${all_commands[@]}"; do
    total=$((total + 1))
    exit_code="${status_by_command["$command"]:-125}"
    output="${output_by_command["$command"]-}"

    if [[ "$exit_code" -eq 0 ]]; then
      echo "### PASS \`$command\`"
    else
      failed=$((failed + 1))
      echo "### FAIL \`$command\` (exit $exit_code)"
    fi
    echo '```text'
    if [[ -n "$output" ]]; then
      echo "$output"
    else
      echo "(no output)"
    fi
    echo '```'
    echo ""
  done

  if [[ "$failed" -eq 0 ]]; then
    echo "## Phase 1 Result: PASS ($total/$total gates passed)"
  else
    echo "## Phase 1 Result: FAIL ($failed failed, $((total - failed)) passed out of $total)"
  fi

  # --- Classification Summary (parsed by SKILL.md for Phase 2 dispatch) ---
  echo ""
  echo "## Classification Summary"
  echo ""
  echo "| Flag | Value | Files |"
  echo "|------|-------|-------|"
  echo "| has_shell | $has_shell | ${(j:, :)shell_files:-none} |"
  echo "| has_phases | $has_phases | ${(j:, :)phase_files:-none} |"
  echo "| has_config | $has_config | ${(j:, :)config_files:-none} |"
  echo "| has_bootstrap | $has_bootstrap | ${(j:, :)bootstrap_files:-none} |"
  echo "| has_js | $has_js | ${(j:, :)js_files:-none} |"
  echo "| has_docs | $has_docs | ${(j:, :)doc_files:-none} |"
  echo "| has_skills | $has_skills | ${(j:, :)skill_files:-none} |"

  if [[ "$failed" -ne 0 ]]; then
    return 1
  fi
  return 0
}

# --- Main ---

main() {
  if [[ "$#" -gt 0 ]]; then
    changed_files=("$@")
  else
    detect_changed_files
  fi

  if [[ "${#changed_files[@]}" -eq 0 && -z "$GOAL_ARTIFACT" ]]; then
    echo "# Verification Gate Report"
    echo ""
    echo "**Base ref:** \`$BASE_REF\`"
    echo ""
    echo "No changed files detected relative to \`$BASE_REF\`. Nothing to verify."
    echo ""
    echo "## Classification Summary"
    echo ""
    echo "| Flag | Value | Files |"
    echo "|------|-------|-------|"
    echo "| has_shell | false | none |"
    echo "| has_phases | false | none |"
    echo "| has_config | false | none |"
    echo "| has_bootstrap | false | none |"
    echo "| has_js | false | none |"
    echo "| has_docs | false | none |"
    echo "| has_skills | false | none |"
    exit 0
  fi

  collect_commands

  local command
  for command in "${syntax_commands[@]}"; do
    run_and_capture "$command"
  done
  for command in "${behavior_commands[@]}"; do
    run_and_capture "$command"
  done

  print_report
}

main "$@"
