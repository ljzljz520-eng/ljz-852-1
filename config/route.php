<?php
/**
 * 公开课资料索引站 - 路由
 */

use Webman\Route;

Route::get('/', [app\controller\IndexController::class, 'index']);
Route::get('/search', [app\controller\SearchController::class, 'index']);
Route::get('/material/{id:\d+}', [app\controller\MaterialController::class, 'show']);
Route::get('/disclaimer', [app\controller\IndexController::class, 'disclaimer']);

// 关闭默认路由,避免未约定的控制器暴露
Route::disableDefaultRoute();
