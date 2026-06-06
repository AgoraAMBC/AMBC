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
$id_lancamento        = isset($dados['id']) ? (int)$dados['id'] : null;
$fk_conta_regente     = $dados['fk_conta_regente'] ?? null;
$fk_conta_subordinada = $dados['fk_conta_subordinada'] ?? null;
$fk_tipo_lancamento   = $dados['fk_tipo_lancamento'] ?? null;
$fk_forma_pagamento   = $dados['fk_forma_pagamento'] ?? null;
$fk_status_conta      = $dados['fk_status_conta'] ?? null;
$fk_associado         = $dados['fk_associado'] ?? null;
$fk_parceiro          = $dados['fk_parceiro'] ?? null;
$data_lancamento      = $dados['dataLancamento'] ?? ($dados['data_lancamento'] ?? date('Y-m-d'));
$data_vencimento      = $dados['data_vencimento'] ?? null;
$data_pagamento       = $dados['data_pagamento'] ?? null;
$valor_pago           = parseDecimal($dados['valor_pago'] ?? null);
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

if ((int)$fk_status_conta === 2) {
    $data_pagamento = $data_pagamento ?: date('Y-m-d');
    $valor_pago = $valor_pago ?: $valor;
} else {
    $data_pagamento = null;
    $valor_pago = null;
}

try {
    $pdo->beginTransaction();

    if ($fk_conta_regente) {
        $stmtConta = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE id_conta_regente = :id AND ativo = TRUE');
        $stmtConta->execute([':id' => $fk_conta_regente]);
        if (!$stmtConta->fetch()) {
            throw new Exception('Conta regente nÃ£o encontrada ou inativa.');
        }
    }

    if ($fk_conta_subordinada) {
        $sqlSubconta = '
            SELECT id_conta_subordinada
            FROM conta_subordinada
            WHERE id_conta_subordinada = :id
              AND ativo = TRUE
        ';
        $paramsSubconta = [':id' => $fk_conta_subordinada];

        if ($fk_conta_regente) {
            $sqlSubconta .= ' AND fk_conta_regente = :regente';
            $paramsSubconta[':regente'] = $fk_conta_regente;
        }

        $stmtSubconta = $pdo->prepare($sqlSubconta);
        $stmtSubconta->execute($paramsSubconta);
        if (!$stmtSubconta->fetch()) {
            throw new Exception('Conta subordinada nÃ£o encontrada, inativa ou incompatÃ­vel com a conta regente.');
        }
    }

    $params = [
        ':fk_conta_regente'     => $fk_conta_regente ?: null,
        ':fk_conta_subordinada' => $fk_conta_subordinada ?: null,
        ':fk_tipo_lancamento'   => $fk_tipo_lancamento,
        ':fk_forma_pagamento'   => $fk_forma_pagamento ?: null,
        ':fk_status_conta'      => $fk_status_conta,
        ':fk_associado'         => $fk_associado ?: null,
        ':fk_parceiro'          => $fk_parceiro ?: null,
        ':descricao'            => $descricao,
        ':valor'                => $valor,
        ':valor_pago'           => $valor_pago ?: null,
        ':data_lancamento'      => $data_lancamento ?: null,
        ':data_vencimento'      => $data_vencimento ?: null,
        ':data_pagamento'       => $data_pagamento ?: null,
        ':observacao'           => $observacao ?: null
    ];

    if ($id_lancamento) {
        $sql = "
            UPDATE lancamento SET
                fk_conta_regente     = :fk_conta_regente,
                fk_conta_subordinada = :fk_conta_subordinada,
                fk_tipo_lancamento   = :fk_tipo_lancamento,
                fk_forma_pagamento   = :fk_forma_pagamento,
                fk_status_conta      = :fk_status_conta,
                fk_associado         = :fk_associado,
                fk_parceiro          = :fk_parceiro,
                descricao            = :descricao,
                valor                = :valor,
                valor_pago           = :valor_pago,
                data_lancamento      = :data_lancamento,
                data_vencimento      = :data_vencimento,
                data_pagamento       = :data_pagamento,
                observacao           = :observacao
            WHERE id_lancamento = :id_lancamento
        ";
        $params[':id_lancamento'] = $id_lancamento;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $mensagem = 'Lançamento atualizado com sucesso';
    } else {
        if ($isParcelado && (!is_array($parcelas) || count($parcelas) !== $total_parcelas)) {
            throw new Exception('Número de parcelas inválido ou dados de parcelamento incompletos.');
        }

        $sql = "
            INSERT INTO lancamento (
                fk_conta_regente,
                fk_conta_subordinada,
                fk_tipo_lancamento,
                fk_forma_pagamento,
                fk_status_conta,
                fk_associado,
                fk_parceiro,
                descricao,
                valor,
                valor_pago,
                data_lancamento,
                data_vencimento,
                data_pagamento,
                observacao
            ) VALUES (
                :fk_conta_regente,
                :fk_conta_subordinada,
                :fk_tipo_lancamento,
                :fk_forma_pagamento,
                :fk_status_conta,
                :fk_associado,
                :fk_parceiro,
                :descricao,
                :valor,
                :valor_pago,
                :data_lancamento,
                :data_vencimento,
                :data_pagamento,
                :observacao
            )
        ";

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

                $params[':descricao'] = $descricaoParcela;
                $params[':valor'] = $parcelaValor;
                $params[':valor_pago'] = $data_pagamento ? $parcelaValor : null;
                $params[':data_vencimento'] = $parcelaVencimento;

                $stmt = $pdo->prepare($sql);
                $stmt->execute($params);
            }

            if (round($somaParcelas, 2) !== round($valor, 2)) {
                throw new Exception('A soma das parcelas deve ser igual ao valor total.');
            }
        } else {
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
        }

        $mensagem = 'Lançamento cadastrado com sucesso';
    }

    $pdo->commit();

    echo json_encode([
        "sucesso" => true,
        "mensagem" => $mensagem
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
