<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$pdo       = obterConexao();
$categoria = $_GET['categoria'] ?? 'institucional';

try {
    $stmt = $pdo->prepare(
        'SELECT d.id_documento,
                d.assunto,
                d.versao,
                d.data_documento,
                d.arquivo_path,
                COALESCE(t.descricao, d.tipo_livre) AS tipo
         FROM documento d
         LEFT JOIN tipo_documento t ON t.id_tipo_documento = d.fk_tipo_documento
         WHERE d.categoria = :categoria
         ORDER BY d.data_documento DESC, d.id_documento DESC'
    );
    $stmt->execute([':categoria' => $categoria]);
    jsonResposta($stmt->fetchAll());
} catch (PDOException $e) {
    jsonErro('Erro ao listar documentos: ' . $e->getMessage(), 500);
}
