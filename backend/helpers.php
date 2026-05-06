<?php
declare(strict_types=1);

function configurarCors(): void {
    header('Content-Type: application/json; charset=UTF-8');

    // 🌐 Whitelist de origens permitidas
    $origem = $_SERVER['HTTP_ORIGIN'] ?? '';
    $origensPermitidas = [
        'http://ambc-v2.test',
        'http://localhost',
        'http://localhost:8080',
        'http://localhost:5500',
        'http://127.0.0.1:5500',
        'https://ambc-testes.onrender.com',
    ];

    if (in_array($origem, $origensPermitidas, true)) {
        header("Access-Control-Allow-Origin: $origem");
        header('Access-Control-Allow-Credentials: true');
    }

    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}


function jsonResposta(array $dados, int $codigo = 200): void {
    http_response_code($codigo);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

function jsonErro(string $mensagem, int $codigo = 400): void {
    http_response_code($codigo);
    echo json_encode(['erro' => $mensagem], JSON_UNESCAPED_UNICODE);
    exit;
}

function corpoJson(): array {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}
