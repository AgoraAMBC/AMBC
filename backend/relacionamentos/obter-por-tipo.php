<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Método não permitido', 405);
}

$fk_tipo = (int)($_GET['fk_tipo_lancamento'] ?? 0);
if ($fk_tipo <= 0) jsonErro('Tipo de lançamento inválido', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("
        SELECT
            rl.id_relacionamento,
            rl.fk_tipo_lancamento,
            rl.fk_conta_regente,
            rl.fk_conta_subordinada,
            rl.natureza,
            rl.modo
        FROM relacionamento_lancamento rl
        WHERE rl.fk_tipo_lancamento = :tipo AND rl.ativo = true
        LIMIT 1
    ");
    $stmt->execute([':tipo' => $fk_tipo]);
    $relacionamento = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$relacionamento) {
        jsonErro('Nenhuma regra ativa encontrada para este tipo', 404);
    }

    jsonResposta(['data' => $relacionamento]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar regra: ' . $e->getMessage(), 500);
}
