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
        'SELECT id_notificacao, titulo, mensagem, lida, criado_em
         FROM notificacao
         WHERE fk_usuario = :uid
         ORDER BY lida ASC, criado_em DESC
         LIMIT 20'
    );
    $stmt->execute([':uid' => $_SESSION['id_usuario']]);
    $notificacoes = $stmt->fetchAll();

    $nao_lidas = (int) array_sum(array_column($notificacoes, 'lida') === [] ? [] :
        array_map(fn($n) => $n['lida'] == 0 ? 1 : 0, $notificacoes));

    jsonResposta(['notificacoes' => $notificacoes, 'nao_lidas' => $nao_lidas]);
} catch (PDOException $e) {
    jsonResposta(['notificacoes' => [], 'nao_lidas' => 0]);
}
