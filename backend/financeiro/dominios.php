<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Metodo nao permitido', 405);

try {
    $pdo = obterConexao();

    // Tipos de lançamento que possuem regras ativas no Relacionamentos
    $tipos = $pdo->query("
        SELECT DISTINCT
            tl.id_tipo_lancamento,
            tl.descricao
        FROM tipo_lancamento tl
        INNER JOIN relacionamento_lancamento rl ON rl.fk_tipo_lancamento = tl.id_tipo_lancamento
        WHERE rl.ativo = true
        ORDER BY tl.descricao ASC
    ")->fetchAll(PDO::FETCH_ASSOC);

    $status = $pdo->query("
        SELECT id_status_conta, descricao
        FROM status_conta
        ORDER BY id_status_conta
    ")->fetchAll(PDO::FETCH_ASSOC);

    $formas = $pdo->query("
        SELECT id_forma_pagamento, descricao
        FROM forma_pagamento
        ORDER BY descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    $regentes = $pdo->query("
        SELECT id_conta_regente, descricao, tipo
        FROM conta_regente
        WHERE ativo = TRUE
        ORDER BY descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    $subordinadas = $pdo->query("
        SELECT id_conta_subordinada, fk_conta_regente, descricao
        FROM conta_subordinada
        WHERE ativo = TRUE
        ORDER BY descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    jsonResposta([
        'tipos' => $tipos,
        'status' => $status,
        'formas_pagamento' => $formas,
        'contas_regentes' => $regentes,
        'contas_subordinadas' => $subordinadas,
    ]);

} catch (PDOException $e) {
    jsonErro('Erro ao carregar dominios financeiros: ' . $e->getMessage(), 500);
}
