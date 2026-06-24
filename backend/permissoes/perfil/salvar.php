<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
iniciarSessao();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);
if (($_SESSION['fk_perfil'] ?? 0) !== 1) jsonErro('Apenas administradores podem alterar permissões.', 403);

$body = corpoJson();
$permissoes = $body['permissoes'] ?? [];

if (!is_array($permissoes) || empty($permissoes)) jsonErro('Nenhuma permissão recebida', 400);

$pdo = obterConexao();

$stmt = $pdo->prepare('
    INSERT INTO permissao_perfil (fk_perfil, fk_modulo, pode_acessar, pode_editar)
    VALUES (:perfil, :modulo, :acessar, :editar)
    ON DUPLICATE KEY UPDATE pode_acessar = VALUES(pode_acessar), pode_editar = VALUES(pode_editar)
');

foreach ($permissoes as $p) {
    $perfil  = (int)($p['fk_perfil']    ?? 0);
    $modulo  = (int)($p['fk_modulo']    ?? 0);
    $acessar = (int)(bool)($p['pode_acessar'] ?? false);
    $editar  = (int)(bool)($p['pode_editar']  ?? false);

    if ($perfil <= 0 || $modulo <= 0) continue;
    $stmt->execute([':perfil' => $perfil, ':modulo' => $modulo, ':acessar' => $acessar, ':editar' => $editar]);
}

jsonResposta(['mensagem' => 'Permissões salvas com sucesso.']);
