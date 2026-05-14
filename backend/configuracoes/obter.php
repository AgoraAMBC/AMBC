<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/headers.php';

session_start();

header('Content-Type: application/json');

try {
    $pdo = obterConexao();

    $stmt = $pdo->query("SELECT chave, valor FROM configuracoes");
    $rows = $stmt->fetchAll();

    $config = [];
    foreach ($rows as $row) {
        $config[$row['chave']] = $row['valor'];
    }

    echo json_encode($config);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}