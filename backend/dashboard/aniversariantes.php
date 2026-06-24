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
    SELECT
        'associado' AS tipo,
        a.id_associado AS id,
        a.nome,
        a.data_nascimento,
        DAY(a.data_nascimento) AS dia,
        MONTH(a.data_nascimento) AS mes,
        NULL AS associado_nome
    FROM associado a
    WHERE a.ativo = TRUE
      AND MONTH(a.data_nascimento) = MONTH(CURRENT_DATE)

    UNION ALL

    SELECT
        'dependente' AS tipo,
        d.id_dependente AS id,
        d.nome,
        d.data_nascimento,
        DAY(d.data_nascimento) AS dia,
        MONTH(d.data_nascimento) AS mes,
        a.nome AS associado_nome
    FROM dependente d
    JOIN associado a ON a.id_associado = d.fk_associado
    WHERE a.ativo = TRUE
      AND MONTH(d.data_nascimento) = MONTH(CURRENT_DATE)

    ORDER BY dia, tipo, nome
";

$stmt = $pdo->query($sql);
$aniversariantes = $stmt->fetchAll();

$resultado = array_map(function ($item) {
    return [
        'tipo'       => $item['tipo'],
        'id'         => (int) $item['id'],
        'nome'       => $item['nome'],
        'data_nascimento' => $item['data_nascimento'],
        'dia'        => (int) $item['dia'],
        'mes'        => (int) $item['mes'],
        'associado_nome' => $item['associado_nome'],
    ];
}, $aniversariantes);

jsonResposta($resultado);
