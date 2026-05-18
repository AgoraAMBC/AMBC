<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$body = corpoJson();
$id   = (int)($body['id_plano'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

try {
    $pdo  = obterConexao();
    $stmt = $pdo->prepare("DELETE FROM plano_associacao WHERE id_plano = :id RETURNING id_plano");
    $stmt->execute([':id' => $id]);

    if (!$stmt->fetch()) jsonErro('Plano não encontrado.', 404);

    jsonResposta(['mensagem' => 'Plano excluído com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao excluir plano: ' . $e->getMessage(), 500);
}
