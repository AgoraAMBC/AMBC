<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pagina    = max(1, (int)($_GET['pagina'] ?? 1));
$porPagina = 10;
$offset    = ($pagina - 1) * $porPagina;

$pdo = obterConexao();

$stmtTotal = $pdo->query("
    SELECT COUNT(*) FROM dependente d
");
$total = (int)$stmtTotal->fetchColumn();

$stmt = $pdo->query("
    SELECT
        d.id_dependente,
        d.nome,
        d.data_nascimento,
        d.cpf,
        d.observacao,
        d.fk_associado,
        COALESCE(a.nome, '') AS nome_associado,
        COALESCE(a.logradouro, '') AS rua_associado,
        COALESCE(a.ativo, FALSE) AS associado_ativo,
        COALESCE(p.descricao, '') AS parentesco,
        d.fk_parentesco,
        COALESCE(g.descricao, '') AS genero,
        d.fk_genero
    FROM dependente d
    LEFT JOIN associado a ON a.id_associado = d.fk_associado
    LEFT JOIN parentesco p ON p.id_parentesco = d.fk_parentesco
    LEFT JOIN genero g ON g.id_genero = d.fk_genero
    ORDER BY d.nome ASC
    LIMIT $porPagina OFFSET $offset
");

$dependentes = $stmt->fetchAll();

jsonResposta([
    'dados'      => $dependentes,
    'total'      => $total,
    'pagina'     => $pagina,
    'por_pagina' => $porPagina,
    'paginas'    => (int)ceil($total / $porPagina),
]);