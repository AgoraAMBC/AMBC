<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo        = obterConexao();
$dados      = corpoJson();
$fkRegente  = (int)($dados['fk_conta_regente'] ?? 0);
$descricao  = trim($dados['descricao'] ?? '');
$observacao = trim($dados['observacao'] ?? '');

if ($fkRegente <= 0)  jsonErro('Conta regente é obrigatória');
if ($descricao === '') jsonErro('Nome é obrigatório');

$stmt = $pdo->prepare('SELECT id_conta_regente FROM conta_regente WHERE id_conta_regente = :id AND ativo = TRUE');
$stmt->execute([':id' => $fkRegente]);
if (!$stmt->fetch()) jsonErro('Conta regente não encontrada ou inativa');

$stmt = $pdo->prepare('
    INSERT INTO conta_subordinada (fk_conta_regente, descricao, observacao)
    VALUES (:fk_conta_regente, :descricao, :observacao)
    RETURNING id_conta_subordinada
');
$stmt->execute([
    ':fk_conta_regente' => $fkRegente,
    ':descricao'        => $descricao,
    ':observacao'       => $observacao ?: null,
]);

jsonResposta(['mensagem' => 'Conta subordinada cadastrada com sucesso', 'id' => (int)$stmt->fetchColumn()], 201);
