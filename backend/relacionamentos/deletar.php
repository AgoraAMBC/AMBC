<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    jsonErro('Método não permitido', 405);
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("DELETE FROM relacionamento_lancamento WHERE id_relacionamento = :id");
    $stmt->execute([':id' => $id]);

    if ($stmt->rowCount() === 0) {
        jsonErro('Relacionamento não encontrado', 404);
    }

    jsonResposta(['message' => 'Relacionamento excluído com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao excluir: ' . $e->getMessage(), 500);
}