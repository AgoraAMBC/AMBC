<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
$id    = (int)($dados['id_parceiro'] ?? 0);

if ($id <= 0) jsonErro('ID inválido', 400);

$pdo = obterConexao();

// Busca status atual
$stmt = $pdo->prepare('SELECT ativo FROM parceiro WHERE id_parceiro = :id');
$stmt->execute([':id' => $id]);
$parceiro = $stmt->fetch();

if (!$parceiro) jsonErro('Parceiro não encontrado', 404);

// Inverte o status
$novoStatus = !$parceiro['ativo'];

$pdo->prepare('UPDATE parceiro SET ativo = :ativo WHERE id_parceiro = :id')
    ->execute([':ativo' => $novoStatus, ':id' => $id]);

$mensagem = $novoStatus ? 'Parceiro ativado com sucesso.' : 'Parceiro inativado com sucesso.';

jsonResposta(['mensagem' => $mensagem, 'ativo' => $novoStatus]);
