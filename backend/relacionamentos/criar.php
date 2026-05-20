<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$fk_tipo_lancamento = $body['fk_tipo_lancamento'] ?? null;
$fk_conta_regente = $body['fk_conta_regente'] ?? null;
$fk_conta_subordinada = $body['fk_conta_subordinada'] ?? null;
$natureza = $body['natureza'] ?? null;
$modo = $body['modo'] ?? null;
$ativo = isset($body['ativo']) ? (bool)$body['ativo'] : true;
$observacao = $body['observacao'] ?? null;

if (!$fk_tipo_lancamento || !$fk_conta_regente || !$fk_conta_subordinada || !$natureza || !$modo) {
    jsonErro('Campos obrigatórios não informados', 422);
}

if (!in_array($natureza, ['RECEBER', 'PAGAR'])) {
    jsonErro('Natureza inválida', 422);
}

if (!in_array($modo, ['FIXO', 'SUGERIDO'])) {
    jsonErro('Modo inválido', 422);
}

try {
    $pdo = obterConexao();

    // Se está ativando um novo, desativar o anterior para este tipo
    if ($ativo) {
        $stmtDesativa = $pdo->prepare("
            UPDATE relacionamento_lancamento
            SET ativo = false, atualizado_em = NOW()
            WHERE fk_tipo_lancamento = :tipo AND ativo = true AND id_relacionamento != COALESCE(NULL, 0)
        ");
        $stmtDesativa->execute([':tipo' => $fk_tipo_lancamento]);
    }

    // Inserir novo relacionamento
    $sql = "
        INSERT INTO relacionamento_lancamento (
            fk_tipo_lancamento, fk_conta_regente, fk_conta_subordinada,
            natureza, modo, ativo, observacao, criado_em, atualizado_em
        ) VALUES (
            :tipo, :regente, :subordinada,
            :natureza, :modo, :ativo, :obs, NOW(), NOW()
        )
        RETURNING id_relacionamento
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':tipo' => $fk_tipo_lancamento,
        ':regente' => $fk_conta_regente,
        ':subordinada' => $fk_conta_subordinada,
        ':natureza' => $natureza,
        ':modo' => $modo,
        ':ativo' => $ativo ? 'true' : 'false',
        ':obs' => $observacao
    ]);

    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    jsonResposta([
        'data' => ['id_relacionamento' => (int)$row['id_relacionamento']],
        'message' => 'Relacionamento criado com sucesso.'
    ], 201);

} catch (PDOException $e) {
    jsonErro('Erro ao salvar: ' . $e->getMessage(), 500);
}
