#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

CHANGELOG_PATH="$ROOT_DIR/CHANGELOG.md"

usage() {
  cat <<'EOF'
Usage: scripts/release.zsh [--version <vX.Y.Z>] [--tag-postfix <POSTFIX>] [--dry-run]

Creates a release commit from CHANGELOG.md, then tags it.

Behavior:
- Prompts for version when not provided
- Rejects tag creation when any existing tag is an exact or prefix match
  (example: v0.1.5 is blocked if v0.1.5-ndream exists)
- Moves CHANGELOG.md [Unreleased] entries into a new "## [X.Y.Z] - YYYY-MM-DD" section
  (note: no 'v' prefix and no postfix in CHANGELOG header)
- Commits CHANGELOG.md and creates the git tag with optional postfix
  (tag format: v{version}-{postfix} or v{version} if no postfix)

Options:
  --version <v>       Version/tag to create (e.g., v0.1.6)
  --tag-postfix <p>   Optional postfix for git tag only, not used in CHANGELOG (e.g., ndream)
  --dry-run           Print what would happen; do not modify git or files
  -h, --help          Show this help
EOF
}

VERSION=""
TAG_POSTFIX=""
DRY_RUN=false

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --version)
        VERSION="${2:-}"
        shift
        ;;
      --tag-postfix)
        TAG_POSTFIX="${2:-}"
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1 (run scripts/release.zsh --help)"
        ;;
    esac
    shift
  done
}

prompt_version_if_needed() {
  if [[ -n "$VERSION" ]]; then
    return 0
  fi

  if ! is_interactive; then
    die "Missing --version in non-interactive mode"
  fi

  print -r -- "Enter version (e.g., v0.1.6): "
  read -r VERSION

  if [[ -z "$VERSION" ]]; then
    die "Version cannot be empty"
  fi
}

prompt_postfix_if_needed() {
  if [[ -n "$TAG_POSTFIX" ]]; then
    return 0
  fi

  if ! is_interactive; then
    return 0
  fi

  print -r -- "Enter tag postfix (optional, press enter to skip): "
  read -r TAG_POSTFIX

  # TAG_POSTFIX can be empty; that's fine
}

normalize_tag() {
  local input="$1"
  local v
  v="${input#v}"

  if [[ ! "$v" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    die "Version must match vX.Y.Z (got: $input)"
  fi

  print -r -- "v${v}"
}

assert_clean_worktree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    die "Working tree is not clean (commit/stash changes before releasing)"
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    die "Working tree has uncommitted changes (commit/stash before releasing)"
  fi
}

assert_tag_no_prefix_conflicts() {
  local candidate="$1"

  # Build the full tag name (candidate already includes 'v' prefix)
  local full_tag
  if [[ -n "$TAG_POSTFIX" ]]; then
    full_tag="${candidate}-${TAG_POSTFIX}"
  else
    full_tag="$candidate"
  fi

  # Check if exact tag already exists
  if git rev-parse -q --verify "refs/tags/${full_tag}" >/dev/null 2>&1; then
    print -u2 "ERROR: Tag '$full_tag' already exists"
    return 1
  fi

  # Check if any tag starts with our candidate (without postfix)
  # This prevents v0.1.6 being created if v0.1.6-ndream already exists
  local -a conflicts
  conflicts=( $(git for-each-ref --format='%(refname:short)' "refs/tags/${candidate}*" 2>/dev/null || true) )

  if (( ${#conflicts[@]} > 0 )); then
    print -u2 "ERROR: Cannot create tag '$full_tag'. Conflicting tags exist:"
    local t
    for t in "${conflicts[@]}"; do
      print -u2 "  $t"
    done
    return 1
  fi

  return 0
}

assert_changelog_ready() {
  [[ -f "$CHANGELOG_PATH" ]] || die "Missing CHANGELOG.md at $CHANGELOG_PATH"

  if ! grep -q '^## \[Unreleased\]$' "$CHANGELOG_PATH"; then
    die "CHANGELOG.md is missing a '## [Unreleased]' section"
  fi
}

assert_unreleased_not_empty() {
  local unreleased_body
  unreleased_body="$(
    awk '
      $0 ~ /^## \[Unreleased\]$/ { in_unreleased=1; next }
      $0 ~ /^## \[/ { if (in_unreleased) exit }
      in_unreleased { print }
    ' "$CHANGELOG_PATH"
  )"

  if [[ -z "${unreleased_body//[[:space:]]/}" ]]; then
    die "[Unreleased] section is empty; nothing to release"
  fi
}

assert_version_not_in_changelog() {
  local version="$1"
  if grep -q "^## \[${version}\]" "$CHANGELOG_PATH"; then
    die "CHANGELOG.md already contains an entry for $version"
  fi
}

update_changelog() {
  local version="$1"
  local release_date="$2"

  local tmp
  tmp="$(mktemp)"
  trap "rm -f '$tmp'" EXIT INT TERM

  awk -v version="$version" -v date="$release_date" '
  BEGIN { in_unreleased = 0; buf = ""; done = 0 }

  /^## \[Unreleased\]$/ {
    if (!done) { in_unreleased = 1; buf = ""; next }
    print; next
  }

  /^## \[/ {
    if (in_unreleased && !done) {
      print "## [Unreleased]"
      print ""
      print "### Added"
      print ""
      print "## [" version "] - " date
      n = split(buf, lines, "\n")
      pending = ""; has = 0
      for (i = 1; i <= n; i++) {
        l = lines[i]
        if (l ~ /^### /) {
          pending = l; has = 0
        } else if (l ~ /^[[:space:]]*$/) {
          if (has) print l
        } else {
          if (!has && pending != "") { print ""; print pending; pending = "" }
          has = 1; print l
        }
      }
      in_unreleased = 0; done = 1
    }
    print; next
  }

  in_unreleased { buf = buf $0 "\n"; next }

  { print }

  END {
    if (in_unreleased && !done) {
      print "## [Unreleased]"
      print ""
      print "### Added"
      print ""
      print "## [" version "] - " date
      n = split(buf, lines, "\n")
      pending = ""; has = 0
      for (i = 1; i <= n; i++) {
        l = lines[i]
        if (l ~ /^### /) {
          pending = l; has = 0
        } else if (l ~ /^[[:space:]]*$/) {
          if (has) print l
        } else {
          if (!has && pending != "") { print ""; print pending; pending = "" }
          has = 1; print l
        }
      }
    }
  }
  ' "$CHANGELOG_PATH" >"$tmp"

  if [[ ! -s "$tmp" ]]; then
    die "Failed to update CHANGELOG.md (output file was empty)"
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    ok "[dry-run] Would update CHANGELOG.md for $version"
    echo ""
    echo "=== New CHANGELOG.md (dry-run preview) ==="
    cat "$tmp"
    echo "==========================================="
    return 0
  fi

  mv "$tmp" "$CHANGELOG_PATH"
}

create_release_commit() {
  local tag="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    ok "[dry-run] Would commit CHANGELOG.md with message: chore(release): $tag"
    return 0
  fi

  git add "$CHANGELOG_PATH"
  git commit -m "chore(release): $tag"
}

create_tag() {
  local tag="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    ok "[dry-run] Would create git tag: $tag"
    return 0
  fi

  git tag "$tag"
}

main() {
  cd "$ROOT_DIR" || die "Cannot cd to ROOT_DIR: $ROOT_DIR"

  require_cmd git
  require_cmd awk
  require_cmd mktemp

  parse_args "$@"
  prompt_version_if_needed
  prompt_postfix_if_needed

  local tag changelog_version release_date
  changelog_version="$(normalize_tag "$VERSION")"
  tag="$changelog_version"  # Start with version without postfix
  release_date="$(date +%Y-%m-%d)"

  # Add postfix to tag if provided
  if [[ -n "$TAG_POSTFIX" ]]; then
    tag="${tag}-${TAG_POSTFIX}"
  fi

  assert_changelog_ready
  assert_version_not_in_changelog "$changelog_version"

  if [[ "$DRY_RUN" != "true" ]]; then
    assert_clean_worktree
  fi

  assert_tag_no_prefix_conflicts "$changelog_version" || die "Tag conflict detected"
  assert_unreleased_not_empty

  log "Releasing $tag ($release_date)"
  update_changelog "$changelog_version" "$release_date"
  create_release_commit "$tag"
  create_tag "$tag"

  ok "Release prepared: $tag"
  if [[ "$DRY_RUN" != "true" ]]; then
    log "Next: git push && git push --tags"
  fi
}

main "$@"
