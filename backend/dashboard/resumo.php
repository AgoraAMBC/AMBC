<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

// Contar associados
$stmtAssociados = $pdo->query("SELECT COUNT(*) FROM associado WHERE ativo = TRUE");
$totalAssociados = (int)$stmtAssociados->fetchColumn();

// Contar dependentes
$stmtDependentes = $pdo->query("SELECT COUNT(*) FROM dependente");
$totalDependentes = (int)$stmtDependentes->fetchColumn();

// Contar parceiros
$stmtParceiros = $pdo->query("SELECT COUNT(*) FROM parceiro WHERE ativo = TRUE");
$totalParceiros = (int)$stmtParceiros->fetchColumn();

$cards = [
    'associados' => [
        'total' => $totalAssociados,
        'variacao' => 0
    ],
    'dependentes' => [
        'total' => $totalDependentes,
        'variacao' => 0
    ],
    'parceiros' => [
        'total' => $totalParceiros,
        'variacao' => 0
    ],
    'resultado_mes' => [
        'total' => 0,
        'variacao' => 0
    ]
];

$distribuicao = [
    'associados' => $totalAssociados,
    'dependentes' => $totalDependentes,
    'parceiros' => $totalParceiros,
];

jsonResposta([
    'cards' => $cards,
    'distribuicao' => $distribuicao,
    'grafico' => [],
    'ultimas_transacoes' => []
]);