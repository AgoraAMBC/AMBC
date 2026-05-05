<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();
$id    = (int)($dados['id_conta_regente'] ?? 0);

if ($id <= 0) jsonErro('ID inválido');

$stmt = $pdo->prepare('SELECT ativo FROM conta_regente WHERE id_conta_regente = :id');
$stmt->execute([':id' => $id]);
$conta = $stmt->fetch();
if (!$conta) jsonErro('Conta regente não encontrada', 404);

$novoAtivo = !filter_var($conta['ativo'], FILTER_VALIDATE_BOOLEAN);
$pdo->prepare('UPDATE conta_regente SET ativo = :ativo WHERE id_conta_regente = :id')
    ->execute([':ativo' => $novoAtivo ? 'TRUE' : 'FALSE', ':id' => $id]);

$acao = $novoAtivo ? 'ativada' : 'inativada';
jsonResposta(['mensagem' => "Conta regente $acao com sucesso", 'ativo' => $novoAtivo]);
