#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/env.sh"

if PHP="$(find_php)"; then
  (cd "$ROOT" && "$PHP" start.php stop) || true
else
  echo "未找到 PHP,跳过 webman 停止(如仍在运行请手动结束进程)"
fi

PID_FILE="$ROOT/.runtime/manticore/run/searchd.pid"
if [ -f "$PID_FILE" ]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null && echo "manticore stopped" || true
fi
