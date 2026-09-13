# 公开课资料索引站

基于 **webman** + **Manticore Search** 的公开课程资料元数据索引站。仅收录资料的标题、类型、大小、发布时间、摘要等元数据,**不提供任何文件存储与下载**,全站附带合规提示与免责声明。

## 功能

- **首页**:关键词搜索框、热门关键词、最新收录、全站统计
- **结果页**:标题 / 文件类型徽标 / 大小 / 发布时间 / 高亮摘要,支持类型筛选与分页
- **详情页**:资料简介、完整文件清单、相似资料推荐(基于课程+标签的 More-Like-This 检索)
- **合规**:全站顶部合规横幅、页脚版权声明、详情页提示框、`/disclaimer` 完整免责声明
- **数据**:`scripts/seed.php` 一键导入 36 条虚构模拟数据

## 目录结构

```
app/controller/     Index(首页/免责声明) Search(结果页) Material(详情页)
app/service/        Manticore PDO 客户端(SphinxQL)
app/view/           Raw PHP 模板
config/manticore.php 搜索服务连接配置(支持 MANTICORE_HOST/PORT 环境变量覆盖)
scripts/setup.sh    全新克隆的一键准备(PHP/Composer 依赖/搜索服务检查)
scripts/start.sh    启动 Manticore 与 webman
scripts/stop.sh     停止服务
scripts/seed.php    建表 + 导入模拟数据
```

## 运行环境

本仓库运行时使用免安装组件(位于 `.runtime/`,已 gitignore):

- PHP 8.4 静态二进制(static-php-cli)
- Manticore Search 29(deb 解包,监听 `9306` MySQL 协议 / `9308` HTTP)

常规环境(有系统 PHP 8.1+ 与 Manticore)时,直接 `composer install` 并修改 `config/manticore.php` 连接信息即可。

## 快速开始

`vendor/` 与 `.runtime/` 不随仓库分发(见 .gitignore),全新克隆请先做一次准备:

```bash
# 0. 全新克隆:准备 PHP 运行时、Composer 依赖与搜索服务(已就绪的步骤会自动跳过)
bash scripts/setup.sh

# 1. 启动搜索服务与 web 服务
bash scripts/start.sh

# 2. 导入模拟数据(建表 + 写入)
php scripts/seed.php            # 本仓库环境: .runtime/php/php scripts/seed.php

# 3. 访问
# 首页   http://127.0.0.1:8787/
# 搜索   http://127.0.0.1:8787/search?q=操作系统
# 详情   http://127.0.0.1:8787/material/1
```

`scripts/start.sh` 会依次解析:PHP(`.runtime/php/php` → 系统 `php`)、Composer 依赖(缺失时自动 `composer install`)、搜索服务(`.runtime` 自带 searchd → 系统 `searchd` → 报错并给出 Docker/安装指引)。

## 索引结构(Manticore RT 表)

| 字段 | 类型 | 说明 |
|---|---|---|
| title / summary / course / tags | text | 全文索引(`ngram_len=1` 支持中文检索) |
| file_type | string | 文件类型(pdf/ppt/doc/zip/epub/mp4),用于筛选 |
| file_size | bigint | 总字节数 |
| files | json | 文件清单 `[{name, size}]` |
| downloads | int | 热度 |
| published_at | timestamp | 发布时间 |

## 合规说明

本站为学习导航类索引演示项目:不存储、不传输任何课程文件;所有资料信息归原作者/机构所有;提供"通知-删除"渠道(takedown@example.com),核实后 48 小时内移除索引。详见 `/disclaimer` 页面。
