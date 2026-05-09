<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Método não permitido', 405);
}

try {
    $pdo = obterConexao();

    // Usa o próximo valor da sequence do id_associado
    $stmt = $pdo->query("
        SELECT COALESCE(MAX(id_associado), 0) + 1 AS proxima
        FROM associado
    ");

    $row     = $stmt->fetch(PDO::FETCH_ASSOC);
    $numero  = (int)($row['proxima'] ?? 1);
    $proxima = str_pad((string)$numero, 4, '0', STR_PAD_LEFT);

    jsonResposta(['matricula' => $proxima]);

} catch (Exception $e) {
    jsonErro('Erro ao gerar matrícula: ' . $e->getMessage(), 500);
}
