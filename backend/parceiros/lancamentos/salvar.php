<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/utils.php';

configurarCors();

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT'], true)) {
    jsonErro('Metodo nao permitido', 405);
}

$dados = corpoJson();
$idParceiro = (int)($dados['id_parceiro'] ?? 0);
if ($idParceiro <= 0) jsonErro('ID do parceiro invalido', 400);

$pdo = obterConexao();

try {
    $pdo->beginTransaction();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $idLancamento = salvarLancamentoParceiro($pdo, $idParceiro, $dados);
        $pdo->commit();
        jsonResposta(['id_lancamento' => $idLancamento, 'mensagem' => 'Lancamento cadastrado com sucesso.'], 201);
    }

    $idLancamento = (int)($dados['id_lancamento'] ?? 0);
    if ($idLancamento <= 0) jsonErro('ID do lancamento invalido', 400);

    atualizarLancamentoParceiro($pdo, $idParceiro, $idLancamento, $dados);
    $pdo->commit();
    jsonResposta(['mensagem' => 'Lancamento atualizado com sucesso.']);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    jsonErro('Erro ao salvar lancamento: ' . $e->getMessage(), 500);
}
