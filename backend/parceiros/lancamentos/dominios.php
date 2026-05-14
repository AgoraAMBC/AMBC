<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Metodo nao permitido', 405);

$pdo = obterConexao();

$tipos = $pdo->query('SELECT id_tipo_lancamento, descricao FROM tipo_lancamento ORDER BY id_tipo_lancamento')->fetchAll();
$status = $pdo->query('SELECT id_status_conta, descricao FROM status_conta ORDER BY id_status_conta')->fetchAll();
$formas = $pdo->query('SELECT id_forma_pagamento, descricao FROM forma_pagamento ORDER BY descricao')->fetchAll();

$regentes = $pdo->query("
    SELECT id_conta_regente, descricao, tipo
    FROM conta_regente
    WHERE ativo = TRUE
    ORDER BY descricao
")->fetchAll();

$subordinadas = $pdo->query("
    SELECT id_conta_subordinada, fk_conta_regente, descricao
    FROM conta_subordinada
    WHERE ativo = TRUE
    ORDER BY descricao
")->fetchAll();

jsonResposta([
    'tipos' => $tipos,
    'status' => $status,
    'formas_pagamento' => $formas,
    'contas_regentes' => $regentes,
    'contas_subordinadas' => $subordinadas,
]);
