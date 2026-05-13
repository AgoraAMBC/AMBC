<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Metodo nao permitido', 405);
}

$pdo = obterConexao();

$temTipoContaRegente = colunaExiste($pdo, 'conta_regente', 'tipo');

$totalAssociados = (int)$pdo
    ->query('SELECT COUNT(*) FROM associado WHERE ativo = TRUE')
    ->fetchColumn();

$totalDependentes = (int)$pdo
    ->query('SELECT COUNT(*) FROM dependente')
    ->fetchColumn();

$totalParceiros = (int)$pdo
    ->query('SELECT COUNT(*) FROM parceiro WHERE ativo = TRUE')
    ->fetchColumn();

$resultadoMes = buscarResultadoMes($pdo, $temTipoContaRegente, 'CURRENT_DATE');
$resultadoAnterior = buscarResultadoMes($pdo, $temTipoContaRegente, "CURRENT_DATE - INTERVAL '1 month'");

jsonResposta([
    'cards' => [
        'associados' => [
            'total' => $totalAssociados,
            'variacao' => buscarVariacaoCadastro($pdo, 'associado', 'ativo = TRUE'),
        ],
        'dependentes' => [
            'total' => $totalDependentes,
            'variacao' => buscarVariacaoCadastro($pdo, 'dependente'),
        ],
        'parceiros' => [
            'total' => $totalParceiros,
            'variacao' => buscarVariacaoCadastro($pdo, 'parceiro', 'ativo = TRUE'),
        ],
        'resultado_mes' => [
            'total' => $resultadoMes,
            'variacao' => calcularVariacao($resultadoMes, $resultadoAnterior),
        ],
    ],
    'grafico' => buscarGraficoFinanceiro($pdo, $temTipoContaRegente),
    'distribuicao' => [
        'associados' => $totalAssociados,
        'dependentes' => $totalDependentes,
        'parceiros' => $totalParceiros,
    ],
    'ultimas_transacoes' => buscarUltimasTransacoes($pdo, $temTipoContaRegente),
]);

function colunaExiste(PDO $pdo, string $tabela, string $coluna): bool {
    $stmt = $pdo->prepare("
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = :tabela
              AND column_name = :coluna
        )
    ");
    $stmt->execute([
        ':tabela' => $tabela,
        ':coluna' => $coluna,
    ]);
    return (bool)$stmt->fetchColumn();
}

function buscarVariacaoCadastro(PDO $pdo, string $tabela, string $filtro = '1=1'): float {
    $stmt = $pdo->query("
        SELECT
            COUNT(*) FILTER (
                WHERE DATE_TRUNC('month', criado_em) = DATE_TRUNC('month', CURRENT_DATE)
            ) AS este_mes,
            COUNT(*) FILTER (
                WHERE DATE_TRUNC('month', criado_em) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
            ) AS mes_anterior
        FROM {$tabela}
        WHERE {$filtro}
    ");

    $linha = $stmt->fetch();
    return calcularVariacao((float)$linha['este_mes'], (float)$linha['mes_anterior']);
}

function buscarResultadoMes(PDO $pdo, bool $temTipoContaRegente, string $dataReferenciaSql): float {
    if ($temTipoContaRegente) {
        $stmt = $pdo->query("
            SELECT COALESCE(
                SUM(CASE
                    WHEN cr.tipo = 'receita' THEN c.valor
                    WHEN cr.tipo = 'despesa' THEN -c.valor
                    ELSE c.valor
                END),
                0
            ) AS resultado
            FROM lancamento c
            LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
            LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
            WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
              AND DATE_TRUNC('month', c.data_lancamento) = DATE_TRUNC('month', {$dataReferenciaSql})
        ");
        return (float)$stmt->fetchColumn();
    }

    $stmt = $pdo->query("
        SELECT COALESCE(SUM(c.valor), 0) AS resultado
        FROM lancamento c
        LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
        WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
          AND DATE_TRUNC('month', c.data_lancamento) = DATE_TRUNC('month', {$dataReferenciaSql})
    ");
    return (float)$stmt->fetchColumn();
}

function buscarGraficoFinanceiro(PDO $pdo, bool $temTipoContaRegente): array {
    if ($temTipoContaRegente) {
        $stmt = $pdo->query("
            SELECT
                TO_CHAR(DATE_TRUNC('month', c.data_lancamento), 'YYYY-MM') AS mes,
                COALESCE(SUM(CASE WHEN cr.tipo = 'receita' THEN c.valor ELSE 0 END), 0) AS receita,
                COALESCE(SUM(CASE WHEN cr.tipo = 'despesa' THEN c.valor ELSE 0 END), 0) AS despesa
            FROM lancamento c
            LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
            LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
            WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
              AND c.data_lancamento >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '5 months')
            GROUP BY DATE_TRUNC('month', c.data_lancamento)
            ORDER BY DATE_TRUNC('month', c.data_lancamento)
        ");
    } else {
        $stmt = $pdo->query("
            SELECT
                TO_CHAR(DATE_TRUNC('month', c.data_lancamento), 'YYYY-MM') AS mes,
                COALESCE(SUM(c.valor), 0) AS receita,
                0 AS despesa
            FROM lancamento c
            LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
            WHERE (LOWER(sc.descricao) = 'liquidado' OR c.fk_status_conta = 2)
              AND c.data_lancamento >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '5 months')
            GROUP BY DATE_TRUNC('month', c.data_lancamento)
            ORDER BY DATE_TRUNC('month', c.data_lancamento)
        ");
    }

    return preencherMesesVazios($stmt->fetchAll());
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

function buscarUltimasTransacoes(PDO $pdo, bool $temTipoContaRegente): array {
    $campoTipo = $temTipoContaRegente ? 'cr.tipo' : "'receita'";

    $stmt = $pdo->query("
        SELECT
            c.id_lancamento AS id_conta,
            c.descricao,
            c.valor AS valor_total,
            TO_CHAR(c.data_lancamento, 'YYYY-MM-DD') AS data_lancamento,
            sc.descricao AS status,
            cr.descricao AS categoria,
            {$campoTipo} AS tipo,
            a.nome AS associado
        FROM lancamento c
        LEFT JOIN status_conta sc ON sc.id_status_conta = c.fk_status_conta
        LEFT JOIN conta_regente cr ON cr.id_conta_regente = c.fk_conta_regente
        LEFT JOIN associado a ON a.id_associado = c.fk_associado
        ORDER BY c.data_lancamento DESC, c.criado_em DESC
        LIMIT 10
    ");

    $transacoes = $stmt->fetchAll();
    foreach ($transacoes as &$transacao) {
        $transacao['id_conta'] = (int)$transacao['id_conta'];
        $transacao['valor_total'] = (float)$transacao['valor_total'];
    }
    unset($transacao);

    return $transacoes;
}

function calcularVariacao(float $atual, float $anterior): float {
    if ($anterior == 0.0) {
        return 0.0;
    }

    return round((($atual - $anterior) / abs($anterior)) * 100, 1);
}
