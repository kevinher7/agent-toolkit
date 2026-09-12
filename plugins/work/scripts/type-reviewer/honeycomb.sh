#!/usr/bin/env bash
# Check the whole project so tsconfig.json applies. The reviewing agent filters
# findings to the supplied files; retain all output and the compiler exit status.
# Usage: honeycomb.sh all | <file.ts> <file.tsx> ...
set -uo pipefail

if [ "${1:-all}" != all ]; then
  HAS_SOURCE=false
  for file in "$@"; do
    case "$file" in
      *.ts|*.tsx|*.js|*.jsx) HAS_SOURCE=true ;;
    esac
  done
  if [ "$HAS_SOURCE" = false ]; then
    echo '(no .ts/.tsx/.js/.jsx files in change set)'
    exit 0
  fi
fi

if [ ! -x node_modules/.bin/tsc ]; then
  echo 'type-reviewer: project-local TypeScript compiler is not installed' >&2
  exit 127
fi

node_modules/.bin/tsc --noEmit --pretty false 2>&1
