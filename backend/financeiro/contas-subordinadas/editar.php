<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$pdo        = obterConexao();
$dados      = corpoJson();
$id         = (int)($dados['id_conta_subordinada'] ?? 0);
$fkRegente  = (int)($dados['fk_conta_regente'] ?? 0);
$descricao  = trim($dados['descricao'] ?? '');
$observacao = trim($dados['observacao'] ?? '');

if ($id <= 0)          jsonErro('ID inválido');
if ($fkRegente <= 0)   jsonErro('Conta regente é obrigatória');
if ($descricao === '')  jsonErro('Nome é obrigatório');

$stmt = $pdo->prepare('SELECT id_conta_subordinada FROM conta_subordinada WHERE id_conta_subordinada = :id');
$stmt->execute([':id' => $id]);
if (!$stmt->fetch()) jsonErro('Conta subordinada não encontrada', 404);

$pdo->prepare('
    UPDATE conta_subordinada
    SET fk_conta_regente = :fk_regente, descricao = :descricao, observacao = :observacao, atualizado_em = NOW()
    WHERE id_conta_subordinada = :id
')->execute([
    ':fk_regente' => $fkRegente,
    ':descricao'  => $descricao,
    ':observacao' => $observacao ?: null,
    ':id'         => $id,
]);

jsonResposta(['mensagem' => 'Conta subordinada atualizada com sucesso']);
