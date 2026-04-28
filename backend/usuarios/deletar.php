<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    jsonErro('Método não permitido', 405);
}

$corpo = corpoJson();
$id    = isset($corpo['id_usuario']) ? (int)$corpo['id_usuario'] : 0;

if ($id <= 0) {
    jsonErro('ID do usuário inválido');
}

$pdo = obterConexao();

$pdo->prepare('DELETE FROM permissao_usuario WHERE fk_usuario = :id')->execute([':id' => $id]);

$stmt = $pdo->prepare('DELETE FROM usuario WHERE id_usuario = :id');
$stmt->execute([':id' => $id]);

if ($stmt->rowCount() === 0) {
    jsonErro('Usuário não encontrado', 404);
}

jsonResposta(['mensagem' => 'Usuário excluído com sucesso!']);
