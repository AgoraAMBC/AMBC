<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$pagina   = max(1, (int)($_GET['pagina']   ?? 1));
$busca    = trim($_GET['busca']            ?? '');
$status   = trim($_GET['status']           ?? '');
$limite   = 25;
$offset   = ($pagina - 1) * $limite;

// Monta filtros dinamicamente
$where  = ['1=1'];
$params = [];

if ($busca !== '') {
    $like = "%{$busca}%";
    $where[]           = "(p.nome_razao_social LIKE :busca1 OR p.cpf_cnpj LIKE :busca2 OR p.email LIKE :busca3)";
    $params[':busca1'] = $like;
    $params[':busca2'] = $like;
    $params[':busca3'] = $like;
}

if ($status === 'ativo')   { $where[] = 'p.ativo = 1'; }
if ($status === 'inativo') { $where[] = 'p.ativo = 0'; }

$clausulaWhere = implode(' AND ', $where);

// Total para paginação
$sqlTotal = "SELECT COUNT(*) FROM parceiro p WHERE {$clausulaWhere}";
$stmtTotal = $pdo->prepare($sqlTotal);
$stmtTotal->execute($params);
$total   = (int)$stmtTotal->fetchColumn();
$paginas = (int)ceil($total / $limite);

// Busca os parceiros
$sql = "
    SELECT
        p.id_parceiro,
        p.nome_razao_social,
        p.cpf_cnpj,
        p.email,
        p.tipo_pessoa,
        p.tipo_servico,
        p.cidade,
        p.uf,
        p.ativo,
        p.criado_em,
        -- Telefone principal
        (
            SELECT CONCAT('(', t.ddd, ') ', t.numero)
            FROM telefone_parceiro t
            WHERE t.fk_parceiro = p.id_parceiro
            ORDER BY t.id_telefone_parceiro
            LIMIT 1
        ) AS telefone_principal
    FROM parceiro p
    WHERE {$clausulaWhere}
    ORDER BY p.nome_razao_social
    LIMIT :limite OFFSET :offset
";

$stmt = $pdo->prepare($sql);
foreach ($params as $chave => $valor) {
    $stmt->bindValue($chave, $valor);
}
$stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$parceiros = $stmt->fetchAll();

jsonResposta([
    'dados'   => $parceiros,
    'pagina'  => $pagina,
    'paginas' => $paginas,
    'total'   => $total,
]);
