<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido ou não informado', 400);

$pdo = obterConexao();

$stmtCheck = $pdo->prepare("SELECT id_associado FROM associado WHERE id_associado = :id");
$stmtCheck->execute([':id' => $id]);
if (!$stmtCheck->fetch()) jsonErro('Associado não encontrado', 404);

try {
    // Remove associado (os dependentes são removidos automaticamente por CASCADE)
    $stmt = $pdo->prepare("DELETE FROM associado WHERE id_associado = :id");
    $stmt->execute([':id' => $id]);

    if ($stmt->rowCount() === 0) jsonErro('Associado não encontrado', 404);

    jsonResposta(['mensagem' => 'Associado removido com sucesso']);

} catch (Exception $e) {
    $pdo->rollBack();
    jsonErro('Erro ao remover associado: ' . $e->getMessage(), 500);
}
