#!/usr/bin/env bash
# 共享函数:解析 PHP / Composer / searchd 路径
# 供 start.sh / stop.sh / setup.sh source,不单独执行

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# PHP CLI:优先仓库自带 .runtime/php/php,其次系统 php
find_php() {
  if [ -x "$ROOT/.runtime/php/php" ]; then
    echo "$ROOT/.runtime/php/php"
  elif have_cmd php; then
    command -v php
  else
    return 1
  fi
}

# searchd:优先仓库自带 .runtime,其次系统 searchd
find_searchd() {
  if [ -x "$ROOT/.runtime/manticore/rootfs/usr/bin/searchd" ]; then
    echo "$ROOT/.runtime/manticore/rootfs/usr/bin/searchd"
  elif have_cmd searchd; then
    command -v searchd
  else
    return 1
  fi
}

# 安装 Composer 依赖(vendor/ 被 gitignore,克隆后必须执行)
composer_install() {
  local php="$1"
  if have_cmd composer; then
    (cd "$ROOT" && composer install --no-interaction --prefer-dist)
  elif [ -f "$ROOT/.runtime/bin/composer.phar" ]; then
    (cd "$ROOT" && "$php" "$ROOT/.runtime/bin/composer.phar" install --no-interaction --prefer-dist)
  else
    return 1
  fi
}

# 确保 vendor/autoload.php 存在,缺失时自动 composer install
ensure_vendor() {
  local php="$1"
  [ -f "$ROOT/vendor/autoload.php" ] && return 0
  echo "vendor/autoload.php 不存在,正在安装 Composer 依赖..."
  composer_install "$php"
}
