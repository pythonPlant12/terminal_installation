# Mandatory Pre-Merge Shell Checklist

Run every check. Treat any `FAIL` as a merge blocker.

## 1) Interactive Guard

Requirement:
- Guard interactive prompts and destructive manual flows with a TTY check or explicit non-interactive flag.

Fail patterns:
- `read` or `read -p` without a prior interactive guard.
- Prompt-only confirmation for destructive actions with no `--yes` bypass.

Pass patterns:
- `[[ -t 0 && -t 1 ]] || die "Interactive terminal required"`
- `if [[ ! -t 0 ]]; then ... fi`
- `--yes`/`--non-interactive` mode that skips prompts safely.

Quick scan:
```bash
rg -n 'read -r|read -p|read -s' bin scripts
rg -n '\-\-yes|\-\-non-interactive|tty| -t 0| -t 1' bin scripts
```

## 2) Readonly Name Blacklist

Requirement:
- Reject `readonly` declarations for sensitive shell/env names that can break execution or diagnostics.

Blacklist:
- `PATH`
- `IFS`
- `HOME`
- `PWD`
- `OLDPWD`
- `UID`
- `EUID`
- `SHELLOPTS`
- `BASHOPTS`
- `RANDOM`
- `SECONDS`
- `LINENO`
- `FUNCNAME`
- `BASH_SOURCE`

Fail pattern:
- `readonly <blacklisted_name>=...`

Pass patterns:
- Use project-scoped readonly names such as `ROOT_DIR`, `SCRIPT_PATH`, `SNAPSHOT_DIR`.
- Keep shell-managed vars unmanaged.

Quick scan:
```bash
rg -n 'readonly (PATH|IFS|HOME|PWD|OLDPWD|UID|EUID|SHELLOPTS|BASHOPTS|RANDOM|SECONDS|LINENO|FUNCNAME|BASH_SOURCE)\b' bin scripts
```

## 3) Safe Arithmetic Patterns

Requirement:
- Perform arithmetic only on initialized or validated numeric values.

Fail patterns:
- Arithmetic over unchecked external input.
- `expr`/`let` usage in new code when `(( ... ))` or `$(( ... ))` is clearer and safer.
- Arithmetic on possibly unset variables under `set -u`.

Pass patterns:
- Initialize first: `local -i count=0`
- Validate: `[[ "$keep" =~ ^[0-9]+$ ]] || die "keep must be a non-negative integer"`
- Normalize base-10 input: `keep=$((10#$keep))`
- Prefer: `(( count += 1 ))` and `value=$((a + b))`

Quick scan:
```bash
rg -n 'expr |(^|[^[:alnum:]_])let ' bin scripts
rg -n '\(\(' bin scripts
```

## 4) Symlink-Safe `ROOT_DIR`

Requirement:
- Resolve script location through symlinks and use physical paths (`pwd -P`) before deriving `ROOT_DIR`.

Fail patterns:
- `ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"` (not symlink-safe).
- Path derivation from `$0` alone in sourced files.

Pass pattern (bash):
```bash
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd -P)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd -P)"
ROOT_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"
readonly ROOT_DIR
```

Pass pattern (zsh):
```zsh
SCRIPT_PATH="${(%):-%x}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd -P)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd -P)"
ROOT_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"
readonly ROOT_DIR
```

Quick scan:
```bash
rg -n 'ROOT_DIR=.*dirname \"\\$0\".*pwd' bootstrap.zsh bin scripts
```

## Merge Gate Rule

Return `BLOCK` unless all four checks are `PASS`.
