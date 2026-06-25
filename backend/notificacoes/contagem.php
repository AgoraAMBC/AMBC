<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/helpers.php';

configurarCors();
iniciarSessao();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

try {
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM notificacao WHERE fk_usuario = :uid AND lida = 0'
    );
    $stmt->execute([':uid' => $_SESSION['id_usuario']]);
    $nao_lidas = (int) $stmt->fetchColumn();
} catch (PDOException $e) {
    $nao_lidas = 0;
}

jsonResposta(['nao_lidas' => $nao_lidas]);
