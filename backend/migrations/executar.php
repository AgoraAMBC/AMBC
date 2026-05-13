<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

header('Content-Type: application/json');

try {
    $pdo = obterConexao();

    $sql = "CREATE TABLE IF NOT EXISTS configuracoes (
        chave VARCHAR(100) PRIMARY KEY,
        valor TEXT,
        atualizado_em TIMESTAMP DEFAULT NOW()
    )";

    $pdo->exec($sql);

    echo json_encode(['sucesso' => true, 'mensagem' => 'Tabela configuracoes criada com sucesso']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}