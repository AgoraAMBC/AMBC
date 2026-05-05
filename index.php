<?php
/**
 * ============================================================
 * Router para o servidor built-in do PHP
 * Serve arquivos estáticos e redireciona para index.html
 * ============================================================
 */

// Obtém o caminho requisitado
$requested = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$requested = ltrim($requested, '/');

// Se for raiz, serve index.html
if ($requested === '' || $requested === '/') {
    header('Content-Type: text/html; charset=utf-8');
    readfile(__DIR__ . '/index.html');
    exit;
}

// Se for um arquivo que existe (CSS, JS, imagens, etc.), serve normalmente
if (is_file($requested)) {
    $ext = pathinfo($requested, PATHINFO_EXTENSION);
    $mime = [
        'js'   => 'application/javascript',
        'css'  => 'text/css',
        'html' => 'text/html',
        'json' => 'application/json',
        'php'  => 'application/x-httpd-php',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
        'svg'  => 'image/svg+xml',
        'woff' => 'font/woff',
        'woff2'=> 'font/woff2',
        'ttf'  => 'font/ttf',
    ][$ext] ?? 'text/plain';
    
    header("Content-Type: $mime");
    readfile($requested);
    exit;
}

// Se for uma pasta que existe, procura por index.html nela
if (is_dir($requested)) {
    $indexFile = rtrim($requested, '/') . '/index.html';
    if (is_file($indexFile)) {
        header('Content-Type: text/html; charset=utf-8');
        readfile($indexFile);
        exit;
    }
}

// Se for uma requisição para o backend PHP, executa normalmente
if (strpos($requested, 'backend/') === 0) {
    require __DIR__ . '/' . $requested;
    exit;
}

// Se não encontrou nada, retorna 404
http_response_code(404);
header('Content-Type: application/json');
echo json_encode(['erro' => 'Arquivo não encontrado: ' . $requested]);
?>
