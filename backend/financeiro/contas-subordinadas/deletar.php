<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$corpo = corpoJson();
$id    = (int)($corpo['id_conta_subordinada'] ?? 0);

if ($id <= 0) jsonErro('ID da conta subordinada é obrigatório', 400);

$pdo = obterConexao();

$stmtVerifica = $pdo->prepare('SELECT COUNT(*) FROM conta WHERE fk_conta_subordinada = :id');
$stmtVerifica->execute([':id' => $id]);
if ((int)$stmtVerifica->fetchColumn() > 0) {
    jsonErro('Não é possível excluir uma subconta que possui movimentos financeiros vinculados', 409);
}

$stmt = $pdo->prepare('DELETE FROM conta_subordinada WHERE id_conta_subordinada = :id');
$stmt->execute([':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Conta subordinada não encontrada', 404);

jsonResposta(['mensagem' => 'Conta subordinada excluída com sucesso']);
