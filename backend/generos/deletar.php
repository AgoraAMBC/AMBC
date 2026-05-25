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

$stmt = $pdo->prepare('SELECT a.nome FROM associado a WHERE a.fk_genero = :id');
$stmt->execute([':id' => $id]);
$associados = $stmt->fetchAll(PDO::FETCH_COLUMN);

$stmt = $pdo->prepare('SELECT d.nome FROM dependente d WHERE d.fk_genero = :id');
$stmt->execute([':id' => $id]);
$dependentes = $stmt->fetchAll(PDO::FETCH_COLUMN);

if ($associados || $dependentes) {
    $partes = array_filter([
        listarVinculados($associados, 'associado'),
        listarVinculados($dependentes, 'dependente'),
    ]);
    jsonErro('Este gênero não pode ser excluído, pois está vinculado a ' . implode(' e ', $partes) . '.', 409);
}

try {
    $stmt = $pdo->prepare('DELETE FROM genero WHERE id_genero = :id');
    $stmt->execute([':id' => $id]);
} catch (PDOException $e) {
    jsonErro('Erro ao excluir: ' . $e->getMessage(), 500);
}

if ($stmt->rowCount() === 0) jsonErro('Registro não encontrado', 404);

jsonResposta(['mensagem' => 'Gênero excluído com sucesso']);
