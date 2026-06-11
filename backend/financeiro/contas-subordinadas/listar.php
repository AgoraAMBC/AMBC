<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo     = obterConexao();
$regente = (int)($_GET['fk_conta_regente'] ?? 0);
$busca   = trim($_GET['busca'] ?? '');
$ativos  = $_GET['ativos'] ?? '';

$where  = ['1=1'];
$params = [];

if ($regente > 0) {
    $where[]           = 'cs.fk_conta_regente = :regente';
    $params[':regente'] = $regente;
}
if ($busca !== '') {
    $like = '%' . $busca . '%';
    $where[]           = '(cs.descricao LIKE :busca1 OR cr.descricao LIKE :busca2)';
    $params[':busca1'] = $like;
    $params[':busca2'] = $like;
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
        cr.descricao AS regente,
        COUNT(l.id_lancamento) AS total_movimentos
    FROM conta_subordinada cs
    JOIN  conta_regente cr ON cr.id_conta_regente = cs.fk_conta_regente
    LEFT JOIN lancamento l ON l.fk_conta_subordinada = cs.id_conta_subordinada
    WHERE $condicao
    GROUP BY cs.id_conta_subordinada, cs.fk_conta_regente, cs.descricao, cs.observacao, cs.ativo, cr.descricao
    ORDER BY cr.descricao ASC, cs.descricao ASC
");
$stmt->execute($params);
$dados = $stmt->fetchAll();

foreach ($dados as &$r) {
    $r['ativo']            = (bool)$r['ativo'];
    $r['total_movimentos'] = (int)$r['total_movimentos'];
}

jsonResposta(['dados' => $dados]);
