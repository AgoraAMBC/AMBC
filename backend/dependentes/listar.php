<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$pagina = max(1, (int)($_GET['pagina'] ?? 1));
$busca  = trim($_GET['busca']  ?? '');
$status = trim($_GET['status'] ?? '');
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
        d.ativo,
        d.criado_em,
        a.id_associado  AS id_associado_pai,
        a.nome          AS nome_associado,
        p.descricao     AS parentesco
    FROM dependente d
    LEFT JOIN associado a ON a.id_associado = d.fk_associado
    LEFT JOIN parentesco p ON p.id_parentesco = d.fk_parentesco
    WHERE {$clausulaWhere}
    ORDER BY d.nome
    LIMIT :limite OFFSET :offset
";

$stmt = $pdo->prepare($sql);
$stmt->execute(array_merge($params, [':limite' => $limite, ':offset' => $offset]));

jsonResposta([
    'dados'   => $stmt->fetchAll(),
    'pagina'  => $pagina,
    'paginas' => $paginas,
    'total'   => $total,
]);
