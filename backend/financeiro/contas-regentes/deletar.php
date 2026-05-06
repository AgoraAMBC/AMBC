<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$corpo = corpoJson();
$id    = (int)($corpo['id_conta_regente'] ?? 0);

if ($id <= 0) jsonErro('ID da conta regente é obrigatório', 400);

$pdo = obterConexao();

$stmtVerifica = $pdo->prepare('SELECT COUNT(*) FROM conta_subordinada WHERE fk_conta_regente = :id');
$stmtVerifica->execute([':id' => $id]);
if ((int)$stmtVerifica->fetchColumn() > 0) {
    jsonErro('Não é possível excluir uma conta que possui subcontas vinculadas', 409);
}

$stmt = $pdo->prepare('DELETE FROM conta_regente WHERE id_conta_regente = :id');
$stmt->execute([':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Conta regente não encontrada', 404);

jsonResposta(['mensagem' => 'Conta regente excluída com sucesso']);
