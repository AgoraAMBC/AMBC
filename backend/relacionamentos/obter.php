<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Método não permitido', 405);
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("
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
            cr.tipo as conta_regente_tipo,
            cs.descricao as conta_subordinada
        FROM relacionamento_lancamento rl
        LEFT JOIN tipo_lancamento tl ON rl.fk_tipo_lancamento = tl.id_tipo_lancamento
        LEFT JOIN conta_regente cr ON rl.fk_conta_regente = cr.id_conta_regente
        LEFT JOIN conta_subordinada cs ON rl.fk_conta_subordinada = cs.id_conta_subordinada
        WHERE rl.id_relacionamento = :id
    ");
    $stmt->execute([':id' => $id]);
    $relacionamento = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$relacionamento) {
        jsonErro('Relacionamento não encontrado', 404);
    }

    jsonResposta(['data' => $relacionamento]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar relacionamento: ' . $e->getMessage(), 500);
}