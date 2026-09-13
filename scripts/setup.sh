#!/usr/bin/env bash
# 全新克隆环境的一键准备脚本:
#   1) 确保 PHP CLI 可用(缺失时下载 static-php 免安装二进制到 .runtime/php/)
#   2) 确保 Composer 可用(缺失时下载 composer.phar 到 .runtime/bin/)
#   3) composer install 安装 vendor 依赖
#   4) 检查 Manticore Search(searchd);有 Docker 时可自动拉起,否则给出安装指引
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/env.sh"

STATIC_PHP_VERSION="${STATIC_PHP_VERSION:-8.4.15}"
ok()   { echo "  [OK] $*"; }
todo() { echo "  [..] $*"; }

echo "==> 1/4 检查 PHP CLI"
if PHP="$(find_php)"; then
  ok "PHP: $PHP ($("$PHP" -r 'echo PHP_VERSION;'))"
else
  todo "未找到 PHP,下载 static-php ${STATIC_PHP_VERSION} 免安装二进制..."
  case "$(uname -m)" in
    x86_64|amd64)  ARCH=x86_64 ;;
    aarch64|arm64) ARCH=aarch64 ;;
    *) echo "错误: 不支持的架构 $(uname -m),请手动安装 PHP 8.1+" >&2; exit 1 ;;
  esac
  URL="https://dl.static-php.dev/static-php-cli/common/php-${STATIC_PHP_VERSION}-cli-linux-${ARCH}.tar.gz"
  mkdir -p "$ROOT/.runtime/php"
  if have_cmd curl;  then curl -fSL "$URL" -o /tmp/static-php.tar.gz;
  elif have_cmd wget; then wget -O /tmp/static-php.tar.gz "$URL";
  else echo "错误: 需要 curl 或 wget 下载 $URL" >&2; exit 1; fi
  tar xzf /tmp/static-php.tar.gz -C "$ROOT/.runtime/php/"
  rm -f /tmp/static-php.tar.gz
  chmod +x "$ROOT/.runtime/php/php"
  PHP="$ROOT/.runtime/php/php"
  ok "PHP 已安装到 .runtime/php/php ($("$PHP" -r 'echo PHP_VERSION;'))"
fi

# webman 必需扩展检查
missing_ext=""
for ext in pdo_mysql pcntl posix; do
  "$PHP" -m | grep -qi "^${ext}$" || missing_ext="$missing_ext $ext"
done
if [ -n "$missing_ext" ]; then
  echo "错误: 当前 PHP 缺少扩展:$missing_ext (webman/PDO 必需)" >&2
  exit 1
fi
ok "扩展 pdo_mysql / pcntl / posix 齐全"

echo "==> 2/4 检查 Composer"
if have_cmd composer; then
  ok "Composer: $(command -v composer)"
elif [ -f "$ROOT/.runtime/bin/composer.phar" ]; then
  ok "Composer: .runtime/bin/composer.phar"
else
  todo "未找到 Composer,下载 composer.phar..."
  mkdir -p "$ROOT/.runtime/bin"
  if have_cmd curl;  then curl -fSL https://getcomposer.org/download/latest-stable/composer.phar -o "$ROOT/.runtime/bin/composer.phar";
  elif have_cmd wget; then wget -O "$ROOT/.runtime/bin/composer.phar" https://getcomposer.org/download/latest-stable/composer.phar;
  else echo "错误: 需要 curl 或 wget 下载 composer.phar" >&2; exit 1; fi
  ok "Composer 已安装到 .runtime/bin/composer.phar"
fi

echo "==> 3/4 安装 Composer 依赖"
composer_install "$PHP"
ok "vendor/ 依赖就绪"

echo "==> 4/4 检查 Manticore Search"
if (echo > /dev/tcp/127.0.0.1/9306) 2>/dev/null; then
  ok "9306 已有 Manticore 在运行"
elif SEARCHD="$(find_searchd)"; then
  ok "searchd: $SEARCHD (将由 scripts/start.sh 启动)"
elif have_cmd docker; then
  todo "未找到 searchd,使用 Docker 启动 manticoresearch/manticore ..."
  docker rm -f manticore >/dev/null 2>&1 || true
  docker run -d --name manticore -p 9306:9306 -p 9308:9308 manticoresearch/manticore
  ok "Manticore 容器已启动(9306/9308)"
else
  cat >&2 <<'TIP'
错误: 未找到 Manticore Search(searchd),且本机无 Docker 可自动拉起。
     任选其一准备搜索服务后重试:
       a) 安装 Docker 后重新运行本脚本(自动拉起 manticoresearch/manticore)
       b) 系统安装: https://manticoresearch.com/install/
       c) 手动放置免安装组件(目录结构参考 README「运行环境」):
            .runtime/manticore/rootfs/usr/bin/searchd   (deb 解包)
            .runtime/manticore/manticore.conf           (listen 9306/9308,data/log/run 目录)
TIP
  exit 1
fi

echo
echo "准备完成! 接下来:"
echo "  bash scripts/start.sh     # 启动 Manticore + webman"
echo "  php scripts/seed.php      # 导入模拟数据(本仓库环境: .runtime/php/php scripts/seed.php)"
echo "  访问 http://127.0.0.1:8787"
