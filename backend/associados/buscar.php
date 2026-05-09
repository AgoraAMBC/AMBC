<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) jsonErro('ID inválido ou não informado', 400);

$pdo = obterConexao();

$stmt = $pdo->prepare("
    SELECT
        a.id_associado,
        a.nome,
        a.email,
        a.cpf_cnpj,
        a.data_nascimento,
        a.observacao,
        a.ativo,
        a.criado_em,
        a.atualizado_em,
        -- Endereço (colunas direto na tabela associado)
        a.logradouro,
        a.numero,
        a.complemento,
        a.cep,
        a.bairro,
        a.cidade,
        a.uf,
        -- Relacionamentos
        a.fk_estadocivil,
        ec.descricao   AS estado_civil,
        a.fk_profissao,
        p.descricao    AS profissao,
        a.fk_categoria,
        cat.descricao  AS categoria,
        a.fk_status,
        sp.descricao   AS status,
        a.fk_genero,
        g.descricao    AS genero
    FROM associado a
    LEFT JOIN estado_civil  ec  ON ec.id_estadocivil = a.fk_estadocivil
    LEFT JOIN profissao     p   ON p.id_profissao    = a.fk_profissao
    LEFT JOIN categoria     cat ON cat.id_categoria  = a.fk_categoria
    LEFT JOIN status_pessoa sp  ON sp.id_status      = a.fk_status
    LEFT JOIN genero        g   ON g.id_genero       = a.fk_genero
    WHERE a.id_associado = :id
");

$stmt->execute([':id' => $id]);
$associado = $stmt->fetch();

if (!$associado) jsonErro('Associado não encontrado', 404);

jsonResposta($associado);
