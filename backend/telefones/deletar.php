<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$id_telefone = $body['id'] ?? $body['id_telefone'] ?? null;
if (!$id_telefone) jsonErro('ID do telefone é obrigatório', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("DELETE FROM telefone WHERE id_telefone = :id RETURNING id_telefone");
    $stmt->execute([':id' => (int)$id_telefone]);
    $resultado = $stmt->fetch();

    if (!$resultado) jsonErro('Telefone não encontrado', 404);

    jsonResposta(['mensagem' => 'Telefone excluído com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao excluir telefone: ' . $e->getMessage(), 500);
}