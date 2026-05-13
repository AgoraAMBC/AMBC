<?php
declare(strict_types=1);

function normalizarStatusLancamento(array $dados): int {
    if (!empty($dados['fk_status_conta'])) {
        return (int)$dados['fk_status_conta'];
    }

    $status = strtolower(trim((string)($dados['status'] ?? '')));
    return match ($status) {
        'pago', 'liquidado' => 2,
        'cancelado' => 3,
        default => 1,
    };
}

function normalizarValorLancamento(mixed $valor): float {
    if (is_string($valor)) {
        $valor = str_replace(['.', ','], ['', '.'], $valor);
    }
    return (float)$valor;
}

function validarLancamentoParceiro(array $dados): array {
    $referencia = trim((string)($dados['referencia'] ?? $dados['descricao'] ?? ''));
    if ($referencia === '') {
        jsonErro('Referencia do lancamento e obrigatoria.', 422);
    }

    $valor = normalizarValorLancamento($dados['valor'] ?? 0);
    if ($valor <= 0) {
        jsonErro('Valor do lancamento deve ser maior que zero.', 422);
    }

    $status = normalizarStatusLancamento($dados);
    $dataPagamento = trim((string)($dados['data_pagamento'] ?? '')) ?: null;
    if ($status === 2 && $dataPagamento === null) {
        $dataPagamento = date('Y-m-d');
    }
    $valorPago = $status === 2 ? normalizarValorLancamento($dados['valor_pago'] ?? $valor) : null;

    return [
        'fk_tipo_lancamento' => !empty($dados['fk_tipo_lancamento']) ? (int)$dados['fk_tipo_lancamento'] : null,
        'fk_conta_regente' => !empty($dados['fk_conta_regente']) ? (int)$dados['fk_conta_regente'] : null,
        'fk_conta_subordinada' => !empty($dados['fk_conta_subordinada']) ? (int)$dados['fk_conta_subordinada'] : null,
        'fk_forma_pagamento' => !empty($dados['fk_forma_pagamento']) ? (int)$dados['fk_forma_pagamento'] : null,
        'fk_status_conta' => $status,
        'referencia' => $referencia,
        'valor' => $valor,
        'valor_pago' => $valorPago,
        'data_lancamento' => trim((string)($dados['data_lancamento'] ?? '')) ?: date('Y-m-d'),
        'data_vencimento' => trim((string)($dados['data_vencimento'] ?? '')) ?: null,
        'data_pagamento' => $dataPagamento,
        'observacao' => trim((string)($dados['observacao'] ?? '')) ?: null,
    ];
}

function salvarLancamentoParceiro(PDO $pdo, int $idParceiro, array $dados): int {
    $l = validarLancamentoParceiro($dados);

    $stmt = $pdo->prepare("
        INSERT INTO lancamento (
            fk_parceiro, fk_tipo_lancamento, fk_conta_regente, fk_conta_subordinada,
            fk_forma_pagamento, fk_status_conta, descricao, valor, valor_pago,
            data_lancamento, data_vencimento, data_pagamento, observacao
        ) VALUES (
            :fk_parceiro, :fk_tipo_lancamento, :fk_conta_regente, :fk_conta_subordinada,
            :fk_forma_pagamento, :fk_status_conta, :descricao, :valor, :valor_pago,
            :data_lancamento, :data_vencimento, :data_pagamento, :observacao
        )
        RETURNING id_lancamento
    ");
    $stmt->execute([
        ':fk_parceiro' => $idParceiro,
        ':fk_tipo_lancamento' => $l['fk_tipo_lancamento'],
        ':fk_conta_regente' => $l['fk_conta_regente'],
        ':fk_conta_subordinada' => $l['fk_conta_subordinada'],
        ':fk_forma_pagamento' => $l['fk_forma_pagamento'],
        ':fk_status_conta' => $l['fk_status_conta'],
        ':descricao' => $l['referencia'],
        ':valor' => $l['valor'],
        ':valor_pago' => $l['valor_pago'],
        ':data_lancamento' => $l['data_lancamento'],
        ':data_vencimento' => $l['data_vencimento'],
        ':data_pagamento' => $l['data_pagamento'],
        ':observacao' => $l['observacao'],
    ]);

    return (int)$stmt->fetchColumn();
}

function atualizarLancamentoParceiro(PDO $pdo, int $idParceiro, int $idLancamento, array $dados): void {
    $l = validarLancamentoParceiro($dados);

    $stmt = $pdo->prepare("
        UPDATE lancamento SET
            fk_tipo_lancamento = :fk_tipo_lancamento,
            fk_conta_regente = :fk_conta_regente,
            fk_conta_subordinada = :fk_conta_subordinada,
            fk_forma_pagamento = :fk_forma_pagamento,
            fk_status_conta = :fk_status_conta,
            descricao = :descricao,
            valor = :valor,
            valor_pago = :valor_pago,
            data_lancamento = :data_lancamento,
            data_vencimento = :data_vencimento,
            data_pagamento = :data_pagamento,
            observacao = :observacao,
            atualizado_em = NOW()
        WHERE id_lancamento = :id_lancamento
          AND fk_parceiro = :fk_parceiro
    ");
    $stmt->execute([
        ':fk_tipo_lancamento' => $l['fk_tipo_lancamento'],
        ':fk_conta_regente' => $l['fk_conta_regente'],
        ':fk_conta_subordinada' => $l['fk_conta_subordinada'],
        ':fk_forma_pagamento' => $l['fk_forma_pagamento'],
        ':fk_status_conta' => $l['fk_status_conta'],
        ':descricao' => $l['referencia'],
        ':valor' => $l['valor'],
        ':valor_pago' => $l['valor_pago'],
        ':data_lancamento' => $l['data_lancamento'],
        ':data_vencimento' => $l['data_vencimento'],
        ':data_pagamento' => $l['data_pagamento'],
        ':observacao' => $l['observacao'],
        ':id_lancamento' => $idLancamento,
        ':fk_parceiro' => $idParceiro,
    ]);

    if ($stmt->rowCount() === 0) {
        jsonErro('Lancamento nao encontrado', 404);
    }
}
