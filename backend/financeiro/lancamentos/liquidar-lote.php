<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$dados = corpoJson();
if (!$dados) jsonErro('Payload inválido', 400);

$liquidacoes    = $dados['liquidacoes']      ?? [];
$data_pagamento = $dados['data_pagamento']   ?? null;
$fk_forma       = isset($dados['fk_forma_pagamento']) ? (int)$dados['fk_forma_pagamento'] : null;

if (!is_array($liquidacoes) || count($liquidacoes) === 0) jsonErro('Informe ao menos um lançamento', 422);
if (!$data_pagamento) jsonErro('Data do pagamento é obrigatória', 422);

foreach ($liquidacoes as $item) {
    if (!isset($item['id']) || (int)$item['id'] <= 0) jsonErro('ID de lançamento inválido na lista', 422);
    if (!isset($item['valor_pago']) || (float)$item['valor_pago'] <= 0) jsonErro('Valor pago inválido na lista', 422);
}

try {
    $pdo = obterConexao();
    $pdo->beginTransaction();

    $processados = 0;
    $pulados     = 0;

    $stmtBusca = $pdo->prepare('SELECT id_lancamento, valor, fk_status_conta FROM lancamento WHERE id_lancamento = :id LIMIT 1');
    $stmtUpd   = $pdo->prepare('
        UPDATE lancamento
        SET fk_status_conta    = :status,
            valor_pago         = :valor_pago,
            data_pagamento     = :data_pagamento,
            fk_forma_pagamento = :fk_forma_pagamento,
            atualizado_em      = NOW()
        WHERE id_lancamento = :id
    ');

    foreach ($liquidacoes as $item) {
        $id         = (int)$item['id'];
        $valor_pago = (float)$item['valor_pago'];

        $stmtBusca->execute([':id' => $id]);
        $lancamento = $stmtBusca->fetch(PDO::FETCH_ASSOC);

        if (!$lancamento || (int)$lancamento['fk_status_conta'] !== 1) {
            $pulados++;
            continue;
        }

        $valor_total = (float)$lancamento['valor'];
        $novo_status = ($valor_pago >= $valor_total) ? 2 : 1;

        $stmtUpd->execute([
            ':status'             => $novo_status,
            ':valor_pago'         => $valor_pago,
            ':data_pagamento'     => $data_pagamento,
            ':fk_forma_pagamento' => $fk_forma,
            ':id'                 => $id,
        ]);
        $processados++;
    }

    $pdo->commit();

    $mensagem = $processados . ' lançamento' . ($processados !== 1 ? 's' : '') . ' processado' . ($processados !== 1 ? 's' : '');
    if ($pulados > 0) $mensagem .= ', ' . $pulados . ' ignorado' . ($pulados !== 1 ? 's' : '');

    jsonResposta(['sucesso' => true, 'mensagem' => $mensagem, 'processados' => $processados, 'pulados' => $pulados]);

} catch (Exception $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    jsonErro('Erro ao processar lote: ' . $e->getMessage(), 500);
}
