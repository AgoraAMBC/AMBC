<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo     = obterConexao();
$regente = (int)($_GET['fk_conta_regente'] ?? 0);
$ativos  = $_GET['ativos'] ?? '';

$where  = ['1=1'];
$params = [];

if ($regente > 0) {
    $where[]           = 'cs.fk_conta_regente = :regente';
    $params[':regente'] = $regente;
}
if ($ativos === '1') {
    $where[] = 'cs.ativo = TRUE';
}

$condicao = implode(' AND ', $where);

$stmt = $pdo->prepare("
    SELECT
        cs.id_conta_subordinada,
        cs.fk_conta_regente,
        cs.descricao,
        cs.observacao,
        cs.ativo,
        cr.descricao AS regente
    FROM conta_subordinada cs
    JOIN  conta_regente cr ON cr.id_conta_regente = cs.fk_conta_regente
    WHERE $condicao
    ORDER BY cr.descricao ASC, cs.descricao ASC
");
$stmt->execute($params);
$dados = $stmt->fetchAll();

foreach ($dados as &$r) {
    $r['ativo'] = (bool)$r['ativo'];
}

jsonResposta(['dados' => $dados]);
