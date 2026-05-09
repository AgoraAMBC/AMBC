<?php
/**
 * ============================================================
 * HEADERS PADRÃO — AMBC V2
 * ============================================================
 * Define os headers HTTP para todas as respostas da API.
 * Deve ser incluído no INÍCIO de todo arquivo PHP da API.
 * ============================================================
 */

// Permite requisições do frontend SPA (mesma origem via Laragon)
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization');

// Preflight OPTIONS — responde imediatamente e encerra
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
