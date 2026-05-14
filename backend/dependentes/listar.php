<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$pagina       = max(1, (int)($_GET['pagina']       ?? 1));
$busca        = trim($_GET['busca']                 ?? '');
$status       = trim($_GET['status']                ?? '');
$idParentesco = (int)($_GET['id_parentesco']        ?? 0);
$idGenero     = (int)($_GET['id_genero']            ?? 0);
$idadeMin     = ($_GET['idade_min'] ?? '') !== '' ? (int)$_GET['idade_min'] : null;
$idadeMax     = ($_GET['idade_max'] ?? '') !== '' ? (int)$_GET['idade_max'] : null;
$logradouro   = trim($_GET['logradouro']            ?? '');
$semPaginacao = ($_GET['sem_paginacao']             ?? '') === '1';

$limite = 25;
$offset = ($pagina - 1) * $limite;

$where  = ['1=1'];
$params = [];

if ($busca !== '') {
    $where[]          = '(d.nome ILIKE :busca OR a.nome ILIKE :busca OR d.cpf ILIKE :busca)';
    $params[':busca'] = "%{$busca}%";
}

if ($status === 'ativo')   { $where[] = 'd.ativo = TRUE';  }
if ($status === 'inativo') { $where[] = 'd.ativo = FALSE'; }

if ($idParentesco > 0) {
    $where[]                  = 'd.fk_parentesco = :fk_parentesco';
    $params[':fk_parentesco'] = $idParentesco;
}

if ($idGenero > 0) {
    $where[]              = 'd.fk_genero = :fk_genero';
    $params[':fk_genero'] = $idGenero;
}

if ($idadeMin !== null) {
    $where[]              = 'EXTRACT(YEAR FROM AGE(d.data_nascimento)) >= :idade_min';
    $params[':idade_min'] = $idadeMin;
}

if ($idadeMax !== null) {
    $where[]              = 'EXTRACT(YEAR FROM AGE(d.data_nascimento)) <= :idade_max';
    $params[':idade_max'] = $idadeMax;
}

if ($logradouro !== '') {
    $where[]               = 'a.logradouro ILIKE :logradouro';
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

if ($semPaginacao) {
    $stmt->execute($params);
} else {
    $stmt->execute(array_merge($params, [':limite' => $limite, ':offset' => $offset]));
}

jsonResposta([
    'dados'   => $stmt->fetchAll(),
    'pagina'  => $pagina,
    'paginas' => $semPaginacao ? 1 : $paginas,
    'total'   => $total,
]);
