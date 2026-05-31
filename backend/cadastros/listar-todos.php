<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pagina  = max(1, (int)($_GET['pagina']  ?? 1));
$busca   = trim($_GET['busca']   ?? '');
$status  = trim($_GET['status']  ?? '');
$tipo    = trim($_GET['tipo']    ?? 'todos');
$limite  = 20;
$offset  = ($pagina - 1) * $limite;

$pdo = obterConexao();

$cadastros = [];
$totalGeral = 0;

// ============================================
// BUSCAR ASSOCIADOS
// ============================================
$whereAssociados = ['1=1'];
$paramsAssociados = [];

if ($busca !== '') {
    $like = "%{$busca}%";
    $whereAssociados[] = "(a.nome LIKE :ba1 OR a.email LIKE :ba2 OR a.cpf_cnpj LIKE :ba3)";
    $paramsAssociados[':ba1'] = $like;
    $paramsAssociados[':ba2'] = $like;
    $paramsAssociados[':ba3'] = $like;
}
if ($status === 'ativo') $whereAssociados[] = 'a.ativo = TRUE';
if ($status === 'inativo') $whereAssociados[] = 'a.ativo = FALSE';
if ($tipo !== 'todos' && $tipo !== 'associado') $whereAssociados[] = '1=0';

$sqlAssociados = "SELECT COUNT(*) FROM associado a WHERE " . implode(' AND ', $whereAssociados);
$stmtTotalAssoc = $pdo->prepare($sqlAssociados);
$stmtTotalAssoc->execute($paramsAssociados);
$totalAssociados = (int)$stmtTotalAssoc->fetchColumn();

if ($tipo === 'todos' || $tipo === 'associado') {
    $sqlAssoc = "
        SELECT
            a.id_associado AS id,
            'associado' AS tipo,
            a.nome,
            a.email,
            a.cpf_cnpj,
            a.ativo,
            a.criado_em,
            a.logradouro AS endereco,
            COALESCE(a.cidade, '') AS cidade,
            COALESCE(a.uf, '') AS uf
        FROM associado a
        WHERE " . implode(' AND ', $whereAssociados) . "
        ORDER BY a.nome
        LIMIT :limite OFFSET :offset
    ";
    $stmtAssoc = $pdo->prepare($sqlAssoc);
    foreach ($paramsAssociados as $k => $v) $stmtAssoc->bindValue($k, $v);
    $stmtAssoc->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmtAssoc->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmtAssoc->execute();
    foreach ($stmtAssoc->fetchAll() as $a) {
        $a['ativo'] = (bool)$a['ativo'];
        $cadastros[] = $a;
    }
}

// ============================================
// BUSCAR DEPENDENTES
// ============================================
$whereDependentes = ['1=1'];
$paramsDependentes = [];

if ($busca !== '') {
    $like = "%{$busca}%";
    $whereDependentes[] = "(d.nome LIKE :bd1 OR d.cpf LIKE :bd2 OR a.nome LIKE :bd3)";
    $paramsDependentes[':bd1'] = $like;
    $paramsDependentes[':bd2'] = $like;
    $paramsDependentes[':bd3'] = $like;
}
if ($status === 'ativo') $whereDependentes[] = 'a.ativo = TRUE';
if ($status === 'inativo') $whereDependentes[] = 'a.ativo = FALSE';
if ($tipo !== 'todos' && $tipo !== 'dependente') $whereDependentes[] = '1=0';

$sqlDependentes = "
    SELECT COUNT(*) FROM dependente d
    LEFT JOIN associado a ON a.id_associado = d.fk_associado
    WHERE " . implode(' AND ', $whereDependentes);
$stmtTotalDep = $pdo->prepare($sqlDependentes);
$stmtTotalDep->execute($paramsDependentes);
$totalDependentes = (int)$stmtTotalDep->fetchColumn();

if ($tipo === 'todos' || $tipo === 'dependente') {
    $sqlDep = "
        SELECT
            d.id_dependente AS id,
            'dependente' AS tipo,
            d.nome,
            '' AS email,
            d.cpf AS cpf_cnpj,
            COALESCE(a.ativo, FALSE) AS ativo,
            d.criado_em,
            COALESCE(a.logradouro, '') AS endereco,
            COALESCE(a.cidade, '') AS cidade,
            COALESCE(a.uf, '') AS uf,
            a.id_associado AS id_associado_titular,
            a.nome AS nome_associado_titular,
            COALESCE(p.descricao, '') AS parentesco
        FROM dependente d
        LEFT JOIN associado a ON a.id_associado = d.fk_associado
        LEFT JOIN parentesco p ON p.id_parentesco = d.fk_parentesco
        WHERE " . implode(' AND ', $whereDependentes) . "
        ORDER BY d.nome
        LIMIT :limite OFFSET :offset
    ";
    $stmtDep = $pdo->prepare($sqlDep);
    foreach ($paramsDependentes as $k => $v) $stmtDep->bindValue($k, $v);
    $stmtDep->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmtDep->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmtDep->execute();
    foreach ($stmtDep->fetchAll() as $d) {
        $d['ativo'] = (bool)$d['ativo'];
        $cadastros[] = $d;
    }
}

// ============================================
// BUSCAR PARCEIROS
// ============================================
$whereParceiros = ['1=1'];
$paramsParceiros = [];

if ($busca !== '') {
    $like = "%{$busca}%";
    $whereParceiros[] = "(p.nome_razao_social LIKE :bp1 OR p.cpf_cnpj LIKE :bp2 OR p.email LIKE :bp3)";
    $paramsParceiros[':bp1'] = $like;
    $paramsParceiros[':bp2'] = $like;
    $paramsParceiros[':bp3'] = $like;
}
if ($status === 'ativo') $whereParceiros[] = 'p.ativo = TRUE';
if ($status === 'inativo') $whereParceiros[] = 'p.ativo = FALSE';
if ($tipo !== 'todos' && $tipo !== 'parceiro') $whereParceiros[] = '1=0';

$sqlParceiros = "SELECT COUNT(*) FROM parceiro p WHERE " . implode(' AND ', $whereParceiros);
$stmtTotalParc = $pdo->prepare($sqlParceiros);
$stmtTotalParc->execute($paramsParceiros);
$totalParceiros = (int)$stmtTotalParc->fetchColumn();

if ($tipo === 'todos' || $tipo === 'parceiro') {
    $sqlParc = "
        SELECT
            p.id_parceiro AS id,
            'parceiro' AS tipo,
            p.nome_razao_social AS nome,
            p.email,
            p.cpf_cnpj,
            p.ativo,
            p.criado_em,
            '' AS endereco,
            p.cidade,
            p.uf
        FROM parceiro p
        WHERE " . implode(' AND ', $whereParceiros) . "
        ORDER BY p.nome_razao_social
        LIMIT :limite OFFSET :offset
    ";
    $stmtParc = $pdo->prepare($sqlParc);
    foreach ($paramsParceiros as $k => $v) $stmtParc->bindValue($k, $v);
    $stmtParc->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmtParc->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmtParc->execute();
    foreach ($stmtParc->fetchAll() as $p) {
        $p['ativo'] = (bool)$p['ativo'];
        $cadastros[] = $p;
    }
}

// Ordena todos os resultados por nome
usort($cadastros, function($a, $b) {
    return strcasecmp($a['nome'] ?? '', $b['nome'] ?? '');
});

$totalGeral = $totalAssociados + $totalDependentes + $totalParceiros;
$paginas = (int)ceil($totalGeral / $limite);

jsonResposta([
    'dados'   => $cadastros,
    'total'   => $totalGeral,
    'pagina'  => $pagina,
    'paginas' => $paginas,
    'totais'  => [
        'associado'  => $totalAssociados,
        'dependente' => $totalDependentes,
        'parceiro'   => $totalParceiros,
    ],
]);