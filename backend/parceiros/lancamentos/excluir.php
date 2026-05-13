<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Metodo nao permitido', 405);

$dados = corpoJson();
$idParceiro = (int)($dados['id_parceiro'] ?? 0);
$idLancamento = (int)($dados['id_lancamento'] ?? 0);

if ($idParceiro <= 0) jsonErro('ID do parceiro invalido', 400);
if ($idLancamento <= 0) jsonErro('ID do lancamento invalido', 400);

$pdo = obterConexao();
$stmt = $pdo->prepare('DELETE FROM lancamento WHERE id_lancamento = :id_lancamento AND fk_parceiro = :id_parceiro');
$stmt->execute([
    ':id_lancamento' => $idLancamento,
    ':id_parceiro' => $idParceiro,
]);

if ($stmt->rowCount() === 0) jsonErro('Lancamento nao encontrado', 404);

jsonResposta(['mensagem' => 'Lancamento removido com sucesso.']);
