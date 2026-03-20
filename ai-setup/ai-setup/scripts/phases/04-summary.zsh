#!/usr/bin/env zsh
set -euo pipefail

STATUS="unknown"
STEPS=""
NEXT_COMMAND=""

while (( $# > 0 )); do
  case "$1" in
    --status)
      STATUS="$2"
      shift 2
      ;;
    --steps)
      STEPS="$2"
      shift 2
      ;;
    --next)
      NEXT_COMMAND="$2"
      shift 2
      ;;
    *)
      print -r -- "Unknown summary option: $1" >&2
      exit 1
      ;;
  esac
done

print -r -- "SUMMARY: status=$STATUS"
print -r -- "SUMMARY: steps=$STEPS"
if [[ -n "$NEXT_COMMAND" ]]; then
  print -r -- "SUMMARY: next=$NEXT_COMMAND"
fi
