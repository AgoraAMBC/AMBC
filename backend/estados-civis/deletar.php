<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();
$id    = (int)($dados['id'] ?? $_GET['id'] ?? 0);

if ($id <= 0) jsonErro('ID inválido');

$stmt = $pdo->prepare('SELECT a.nome FROM associado a WHERE a.fk_estadocivil = :id');
$stmt->execute([':id' => $id]);
$associados = $stmt->fetchAll(PDO::FETCH_COLUMN);

if ($associados) {
    jsonErro('Este estado civil não pode ser excluído, pois está vinculado a ' . listarVinculados($associados, 'associado') . '.', 409);
}

try {
    $stmt = $pdo->prepare('DELETE FROM estado_civil WHERE id_estadocivil = :id');
    $stmt->execute([':id' => $id]);
} catch (PDOException $e) {
    jsonErro('Erro ao excluir: ' . $e->getMessage(), 500);
}

if ($stmt->rowCount() === 0) jsonErro('Registro não encontrado', 404);

jsonResposta(['mensagem' => 'Estado civil excluído com sucesso']);
