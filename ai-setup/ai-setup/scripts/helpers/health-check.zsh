#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

# check_tool_available(tool_name)
# Verify a tool/command exists in PATH.
# Tests: command -v "$tool_name" >/dev/null 2>&1
# Returns 0 if found, 1 if not found
# No output to stdout
check_tool_available() {
  local tool_name="$1"
  
  if command -v "$tool_name" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# check_tool_available_or_linked(tool_name)
# Verify a tool exists in PATH OR is present in ~/.local/bin.
# This is useful for our repo-linked CLIs when PATH does not include ~/.local/bin.
# Returns 0 if found, 1 if not found.
check_tool_available_or_linked() {
  local tool_name="$1"
  local local_bin="$HOME/.local/bin"

  if check_tool_available "$tool_name"; then
    return 0
  fi

  if [[ -x "$local_bin/$tool_name" ]]; then
    return 0
  fi

  return 1
}

# check_tool_auth(tool_name, auth_type)
# Check tool-specific authentication.
# Supports auth_type: "keychain" (for Atlassian), "command-status" (for Codex), "config-file" (for Copilot)
# Returns 0 if auth valid, 1 if missing/invalid
# No output to stdout
check_tool_auth() {
  local tool_name="$1"
  local auth_type="$2"
  
  case "$auth_type" in
    keychain)
      # Check if credentials exist in Keychain
      if security find-generic-password -s "opencode-atlassian-token" -a "$USER" >/dev/null 2>&1; then
        return 0
      else
        return 1
      fi
      ;;
    command-status)
      # For Codex, check if login succeeded (check if command returns success)
      if "$tool_name" login status >/dev/null 2>&1; then
        return 0
      else
        return 1
      fi
      ;;
    config-file)
      # For Copilot, check if config file exists
      if [[ -f "$HOME/.copilot/config.json" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    *)
      # Unknown auth type
      return 1
      ;;
  esac
}

# report_tool_status(tool_name, available, status_type, auth_type, guidance)
# Print human-readable status line with appropriate symbol.
# status_type: "ok" (✅), "warn" (⚠️), or "critical" (❌)
# Format examples:
#   ✅ Codex: available, authenticated
#   ⚠️  Atlassian MCP: not authenticated. Run: opencode-atlassian-login
#   ❌ OpenCode CLI: required component not available
# Returns 0 always
report_tool_status() {
  local tool_name="$1"
  local available="$2"
  local status_type="$3"
  local auth_type="$4"
  local guidance="${5:-}"

  if [[ "$available" == "disabled" ]]; then
    vlog "$tool_name: optional component disabled by configuration"
    return 0
  fi
  
  case "$status_type" in
    ok)
      ok "$tool_name: available, authenticated"
      ;;
    warn)
      if [[ -n "$guidance" ]]; then
        warn "$tool_name: $guidance"
      else
        warn "$tool_name: not available"
      fi
      ;;
    critical)
      if [[ -n "$guidance" ]]; then
        print -r -- "❌ $tool_name: $guidance"
      else
        print -r -- "❌ $tool_name: critical component missing"
      fi
      ;;
    *)
      warn "$tool_name: unknown status"
      ;;
  esac
  
  return 0
}

# report_health_summary(tools_array)
# Print aggregate summary with critical vs warning distinction.
# Takes array of tool statuses: @("atlassian:ok" "codex:warn" "copilot:ok" "opencode:critical")
# Counts ok, warn, critical statuses
# Prints summary line: "Integration Health: 3 ready, 1 missing (critical), 1 needs setup"
# Returns 0 if all ok, 1 if any warn/critical
report_health_summary() {
  local -a tools_array=("${@}")
  
  local ok_count=0
  local warn_count=0
  local critical_count=0
  local disabled_count=0
  
  for tool_status in "${tools_array[@]}"; do
    local tool_health="${tool_status#*:}"
    
    case "$tool_health" in
      ok)
        ((ok_count += 1))
        ;;
      warn)
        ((warn_count += 1))
        ;;
      critical)
        ((critical_count += 1))
        ;;
      disabled)
        ((disabled_count += 1))
        ;;
    esac
  done
  
  local total_enabled=$((ok_count + warn_count + critical_count))
  
  if (( total_enabled == 0 )); then
    warn "Integration Health: no required checks enabled"
    return 0
  fi

  # Report critical failures first
  if (( critical_count > 0 )); then
    print -r -- ""
    print -r -- "❌ Critical components missing ($critical_count). Bootstrap incomplete."
    return 1
  fi

  # Report non-critical status
  if (( warn_count + critical_count == 0 )); then
    ok "Integration Health: $ok_count/$total_enabled ready"
    return 0
  else
    warn "Integration Health: $ok_count/$total_enabled ready, $warn_count need setup"
    return 1
  fi
}

# check_learnings_researcher_rule()
# Verify the learnings-researcher mandate rule is deployed and matches the repo copy.
# FAIL (return 1) if the rule file is absent OR differs from the repo's authoritative copy.
# Returns 0 if present and content-identical to repo copy.
check_learnings_researcher_rule() {
  local rule_file="$HOME/.config/opencode/rules/learnings-researcher-mandate.md"
  local repo_rule_file="$ROOT_DIR/opencode/rules/learnings-researcher-mandate.md"

  if [[ ! -f "$rule_file" ]]; then
    return 1
  fi

  if ! diff -q "$rule_file" "$repo_rule_file" >/dev/null 2>&1; then
    return 1
  fi

  return 0
}

# check_gsd_workflows_patched()
# Verify ALL GSD workflows contain the learnings-researcher invocation.
# WARN (return 1) if any workflow is missing the patch.
# Returns 0 if all 4 workflows are patched, 1 if any is missing.
check_gsd_workflows_patched() {
  local workflows_dir="$HOME/.config/opencode/get-shit-done/workflows"
  local -a workflows=(plan-phase execute-phase quick research-phase)
  local wf
  for wf in "${workflows[@]}"; do
    if ! grep -ql 'Institutional Knowledge Check (MANDATORY)' "$workflows_dir/$wf.md" 2>/dev/null \
       || ! grep -ql 'subagent_type="learnings-researcher"' "$workflows_dir/$wf.md" 2>/dev/null; then
      return 1
    fi
  done
  return 0
}
