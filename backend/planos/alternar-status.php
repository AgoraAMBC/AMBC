<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
$id    = (int)($dados['id_plano'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

$pdo  = obterConexao();
$stmt = $pdo->prepare('SELECT ativo FROM plano_associacao WHERE id_plano = :id');
$stmt->execute([':id' => $id]);
$plano = $stmt->fetch();

if (!$plano) jsonErro('Plano não encontrado.', 404);

$novoStatus = !filter_var($plano['ativo'], FILTER_VALIDATE_BOOLEAN);

$pdo->prepare("UPDATE plano_associacao SET ativo = :ativo WHERE id_plano = :id")
    ->execute([':ativo' => $novoStatus ? 'true' : 'false', ':id' => $id]);

$mensagem = $novoStatus ? 'Plano ativado com sucesso.' : 'Plano inativado com sucesso.';
jsonResposta(['mensagem' => $mensagem, 'ativo' => $novoStatus]);
