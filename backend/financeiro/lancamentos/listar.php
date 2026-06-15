<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Metodo nao permitido', 405);

try {
    $pdo = obterConexao();

    $tipo = trim($_GET['tipo'] ?? '');
    $status = trim($_GET['status'] ?? '');
    $inicio = trim($_GET['inicio'] ?? '');
    $fim = trim($_GET['fim'] ?? '');
    $idAssociado = isset($_GET['id_associado']) ? (int)$_GET['id_associado'] : 0;
    $limite = max(1, min(200, (int)($_GET['limite'] ?? 100)));

    $where = ['1=1'];
    $params = [];

    if ($idAssociado > 0) {
        $where[] = 'l.fk_associado = :id_associado';
        $params[':id_associado'] = $idAssociado;
    }

    if (in_array($tipo, ['receita', 'despesa'], true)) {
        $where[] = 'LOWER(cr.tipo) = :tipo';
        $params[':tipo'] = $tipo;
    }

    if ($status !== '' && $status !== 'todos') {
        if ($status === 'pago') {
            $where[] = "LOWER(sc.descricao) IN ('liquidado', 'pago')";
        } elseif ($status === 'pendente') {
            $where[] = "LOWER(sc.descricao) = 'aberto'";
            $where[] = "(l.data_vencimento IS NULL OR l.data_vencimento >= CURRENT_DATE)";
        } elseif ($status === 'atrasado') {
            $where[] = "LOWER(sc.descricao) = 'aberto'";
            $where[] = 'l.data_vencimento < CURRENT_DATE';
        } elseif ($status === 'cancelado') {
            $where[] = "LOWER(sc.descricao) = 'cancelado'";
        }
    }

    if ($inicio !== '') {
        $where[] = 'COALESCE(l.data_vencimento, l.data_lancamento) >= :inicio';
        $params[':inicio'] = $inicio;
    }

    if ($fim !== '') {
        $where[] = 'COALESCE(l.data_vencimento, l.data_lancamento) <= :fim';
        $params[':fim'] = $fim;
    }

    $condicao = implode(' AND ', $where);

    $stmt = $pdo->prepare("
        SELECT
            l.id_lancamento,
            l.descricao,
            l.valor,
            l.valor_pago,
            l.data_lancamento,
            l.data_vencimento,
            l.data_pagamento,
            l.fk_parcelamento,
            l.numero_parcela,
            l.total_parcelas,
            COALESCE(cr.descricao, '') AS conta_regente,
            COALESCE(cs.descricao, '') AS conta_subordinada,
            COALESCE(tl.descricao, '') AS tipo_lancamento,
            COALESCE(sc.descricao, 'Aberto') AS status_conta,
            COALESCE(fp.descricao, '') AS forma_pagamento,
            COALESCE(cr.tipo, 'receita') AS tipo,
            l.fk_status_conta,
            l.fk_tipo_lancamento,
            l.fk_forma_pagamento,
            l.fk_conta_regente,
            l.fk_conta_subordinada,
            l.fk_associado,
            l.fk_parceiro,
            l.observacao,
            l.criado_em,
            COALESCE(a.nome, p.nome_razao_social, '') AS pessoa_nome,
            CASE WHEN a.id_associado IS NOT NULL THEN 'associado'
                 WHEN p.id_parceiro IS NOT NULL THEN 'parceiro'
                 ELSE '' END AS pessoa_tipo
        FROM lancamento l
        LEFT JOIN conta_regente cr ON cr.id_conta_regente = l.fk_conta_regente
        LEFT JOIN conta_subordinada cs ON cs.id_conta_subordinada = l.fk_conta_subordinada
        LEFT JOIN tipo_lancamento tl ON tl.id_tipo_lancamento = l.fk_tipo_lancamento
        LEFT JOIN status_conta sc ON sc.id_status_conta = l.fk_status_conta
        LEFT JOIN forma_pagamento fp ON fp.id_forma_pagamento = l.fk_forma_pagamento
        LEFT JOIN associado a ON a.id_associado = l.fk_associado
        LEFT JOIN parceiro p ON p.id_parceiro = l.fk_parceiro
        WHERE $condicao
        ORDER BY COALESCE(l.data_vencimento, l.data_lancamento) DESC, l.id_lancamento DESC
        LIMIT " . (int)$limite . "
    ");
    $stmt->execute($params);
    $lancamentos = $stmt->fetchAll();

    foreach ($lancamentos as &$lancamento) {
        $statusNormalizado = strtolower((string)$lancamento['status_conta']);
        $vencimento = $lancamento['data_vencimento'] ?? null;

        $lancamento['id'] = (int)$lancamento['id_lancamento'];
        $lancamento['valor'] = (float)$lancamento['valor'];
        $lancamento['valor_pago'] = $lancamento['valor_pago'] !== null ? (float)$lancamento['valor_pago'] : null;
        $lancamento['conta'] = $lancamento['conta_regente'];
        $lancamento['subconta'] = $lancamento['conta_subordinada'];
        $lancamento['vencimento'] = $vencimento;
        $lancamento['pessoa'] = $lancamento['pessoa_nome'] ?? '';
        $lancamento['pessoa_tipo'] = $lancamento['pessoa_tipo'] ?? '';
        $lancamento['status'] = match (true) {
            str_contains($statusNormalizado, 'liquidado'), str_contains($statusNormalizado, 'pago') => 'pago',
            str_contains($statusNormalizado, 'cancelado') => 'cancelado',
            $vencimento && $vencimento < date('Y-m-d') => 'atrasado',
            default => 'pendente',
        };
    }

    jsonResposta(['dados' => $lancamentos, 'lancamentos' => $lancamentos]);
} catch (PDOException $e) {
    jsonErro('Erro ao buscar lancamentos: ' . $e->getMessage(), 500);
}
