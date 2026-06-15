<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Metodo nao permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
$id = isset($dados['id']) ? (int)$dados['id'] : 0;

if ($id <= 0) jsonErro('ID do lancamento invalido', 400);

try {
    $pdo = obterConexao();
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('SELECT id_lancamento FROM lancamento WHERE id_lancamento = :id');
    $stmt->execute([':id' => $id]);

    if (!$stmt->fetch()) {
        $pdo->rollBack();
        jsonErro('Lancamento nao encontrado', 404);
    }

    $pdo->prepare('DELETE FROM lancamento WHERE id_lancamento = :id')->execute([':id' => $id]);

    $pdo->commit();

    jsonResposta(['mensagem' => 'Lancamento excluido com sucesso']);
} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    jsonErro('Erro ao excluir lancamento: ' . $e->getMessage(), 500);
}
