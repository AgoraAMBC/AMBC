<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();
$id    = (int)($dados['id_usuario'] ?? 0);

if ($id <= 0) jsonErro('Usuário inválido');

$stmt = $pdo->prepare('SELECT ativo FROM usuario WHERE id_usuario = :id');
$stmt->execute([':id' => $id]);
$usuario = $stmt->fetch();

if (!$usuario) jsonErro('Usuário não encontrado', 404);

$novoStatus = !(bool)$usuario['ativo'];

$pdo->prepare('UPDATE usuario SET ativo = :ativo, atualizado_em = NOW() WHERE id_usuario = :id')
    ->execute([':ativo' => $novoStatus ? 'TRUE' : 'FALSE', ':id' => $id]);

jsonResposta([
    'mensagem' => 'Usuário ' . ($novoStatus ? 'ativado' : 'desativado') . ' com sucesso',
    'ativo'    => $novoStatus,
]);
