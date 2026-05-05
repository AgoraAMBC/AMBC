<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$corpo = corpoJson();
$id    = (int)($corpo['id_associado'] ?? 0);

if ($id <= 0) jsonErro('ID do associado é obrigatório', 400);

$pdo = obterConexao();

$stmt = $pdo->prepare('DELETE FROM associado WHERE id_associado = :id');
$stmt->execute([':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Associado não encontrado', 404);

jsonResposta(['mensagem' => 'Associado excluído com sucesso']);
