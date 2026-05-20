<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

try {
    $pdo = obterConexao();

    $sql = "
        SELECT
            rl.id_relacionamento,
            rl.fk_tipo_lancamento,
            rl.fk_conta_regente,
            rl.fk_conta_subordinada,
            rl.natureza,
            rl.modo,
            rl.ativo,
            rl.observacao,
            rl.criado_em,
            rl.atualizado_em,
            tl.descricao as tipo_lancamento,
            cr.descricao as conta_regente,
            cs.descricao as conta_subordinada
        FROM relacionamento_lancamento rl
        LEFT JOIN tipo_lancamento tl ON rl.fk_tipo_lancamento = tl.id_tipo_lancamento
        LEFT JOIN conta_regente cr ON rl.fk_conta_regente = cr.id_conta_regente
        LEFT JOIN conta_subordinada cs ON rl.fk_conta_subordinada = cs.id_conta_subordinada
        ORDER BY rl.ativo DESC, tl.descricao ASC
    ";

    $stmt = $pdo->query($sql);
    $relacionamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    jsonResposta([
        'data' => $relacionamentos,
        'total' => count($relacionamentos)
    ]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar relacionamentos: ' . $e->getMessage(), 500);
}
