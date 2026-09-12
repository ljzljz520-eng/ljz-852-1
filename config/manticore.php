<?php
return [
    'host' => getenv('MANTICORE_HOST') ?: '127.0.0.1',
    'port' => (int)(getenv('MANTICORE_PORT') ?: 9306),
    'user' => getenv('MANTICORE_USER') ?: '',
    'pass' => getenv('MANTICORE_PASS') ?: '',
    'table' => 'materials',
];
