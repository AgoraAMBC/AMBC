<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

$pdo = obterConexao();

// Busca dados do parceiro
$stmt = $pdo->prepare("
    SELECT
        p.*,
        u.nome AS criado_por_nome
    FROM parceiro p
    LEFT JOIN usuario u ON u.id_usuario = p.criado_por
    WHERE p.id_parceiro = :id
");
$stmt->execute([':id' => $id]);
$parceiro = $stmt->fetch();

if (!$parceiro) jsonErro('Parceiro não encontrado', 404);

// Busca telefones
$stmtTel = $pdo->prepare("
    SELECT
        t.id_telefone_parceiro,
        t.ddd,
        t.numero,
        t.fk_tipo_telefone,
        tt.descricao AS tipo_telefone,
        t.observacao
    FROM telefone_parceiro t
    LEFT JOIN tipo_telefone tt ON tt.id_tipo_telefone = t.fk_tipo_telefone
    WHERE t.fk_parceiro = :id
    ORDER BY t.id_telefone_parceiro
");
$stmtTel->execute([':id' => $id]);
$parceiro['telefones'] = $stmtTel->fetchAll();

jsonResposta($parceiro);
