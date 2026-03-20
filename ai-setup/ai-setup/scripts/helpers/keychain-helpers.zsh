#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

# store_in_keychain(service, value)
# Stores a value in macOS Keychain for the current user.
# Uses 'security add-generic-password' with -U flag for idempotent updates.
# Returns 0 on success, 1 on Keychain error.
store_in_keychain() {
  local service="$1"
  local value="$2"
  
  if security add-generic-password -U -s "$service" -a "$USER" -w "$value" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# retrieve_from_keychain(service)
# Retrieves a stored value from Keychain.
# Returns the value to stdout (empty string if not found).
# Exit code is always 0 (use stdout empty-check if needed).
retrieve_from_keychain() {
  local service="$1"
  
  security find-generic-password -s "$service" -a "$USER" -w 2>/dev/null || true
  return 0
}

# validate_atlassian_token(url, email, token)
# Tests Atlassian credentials against Jira API.
# Makes HTTP request to {url}/rest/api/3/myself with Basic auth (email:token)
# Returns 0 if HTTP 200 (valid), 1 if HTTP 401 (invalid), 2 if unreachable.
# Uses curl with -s -o /dev/null -w "%{http_code}" to check status without body.
validate_atlassian_token() {
  local url="$1"
  local email="$2"
  local token="$3"
  
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${email}:${token}" \
    "${url}/rest/api/3/myself" 2>/dev/null || echo "000")
  
  case "$http_code" in
    200)
      return 0
      ;;
    401)
      return 1
      ;;
    *)
      return 2
      ;;
  esac
}
