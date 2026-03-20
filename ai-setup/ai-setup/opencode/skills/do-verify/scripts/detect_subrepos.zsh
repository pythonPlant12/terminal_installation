#!/usr/bin/env zsh
# detect_subrepos.zsh — Scan for nested git repositories with non-default branch checkouts
#
# Usage: detect_subrepos.zsh [search-root] [max-depth]
#   search-root  Directory to scan (default: repo root derived from script location)
#   max-depth    Max depth for find (default: 3)
#
# Output: one line per sub-repo discovered (colon-delimited):
#   NON_DEFAULT:<abs-path>:<current-branch>:<default-branch>
#   UNKNOWN_DEFAULT:<abs-path>:<current-branch>
#   ON_DEFAULT:<abs-path>:<current-branch>:<default-branch>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SEARCH_ROOT="${1:-$ROOT_DIR}"
MAX_DEPTH="${2:-3}"

SEARCH_ROOT="$(cd "$SEARCH_ROOT" && pwd -P 2>/dev/null || echo "$SEARCH_ROOT")"

get_default_branch() {
  local repo_path="$1"
  local val

  if val="$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"; then
    if [[ -n "$val" ]]; then
      printf '%s' "${val#refs/remotes/origin/}"
      return 0
    fi
  fi

  if val="$(git -C "$repo_path" config --get init.defaultBranch 2>/dev/null)"; then
    if [[ -n "$val" ]]; then
      printf '%s' "$val"
      return 0
    fi
  fi

  if val="$(git -C "$repo_path" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"; then
    if [[ -n "$val" && "$val" != "(unknown)" ]]; then
      printf '%s' "$val"
      return 0
    fi
  fi

  return 1
}

scan_subrepos() {
  local search_root="$1"
  local max_depth="$2"

  local main_top
  main_top="$(git -C "$search_root" rev-parse --show-toplevel 2>/dev/null || true)"

  local -a candidates
  candidates=()
  while IFS= read -r entry; do
    candidates+=("$entry")
  done < <(
    find "$search_root" \
      -maxdepth "$max_depth" \
      -mindepth 1 \
      \( -type d -o -type l \) \
      -not -name '.git' \
      -not -path '*/.git' \
      -not -path '*/.git/*' \
      2>/dev/null | sort
  )

  local candidate real_path repo_top current_branch default_branch
  for candidate in "${candidates[@]}"; do
    if ! real_path="$(cd "$candidate" && pwd -P 2>/dev/null)"; then
      continue
    fi

    if ! repo_top="$(git -C "$real_path" rev-parse --show-toplevel 2>/dev/null)"; then
      continue
    fi
    [[ "$repo_top" != "$real_path" ]] && continue
    [[ -n "$main_top" && "$repo_top" == "$main_top" ]] && continue

    if ! current_branch="$(git -C "$real_path" rev-parse --abbrev-ref HEAD 2>/dev/null)"; then
      continue
    fi
    [[ "$current_branch" == "HEAD" ]] && continue

    if ! default_branch="$(get_default_branch "$real_path")"; then
      printf 'UNKNOWN_DEFAULT:%s:%s\n' "$real_path" "$current_branch"
      continue
    fi

    if [[ "$current_branch" == "$default_branch" ]]; then
      printf 'ON_DEFAULT:%s:%s:%s\n' "$real_path" "$current_branch" "$default_branch"
    else
      printf 'NON_DEFAULT:%s:%s:%s\n' "$real_path" "$current_branch" "$default_branch"
    fi
  done
}

scan_subrepos "$SEARCH_ROOT" "$MAX_DEPTH"
