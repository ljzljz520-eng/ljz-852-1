<?php

namespace app\service;

use PDO;
use support\exception\BusinessException;

/**
 * Manticore(Searchd) 轻量客户端
 * 通过 MySQL 协议(SphinxQL)访问,webman 常驻进程内复用连接
 */
class Manticore
{
    protected static ?PDO $pdo = null;

    public static function pdo(): PDO
    {
        if (self::$pdo === null) {
            $cfg = config('manticore');
            self::$pdo = new PDO(
                sprintf('mysql:host=%s;port=%d;charset=utf8mb4', $cfg['host'], $cfg['port']),
                $cfg['user'],
                $cfg['pass'],
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                    PDO::ATTR_TIMEOUT            => 3,
                ]
            );
        }
        return self::$pdo;
    }

    /** 断线重连兜底执行 */
    public static function run(callable $fn)
    {
        try {
            return $fn(self::pdo());
        } catch (\Throwable $e) {
            self::$pdo = null; // 重建连接再试一次
            return $fn(self::pdo());
        }
    }

    public static function query(string $sql): array
    {
        return self::run(fn(PDO $pdo) => $pdo->query($sql)->fetchAll());
    }

    public static function one(string $sql): ?array
    {
        $rows = self::query($sql);
        return $rows[0] ?? null;
    }

    /** MATCH() 查询串转义 */
    public static function quote(string $keyword): string
    {
        $keyword = trim($keyword);
        return "'" . str_replace(['\\', "'"], ['\\\\', "\\'"], $keyword) . "'";
    }

    /** 普通字符串字面值转义 */
    public static function literal(string $value): string
    {
        return "'" . str_replace(['\\', "'"], ['\\\\', "\\'"], $value) . "'";
    }

    /**
     * 关键词搜索
     * @return array{rows:array,total:int}
     */
    public static function search(string $keyword, string $fileType = '', int $page = 1, int $perPage = 10): array
    {
        $table  = config('manticore.table');
        $where  = ['MATCH(' . self::quote($keyword) . ')'];
        if ($fileType !== '') {
            $where[] = 'file_type = ' . self::literal($fileType);
        }
        $offset = max(0, ($page - 1) * $perPage);

        $sql = sprintf(
            "SELECT id, title, summary, course, tags, file_type, file_size, downloads, published_at,
                    SNIPPET(summary, QUERY()) AS snippet, WEIGHT() AS w
             FROM %s WHERE %s
             ORDER BY w DESC, published_at DESC
             LIMIT %d, %d",
            $table, implode(' AND ', $where), $offset, $perPage
        );
        $rows = self::query($sql);

        $meta = self::query('SHOW META');
        $total = 0;
        foreach ($meta as $m) {
            if (($m['Variable_name'] ?? '') === 'total_found') {
                $total = (int)$m['Value'];
            }
        }
        return ['rows' => $rows, 'total' => $total];
    }

    /** 按 ID 取详情 */
    public static function find(int $id): ?array
    {
        $table = config('manticore.table');
        return self::one("SELECT * FROM {$table} WHERE id = {$id}");
    }

    /**
     * 相似资料:用课程名 + 标签做 More-Like-This 检索
     */
    public static function similar(array $doc, int $limit = 6): array
    {
        $table = config('manticore.table');
        // 课程名 + 标签分词后以 OR 组合;CJK 词需加双引号按短语匹配,否则 ngram 下 OR 结果异常
        $terms = preg_split('/[\s,]+/u', ($doc['course'] ?? '') . ',' . ($doc['tags'] ?? ''), -1, PREG_SPLIT_NO_EMPTY);
        $terms = array_slice(array_unique(array_map('trim', $terms ?: [])), 0, 8);
        if (!$terms) {
            return [];
        }
        $match = implode(' | ', array_map(
            fn(string $t) => '"' . str_replace('"', '', $t) . '"',
            $terms
        ));
        $sql = sprintf(
            "SELECT id, title, course, file_type, file_size, downloads, published_at
             FROM %s WHERE MATCH(%s) AND id != %d
             ORDER BY WEIGHT() DESC LIMIT %d",
            $table, self::quote($match), (int)$doc['id'], $limit
        );
        return self::query($sql);
    }

    /** 最新收录(首页展示) */
    public static function latest(int $limit = 8): array
    {
        $table = config('manticore.table');
        return self::query(
            "SELECT id, title, course, file_type, file_size, downloads, published_at
             FROM {$table} ORDER BY published_at DESC LIMIT {$limit}"
        );
    }

    /** 全站统计 */
    public static function stats(): array
    {
        $table = config('manticore.table');
        $row = self::one("SELECT COUNT(*) AS c, SUM(file_size) AS s FROM {$table}");
        return ['count' => (int)($row['c'] ?? 0), 'bytes' => (int)($row['s'] ?? 0)];
    }
}
