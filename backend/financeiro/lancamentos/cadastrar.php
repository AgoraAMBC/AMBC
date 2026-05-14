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

try {

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
    )
    VALUES (
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

  $stmt->execute([
    ':fk_conta_regente'     => $dados['fk_conta_regente'] ?: null,
    ':fk_conta_subordinada' => $dados['fk_conta_subordinada'] ?: null,
    ':fk_tipo_lancamento'   => $dados['fk_tipo_lancamento'],
    ':fk_forma_pagamento'   => $dados['fk_forma_pagamento'],
    ':fk_status_conta'      => $dados['fk_status_conta'],
    ':descricao'            => $dados['descricao'],
    ':valor'                => $dados['valor'],
    ':data_lancamento'      => $dados['dataLancamento'] ?: null,
    ':data_vencimento'      => $dados['data_vencimento'] ?: null,
    ':observacao'           => $dados['observacao'] ?: null
]);

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Lançamento cadastrado com sucesso"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "erro" => $e->getMessage()
    ]);
}