<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$id_dependente = $body['id'] ?? $body['id_dependente'] ?? null;
if (!$id_dependente) jsonErro('ID do dependente é obrigatório', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("DELETE FROM dependente WHERE id_dependente = :id RETURNING id_dependente");
    $stmt->execute([':id' => (int)$id_dependente]);
    $resultado = $stmt->fetch();

    if (!$resultado) jsonErro('Dependente não encontrado', 404);

    jsonResposta(['mensagem' => 'Dependente excluído com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao excluir dependente: ' . $e->getMessage(), 500);
}