<?php

namespace app\controller;

use app\service\Manticore;
use support\Request;
use support\Response;

class MaterialController
{
    /** 资料详情页:文件清单 + 相似资料 */
    public function show(Request $request, int $id): Response
    {
        try {
            $doc = Manticore::find($id);
        } catch (\Throwable $e) {
            $doc = null;
        }

        if (!$doc) {
            return view('material/404', ['id' => $id])->withStatus(404);
        }

        $files = [];
        if (!empty($doc['files'])) {
            $decoded = json_decode($doc['files'], true);
            if (is_array($decoded)) {
                $files = $decoded;
            }
        }

        $similar = [];
        try {
            $similar = Manticore::similar($doc, 6);
        } catch (\Throwable $e) {
            // 相似推荐失败不影响详情页
            \support\Log::error('similar failed: ' . $e->getMessage());
        }

        return view('material/show', [
            'doc'     => $doc,
            'files'   => $files,
            'similar' => $similar,
            'tags'    => array_filter(array_map('trim', explode(',', $doc['tags'] ?? ''))),
        ]);
    }
}
