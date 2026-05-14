<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

// CORS manual — configurarCors() sobrescreve Content-Type para JSON
$origem = $_SERVER['HTTP_ORIGIN'] ?? '';
$origensPermitidas = [
    'http://ambc-v2.test', 'http://localhost', 'http://localhost:8080',
    'http://localhost:5500', 'http://127.0.0.1:5500', 'https://ambc-testes.onrender.com',
];
if (in_array($origem, $origensPermitidas, true)) {
    header("Access-Control-Allow-Origin: $origem");
    header('Access-Control-Allow-Credentials: true');
}
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { http_response_code(405); exit; }

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) { http_response_code(400); echo 'ID inválido'; exit; }

$pdo = obterConexao();

try {
    $stmt = $pdo->prepare('SELECT assunto, arquivo_path FROM documento WHERE id_documento = :id');
    $stmt->execute([':id' => $id]);
    $doc = $stmt->fetch();

    if (!$doc) { http_response_code(404); echo 'Documento não encontrado'; exit; }

    $caminho = __DIR__ . '/../uploads/documentos/' . basename($doc['arquivo_path']);

    if (!file_exists($caminho)) { http_response_code(404); echo 'Arquivo não encontrado'; exit; }

    $ext  = strtolower(pathinfo($caminho, PATHINFO_EXTENSION));
    $mime = match ($ext) {
        'pdf'  => 'application/pdf',
        'doc'  => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        default => 'application/octet-stream',
    };

    $nomeDownload = preg_replace('/[^a-zA-Z0-9\-_. ]/', '_', $doc['assunto']) . '.' . $ext;

    header('Content-Type: ' . $mime);
    header('Content-Disposition: attachment; filename="' . $nomeDownload . '"');
    header('Content-Length: ' . filesize($caminho));
    header('Cache-Control: no-cache, no-store, must-revalidate');
    readfile($caminho);
    exit;
} catch (PDOException $e) {
    http_response_code(500);
    echo 'Erro interno';
    exit;
}
