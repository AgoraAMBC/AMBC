<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Metodo nao permitido', 405);
}

$pdo = obterConexao();

$sql = "
    SELECT * FROM (
        (SELECT 'associado' AS tipo, a.id_associado AS id, a.nome, a.criado_em, NULL AS associado_nome
         FROM associado a
         WHERE a.ativo = 1
         ORDER BY a.criado_em DESC
         LIMIT 3)

        UNION ALL

        (SELECT 'dependente' AS tipo, d.id_dependente AS id, d.nome, d.criado_em, a.nome AS associado_nome
         FROM dependente d
         JOIN associado a ON a.id_associado = d.fk_associado
         WHERE a.ativo = 1
         ORDER BY d.criado_em DESC
         LIMIT 3)

        UNION ALL

        (SELECT 'parceiro' AS tipo, p.id_parceiro AS id, p.nome_razao_social AS nome, p.criado_em, NULL AS associado_nome
         FROM parceiro p
         WHERE p.ativo = 1
         ORDER BY p.criado_em DESC
         LIMIT 3)
    ) AS ultimos
    ORDER BY criado_em DESC
    LIMIT 3
";

$stmt = $pdo->query($sql);
$resultado = $stmt->fetchAll();

$resultado = array_map(function ($item) {
    return [
        'tipo'           => $item['tipo'],
        'id'             => (int) $item['id'],
        'nome'           => $item['nome'],
        'criado_em'      => $item['criado_em'],
        'associado_nome' => $item['associado_nome'],
    ];
}, $resultado);

jsonResposta($resultado);
