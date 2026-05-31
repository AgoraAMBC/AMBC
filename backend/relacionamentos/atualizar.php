<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
    jsonErro('Método não permitido', 405);
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

try {
    $pdo = obterConexao();

    // Verificar se o relacionamento existe
    $stmtCheck = $pdo->prepare("SELECT id_relacionamento FROM relacionamento_lancamento WHERE id_relacionamento = :id");
    $stmtCheck->execute([':id' => $id]);
    if (!$stmtCheck->fetch()) {
        jsonErro('Relacionamento não encontrado', 404);
    }

    // Monta SET dinamicamente
    $campos = [];
    $params = [':id' => $id];

    if (isset($body['tipo'])) {
        $tipo = trim($body['tipo']);
        // Verificar ou criar o tipo de lançamento
        $stmtTipo = $pdo->prepare("SELECT id_tipo_lancamento FROM tipo_lancamento WHERE descricao LIKE :tipo");
        $stmtTipo->execute([':tipo' => $tipo]);
        $tipoExistente = $stmtTipo->fetch(PDO::FETCH_ASSOC);

        if ($tipoExistente) {
            $fk_tipo_lancamento = $tipoExistente['id_tipo_lancamento'];
        } else {
            $stmtInsertTipo = $pdo->prepare("INSERT INTO tipo_lancamento (descricao) VALUES (:tipo)");
            $stmtInsertTipo->execute([':tipo' => $tipo]);
            $fk_tipo_lancamento = $pdo->lastInsertId();
        }
        $campos[] = 'fk_tipo_lancamento = :tipo';
        $params[':tipo'] = $fk_tipo_lancamento;
    }
    if (isset($body['fk_conta_regente'])) {
        $campos[] = 'fk_conta_regente = :regente';
        $params[':regente'] = $body['fk_conta_regente'];
    }
    if (isset($body['fk_conta_subordinada'])) {
        $campos[] = 'fk_conta_subordinada = :subordinada';
        $params[':subordinada'] = $body['fk_conta_subordinada'];
    }
    if (isset($body['natureza'])) {
        if (!in_array($body['natureza'], ['RECEBER', 'PAGAR'])) {
            jsonErro('Natureza inválida', 422);
        }
        $campos[] = 'natureza = :natureza';
        $params[':natureza'] = $body['natureza'];
    }
    if (isset($body['modo'])) {
        if (!in_array($body['modo'], ['FIXO', 'SUGERIDO'])) {
            jsonErro('Modo inválido', 422);
        }
        $campos[] = 'modo = :modo';
        $params[':modo'] = $body['modo'];
    }
    if (isset($body['ativo'])) {
        $campos[] = 'ativo = :ativo';
        $params[':ativo'] = $body['ativo'] ? 1 : 0;
    }
    if (isset($body['observacao'])) {
        $campos[] = 'observacao = :obs';
        $params[':obs'] = $body['observacao'];
    }

    if (empty($campos)) {
        jsonErro('Nenhum campo para atualizar', 400);
    }

    $campos[] = 'atualizado_em = NOW()';
    $sql = "UPDATE relacionamento_lancamento SET " . implode(', ', $campos) . " WHERE id_relacionamento = :id";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    jsonResposta(['message' => 'Relacionamento atualizado com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao atualizar: ' . $e->getMessage(), 500);
}