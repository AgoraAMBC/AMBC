<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$stmt = $pdo->query("
    SELECT id_plano, nome, preco, periodo, beneficios, ativo, ordem
    FROM plano_associacao
    ORDER BY ordem, id_plano
");

$planos = $stmt->fetchAll();

foreach ($planos as &$p) {
    $p['preco']     = (float)$p['preco'];
    $p['ativo']     = filter_var($p['ativo'], FILTER_VALIDATE_BOOLEAN);
    $p['ordem']     = (int)$p['ordem'];
    $p['beneficios'] = json_decode($p['beneficios'] ?? '[]', true);
}

jsonResposta(['dados' => $planos]);
