<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$id_parceiro = $body['id'] ?? $body['id_parceiro'] ?? null;
if (!$id_parceiro) jsonErro('ID do parceiro é obrigatório', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("DELETE FROM parceiro WHERE id_parceiro = :id");
    $stmt->execute([':id' => (int)$id_parceiro]);

    if ($stmt->rowCount() === 0) jsonErro('Parceiro não encontrado', 404);

    jsonResposta(['mensagem' => 'Parceiro excluído com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao excluir parceiro: ' . $e->getMessage(), 500);
}