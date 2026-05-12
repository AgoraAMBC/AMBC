<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id_associado = isset($_GET['id_associado']) ? (int)$_GET['id_associado'] : null;

if (!$id_associado) jsonErro('ID do associado é obrigatório', 400);

try {
    $pdo = obterConexao();

    $sql = "
        SELECT
            l.id_lancamento,
            l.descricao,
            l.valor,
            l.valor_pago,
            l.data_lancamento,
            l.data_vencimento,
            l.data_pagamento,
            COALESCE(reg.descricao, '') AS conta_regente,
            COALESCE(sub.descricao, '') AS conta_subordinada,
            COALESCE(tl.descricao, '') AS tipo_lancamento,
            COALESCE(sc.descricao, 'Aberto') AS status_conta,
            l.fk_status_conta,
            l.criado_em
        FROM lancamento l
        LEFT JOIN conta_regente reg ON reg.id_conta_regente = l.fk_conta_regente
        LEFT JOIN conta_subordinada sub ON sub.id_conta_subordinada = l.fk_conta_subordinada
        LEFT JOIN tipo_lancamento tl ON tl.id_tipo_lancamento = l.fk_tipo_lancamento
        LEFT JOIN status_conta sc ON sc.id_status_conta = l.fk_status_conta
        WHERE l.fk_associado = :id_associado
        ORDER BY l.data_lancamento DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id_associado' => $id_associado]);
    $lancamentos = $stmt->fetchAll();

    jsonResposta(['lancamentos' => $lancamentos]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar lançamentos: ' . $e->getMessage(), 500);
}