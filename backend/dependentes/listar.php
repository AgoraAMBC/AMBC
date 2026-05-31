<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('M�todo n�o permitido', 405);

$pdo = obterConexao();

$pagina       = max(1, (int)($_GET['pagina']           ?? 1));
$busca        = trim($_GET['busca']                     ?? '');
$status       = trim($_GET['status']                    ?? '');
$idAssociado  = isset($_GET['id_associado']) ? (int)$_GET['id_associado'] : null;
$idParentesco = (int)($_GET['id_parentesco']            ?? 0);
$idGenero     = (int)($_GET['id_genero']                ?? 0);
$idadeMin     = ($_GET['idade_min'] ?? '') !== '' ? (int)$_GET['idade_min'] : null;
$idadeMax     = ($_GET['idade_max'] ?? '') !== '' ? (int)$_GET['idade_max'] : null;
$logradouro   = trim($_GET['logradouro']                ?? '');
$semPaginacao = ($_GET['sem_paginacao']                 ?? '') === '1';

$limite = 25;
$offset = ($pagina - 1) * $limite;

$where  = ['1=1'];
$params = [];

if ($idAssociado !== null) {
    $where[]                  = 'd.fk_associado = :fk_associado';
    $params[':fk_associado']  = $idAssociado;
}

if ($busca !== '') {
    $like = "%{$busca}%";
    $where[]           = '(d.nome LIKE :busca1 OR a.nome LIKE :busca2 OR d.cpf LIKE :busca3)';
    $params[':busca1'] = $like;
    $params[':busca2'] = $like;
    $params[':busca3'] = $like;
}

if ($status === 'ativo')   { $where[] = 'd.ativo = 1'; }
if ($status === 'inativo') { $where[] = 'd.ativo = 0'; }

if ($idParentesco > 0) {
    $where[]                  = 'd.fk_parentesco = :fk_parentesco';
    $params[':fk_parentesco'] = $idParentesco;
}

if ($idGenero > 0) {
    $where[]              = 'd.fk_genero = :fk_genero';
    $params[':fk_genero'] = $idGenero;
}

if ($idadeMin !== null) {
    $where[]              = 'TIMESTAMPDIFF(YEAR, d.data_nascimento, CURDATE()) >= :idade_min';
    $params[':idade_min'] = $idadeMin;
}

if ($idadeMax !== null) {
    $where[]              = 'TIMESTAMPDIFF(YEAR, d.data_nascimento, CURDATE()) <= :idade_max';
    $params[':idade_max'] = $idadeMax;
}

if ($logradouro !== '') {
    $where[]               = 'a.logradouro LIKE :logradouro';
    $params[':logradouro'] = "%{$logradouro}%";
}

$clausulaWhere = implode(' AND ', $where);

$sqlTotal = "SELECT COUNT(*)
             FROM dependente d
             LEFT JOIN associado a ON a.id_associado = d.fk_associado
             WHERE {$clausulaWhere}";
$stmtTotal = $pdo->prepare($sqlTotal);
$stmtTotal->execute($params);
$total   = (int) $stmtTotal->fetchColumn();
$paginas = $total > 0 ? (int) ceil($total / $limite) : 1;

$sql = "
    SELECT
        d.id_dependente,
        d.nome,
        d.cpf,
        d.data_nascimento,
        d.ativo,
        d.criado_em,
        d.fk_genero,
        g.descricao     AS genero,
        d.fk_parentesco,
        p.descricao     AS parentesco,
        a.id_associado  AS id_associado_pai,
        a.nome          AS nome_associado,
        a.logradouro
    FROM dependente d
    LEFT JOIN associado a  ON a.id_associado  = d.fk_associado
    LEFT JOIN parentesco p ON p.id_parentesco = d.fk_parentesco
    LEFT JOIN genero g     ON g.id_genero     = d.fk_genero
    WHERE {$clausulaWhere}
    ORDER BY d.nome
";

if (!$semPaginacao) {
    $sql .= ' LIMIT :limite OFFSET :offset';
}

$stmt = $pdo->prepare($sql);

foreach ($params as $chave => $valor) {
    $stmt->bindValue($chave, $valor);
}
if ($semPaginacao) {
    $stmt->execute();
} else {
    $stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
}

jsonResposta([
    'dados'   => $stmt->fetchAll(),
    'pagina'  => $pagina,
    'paginas' => $semPaginacao ? 1 : $paginas,
    'total'   => $total,
]);
