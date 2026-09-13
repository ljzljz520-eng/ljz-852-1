#!/usr/bin/env bash
# 启动 Manticore + webman
# 全新克隆请先执行: bash scripts/setup.sh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/env.sh"

# 0. 解析 PHP(仓库自带 .runtime 优先,回退系统 php)
if ! PHP="$(find_php)"; then
  echo "错误: 未找到 PHP CLI。" >&2
  echo "     请安装 PHP 8.1+,或运行 bash scripts/setup.sh 自动下载免安装运行时。" >&2
  exit 1
fi

# 1. 确保 Composer 依赖已安装(vendor/ 不随仓库分发)
if ! ensure_vendor "$PHP"; then
  echo "错误: Composer 依赖缺失且自动安装失败(start.php 需要 vendor/autoload.php)。" >&2
  echo "     请运行 bash scripts/setup.sh,或手动执行 composer install。" >&2
  exit 1
fi

# 2. 启动 Manticore(若 9306 未监听)
if ! (echo > /dev/tcp/127.0.0.1/9306) 2>/dev/null; then
  if SEARCHD="$(find_searchd)"; then
    if [[ "$SEARCHD" == "$ROOT/.runtime/"* ]]; then
      MC_CONF="$ROOT/.runtime/manticore/manticore.conf"
    else
      MC_CONF="${MANTICORE_CONF:-/etc/manticoresearch/manticore.conf}"
    fi
    echo "starting manticore... ($SEARCHD --config $MC_CONF)"
    "$SEARCHD" --config "$MC_CONF"
  else
    echo "错误: 未找到 Manticore Search(searchd),且 127.0.0.1:9306 无服务监听。" >&2
    echo "     任选其一准备搜索服务:" >&2
    echo "       a) Docker: docker run -d --name manticore -p 9306:9306 -p 9308:9308 manticoresearch/manticore" >&2
    echo "       b) 系统安装: https://manticoresearch.com/install/" >&2
    echo "       c) 参考 README「运行环境」放置免安装组件到 .runtime/(bash scripts/setup.sh 可查看指引)" >&2
    exit 1
  fi
else
  echo "manticore already running"
fi

# 3. 启动 webman
echo "starting webman..."
cd "$ROOT" && "$PHP" start.php start -d
echo "done. 访问 http://127.0.0.1:8787"
