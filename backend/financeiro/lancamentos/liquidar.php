<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['erro' => 'Método não permitido']);
    exit;
}

require_once '../../config/database.php';

$dados = json_decode(file_get_contents('php://input'), true);
if (!$dados || !is_array($dados)) {
    http_response_code(400);
    echo json_encode(['erro' => 'Payload inválido']);
    exit;
}

$id_lancamento       = isset($dados['id_lancamento'])       ? (int)$dados['id_lancamento']       : 0;
$acao                = $dados['acao']                       ?? 'liquidar'; // 'liquidar' | 'cancelar'
$valor_pago          = isset($dados['valor_pago'])          ? (float)$dados['valor_pago']         : null;
$data_pagamento      = $dados['data_pagamento']             ?? null;
$fk_forma_pagamento  = isset($dados['fk_forma_pagamento'])  ? (int)$dados['fk_forma_pagamento']   : null;

if ($id_lancamento <= 0) {
    http_response_code(422);
    echo json_encode(['erro' => 'ID do lançamento inválido']);
    exit;
}

if ($acao === 'liquidar') {
    if (!$valor_pago || $valor_pago <= 0) {
        http_response_code(422);
        echo json_encode(['erro' => 'Valor recebido deve ser maior que zero']);
        exit;
    }
    if (!$data_pagamento) {
        http_response_code(422);
        echo json_encode(['erro' => 'Data do pagamento é obrigatória']);
        exit;
    }
}

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare('SELECT id_lancamento, fk_status_conta FROM lancamento WHERE id_lancamento = :id LIMIT 1');
    $stmt->execute([':id' => $id_lancamento]);
    $lancamento = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$lancamento) {
        http_response_code(404);
        echo json_encode(['erro' => 'Lançamento não encontrado']);
        exit;
    }

    if ((int)$lancamento['fk_status_conta'] !== 1) {
        http_response_code(409);
        echo json_encode(['erro' => 'Somente lançamentos em aberto podem ser alterados']);
        exit;
    }

    if ($acao === 'cancelar') {
        $pdo->prepare('UPDATE lancamento SET fk_status_conta = 3, atualizado_em = NOW() WHERE id_lancamento = :id')
            ->execute([':id' => $id_lancamento]);

        echo json_encode(['sucesso' => true, 'mensagem' => 'Lançamento cancelado com sucesso']);
        exit;
    }

    $pdo->prepare('
        UPDATE lancamento
        SET fk_status_conta    = 2,
            valor_pago         = :valor_pago,
            data_pagamento     = :data_pagamento,
            fk_forma_pagamento = :fk_forma_pagamento,
            atualizado_em      = NOW()
        WHERE id_lancamento = :id
    ')->execute([
        ':valor_pago'         => $valor_pago,
        ':data_pagamento'     => $data_pagamento,
        ':fk_forma_pagamento' => $fk_forma_pagamento,
        ':id'                 => $id_lancamento,
    ]);

    echo json_encode(['sucesso' => true, 'mensagem' => 'Lançamento liquidado com sucesso']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => 'Erro ao processar lançamento: ' . $e->getMessage()]);
}
