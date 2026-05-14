<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido');

$pdo = obterConexao();

try {
    $stmt = $pdo->prepare('SELECT assunto, arquivo_path FROM documento WHERE id_documento = :id');
    $stmt->execute([':id' => $id]);
    $doc = $stmt->fetch();

    if (!$doc) jsonErro('Documento não encontrado', 404);

    $pdo->prepare('DELETE FROM documento WHERE id_documento = :id')->execute([':id' => $id]);

    $caminho = __DIR__ . '/../uploads/documentos/' . basename($doc['arquivo_path']);
    if (file_exists($caminho)) @unlink($caminho);

    jsonResposta(['mensagem' => 'Documento excluído com sucesso']);
} catch (PDOException $e) {
    jsonErro('Erro ao excluir: ' . $e->getMessage(), 500);
}
