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
            t.id_telefone,
            t.ddd,
            t.numero,
            t.observacao,
            COALESCE(tipo.descricao, t.fk_tipo_telefone::text) AS tipo
        FROM telefone t
        LEFT JOIN tipo_telefone tipo ON tipo.id_tipo_telefone = t.fk_tipo_telefone
        WHERE t.fk_associado = :id_associado
        ORDER BY t.id_telefone
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id_associado' => $id_associado]);
    $telefones = $stmt->fetchAll();

    jsonResposta(['telefones' => $telefones]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar telefones: ' . $e->getMessage(), 500);
}