<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Metodo nao permitido', 405);

if (!empty($_SESSION['id_usuario']) && ($_SESSION['fk_perfil'] ?? 0) != 1) {
    jsonErro('Acesso restrito a administradores.', 403);
}

$dados = json_decode(file_get_contents('php://input'), true);
$id    = isset($dados['id']) ? (int)$dados['id'] : 0;

if ($id <= 0) jsonErro('ID do lancamento invalido', 400);

try {
    $pdo = obterConexao();
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('SELECT id_lancamento, fk_status_conta FROM lancamento WHERE id_lancamento = :id');
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();

    if (!$row) {
        $pdo->rollBack();
        jsonErro('Lancamento nao encontrado', 404);
    }

    if (!in_array((int)$row['fk_status_conta'], [2, 4])) {
        $pdo->rollBack();
        jsonErro('Apenas lancamentos pagos ou isentos podem ser estornados.', 422);
    }

    $pdo->prepare('
        UPDATE lancamento
        SET fk_status_conta = 1,
            valor_pago      = NULL,
            data_pagamento  = NULL
        WHERE id_lancamento = :id
    ')->execute([':id' => $id]);

    $pdo->commit();

    jsonResposta(['mensagem' => 'Lancamento estornado com sucesso']);
} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    jsonErro('Erro ao estornar lancamento: ' . $e->getMessage(), 500);
}
