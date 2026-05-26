<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../../config/database.php';

$pdo = obterConexao();
$dados = json_decode(file_get_contents("php://input"), true);

function parseDecimal($valor) {
    if ($valor === null || $valor === '') return null;
    $valor = preg_replace('/[^\d,\.]/', '', (string)$valor);
    $valor = str_replace(',', '.', $valor);
    return (float)$valor;
}

$descricao            = trim($dados['descricao'] ?? '');
$valor                = parseDecimal($dados['valor'] ?? null);
$fk_conta_regente     = $dados['fk_conta_regente'] ?? null;
$fk_conta_subordinada = $dados['fk_conta_subordinada'] ?? null;
$fk_tipo_lancamento   = $dados['fk_tipo_lancamento'] ?? null;
$fk_forma_pagamento   = $dados['fk_forma_pagamento'] ?? null;
$fk_status_conta      = $dados['fk_status_conta'] ?? null;
$data_lancamento      = $dados['dataLancamento'] ?? null;
$data_vencimento      = $dados['data_vencimento'] ?? null;
$observacao           = trim($dados['observacao'] ?? '');
$total_parcelas       = isset($dados['total_parcelas']) ? (int)$dados['total_parcelas'] : 1;
$parcelas             = $dados['parcelas'] ?? [];
$isParcelado          = $total_parcelas > 1;

if ($isParcelado && (!is_array($parcelas) || count($parcelas) !== $total_parcelas)) {
    http_response_code(422);
    echo json_encode(["sucesso" => false, "erro" => "Número de parcelas inválido ou dados de parcelamento incompletos."]);
    exit;
}

if (!$descricao) {
    http_response_code(422);
    echo json_encode(["sucesso" => false, "erro" => "Descrição é obrigatória."]);
    exit;
}

if (!$valor || $valor <= 0) {
    http_response_code(422);
    echo json_encode(["sucesso" => false, "erro" => "Valor inválido."]);
    exit;
}

if (!$fk_tipo_lancamento) {
    http_response_code(422);
    echo json_encode(["sucesso" => false, "erro" => "Tipo de lançamento é obrigatório."]);
    exit;
}

if (!$fk_status_conta) {
    http_response_code(422);
    echo json_encode(["sucesso" => false, "erro" => "Status do lançamento é obrigatório."]);
    exit;
}

try {
    $pdo->beginTransaction();

    $sql = "
        INSERT INTO lancamento (
            fk_conta_regente,
            fk_conta_subordinada,
            fk_tipo_lancamento,
            fk_forma_pagamento,
            fk_status_conta,
            descricao,
            valor,
            data_lancamento,
            data_vencimento,
            observacao
        ) VALUES (
            :fk_conta_regente,
            :fk_conta_subordinada,
            :fk_tipo_lancamento,
            :fk_forma_pagamento,
            :fk_status_conta,
            :descricao,
            :valor,
            :data_lancamento,
            :data_vencimento,
            :observacao
        )
    ";

    $stmt = $pdo->prepare($sql);

    if ($isParcelado) {
        $somaParcelas = 0;
        foreach ($parcelas as $parcela) {
            $parcelaValor = parseDecimal($parcela['valor'] ?? null);
            $parcelaVencimento = $parcela['data_vencimento'] ?? null;

            if (!$parcelaValor || !$parcelaVencimento) {
                throw new Exception('Cada parcela deve ter valor e data de vencimento.');
            }

            $somaParcelas += $parcelaValor;
            $descricaoParcela = sprintf('%s (Parcela %d/%d)', $descricao, (int)$parcela['numero_parcela'], $total_parcelas);

            $stmt->execute([
                ':fk_conta_regente'     => $fk_conta_regente ?: null,
                ':fk_conta_subordinada' => $fk_conta_subordinada ?: null,
                ':fk_tipo_lancamento'   => $fk_tipo_lancamento,
                ':fk_forma_pagamento'   => $fk_forma_pagamento ?: null,
                ':fk_status_conta'      => $fk_status_conta,
                ':descricao'            => $descricaoParcela,
                ':valor'                => $parcelaValor,
                ':data_lancamento'      => $data_lancamento ?: null,
                ':data_vencimento'      => $parcelaVencimento,
                ':observacao'           => $observacao ?: null
            ]);
        }

        if (round($somaParcelas, 2) !== round($valor, 2)) {
            throw new Exception('A soma das parcelas deve ser igual ao valor total.');
        }
    } else {
        $stmt->execute([
            ':fk_conta_regente'     => $fk_conta_regente ?: null,
            ':fk_conta_subordinada' => $fk_conta_subordinada ?: null,
            ':fk_tipo_lancamento'   => $fk_tipo_lancamento,
            ':fk_forma_pagamento'   => $fk_forma_pagamento ?: null,
            ':fk_status_conta'      => $fk_status_conta,
            ':descricao'            => $descricao,
            ':valor'                => $valor,
            ':data_lancamento'      => $data_lancamento ?: null,
            ':data_vencimento'      => $data_vencimento ?: null,
            ':observacao'           => $observacao ?: null
        ]);
    }

    $pdo->commit();

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Lançamento cadastrado com sucesso"
    ]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    http_response_code(500);
    echo json_encode([
        "sucesso" => false,
        "erro" => $e->getMessage()
    ]);
}
