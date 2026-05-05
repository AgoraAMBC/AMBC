<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo        = obterConexao();
$dados      = corpoJson();
$descricao  = trim($dados['descricao'] ?? '');
$tipo       = trim($dados['tipo'] ?? '');
$observacao = trim($dados['observacao'] ?? '');

if ($descricao === '') jsonErro('Nome é obrigatório');
if (!in_array($tipo, ['receita', 'despesa'], true)) jsonErro('Tipo deve ser receita ou despesa');

$stmt = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE descricao = :descricao');
$stmt->execute([':descricao' => $descricao]);
if ($stmt->fetch()) jsonErro('Já existe uma conta regente com esse nome');

$stmt = $pdo->prepare('
    INSERT INTO conta_regente (descricao, tipo, observacao)
    VALUES (:descricao, :tipo, :observacao)
    RETURNING id_conta_regente
');
$stmt->execute([
    ':descricao'  => $descricao,
    ':tipo'       => $tipo,
    ':observacao' => $observacao ?: null,
]);

jsonResposta(['mensagem' => 'Conta regente cadastrada com sucesso', 'id' => (int)$stmt->fetchColumn()], 201);
