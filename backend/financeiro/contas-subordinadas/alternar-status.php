<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();
$id    = (int)($dados['id_conta_subordinada'] ?? 0);

if ($id <= 0) jsonErro('ID inválido');

$stmt = $pdo->prepare('SELECT ativo FROM conta_subordinada WHERE id_conta_subordinada = :id');
$stmt->execute([':id' => $id]);
$conta = $stmt->fetch();
if (!$conta) jsonErro('Conta subordinada não encontrada', 404);

$novoAtivo = !filter_var($conta['ativo'], FILTER_VALIDATE_BOOLEAN);
$pdo->prepare('UPDATE conta_subordinada SET ativo = :ativo WHERE id_conta_subordinada = :id')
    ->execute([':ativo' => $novoAtivo ? 'TRUE' : 'FALSE', ':id' => $id]);

$acao = $novoAtivo ? 'ativada' : 'inativada';
jsonResposta(['mensagem' => "Conta subordinada $acao com sucesso", 'ativo' => $novoAtivo]);
