<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/database.php';

try {
    $pdo = obterConexao();

    $tipos = $pdo->query(
        'SELECT id_tipo_lancamento, descricao FROM tipo_lancamento ORDER BY descricao'
    )->fetchAll(PDO::FETCH_ASSOC);

    $status = $pdo->query(
        'SELECT id_status_conta, descricao FROM status_conta ORDER BY id_status_conta'
    )->fetchAll(PDO::FETCH_ASSOC);

    $formas_pagamento = $pdo->query(
        'SELECT id_forma_pagamento, descricao FROM forma_pagamento ORDER BY descricao'
    )->fetchAll(PDO::FETCH_ASSOC);

    $contas_regentes = $pdo->query(
        'SELECT id_conta_regente, descricao, tipo FROM conta_regente WHERE ativo = 1 ORDER BY descricao'
    )->fetchAll(PDO::FETCH_ASSOC);

    $contas_subordinadas = $pdo->query(
        'SELECT id_conta_subordinada, fk_conta_regente, descricao FROM conta_subordinada WHERE ativo = 1 ORDER BY descricao'
    )->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'tipos'               => $tipos,
        'status'              => $status,
        'formas_pagamento'    => $formas_pagamento,
        'contas_regentes'     => $contas_regentes,
        'contas_subordinadas' => $contas_subordinadas,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => 'Erro ao carregar domínios: ' . $e->getMessage()]);
}
