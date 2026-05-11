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

$stmt = $pdo->prepare('SELECT id_profissao FROM profissao WHERE descricao = :descricao AND id_profissao <> :id');
$stmt->execute([':descricao' => $descricao, ':id' => $id]);
if ($stmt->fetch()) jsonErro('Já existe uma profissão com esta descrição');

$stmt = $pdo->prepare('UPDATE profissao SET descricao = :descricao WHERE id_profissao = :id');
$stmt->execute([':descricao' => $descricao, ':id' => $id]);

if ($stmt->rowCount() === 0) jsonErro('Registro não encontrado', 404);

jsonResposta(['mensagem' => 'Profissão atualizada com sucesso']);
