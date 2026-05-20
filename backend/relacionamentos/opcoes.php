<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

try {
    $pdo = obterConexao();

    // Tipos de lançamento ativos
    $tipos = $pdo->query("
        SELECT id_tipo_lancamento AS id, descricao
        FROM tipo_lancamento
        WHERE ativo = true
        ORDER BY descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    // Contas regentes ativas
    $regentes = $pdo->query("
        SELECT id_conta_regente AS id, descricao, tipo
        FROM conta_regente
        WHERE ativo = true
        ORDER BY descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    // Contas subordinadas ativas
    $subordinadas = $pdo->query("
        SELECT cs.id_conta_subordinada AS id, cs.descricao, cr.descricao AS regente
        FROM conta_subordinada cs
        JOIN conta_regente cr ON cs.fk_conta_regente = cr.id_conta_regente
        WHERE cs.ativo = true
        ORDER BY cr.descricao, cs.descricao
    ")->fetchAll(PDO::FETCH_ASSOC);

    jsonResposta([
        'data' => [
            'tipos_lancamento' => $tipos,
            'contas_regentes' => $regentes,
            'contas_subordinadas' => $subordinadas,
        ]
    ]);

} catch (PDOException $e) {
    jsonErro('Erro ao carregar opções: ' . $e->getMessage(), 500);
}