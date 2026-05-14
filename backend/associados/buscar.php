<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido ou não informado', 400);

$pdo = obterConexao();

$sql = "
    SELECT
        a.id_associado,
        a.matricula,
        a.nome,
        a.email,
        a.cpf_cnpj,
        a.data_nascimento,
        a.observacao,
        a.ativo,
        a.data_entrada,
        a.criado_em,
        a.atualizado_em,
        -- Endereço
        a.logradouro,
        a.numero,
        a.complemento,
        a.cep,
        a.bairro,
        a.cidade,
        a.uf,
        -- FKs
        a.fk_estadocivil,
        a.fk_profissao,
        a.fk_categoria,
        a.fk_status,
        a.fk_genero,
        -- Descrições (para referência, mas usamos os IDs nos selects)
        ec.descricao AS estado_civil_desc,
        p.descricao  AS profissao_desc,
        cat.descricao AS categoria_desc,
        sp.descricao AS status_desc,
        g.descricao  AS genero_desc
    FROM associado a
    LEFT JOIN estado_civil ec  ON ec.id_estadocivil  = a.fk_estadocivil
    LEFT JOIN profissao     p   ON p.id_profissao     = a.fk_profissao
    LEFT JOIN categoria     cat ON cat.id_categoria   = a.fk_categoria
    LEFT JOIN status_pessoa sp  ON sp.id_status       = a.fk_status
    LEFT JOIN genero        g   ON g.id_genero        = a.fk_genero
    WHERE a.id_associado = :id
";

$stmt = $pdo->prepare($sql);
$stmt->execute([':id' => $id]);
$associado = $stmt->fetch();

if (!$associado) jsonErro('Associado não encontrado', 404);

// Telefones
$stmtTel = $pdo->prepare("
    SELECT
        t.id_telefone,
        t.ddd,
        t.numero,
        t.observacao,
        COALESCE(tt.descricao, '') AS tipo
    FROM telefone t
    LEFT JOIN tipo_telefone tt ON tt.id_tipo_telefone = t.fk_tipo_telefone
    WHERE t.fk_associado = :id_associado
    ORDER BY t.id_telefone
");
$stmtTel->execute([':id_associado' => $id]);
$telefones = $stmtTel->fetchAll();

// Dependentes
$stmtDep = $pdo->prepare("
    SELECT
        d.id_dependente,
        d.nome,
        d.data_nascimento,
        d.cpf,
        d.observacao,
        d.fk_parentesco,
        d.fk_genero,
        COALESCE(par.descricao, '') AS parentesco,
        COALESCE(g.descricao, '') AS genero
    FROM dependente d
    LEFT JOIN parentesco par ON par.id_parentesco = d.fk_parentesco
    LEFT JOIN genero g ON g.id_genero = d.fk_genero
    WHERE d.fk_associado = :id_associado
    ORDER BY d.nome
");
$stmtDep->execute([':id_associado' => $id]);
$dependentes = $stmtDep->fetchAll();

jsonResposta([
    'data' => $associado,
    'telefones' => $telefones,
    'dependentes' => $dependentes
]);