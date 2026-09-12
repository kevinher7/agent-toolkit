#!/usr/bin/env bash
# Run the bee repo's Python type checker (ty).
#
# Usage:
#   bee.sh all                          # check the whole project
#   bee.sh <file1.py> <file2.py> ...    # check only the listed files
#
# Exits 127 if ty is not installed (tried `poetry run ty` then `ty`).
# Other exit codes are passed through from ty.
set -uo pipefail

MODE=${1:-all}

# Pick runner: prefer poetry; fall back to bare ty.
if command -v poetry >/dev/null 2>&1; then
  RUNNER=("poetry" "run" "ty" "check")
elif command -v ty >/dev/null 2>&1; then
  RUNNER=("ty" "check")
else
  echo "type-reviewer: ty is not installed (tried 'poetry run ty', 'ty')" >&2
  exit 127
fi

if [ "$MODE" = "all" ]; then
  "${RUNNER[@]}" 2>&1
  exit $?
fi

# Subset mode: filter args to .py only, then check.
PY_FILES=()
for f in "$@"; do
  case "$f" in
    *.py) PY_FILES+=("$f") ;;
  esac
done

if [ ${#PY_FILES[@]} -eq 0 ]; then
  echo "(no .py files in change set)"
  exit 0
fi

"${RUNNER[@]}" "${PY_FILES[@]}" 2>&1
