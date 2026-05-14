<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

try {
    $stmt = $pdo->query('SELECT id_tipo_documento AS id, descricao FROM tipo_documento ORDER BY id_tipo_documento');
    jsonResposta($stmt->fetchAll());
} catch (PDOException $e) {
    jsonErro('Erro ao listar tipos: ' . $e->getMessage(), 500);
}
