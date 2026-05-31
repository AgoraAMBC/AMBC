<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$pagina    = max(1, (int)($_GET['pagina'] ?? 1));
$porPagina = 25;
$offset    = ($pagina - 1) * $porPagina;
$busca     = trim($_GET['busca'] ?? '');
$status    = $_GET['status'] ?? '';

$where  = ['1=1'];
$params = [];

if ($busca !== '') {
    $like = '%' . $busca . '%';
    $where[]           = '(a.nome LIKE :busca1 OR a.email LIKE :busca2 OR a.cpf_cnpj LIKE :busca3)';
    $params[':busca1'] = $like;
    $params[':busca2'] = $like;
    $params[':busca3'] = $like;
}
if ($status === 'ativo')   $where[] = 'a.ativo = 1';
if ($status === 'inativo') $where[] = 'a.ativo = 0';

$condicao = implode(' AND ', $where);

$stmtTotal = $pdo->prepare("SELECT COUNT(*) FROM associado a WHERE $condicao");
$stmtTotal->execute($params);
$total = (int)$stmtTotal->fetchColumn();

$stmt = $pdo->prepare("
    SELECT
        a.id_associado,
        a.nome,
        a.email,
        a.cpf_cnpj,
        a.ativo,
        a.criado_em
    FROM associado a
    WHERE $condicao
    ORDER BY a.nome ASC
    LIMIT :limite OFFSET :offset
");
foreach ($params as $chave => $valor) {
    $stmt->bindValue($chave, $valor);
}
$stmt->bindValue(':limite', $porPagina, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset,    PDO::PARAM_INT);
$stmt->execute();

$associados = $stmt->fetchAll();
foreach ($associados as &$a) {
    $a['ativo'] = (bool)$a['ativo'];
}

jsonResposta([
    'dados'      => $associados,
    'total'      => $total,
    'pagina'     => $pagina,
    'por_pagina' => $porPagina,
    'paginas'    => (int)ceil($total / $porPagina),
]);
