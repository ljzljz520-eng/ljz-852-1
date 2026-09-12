<?php

namespace app\controller;

use app\service\Manticore;
use support\Request;
use support\Response;

class IndexController
{
    /** 首页:搜索框 + 最新收录 */
    public function index(Request $request): Response
    {
        $latest = [];
        $stats  = ['count' => 0, 'bytes' => 0];
        try {
            $latest = Manticore::latest(8);
            $stats  = Manticore::stats();
        } catch (\Throwable $e) {
            // 搜索服务未就绪时首页仍可打开
        }
        return view('index/index', [
            'latest' => $latest,
            'stats'  => $stats,
        ]);
    }

    /** 免责声明 */
    public function disclaimer(Request $request): Response
    {
        return view('index/disclaimer');
    }
}
