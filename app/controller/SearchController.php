<?php

namespace app\controller;

use app\service\Manticore;
use support\Request;
use support\Response;

class SearchController
{
    protected const PER_PAGE = 10;
    protected const FILE_TYPES = ['pdf', 'ppt', 'doc', 'zip', 'epub', 'mp4'];

    /** 搜索结果页 */
    public function index(Request $request): Response
    {
        $keyword  = trim((string)$request->get('q', ''));
        $fileType = strtolower(trim((string)$request->get('type', '')));
        $page     = max(1, (int)$request->get('page', 1));

        if (!in_array($fileType, self::FILE_TYPES, true)) {
            $fileType = '';
        }

        $rows = [];
        $total = 0;
        $error = null;

        if ($keyword !== '') {
            try {
                $result = Manticore::search($keyword, $fileType, $page, self::PER_PAGE);
                $rows   = $result['rows'];
                $total  = $result['total'];
            } catch (\Throwable $e) {
                $error = '搜索服务暂时不可用,请稍后再试';
            }
        }

        return view('search/index', [
            'keyword'    => $keyword,
            'fileType'   => $fileType,
            'fileTypes'  => self::FILE_TYPES,
            'rows'       => $rows,
            'total'      => $total,
            'page'       => $page,
            'perPage'    => self::PER_PAGE,
            'totalPages' => (int)ceil($total / self::PER_PAGE),
            'error'      => $error,
        ]);
    }
}
