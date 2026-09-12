<?php
/**
 * Here is your custom functions.
 */

if (!function_exists('format_size')) {
    /** 字节数人性化 */
    function format_size(int $bytes): string
    {
        if ($bytes >= 1073741824) return round($bytes / 1073741824, 2) . ' GB';
        if ($bytes >= 1048576)    return round($bytes / 1048576, 1) . ' MB';
        if ($bytes >= 1024)       return round($bytes / 1024, 1) . ' KB';
        return $bytes . ' B';
    }
}

if (!function_exists('format_date')) {
    function format_date($ts): string
    {
        return $ts ? date('Y-m-d', (int)$ts) : '-';
    }
}

if (!function_exists('file_icon')) {
    /** 文件类型徽标样式 */
    function file_icon(string $type): string
    {
        return match (strtolower($type)) {
            'pdf'  => 'badge-pdf',
            'ppt', 'pptx' => 'badge-ppt',
            'doc', 'docx' => 'badge-doc',
            'zip', 'rar', '7z' => 'badge-zip',
            'mp4', 'mkv' => 'badge-video',
            'epub', 'mobi' => 'badge-epub',
            default => 'badge-other',
        };
    }
}
