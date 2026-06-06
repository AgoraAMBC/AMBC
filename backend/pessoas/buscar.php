<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$busca = trim($_GET['busca'] ?? '');
$limite = max(1, min(50, (int)($_GET['limite'] ?? 15)));

if ($busca === '') {
    jsonResposta(['dados' => []]);
}

$like = '%' . $busca . '%';

$sql = "
    SELECT id, tipo, nome, documento, email
    FROM (
        SELECT
            a.id_associado AS id,
            'associado' AS tipo,
            a.nome AS nome,
            a.cpf_cnpj AS documento,
            a.email AS email
        FROM associado a
        WHERE a.ativo = 1
          AND (a.nome LIKE :busca1 OR a.email LIKE :busca2 OR a.cpf_cnpj LIKE :busca3)

        UNION ALL

        SELECT
            p.id_parceiro AS id,
            'parceiro' AS tipo,
            p.nome_razao_social AS nome,
            p.cpf_cnpj AS documento,
            p.email AS email
        FROM parceiro p
        WHERE p.ativo = 1
          AND (p.nome_razao_social LIKE :busca4 OR p.email LIKE :busca5 OR p.cpf_cnpj LIKE :busca6)
    ) AS pessoas
    ORDER BY nome ASC
    LIMIT :limite
";

$stmt = $pdo->prepare($sql);
$stmt->bindValue(':busca1', $like);
$stmt->bindValue(':busca2', $like);
$stmt->bindValue(':busca3', $like);
$stmt->bindValue(':busca4', $like);
$stmt->bindValue(':busca5', $like);
$stmt->bindValue(':busca6', $like);
$stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
$stmt->execute();

$dados = $stmt->fetchAll();

foreach ($dados as &$p) {
    $p['id'] = (int)$p['id'];
    $p['rotulo'] = $p['nome'] . ($p['documento'] ? ' — ' . $p['documento'] : '');
}

jsonResposta(['dados' => $dados]);
