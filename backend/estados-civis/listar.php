<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$stmt = $pdo->query("SELECT id_estadocivil AS id, descricao FROM estado_civil ORDER BY descricao");

jsonResposta($stmt->fetchAll());
