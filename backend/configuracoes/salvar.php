<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/headers.php';

session_start();

header('Content-Type: application/json');

try {
    $pdo = obterConexao();

    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || !is_array($input)) {
        http_response_code(400);
        echo json_encode(['erro' => 'Dados inválidos']);
        exit;
    }

    $pdo->beginTransaction();

    $stmt = $pdo->prepare("
        INSERT INTO configuracoes (chave, valor, atualizado_em)
        VALUES (:chave, :valor, NOW())
        ON DUPLICATE KEY UPDATE valor = VALUES(valor), atualizado_em = NOW()
    ");

    foreach ($input as $chave => $valor) {
        $stmt->execute(['chave' => $chave, 'valor' => $valor]);
    }

    $pdo->commit();

    echo json_encode(['sucesso' => true, 'mensagem' => 'Configurações salvas com sucesso']);
} catch (Exception $e) {
    $pdo?->rollBack();
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}