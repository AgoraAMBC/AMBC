<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$pdo        = obterConexao();
$dados      = corpoJson();
$id         = (int)($dados['id_conta_regente'] ?? 0);
$descricao  = trim($dados['descricao'] ?? '');
$tipo       = trim($dados['tipo'] ?? '');
$observacao = trim($dados['observacao'] ?? '');

if ($id <= 0)          jsonErro('ID inválido');
if ($descricao === '')  jsonErro('Nome é obrigatório');
if (!in_array($tipo, ['receita', 'despesa'], true)) jsonErro('Tipo deve ser receita ou despesa');

$stmt = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE id_conta_regente = :id');
$stmt->execute([':id' => $id]);
if (!$stmt->fetch()) jsonErro('Conta regente não encontrada', 404);

$stmt = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE descricao = :descricao AND id_conta_regente != :id');
$stmt->execute([':descricao' => $descricao, ':id' => $id]);
if ($stmt->fetch()) jsonErro('Já existe outra conta regente com esse nome');

$pdo->prepare('
    UPDATE conta_regente
    SET descricao = :descricao, tipo = :tipo, observacao = :observacao, atualizado_em = NOW()
    WHERE id_conta_regente = :id
')->execute([
    ':descricao'  => $descricao,
    ':tipo'       => $tipo,
    ':observacao' => $observacao ?: null,
    ':id'         => $id,
]);

jsonResposta(['mensagem' => 'Conta regente atualizada com sucesso']);
