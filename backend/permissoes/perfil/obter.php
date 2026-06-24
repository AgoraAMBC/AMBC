<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$perms = $pdo->query('SELECT fk_perfil, fk_modulo, pode_acessar, pode_editar FROM permissao_perfil')->fetchAll();
jsonResposta($perms);
