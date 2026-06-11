<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$dados = corpoJson();
if (!$dados) jsonErro('Payload inválido', 400);

$id_lancamento      = isset($dados['id_lancamento'])      ? (int)$dados['id_lancamento']      : 0;
$acao               = $dados['acao']                      ?? 'liquidar';
$valor_pago         = isset($dados['valor_pago'])         ? (float)$dados['valor_pago']        : null;
$data_pagamento     = $dados['data_pagamento']            ?? null;
$fk_forma_pagamento = isset($dados['fk_forma_pagamento']) ? (int)$dados['fk_forma_pagamento']  : null;

if ($id_lancamento <= 0) jsonErro('ID do lançamento inválido', 422);

if ($acao === 'liquidar') {
    if (!$valor_pago || $valor_pago <= 0) jsonErro('Valor recebido deve ser maior que zero', 422);
    if (!$data_pagamento) jsonErro('Data do pagamento é obrigatória', 422);
}

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare('SELECT id_lancamento, fk_status_conta FROM lancamento WHERE id_lancamento = :id LIMIT 1');
    $stmt->execute([':id' => $id_lancamento]);
    $lancamento = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$lancamento) jsonErro('Lançamento não encontrado', 404);

    if ((int)$lancamento['fk_status_conta'] !== 1) {
        jsonErro('Somente lançamentos em aberto podem ser alterados', 409);
    }

    if ($acao === 'cancelar') {
        $pdo->prepare('UPDATE lancamento SET fk_status_conta = 3, atualizado_em = NOW() WHERE id_lancamento = :id')
            ->execute([':id' => $id_lancamento]);
        jsonResposta(['sucesso' => true, 'mensagem' => 'Lançamento cancelado com sucesso']);
    }

    $stmt = $pdo->prepare('SELECT valor FROM lancamento WHERE id_lancamento = :id LIMIT 1');
    $stmt->execute([':id' => $id_lancamento]);
    $valor_total = (float)$stmt->fetchColumn();

    $novo_status = ($valor_pago >= $valor_total) ? 2 : 1;
    $mensagem    = ($novo_status === 2)
        ? 'Lançamento liquidado com sucesso'
        : 'Pagamento parcial registrado. Lançamento permanece em aberto';

    $pdo->prepare('
        UPDATE lancamento
        SET fk_status_conta    = :status,
            valor_pago         = :valor_pago,
            data_pagamento     = :data_pagamento,
            fk_forma_pagamento = :fk_forma_pagamento,
            atualizado_em      = NOW()
        WHERE id_lancamento = :id
    ')->execute([
        ':status'             => $novo_status,
        ':valor_pago'         => $valor_pago,
        ':data_pagamento'     => $data_pagamento,
        ':fk_forma_pagamento' => $fk_forma_pagamento,
        ':id'                 => $id_lancamento,
    ]);

    jsonResposta(['sucesso' => true, 'mensagem' => $mensagem]);

} catch (Exception $e) {
    jsonErro('Erro ao processar lançamento: ' . $e->getMessage(), 500);
}
