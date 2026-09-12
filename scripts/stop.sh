#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PHP="$ROOT/.runtime/php/php"
cd "$ROOT" && "$PHP" start.php stop || true
if [ -f "$ROOT/.runtime/manticore/run/searchd.pid" ]; then
  kill "$(cat "$ROOT/.runtime/manticore/run/searchd.pid")" 2>/dev/null && echo "manticore stopped" || true
fi
