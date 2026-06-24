<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$dados = corpoJson();

function parseDecimal(mixed $valor): ?float {
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
    jsonErro('Número de parcelas inválido ou dados de parcelamento incompletos.', 422);
}

if (!$descricao) jsonErro('Descrição é obrigatória.', 422);
if (!$valor || $valor <= 0) jsonErro('Valor inválido.', 422);
if (!$fk_tipo_lancamento) jsonErro('Tipo de lançamento é obrigatório.', 422);
if (!$fk_status_conta) jsonErro('Status do lançamento é obrigatório.', 422);

if ((int)$fk_status_conta === 2 || (int)$fk_status_conta === 4) {
    $data_pagamento = $data_pagamento ?: date('Y-m-d');
    $valor_pago = $valor_pago ?: $valor;
} else {
    $data_pagamento = null;
    $valor_pago = null;
}

try {
    $pdo = obterConexao();
    $pdo->beginTransaction();

    if ($fk_conta_regente) {
        $stmtConta = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE id_conta_regente = :id AND ativo = TRUE');
        $stmtConta->execute([':id' => $fk_conta_regente]);
        if (!$stmtConta->fetch()) {
            throw new Exception('Conta regente não encontrada ou inativa.');
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
            throw new Exception('Conta subordinada não encontrada, inativa ou incompatível com a conta regente.');
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
        ':observacao'           => $observacao ?: null,
    ];

    if ($id_lancamento) {
        $sql = '
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
        ';
        $params[':id_lancamento'] = $id_lancamento;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $mensagem = 'Lançamento atualizado com sucesso';
    } else {
        // Impede duplicata de anuidade (tipo 1) para o mesmo associado no mesmo ano
        if ((int)$fk_tipo_lancamento === 1 && (int)$fk_associado > 0 && !empty($parcelas)) {
            $anoAnu = (int)substr($parcelas[0]['data_vencimento'] ?? '', 0, 4);
            if ($anoAnu > 0) {
                $stmtDup = $pdo->prepare('
                    SELECT COUNT(*) FROM lancamento
                    WHERE fk_associado       = :a
                      AND fk_tipo_lancamento = 1
                      AND YEAR(data_vencimento) = :ano
                      AND fk_status_conta   <> 3
                ');
                $stmtDup->execute([':a' => (int)$fk_associado, ':ano' => $anoAnu]);
                if ($stmtDup->fetchColumn() > 0) {
                    jsonErro("Já existe uma anuidade {$anoAnu} cadastrada para este associado.", 409);
                }
            }
        }

        $sql = '
            INSERT INTO lancamento (
                fk_conta_regente, fk_conta_subordinada, fk_tipo_lancamento,
                fk_forma_pagamento, fk_status_conta, fk_associado, fk_parceiro,
                descricao, valor, valor_pago, data_lancamento,
                data_vencimento, data_pagamento, observacao
            ) VALUES (
                :fk_conta_regente, :fk_conta_subordinada, :fk_tipo_lancamento,
                :fk_forma_pagamento, :fk_status_conta, :fk_associado, :fk_parceiro,
                :descricao, :valor, :valor_pago, :data_lancamento,
                :data_vencimento, :data_pagamento, :observacao
            )
        ';

        if ($isParcelado) {
            $sqlParcelado = '
                INSERT INTO lancamento (
                    fk_conta_regente, fk_conta_subordinada, fk_tipo_lancamento,
                    fk_forma_pagamento, fk_status_conta, fk_associado, fk_parceiro,
                    fk_parcelamento, numero_parcela, total_parcelas,
                    descricao, valor, valor_pago, data_lancamento,
                    data_vencimento, data_pagamento, observacao
                ) VALUES (
                    :fk_conta_regente, :fk_conta_subordinada, :fk_tipo_lancamento,
                    :fk_forma_pagamento, :fk_status_conta, :fk_associado, :fk_parceiro,
                    :fk_parcelamento, :numero_parcela, :total_parcelas,
                    :descricao, :valor, :valor_pago, :data_lancamento,
                    :data_vencimento, :data_pagamento, :observacao
                )
            ';
            $stmtParcelado = $pdo->prepare($sqlParcelado);

            $somaParcelas   = 0;
            $fkParcelamento = null;

            foreach ($parcelas as $i => $parcela) {
                $parcelaValor     = parseDecimal($parcela['valor'] ?? null);
                $parcelaVencimento = $parcela['data_vencimento'] ?? null;
                $numeroParcela     = (int)($parcela['numero_parcela'] ?? ($i + 1));

                if (!$parcelaValor || !$parcelaVencimento) {
                    throw new Exception('Cada parcela deve ter valor e data de vencimento.');
                }

                $somaParcelas += $parcelaValor;

                // Status e pagamento podem ser definidos por parcela individualmente
                $parcelaStatus    = isset($parcela['fk_status_conta']) ? (int)$parcela['fk_status_conta'] : (int)$fk_status_conta;
                $parcelaVpago     = isset($parcela['valor_pago'])     ? parseDecimal($parcela['valor_pago'])    : (($parcelaStatus === 2 || $parcelaStatus === 4) ? $parcelaValor : null);
                $parcelaDataPag   = isset($parcela['data_pagamento']) ? $parcela['data_pagamento']              : (($parcelaStatus === 2 || $parcelaStatus === 4) ? ($data_pagamento ?: date('Y-m-d')) : null);

                $params[':fk_status_conta'] = $parcelaStatus;
                $params[':fk_parcelamento'] = $fkParcelamento;
                $params[':numero_parcela']  = $numeroParcela;
                $params[':total_parcelas']  = $total_parcelas;
                $params[':descricao']       = sprintf('%s (Parcela %d/%d)', $descricao, $numeroParcela, $total_parcelas);
                $params[':valor']           = $parcelaValor;
                $params[':valor_pago']      = $parcelaVpago;
                $params[':data_pagamento']  = $parcelaDataPag;
                $params[':data_vencimento'] = $parcelaVencimento;

                $stmtParcelado->execute($params);

                // Após a primeira inserção: usar o próprio ID como fk_parcelamento
                if ($fkParcelamento === null) {
                    $fkParcelamento = (int)$pdo->lastInsertId();
                    $pdo->prepare('UPDATE lancamento SET fk_parcelamento = :fp WHERE id_lancamento = :id')
                        ->execute([':fp' => $fkParcelamento, ':id' => $fkParcelamento]);
                }
            }

            if (round($somaParcelas, 2) !== round($valor, 2)) {
                throw new Exception('A soma das parcelas deve ser igual ao valor total.');
            }
        } else {
            $pdo->prepare($sql)->execute($params);
            $id_lancamento = (int)$pdo->lastInsertId();
        }

        $mensagem = 'Lançamento cadastrado com sucesso';
    }

    $pdo->commit();
    jsonResposta(['sucesso' => true, 'mensagem' => $mensagem, 'id_lancamento' => $id_lancamento]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonErro($e->getMessage(), 500);
}
