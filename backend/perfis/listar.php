<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo     = obterConexao();
$perfis  = $pdo->query('SELECT id_perfil, descricao FROM perfil_usuario ORDER BY descricao')->fetchAll();
jsonResposta($perfis);
