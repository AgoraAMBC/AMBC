<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$pagina    = max(1, (int)($_GET['pagina'] ?? 1));
$porPagina = 10;
$offset    = ($pagina - 1) * $porPagina;
$busca     = trim($_GET['busca'] ?? '');
$perfil    = (int)($_GET['perfil'] ?? 0);
$status    = $_GET['status'] ?? '';

$where  = ['1=1'];
$params = [];

if ($busca !== '') {
    $where[]          = '(u.nome ILIKE :busca OR u.email ILIKE :busca)';
    $params[':busca'] = '%' . $busca . '%';
}
if ($perfil > 0) {
    $where[]           = 'u.fk_perfil = :perfil';
    $params[':perfil'] = $perfil;
}
if ($status === 'ativo')   $where[] = 'u.ativo = TRUE';
if ($status === 'inativo') $where[] = 'u.ativo = FALSE';

$condicao = implode(' AND ', $where);

$stmtTotal = $pdo->prepare("SELECT COUNT(*) FROM usuario u WHERE $condicao");
$stmtTotal->execute($params);
$total = (int)$stmtTotal->fetchColumn();

$stmt = $pdo->prepare("
    SELECT
        u.id_usuario,
        u.nome,
        u.email,
        u.ativo,
        u.primeiro_acesso,
        u.ultimo_acesso,
        p.descricao AS perfil
    FROM usuario u
    JOIN perfil_usuario p ON p.id_perfil = u.fk_perfil
    WHERE $condicao
    ORDER BY u.nome ASC
    LIMIT :limite OFFSET :offset
");
foreach ($params as $chave => $valor) {
    $stmt->bindValue($chave, $valor);
}
$stmt->bindValue(':limite', $porPagina, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();

$usuarios = $stmt->fetchAll();
foreach ($usuarios as &$u) {
    $u['ativo']           = (bool)$u['ativo'];
    $u['primeiro_acesso'] = (bool)$u['primeiro_acesso'];
    // Adiciona sufixo UTC para o JS interpretar corretamente o fuso
    if ($u['ultimo_acesso']) {
        $u['ultimo_acesso'] = str_replace(' ', 'T', $u['ultimo_acesso']) . '+00:00';
    }
}

jsonResposta([
    'dados'      => $usuarios,
    'total'      => $total,
    'pagina'     => $pagina,
    'por_pagina' => $porPagina,
    'paginas'    => (int)ceil($total / $porPagina),
]);
