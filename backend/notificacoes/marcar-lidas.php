<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/helpers.php';

configurarCors();
iniciarSessao();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo  = obterConexao();
$body = corpoJson();
$id   = isset($body['id_notificacao']) ? (int)$body['id_notificacao'] : null;

try {
    if ($id) {
        $stmt = $pdo->prepare(
            'UPDATE notificacao SET lida = 1 WHERE id_notificacao = :id AND fk_usuario = :uid'
        );
        $stmt->execute([':id' => $id, ':uid' => $_SESSION['id_usuario']]);
    } else {
        $stmt = $pdo->prepare('UPDATE notificacao SET lida = 1 WHERE fk_usuario = :uid');
        $stmt->execute([':uid' => $_SESSION['id_usuario']]);
    }
    jsonResposta(['ok' => true]);
} catch (PDOException $e) {
    jsonErro('Erro ao marcar notificações', 500);
}
