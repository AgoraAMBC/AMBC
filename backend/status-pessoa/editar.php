<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();

$id        = (int)($dados['id'] ?? 0);
$descricao = trim($dados['descricao'] ?? '');

if ($id <= 0)         jsonErro('ID inválido');
if ($descricao === '') jsonErro('Descrição é obrigatória');

$stmt = $pdo->prepare('SELECT id_status FROM status_pessoa WHERE descricao = :descricao AND id_status <> :id');
$stmt->execute([':descricao' => $descricao, ':id' => $id]);
if ($stmt->fetch()) jsonErro('Já existe um status com esta descrição');

$stmt = $pdo->prepare('UPDATE status_pessoa SET descricao = :descricao WHERE id_status = :id');
$stmt->execute([':descricao' => $descricao, ':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Registro não encontrado', 404);

jsonResposta(['mensagem' => 'Status atualizado com sucesso']);
