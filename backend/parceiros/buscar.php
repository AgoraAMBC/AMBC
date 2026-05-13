<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

$pdo = obterConexao();

// Busca dados do parceiro
$stmt = $pdo->prepare("
    SELECT
        p.*,
        u.nome AS criado_por_nome
    FROM parceiro p
    LEFT JOIN usuario u ON u.id_usuario = p.criado_por
    WHERE p.id_parceiro = :id
");
$stmt->execute([':id' => $id]);
$parceiro = $stmt->fetch();

if (!$parceiro) jsonErro('Parceiro não encontrado', 404);

// Busca telefones
$stmtTel = $pdo->prepare("
    SELECT
        t.id_telefone_parceiro,
        t.ddd,
        t.numero,
        t.fk_tipo_telefone,
        tt.descricao AS tipo_telefone,
        t.observacao
    FROM telefone_parceiro t
    LEFT JOIN tipo_telefone tt ON tt.id_tipo_telefone = t.fk_tipo_telefone
    WHERE t.fk_parceiro = :id
    ORDER BY t.id_telefone_parceiro
");
$stmtTel->execute([':id' => $id]);
$parceiro['telefones'] = $stmtTel->fetchAll();

$stmtLanc = $pdo->prepare("
    SELECT
        l.id_lancamento,
        l.fk_tipo_lancamento,
        tl.descricao AS tipo_lancamento,
        l.descricao AS referencia,
        l.valor,
        l.valor_pago,
        l.data_lancamento,
        l.data_vencimento,
        l.data_pagamento,
        l.fk_status_conta,
        sc.descricao AS status,
        l.fk_forma_pagamento,
        fp.descricao AS forma_pagamento,
        l.fk_conta_regente,
        cr.descricao AS conta_regente,
        l.fk_conta_subordinada,
        cs.descricao AS conta_subordinada,
        l.observacao
    FROM lancamento l
    LEFT JOIN tipo_lancamento tl ON tl.id_tipo_lancamento = l.fk_tipo_lancamento
    LEFT JOIN status_conta sc ON sc.id_status_conta = l.fk_status_conta
    LEFT JOIN forma_pagamento fp ON fp.id_forma_pagamento = l.fk_forma_pagamento
    LEFT JOIN conta_regente cr ON cr.id_conta_regente = l.fk_conta_regente
    LEFT JOIN conta_subordinada cs ON cs.id_conta_subordinada = l.fk_conta_subordinada
    WHERE l.fk_parceiro = :id
    ORDER BY l.data_lancamento DESC, l.id_lancamento DESC
");
$stmtLanc->execute([':id' => $id]);
$parceiro['lancamentos'] = $stmtLanc->fetchAll();

jsonResposta($parceiro);
