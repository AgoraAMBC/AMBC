<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$fk_associado     = $body['fk_associado']     ?? null;
$tipo             = $body['tipo']             ?? 'receber';
$descricao        = $body['descricao']        ?? null;
$valor            = $body['valor']           ?? null;
$vencimento       = $body['vencimento']      ?? null;
$data_pagamento   = $body['data_pagamento']  ?? null;
$forma_pagamento  = $body['forma_pagamento'] ?? null;
$status           = $body['status']          ?? 'aberto';
$conta_subordinada = $body['conta_subordinada'] ?? null;

if (!$fk_associado || !$descricao || !$valor) {
    jsonErro('Associado, descrição e valor são obrigatórios', 422);
}

$valor = preg_replace('/[^\d.,]/', '', $valor);
$valor = str_replace(',', '.', $valor);
$valor = (float)$valor;
if ($valor <= 0) jsonErro('Valor inválido', 422);

try {
    $pdo = obterConexao();

    // Busca ou cria conta_regente
    $regenteDesc = $tipo === 'pagar' ? 'Contas a Pagar' : 'Contas a Receber';
    $stmtReg = $pdo->prepare("SELECT id_conta_regente FROM conta_regente WHERE descricao ILIKE :desc LIMIT 1");
    $stmtReg->execute([':desc' => '%' . $regenteDesc . '%']);
    $regente = $stmtReg->fetch();
    $fk_conta_regente = $regente ? (int)$regente['id_conta_regente'] : null;

    // Busca ou cria conta_subordinada
    $fk_conta_sub = null;
    if ($conta_subordinada && $fk_conta_regente) {
        $stmtSub = $pdo->prepare("SELECT id_conta_subordinada FROM conta_subordinada WHERE fk_conta_regente = :fk AND descricao ILIKE :desc LIMIT 1");
        $stmtSub->execute([':fk' => $fk_conta_regente, ':desc' => '%' . $conta_subordinada . '%']);
        $sub = $stmtSub->fetch();
        $fk_conta_sub = $sub ? (int)$sub['id_conta_subordinada'] : null;
    }

    // Status
    $statusMap = ['aberto' => 1, 'pago' => 2, 'cancelado' => 3];
    $fk_status = $statusMap[$status] ?? 1;

    // Forma pagamento
    $formaMap = ['pix' => 1, 'boleto' => 2, 'cartao' => 3, 'dinheiro' => 5, 'transferencia' => 6];
    $fk_forma = $forma_pagamento ? ($formaMap[$forma_pagamento] ?? null) : null;

    // Tipo lancamento
    $tipoMap = ['receber' => 1, 'pagar' => 2];
    $fk_tipo = $tipoMap[$tipo] ?? 1;

    $sql = "
        INSERT INTO lancamento (
            fk_associado, fk_conta_regente, fk_conta_subordinada,
            fk_tipo_lancamento, fk_forma_pagamento, fk_status_conta,
            descricao, valor, data_lancamento, data_vencimento, data_pagamento
        ) VALUES (
            :fk_associado, :fk_conta_regente, :fk_conta_subordinada,
            :fk_tipo, :fk_forma, :fk_status,
            :descricao, :valor, :data_lancamento, :vencimento, :pagamento
        )
        RETURNING id_lancamento
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':fk_associado'       => $fk_associado,
        ':fk_conta_regente'   => $fk_conta_regente,
        ':fk_conta_subordinada'=> $fk_conta_sub,
        ':fk_tipo'            => $fk_tipo,
        ':fk_forma'           => $fk_forma,
        ':fk_status'          => $fk_status,
        ':descricao'          => $descricao,
        ':valor'              => $valor,
        ':data_lancamento'    => date('Y-m-d'),
        ':vencimento'         => $vencimento ?: null,
        ':pagamento'          => $data_pagamento ?: null,
    ]);

    $row = $stmt->fetch();

    jsonResposta([
        'mensagem'     => 'Lançamento criado com sucesso.',
        'id_lancamento' => (int)$row['id_lancamento']
    ], 201);

} catch (Exception $e) {
    jsonErro('Erro ao criar lançamento: ' . $e->getMessage(), 500);
}