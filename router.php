<?php
/**
 * ============================================================
 * Router para o servidor built-in do PHP
 * Arquivo inicial do desenvolvimento
 * ============================================================
 * 
 * INICIE O SERVIDOR COM:
 * php -S localhost:3000 router.php
 */

$requested_uri = $_SERVER['REQUEST_URI'];
$requested_file = __DIR__ . parse_url($requested_uri, PHP_URL_PATH);

// Se for um arquivo PHP, deixa executar normalmente
if (is_file($requested_file) && substr($requested_file, -4) === '.php') {
    return false; // deixa o servidor built-in executar
}

// Se for uma requisição para backend sem .php, tenta com .php
if (strpos($requested_file, __DIR__ . '/backend/') === 0 && !is_file($requested_file)) {
    $with_php = $requested_file . '.php';
    if (is_file($with_php)) {
        $_SERVER['SCRIPT_FILENAME'] = $with_php;
        return false;
    }
}

// Se for um arquivo estático que existe (CSS, JS, imagens, etc.), serve normalmente
if (is_file($requested_file)) {
    // Detecta MIME type
    $ext = pathinfo($requested_file, PATHINFO_EXTENSION);
    $mime_types = [
        'js'    => 'application/javascript; charset=utf-8',
        'css'   => 'text/css; charset=utf-8',
        'html'  => 'text/html; charset=utf-8',
        'json'  => 'application/json; charset=utf-8',
        'png'   => 'image/png',
        'jpg'   => 'image/jpeg',
        'jpeg'  => 'image/jpeg',
        'gif'   => 'image/gif',
        'svg'   => 'image/svg+xml',
        'woff'  => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf'   => 'font/ttf',
        'eot'   => 'application/vnd.ms-fontobject',
    ];
    
    $mime = $mime_types[$ext] ?? 'text/plain';
    header("Content-Type: $mime");
    readfile($requested_file);
    return true;
}

// Se for um diretório com index.html, serve o index.html
if (is_dir($requested_file)) {
    $index_file = rtrim($requested_file, '/\\') . '/index.html';
    if (is_file($index_file)) {
        header('Content-Type: text/html; charset=utf-8');
        readfile($index_file);
        return true;
    }
}

// Para requisições na raiz, serve index.html
if ($requested_uri === '/' || $requested_uri === '') {
    header('Content-Type: text/html; charset=utf-8');
    readfile(__DIR__ . '/index.html');
    return true;
}

// Se não encontrar, retorna false para o servidor lidar com 404
return false;
?>
