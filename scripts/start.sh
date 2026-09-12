#!/usr/bin/env bash
# 启动 Manticore + webman
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PHP="$ROOT/.runtime/php/php"
SEARCHD="$ROOT/.runtime/manticore/rootfs/usr/bin/searchd"
MC_CONF="$ROOT/.runtime/manticore/manticore.conf"

# 1. 启动 Manticore(若未运行)
if ! (echo > /dev/tcp/127.0.0.1/9306) 2>/dev/null; then
  echo "starting manticore..."
  "$SEARCHD" --config "$MC_CONF"
else
  echo "manticore already running"
fi

# 2. 启动 webman
echo "starting webman..."
cd "$ROOT" && "$PHP" start.php start -d
echo "done. 访问 http://127.0.0.1:8787"
