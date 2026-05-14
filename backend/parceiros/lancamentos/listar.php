<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Metodo nao permitido', 405);

$idParceiro = (int)($_GET['id_parceiro'] ?? 0);
if ($idParceiro <= 0) jsonErro('ID do parceiro invalido', 400);

$pdo = obterConexao();

$stmt = $pdo->prepare("
    SELECT
        l.id_lancamento,
        l.fk_parceiro,
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
    WHERE l.fk_parceiro = :id_parceiro
    ORDER BY l.data_lancamento DESC, l.id_lancamento DESC
");
$stmt->execute([':id_parceiro' => $idParceiro]);
$dados = $stmt->fetchAll();

foreach ($dados as &$linha) {
    $linha['valor'] = (float)$linha['valor'];
    $linha['valor_pago'] = $linha['valor_pago'] !== null ? (float)$linha['valor_pago'] : null;
}

jsonResposta(['dados' => $dados]);
