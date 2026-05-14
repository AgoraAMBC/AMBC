<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

try {
    $stmt = $pdo->query('SELECT chave, valor FROM configuracao_sistema ORDER BY chave');
    $rows = $stmt->fetchAll();

    $configs = [];
    foreach ($rows as $row) {
        $configs[$row['chave']] = $row['valor'];
    }

    jsonResposta($configs);
} catch (PDOException $e) {
    jsonErro('Erro ao carregar configurações: ' . $e->getMessage(), 500);
}
