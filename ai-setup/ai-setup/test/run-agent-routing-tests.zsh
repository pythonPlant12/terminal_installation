#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_PATH="${0:A}"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

RESULTS_DIR="$ROOT_DIR/test/results"
ensure_dir "$RESULTS_DIR"

# ─── Test Case Registry ──────────────────────────────────────────────────────
#
# Each test case is defined as a set of variables with a common prefix.
# Format: TC_<id>_<field>
#
# Fields:
#   agent           - specialist or router under test
#   category        - positive | negative | router-selection
#   prompt_theme    - short description of the prompt domain
#   markers         - comma-separated domain markers to assert (positive/router tests)
#   anti_markers    - comma-separated anti-markers that must NOT appear (negative tests)
#   expected_specialist - target specialist for router selection tests
#   session_id      - OpenCode session ID from test execution
#   status          - pass | fail | pending

# ── Positive Tests (TC-01 through TC-05) ─────────────────────────────────────

TC_01_agent="vue-virtuoso"
TC_01_category="positive"
TC_01_prompt_theme="Vue 3 Composition API data table"
TC_01_markers="<script setup>,Composition API,Pinia,virtual scrolling"
TC_01_anti_markers=""
TC_01_expected_specialist=""
TC_01_session_id="ses_340b29cb2ffefmmu4MJdvi2okp"
TC_01_status="pass"

TC_02_agent="github-actions-pro"
TC_02_category="positive"
TC_02_prompt_theme="CI/CD workflow with matrix strategy"
TC_02_markers="workflow YAML,matrix strategy,actions/cache,OIDC"
TC_02_anti_markers=""
TC_02_expected_specialist=""
TC_02_session_id="ses_340b28facffedK54bqLIw35F3R"
TC_02_status="pass"

TC_03_agent="gcp-architect"
TC_03_category="positive"
TC_03_prompt_theme="Multi-region GCP analytics platform"
TC_03_markers="BigQuery,Dataflow,Pub/Sub,cost optimization"
TC_03_anti_markers=""
TC_03_expected_specialist=""
TC_03_session_id="ses_340b27f7bffeVvRBtkljnOiA5S"
TC_03_status="pass"

TC_04_agent="market-researcher"
TC_04_category="positive"
TC_04_prompt_theme="Competitive analysis for AI code review SaaS"
TC_04_markers="TAM/SAM/SOM,competitor matrix,pricing analysis,strategic positioning"
TC_04_anti_markers=""
TC_04_expected_specialist=""
TC_04_session_id="ses_340b27154ffeRPyXsK20mlxU4M"
TC_04_status="pass"

TC_05_agent="tech-debt-surgeon"
TC_05_category="positive"
TC_05_prompt_theme="Legacy Express.js refactoring roadmap"
TC_05_markers="incremental migration,test-first,callback to async/await,phased roadmap"
TC_05_anti_markers=""
TC_05_expected_specialist=""
TC_05_session_id="ses_340b25bf2ffeH8ch892tp6FGdb"
TC_05_status="pass"

# ── Negative Tests (TC-NEG-01 through TC-NEG-05) ────────────────────────────

TC_NEG_01_agent="vue-virtuoso"
TC_NEG_01_category="negative"
TC_NEG_01_prompt_theme="GCP architecture (cross-domain)"
TC_NEG_01_markers=""
TC_NEG_01_anti_markers="<script setup>,Composition API,Pinia,Vue Router,Nuxt,ref(),reactive()"
TC_NEG_01_expected_specialist=""
TC_NEG_01_session_id="ses_340220e18ffe46yPaIjPqjRXj0"
TC_NEG_01_status="pass"

TC_NEG_02_agent="github-actions-pro"
TC_NEG_02_category="negative"
TC_NEG_02_prompt_theme="Vue 3 component (cross-domain)"
TC_NEG_02_markers=""
TC_NEG_02_anti_markers="workflow YAML,actions/cache,matrix strategy,OIDC,runs-on,composite action"
TC_NEG_02_expected_specialist=""
TC_NEG_02_session_id="ses_34021e59cffeYyjYkwGSovOeuD"
TC_NEG_02_status="pass"

TC_NEG_03_agent="gcp-architect"
TC_NEG_03_category="negative"
TC_NEG_03_prompt_theme="Express.js refactoring (cross-domain)"
TC_NEG_03_markers=""
TC_NEG_03_anti_markers="BigQuery,Pub/Sub,Dataflow,Terraform google_*,VPC Service Controls,CMEK,GKE"
TC_NEG_03_expected_specialist=""
TC_NEG_03_session_id="ses_34021b9adffewTgK5ps2TaMzhd"
TC_NEG_03_status="pass"

TC_NEG_04_agent="market-researcher"
TC_NEG_04_category="negative"
TC_NEG_04_prompt_theme="GitHub Actions CI/CD (cross-domain)"
TC_NEG_04_markers=""
TC_NEG_04_anti_markers="TAM/SAM/SOM,Porter's Five Forces,SWOT,competitive matrix,pricing tiers,GTM strategy"
TC_NEG_04_expected_specialist=""
TC_NEG_04_session_id="ses_34021952dffeLrZ76fuyym9cyR"
TC_NEG_04_status="pass"

TC_NEG_05_agent="tech-debt-surgeon"
TC_NEG_05_category="negative"
TC_NEG_05_prompt_theme="Competitive analysis (cross-domain)"
TC_NEG_05_markers=""
TC_NEG_05_anti_markers="Strangler Fig,Branch by Abstraction,characterization tests,callback migration,phased refactoring"
TC_NEG_05_expected_specialist=""
TC_NEG_05_session_id="ses_340215686ffe8GLUR87v1JLw4h"
TC_NEG_05_status="pass"

# ── Router Selection Tests (TC-RSL-01 through TC-RSL-05) ─────────────────────

TC_RSL_01_agent="language-router"
TC_RSL_01_category="router-selection"
TC_RSL_01_prompt_theme="Advanced TypeScript type system"
TC_RSL_01_markers="conditional types,mapped types,template literal types,infer,branded types"
TC_RSL_01_anti_markers=""
TC_RSL_01_expected_specialist="typescript-sage"
TC_RSL_01_session_id="ses_3401fe0a1ffeNDYrujXq7CiozU"
TC_RSL_01_status="pass"

TC_RSL_02_agent="devops-router"
TC_RSL_02_category="router-selection"
TC_RSL_02_prompt_theme="Kubernetes production deployment"
TC_RSL_02_markers="Kubernetes,Helm,Istio,Prometheus,canary deployments,HPA"
TC_RSL_02_anti_markers=""
TC_RSL_02_expected_specialist="devops-maestro"
TC_RSL_02_session_id="ses_3401fb9fbffeieThAfQ26ZIsDu"
TC_RSL_02_status="pass"

TC_RSL_03_agent="infra-router"
TC_RSL_03_category="router-selection"
TC_RSL_03_prompt_theme="Linux server hardening"
TC_RSL_03_markers="sysctl,AppArmor,sshd_config,systemd,auditd,nftables"
TC_RSL_03_anti_markers=""
TC_RSL_03_expected_specialist="linux-admin"
TC_RSL_03_session_id="ses_3401fb028ffeETRGsg0TQ7M9YX"
TC_RSL_03_status="pass"

TC_RSL_04_agent="business-strategy-router"
TC_RSL_04_category="router-selection"
TC_RSL_04_prompt_theme="Early-stage startup technical strategy"
TC_RSL_04_markers="build vs buy,TCO,hiring plan,tech debt as leverage,MVP,boring technology"
TC_RSL_04_anti_markers=""
TC_RSL_04_expected_specialist="startup-cto"
TC_RSL_04_session_id="ses_3401f8ff0ffecNdkCEOUg3u7Jk"
TC_RSL_04_status="pass"

TC_RSL_05_agent="architecture-router"
TC_RSL_05_category="router-selection"
TC_RSL_05_prompt_theme="System architecture review"
TC_RSL_05_markers="SOLID,coupling analysis,API contracts,service boundaries,dependency inversion"
TC_RSL_05_anti_markers=""
TC_RSL_05_expected_specialist="architecture-strategist"
TC_RSL_05_session_id="ses_3401f775dffeBAyLPNSrwqs4wk"
TC_RSL_05_status="pass"

# ─── All test case IDs ────────────────────────────────────────────────────────

ALL_TEST_IDS=(
  TC_01 TC_02 TC_03 TC_04 TC_05
  TC_NEG_01 TC_NEG_02 TC_NEG_03 TC_NEG_04 TC_NEG_05
  TC_RSL_01 TC_RSL_02 TC_RSL_03 TC_RSL_04 TC_RSL_05
)

# ─── Helper: get test field value ─────────────────────────────────────────────

get_field() {
  local test_id="$1" field="$2"
  local var_name="${test_id}_${field}"
  echo "${(P)var_name}"
}

# ─── record_result ────────────────────────────────────────────────────────────
# Usage: record_result <test-id> <status> <session-id> [markers-found]
# Writes a JSON result file to test/results/<test-id>.json

record_result() {
  local test_id="$1"
  local tc_status="$2"
  local session_id="$3"
  local markers_found="${4:-}"

  local agent category prompt_theme
  agent="$(get_field "$test_id" agent)"
  category="$(get_field "$test_id" category)"
  prompt_theme="$(get_field "$test_id" prompt_theme)"

  local result_file="$RESULTS_DIR/${test_id}.json"
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "$result_file" <<EOJSON
{
  "test_id": "${test_id}",
  "agent": "${agent}",
  "category": "${category}",
  "prompt_theme": "${prompt_theme}",
  "status": "${tc_status}",
  "session_id": "${session_id}",
  "markers_found": "${markers_found}",
  "timestamp": "${timestamp}"
}
EOJSON

  ok "Recorded result: ${test_id} → ${tc_status} (${result_file})"
}

# ─── validate_markers ─────────────────────────────────────────────────────────
# Usage: validate_markers <test-id> <response-text>
# Checks that expected markers appear in the response.
# Returns 0 if >=3 markers found, 1 otherwise. Prints found/missing.

validate_markers() {
  local test_id="$1"
  local response_text="$2"

  local markers_csv
  markers_csv="$(get_field "$test_id" markers)"

  if [[ -z "$markers_csv" ]]; then
    warn "No markers defined for ${test_id}"
    return 0
  fi

  local -a markers=("${(@s/,/)markers_csv}")
  local found=0
  local total=${#markers[@]}
  local -a found_list=()
  local -a missing_list=()

  local marker
  for marker in "${markers[@]}"; do
    marker="${marker## }"  # trim leading space
    marker="${marker%% }"  # trim trailing space
    if [[ "$response_text" == *"$marker"* ]]; then
      found=$((found + 1))
      found_list+=("$marker")
    else
      missing_list+=("$marker")
    fi
  done

  log "Markers for ${test_id}: ${found}/${total} found"
  if (( ${#found_list[@]} > 0 )); then
    log "  Found: ${(j:, :)found_list}"
  fi
  if (( ${#missing_list[@]} > 0 )); then
    warn "  Missing: ${(j:, :)missing_list}"
  fi

  if (( found >= 3 )); then
    return 0
  else
    return 1
  fi
}

# ─── validate_anti_markers ───────────────────────────────────────────────────
# Usage: validate_anti_markers <test-id> <response-text>
# Checks that anti-markers do NOT appear at specialist depth.
# Returns 0 if <2 anti-markers found (pass), 1 if >=2 found (fail).

validate_anti_markers() {
  local test_id="$1"
  local response_text="$2"

  local anti_markers_csv
  anti_markers_csv="$(get_field "$test_id" anti_markers)"

  if [[ -z "$anti_markers_csv" ]]; then
    return 0
  fi

  local -a anti_markers=("${(@s/,/)anti_markers_csv}")
  local triggered=0
  local -a triggered_list=()

  local marker
  for marker in "${anti_markers[@]}"; do
    marker="${marker## }"
    marker="${marker%% }"
    if [[ "$response_text" == *"$marker"* ]]; then
      triggered=$((triggered + 1))
      triggered_list+=("$marker")
    fi
  done

  if (( triggered > 0 )); then
    warn "Anti-markers triggered for ${test_id}: ${triggered} — ${(j:, :)triggered_list}"
  else
    log "Anti-markers for ${test_id}: 0 triggered (clean)"
  fi

  if (( triggered >= 2 )); then
    return 1
  else
    return 0
  fi
}

# ─── report_results ──────────────────────────────────────────────────────────
# Prints a human-readable summary of all test results.

report_results() {
  local pass=0 fail=0 pending=0 total=${#ALL_TEST_IDS[@]}

  print ""
  print "Agent Routing Test Results"
  print "========================="
  print ""
  printf "%-12s %-28s %-20s %-8s %s\n" "Test ID" "Agent" "Category" "Status" "Session"
  printf "%-12s %-28s %-20s %-8s %s\n" "-------" "-----" "--------" "------" "-------"

  local test_id agent category tc_status session_id
  for test_id in "${ALL_TEST_IDS[@]}"; do
    agent="$(get_field "$test_id" agent)"
    agent="$(get_field "$test_id" agent)"
    category="$(get_field "$test_id" category)"
    tc_status="$(get_field "$test_id" status)"
    session_id="$(get_field "$test_id" session_id)"

    # Check for recorded result file (overrides built-in status)
    local result_file="$RESULTS_DIR/${test_id}.json"
    if [[ -f "$result_file" ]]; then
      # Extract status from JSON (simple grep, no jq dependency)
      local file_status
      file_status="$(grep '"status"' "$result_file" | sed 's/.*: *"\([^"]*\)".*/\1/')"
      if [[ -n "$file_status" ]]; then
        tc_status="$file_status"
      fi
    fi

    case "$tc_status" in
      pass)    pass=$((pass + 1));    printf "%-12s %-28s %-20s \033[32m%-8s\033[0m %s\n" "$test_id" "$agent" "$category" "PASS" "$session_id" ;;
      fail)    fail=$((fail + 1));    printf "%-12s %-28s %-20s \033[31m%-8s\033[0m %s\n" "$test_id" "$agent" "$category" "FAIL" "$session_id" ;;
      pending) pending=$((pending + 1)); printf "%-12s %-28s %-20s \033[33m%-8s\033[0m %s\n" "$test_id" "$agent" "$category" "PENDING" "$session_id" ;;
      *)       pending=$((pending + 1)); printf "%-12s %-28s %-20s %-8s %s\n" "$test_id" "$agent" "$category" "$tc_status" "$session_id" ;;
    esac
  done

  print ""
  print "Summary: ${pass} pass, ${fail} fail, ${pending} pending (${total} total)"

  if (( fail > 0 )); then
    print ""
    warn "Some tests failed. Review results in $RESULTS_DIR/"
  fi

  print ""
}

# ─── report_results_json ─────────────────────────────────────────────────────
# Prints a JSON summary of all test results.

report_results_json() {
  local pass=0 fail=0 pending=0 total=${#ALL_TEST_IDS[@]}
  local first=true

  print "{"
  print "  \"test_results\": ["

  local test_id agent category tc_status session_id expected_specialist
  for test_id in "${ALL_TEST_IDS[@]}"; do
    agent="$(get_field "$test_id" agent)"
    agent="$(get_field "$test_id" agent)"
    category="$(get_field "$test_id" category)"
    tc_status="$(get_field "$test_id" status)"
    session_id="$(get_field "$test_id" session_id)"
    expected_specialist="$(get_field "$test_id" expected_specialist)"

    # Check for recorded result file
    local result_file="$RESULTS_DIR/${test_id}.json"
    if [[ -f "$result_file" ]]; then
      local file_status
      file_status="$(grep '"status"' "$result_file" | sed 's/.*: *"\([^"]*\)".*/\1/')"
      if [[ -n "$file_status" ]]; then
        tc_status="$file_status"
      fi
    fi

    case "$tc_status" in
      pass)    pass=$((pass + 1)) ;;
      fail)    fail=$((fail + 1)) ;;
      *)       pending=$((pending + 1)) ;;
    esac

    if [[ "$first" == "true" ]]; then
      first=false
    else
      print ","
    fi

    printf '    {"test_id": "%s", "agent": "%s", "category": "%s", "status": "%s", "session_id": "%s"' \
      "$test_id" "$agent" "$category" "$tc_status" "$session_id"
    if [[ -n "$expected_specialist" ]]; then
      printf ', "expected_specialist": "%s"' "$expected_specialist"
    fi
    printf "}"
  done

  print ""
  print "  ],"
  print "  \"summary\": {"
  print "    \"pass\": ${pass},"
  print "    \"fail\": ${fail},"
  print "    \"pending\": ${pending},"
  print "    \"total\": ${total}"
  print "  }"
  print "}"
}

# ─── list_test_cases ──────────────────────────────────────────────────────────
# Lists all registered test cases with metadata.

list_test_cases() {
  print ""
  print "Registered Test Cases"
  print "====================="
  print ""
  printf "%-12s %-28s %-20s %s\n" "Test ID" "Agent" "Category" "Prompt Theme"
  printf "%-12s %-28s %-20s %s\n" "-------" "-----" "--------" "------------"

  local test_id agent category prompt_theme
  for test_id in "${ALL_TEST_IDS[@]}"; do
    agent="$(get_field "$test_id" agent)"
    agent="$(get_field "$test_id" agent)"
    category="$(get_field "$test_id" category)"
    prompt_theme="$(get_field "$test_id" prompt_theme)"
    printf "%-12s %-28s %-20s %s\n" "$test_id" "$agent" "$category" "$prompt_theme"
  done

  print ""
  print "Total: ${#ALL_TEST_IDS[@]} test cases"
  print ""
}

# ─── show_help ────────────────────────────────────────────────────────────────

show_help() {
  cat <<EOF
run-agent-routing-tests.zsh — Agent routing test harness automation

USAGE:
  run-agent-routing-tests.zsh --list                             List all test cases
  run-agent-routing-tests.zsh --report                           Show human-readable results
  run-agent-routing-tests.zsh --report-json                      Show JSON results
  run-agent-routing-tests.zsh --record <test-id> <status> <session-id> [markers]
                                                                  Record a test result
  run-agent-routing-tests.zsh --help                             Show this help

SUBCOMMANDS:
  --list          List all 15 registered test cases with metadata.
  --report        Print a human-readable table of test results.
  --report-json   Print a JSON summary of all test results.
  --record        Record a test result to test/results/<test-id>.json.
                  <status> must be 'pass' or 'fail'.
                  <session-id> is the OpenCode session ID.
                  [markers] is an optional comma-separated list of found markers.
  --help          Show this help message.

EXAMPLES:
  # List all test cases
  ./test/run-agent-routing-tests.zsh --list

  # Record a passing result
  ./test/run-agent-routing-tests.zsh --record TC_01 pass ses_abc123 "Pinia,vue-router"

  # Show results in JSON
  ./test/run-agent-routing-tests.zsh --report-json | jq .

TEST CATEGORIES:
  positive          Agent receives in-domain prompt, must respond with domain markers.
  negative          Agent receives cross-domain prompt, must reject and redirect.
  router-selection  Router receives prompt, must select correct specialist.

EOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  local cmd="${1:---help}"

  case "$cmd" in
    --list)
      list_test_cases
      ;;
    --report)
      report_results
      ;;
    --report-json)
      report_results_json
      ;;
    --record)
      if (( $# < 4 )); then
        die "Usage: --record <test-id> <status> <session-id> [markers-found]"
      fi
      record_result "$2" "$3" "$4" "${5:-}"
      ;;
    --help | -h | help)
      show_help
      ;;
    *)
      warn "Unknown command: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
