<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo    = obterConexao();
$busca  = trim($_GET['busca'] ?? '');
$tipo   = $_GET['tipo'] ?? '';
$ativos = $_GET['ativos'] ?? '';

$where  = ['1=1'];
$params = [];

if ($busca !== '') {
    $where[]          = 'cr.descricao ILIKE :busca';
    $params[':busca'] = '%' . $busca . '%';
}
if (in_array($tipo, ['receita', 'despesa'], true)) {
    $where[]        = 'cr.tipo = :tipo';
    $params[':tipo'] = $tipo;
}
if ($ativos === '1') {
    $where[] = 'cr.ativo = TRUE';
}

$condicao = implode(' AND ', $where);

$stmt = $pdo->prepare("
    SELECT
        cr.id_conta_regente,
        cr.descricao,
        cr.tipo,
        cr.observacao,
        cr.ativo,
        COUNT(cs.id_conta_subordinada) AS total_subcontas
    FROM conta_regente cr
    LEFT JOIN conta_subordinada cs ON cs.fk_conta_regente = cr.id_conta_regente
    WHERE $condicao
    GROUP BY cr.id_conta_regente
    ORDER BY cr.descricao ASC
");
$stmt->execute($params);
$dados = $stmt->fetchAll();

foreach ($dados as &$r) {
    $r['ativo']           = (bool)$r['ativo'];
    $r['total_subcontas'] = (int)$r['total_subcontas'];
}

jsonResposta(['dados' => $dados]);
