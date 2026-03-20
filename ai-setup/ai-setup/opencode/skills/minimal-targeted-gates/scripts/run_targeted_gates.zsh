#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT_DIR"

typeset -aU changed_files
typeset -aU changed_areas
typeset -aU syntax_commands
typeset -aU behavior_commands
typeset -aU all_commands
typeset -A has_shell_syntax_for_area
typeset -A status_by_command
typeset -A output_by_command

is_relevant_repo_path() {
  local file="$1"
  case "$file" in
    bootstrap.zsh|scripts/*|bin/*|opencode/*|Brewfile|mise.toml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_changed_files() {
  local line

  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git diff --name-only --cached)

  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git diff --name-only)

  while IFS= read -r line; do
    if [[ -n "$line" ]] && is_relevant_repo_path "$line"; then
      changed_files+=("$line")
    fi
  done < <(git ls-files --others --exclude-standard)
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

  if [[ "$file" == bootstrap.zsh || "$file" == scripts/* || "$file" == Brewfile || "$file" == mise.toml ]]; then
    echo "bootstrap-core"
    return
  fi

  if [[ "$file" == opencode/* ]]; then
    echo "opencode-config"
    return
  fi

  echo "general"
}

detect_shell_lint_for_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  if [[ "$file" == *.zsh ]]; then
    echo "zsh -n $file"
    return
  fi

  if [[ "$file" == *.sh ]]; then
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

default_shell_lint_for_area() {
  local area="$1"
  case "$area" in
    atlassian)
      echo "bash -n bin/opencode-atlassian-login"
      ;;
    backup-recovery)
      echo "zsh -n scripts/phases/12-snapshot-creation.zsh"
      ;;
    bootstrap-core)
      echo "zsh -n scripts/bootstrap.zsh"
      ;;
    opencode-config)
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
    bootstrap-core|opencode-config|general)
      echo "bin/ai-setup-doctor --json"
      ;;
  esac
}

collect_commands() {
  local file area shell_cmd js_cmd

  for file in "${changed_files[@]}"; do
    area="$(classify_area "$file")"
    changed_areas+=("$area")

    shell_cmd="$(detect_shell_lint_for_file "$file")"
    if [[ -n "$shell_cmd" ]]; then
      syntax_commands+=("$shell_cmd")
      has_shell_syntax_for_area["$area"]="1"
    fi

    js_cmd="$(detect_js_lint_for_file "$file")"
    [[ -n "$js_cmd" ]] && syntax_commands+=("$js_cmd")
  done

  for area in "${changed_areas[@]}"; do
    if [[ -z "${has_shell_syntax_for_area["$area"]:-}" ]]; then
      syntax_commands+=("$(default_shell_lint_for_area "$area")")
      has_shell_syntax_for_area["$area"]="1"
    fi
    behavior_commands+=("$(behavior_for_area "$area")")
  done
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

  echo "# Targeted Gate Report"
  echo
  echo "## Changed Files"
  if [[ "${#changed_files[@]}" -eq 0 ]]; then
    echo "- (none)"
  else
    for file in "${changed_files[@]}"; do
      echo "- $file"
    done
  fi

  echo
  echo "## Selected Syntax Gates"
  for command in "${syntax_commands[@]}"; do
    echo "- \`$command\`"
  done

  echo
  echo "## Selected Behavior Gates"
  for command in "${behavior_commands[@]}"; do
    echo "- \`$command\`"
  done

  all_commands=("${syntax_commands[@]}" "${behavior_commands[@]}")

  echo
  echo "## Results"
  for command in "${all_commands[@]}"; do
    total=$((total + 1))
    exit_code="${status_by_command["$command"]:-125}"
    output="${output_by_command["$command"]-}"

    if [[ "$exit_code" -eq 0 ]]; then
      echo "### PASS \`$command\`"
    else
      failed=$((failed + 1))
      echo "### FAIL \`$command\`"
    fi
    echo '```text'
    if [[ -n "$output" ]]; then
      echo "$output"
    else
      echo "(no output)"
    fi
    echo '```'
    echo
  done

  if [[ "$failed" -eq 0 ]]; then
    echo "## Overall: PASS ($total/$total)"
    return 0
  fi

  echo "## Overall: FAIL ($failed failed, $((total - failed)) passed)"
  return 1
}

main() {
  if [[ "$#" -gt 0 ]]; then
    changed_files=("$@")
  else
    detect_changed_files
  fi

  if [[ "${#changed_files[@]}" -eq 0 ]]; then
    echo "No changed files detected. Nothing to validate."
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
