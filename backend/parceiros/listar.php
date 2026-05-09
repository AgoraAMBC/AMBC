<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

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
    $where[]          = "(p.nome_razao_social ILIKE :busca OR p.cpf_cnpj ILIKE :busca OR p.email ILIKE :busca)";
    $params[':busca'] = "%{$busca}%";
}

if ($status === 'ativo')   { $where[] = 'p.ativo = TRUE';  }
if ($status === 'inativo') { $where[] = 'p.ativo = FALSE'; }

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
$stmt->execute(array_merge($params, [':limite' => $limite, ':offset' => $offset]));
$parceiros = $stmt->fetchAll();

jsonResposta([
    'dados'   => $parceiros,
    'pagina'  => $pagina,
    'paginas' => $paginas,
    'total'   => $total,
]);
