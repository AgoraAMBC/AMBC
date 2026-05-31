<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Metodo nao permitido', 405);
}

$pdo = obterConexao();

$resumo = buscarResumoConsolidado($pdo);
$cardsResumo = $resumo['cards'];

jsonResposta([
    'cards' => [
        'associados' => [
            'total' => $cardsResumo['total_associados'],
            'variacao' => calcularVariacao($cardsResumo['associados_mes'], $cardsResumo['associados_mes_anterior']),
        ],
        'dependentes' => [
            'total' => $cardsResumo['total_dependentes'],
            'variacao' => calcularVariacao($cardsResumo['dependentes_mes'], $cardsResumo['dependentes_mes_anterior']),
        ],
        'parceiros' => [
            'total' => $cardsResumo['total_parceiros'],
            'variacao' => calcularVariacao($cardsResumo['parceiros_mes'], $cardsResumo['parceiros_mes_anterior']),
        ],
        'resultado_mes' => [
            'total' => $cardsResumo['resultado_mes'],
            'variacao' => calcularVariacao($cardsResumo['resultado_mes'], $cardsResumo['resultado_mes_anterior']),
        ],
    ],
    'grafico' => preencherMesesVazios($resumo['grafico']),
    'distribuicao' => [
        'associados' => $cardsResumo['total_associados'],
        'dependentes' => $cardsResumo['total_dependentes'],
        'parceiros' => $cardsResumo['total_parceiros'],
    ],
    'ultimas_transacoes' => $resumo['ultimas_transacoes'],
]);

function buscarResumoConsolidado(PDO $pdo): array {
    $stmt = $pdo->query("
        WITH
        assoc AS (
            SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m') THEN 1 ELSE 0 END) AS este_mes,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m') THEN 1 ELSE 0 END) AS mes_anterior
            FROM associado
            WHERE ativo = 1
        ),
        dep AS (
            SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m') THEN 1 ELSE 0 END) AS este_mes,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m') THEN 1 ELSE 0 END) AS mes_anterior
            FROM dependente
        ),
        par AS (
            SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m') THEN 1 ELSE 0 END) AS este_mes,
                SUM(CASE WHEN DATE_FORMAT(criado_em, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m') THEN 1 ELSE 0 END) AS mes_anterior
            FROM parceiro
            WHERE ativo = 1
        ),
        fin AS (
            SELECT
                SUM(CASE
                    WHEN DATE_FORMAT(c.data_lancamento, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
                    THEN CASE WHEN cr.tipo = 'receita' THEN c.valor WHEN cr.tipo = 'despesa' THEN -c.valor ELSE c.valor END
                    ELSE 0
                END) AS resultado_mes,
                SUM(CASE
                    WHEN DATE_FORMAT(c.data_lancamento, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m')
                    THEN CASE WHEN cr.tipo = 'receita' THEN c.valor WHEN cr.tipo = 'despesa' THEN -c.valor ELSE c.valor END
                    ELSE 0
                END) AS resultado_mes_anterior
            FROM lancamento c
            LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
            LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
            WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
              AND c.data_lancamento >= DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m-01')
              AND c.data_lancamento < DATE_FORMAT(DATE_ADD(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m-01')
        ),
        grafico AS (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT('mes', g.mes, 'receita', g.receita, 'despesa', g.despesa)
            ) AS dados
            FROM (
                SELECT
                    DATE_FORMAT(c.data_lancamento, '%Y-%m') AS mes,
                    COALESCE(SUM(CASE WHEN cr.tipo = 'receita' THEN c.valor ELSE 0 END), 0) AS receita,
                    COALESCE(SUM(CASE WHEN cr.tipo = 'despesa' THEN c.valor ELSE 0 END), 0) AS despesa
                FROM lancamento c
                LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
                LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
                WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
                  AND c.data_lancamento >= DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 5 MONTH), '%Y-%m-01')
                GROUP BY DATE_FORMAT(c.data_lancamento, '%Y-%m')
                ORDER BY mes
            ) g
        ),
        ultimas AS (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'id_conta', u.id_lancamento,
                    'descricao', u.descricao,
                    'valor_total', u.valor,
                    'data_lancamento', DATE_FORMAT(u.data_lancamento, '%Y-%m-%d'),
                    'status', u.status_desc,
                    'categoria', u.categoria_desc,
                    'tipo', u.tipo,
                    'associado', u.associado_nome
                )
            ) AS dados
            FROM (
                SELECT
                    c.id_lancamento,
                    c.descricao,
                    c.valor,
                    c.data_lancamento,
                    sc.descricao AS status_desc,
                    cr.descricao AS categoria_desc,
                    cr.tipo,
                    a.nome AS associado_nome
                FROM lancamento c
                LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
                LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
                LEFT JOIN associado a ON a.id_associado = c.fk_associado
                ORDER BY c.data_lancamento DESC, c.criado_em DESC
                LIMIT 10
            ) u
        )
        SELECT
            COALESCE(assoc.total, 0) AS total_associados,
            COALESCE(assoc.este_mes, 0) AS associados_mes,
            COALESCE(assoc.mes_anterior, 0) AS associados_mes_anterior,
            COALESCE(dep.total, 0) AS total_dependentes,
            COALESCE(dep.este_mes, 0) AS dependentes_mes,
            COALESCE(dep.mes_anterior, 0) AS dependentes_mes_anterior,
            COALESCE(par.total, 0) AS total_parceiros,
            COALESCE(par.este_mes, 0) AS parceiros_mes,
            COALESCE(par.mes_anterior, 0) AS parceiros_mes_anterior,
            COALESCE(fin.resultado_mes, 0) AS resultado_mes,
            COALESCE(fin.resultado_mes_anterior, 0) AS resultado_mes_anterior,
            grafico.dados AS grafico,
            ultimas.dados AS ultimas_transacoes
        FROM assoc
        CROSS JOIN dep
        CROSS JOIN par
        CROSS JOIN fin
        CROSS JOIN grafico
        CROSS JOIN ultimas
    ");

    $linha = $stmt->fetch() ?: [];
    $grafico = json_decode((string)($linha['grafico'] ?? '[]'), true) ?: [];
    $transacoes = json_decode((string)($linha['ultimas_transacoes'] ?? '[]'), true) ?: [];

    foreach ($transacoes as &$transacao) {
        $transacao['id_conta'] = (int)($transacao['id_conta'] ?? 0);
        $transacao['valor_total'] = (float)($transacao['valor_total'] ?? 0);
    }
    unset($transacao);

    return [
        'cards' => [
            'total_associados' => (int)($linha['total_associados'] ?? 0),
            'associados_mes' => (float)($linha['associados_mes'] ?? 0),
            'associados_mes_anterior' => (float)($linha['associados_mes_anterior'] ?? 0),
            'total_dependentes' => (int)($linha['total_dependentes'] ?? 0),
            'dependentes_mes' => (float)($linha['dependentes_mes'] ?? 0),
            'dependentes_mes_anterior' => (float)($linha['dependentes_mes_anterior'] ?? 0),
            'total_parceiros' => (int)($linha['total_parceiros'] ?? 0),
            'parceiros_mes' => (float)($linha['parceiros_mes'] ?? 0),
            'parceiros_mes_anterior' => (float)($linha['parceiros_mes_anterior'] ?? 0),
            'resultado_mes' => (float)($linha['resultado_mes'] ?? 0),
            'resultado_mes_anterior' => (float)($linha['resultado_mes_anterior'] ?? 0),
        ],
        'grafico' => $grafico,
        'ultimas_transacoes' => $transacoes,
    ];
}

function preencherMesesVazios(array $dados): array {
    $mapa = [];
    foreach ($dados as $linha) {
        $mapa[$linha['mes']] = $linha;
    }

    $meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    $resultado = [];

    for ($i = 5; $i >= 0; $i--) {
        $data = new DateTime("first day of -{$i} month");
        $chave = $data->format('Y-m');
        $resultado[] = [
            'mes' => $chave,
            'mes_abrev' => $meses[(int)$data->format('n') - 1],
            'receita' => isset($mapa[$chave]) ? (float)$mapa[$chave]['receita'] : 0.0,
            'despesa' => isset($mapa[$chave]) ? (float)$mapa[$chave]['despesa'] : 0.0,
        ];
    }

    return $resultado;
}

function calcularVariacao(float $atual, float $anterior): float {
    if ($anterior == 0.0) {
        return 0.0;
    }

    return round((($atual - $anterior) / abs($anterior)) * 100, 1);
}
