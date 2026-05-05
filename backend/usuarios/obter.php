<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido');

$pdo = obterConexao();

$stmt = $pdo->prepare('
    SELECT id_usuario, nome, email, fk_perfil, fk_associado, ativo
    FROM usuario
    WHERE id_usuario = :id
');
$stmt->execute([':id' => $id]);
$usuario = $stmt->fetch();

if (!$usuario) jsonErro('Usuário não encontrado', 404);

$stmt = $pdo->prepare('
    SELECT fk_modulo, pode_acessar, pode_editar
    FROM permissao_usuario
    WHERE fk_usuario = :id
');
$stmt->execute([':id' => $id]);

$usuario['permissoes'] = array_map(fn($p) => [
    'fk_modulo'    => (int)$p['fk_modulo'],
    'pode_acessar' => filter_var($p['pode_acessar'], FILTER_VALIDATE_BOOLEAN),
    'pode_editar'  => filter_var($p['pode_editar'],  FILTER_VALIDATE_BOOLEAN),
], $stmt->fetchAll());

jsonResposta($usuario);
