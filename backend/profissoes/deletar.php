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

$stmt = $pdo->prepare('DELETE FROM profissao WHERE id_profissao = :id');
$stmt->execute([':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Registro não encontrado', 404);

jsonResposta(['mensagem' => 'Profissão excluída com sucesso']);
