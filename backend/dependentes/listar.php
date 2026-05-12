<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$id_associado = isset($_GET['id_associado']) ? (int)$_GET['id_associado'] : null;

if (!$id_associado) jsonErro('ID do associado é obrigatório', 400);

try {
    $pdo = obterConexao();

    $sql = "
        SELECT
            d.id_dependente,
            d.nome,
            d.data_nascimento,
            d.cpf,
            d.observacao,
            COALESCE(p.descricao, '') AS parentesco,
            p.id_parentesco,
            COALESCE(g.descricao, '') AS genero,
            g.id_genero
        FROM dependente d
        LEFT JOIN parentesco p ON p.id_parentesco = d.fk_parentesco
        LEFT JOIN genero g ON g.id_genero = d.fk_genero
        WHERE d.fk_associado = :id_associado
        ORDER BY d.nome
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id_associado' => $id_associado]);
    $dependentes = $stmt->fetchAll();

    jsonResposta(['dependentes' => $dependentes]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar dependentes: ' . $e->getMessage(), 500);
}