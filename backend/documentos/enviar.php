<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo = obterConexao();

$assunto   = trim($_POST['assunto']   ?? '');
$versao    = trim($_POST['versao']    ?? '');
$categoria = trim($_POST['categoria'] ?? 'institucional');
$fkTipo    = isset($_POST['fk_tipo_documento']) && $_POST['fk_tipo_documento'] !== ''
             ? (int) $_POST['fk_tipo_documento']
             : null;
$tipoLivre = isset($_POST['tipo_livre']) && trim($_POST['tipo_livre']) !== ''
             ? trim($_POST['tipo_livre'])
             : null;

if ($assunto === '') jsonErro('Nome do documento é obrigatório');
if ($fkTipo === null && $tipoLivre === null) jsonErro('Tipo do documento é obrigatório');
if ($fkTipo !== null && $tipoLivre !== null) jsonErro('Informe apenas um tipo');

if (!isset($_FILES['arquivo']) || $_FILES['arquivo']['error'] !== UPLOAD_ERR_OK) {
    $codigos = [
        UPLOAD_ERR_INI_SIZE   => 'Arquivo excede o limite do servidor',
        UPLOAD_ERR_FORM_SIZE  => 'Arquivo excede o limite do formulário',
        UPLOAD_ERR_NO_FILE    => 'Nenhum arquivo enviado',
    ];
    $erro = $codigos[$_FILES['arquivo']['error'] ?? UPLOAD_ERR_NO_FILE] ?? 'Falha no upload';
    jsonErro($erro);
}

$arquivo = $_FILES['arquivo'];
$ext     = strtolower(pathinfo($arquivo['name'], PATHINFO_EXTENSION));

if (!in_array($ext, ['pdf', 'doc', 'docx'], true)) {
    jsonErro('Formato não permitido. Envie PDF, DOC ou DOCX.');
}

if ($arquivo['size'] > 10 * 1024 * 1024) {
    jsonErro('Arquivo muito grande. Máximo 10 MB.');
}

$dirUpload = __DIR__ . '/../uploads/documentos/';
if (!is_dir($dirUpload)) {
    mkdir($dirUpload, 0755, true);
}

$nomeArquivo = uniqid('doc_', true) . '.' . $ext;
$caminho     = $dirUpload . $nomeArquivo;

if (!move_uploaded_file($arquivo['tmp_name'], $caminho)) {
    jsonErro('Falha ao salvar arquivo no servidor', 500);
}

try {
    $stmt = $pdo->prepare(
        'INSERT INTO documento (assunto, versao, categoria, fk_tipo_documento, tipo_livre, arquivo_path, data_documento)
         VALUES (:assunto, :versao, :categoria, :fk_tipo, :tipo_livre, :arquivo_path, CURRENT_DATE)
         RETURNING id_documento, assunto, versao, data_documento, arquivo_path'
    );
    $stmt->execute([
        ':assunto'      => $assunto,
        ':versao'       => $versao !== '' ? $versao : null,
        ':categoria'    => $categoria,
        ':fk_tipo'      => $fkTipo,
        ':tipo_livre'   => $tipoLivre,
        ':arquivo_path' => $nomeArquivo,
    ]);
    jsonResposta($stmt->fetch(), 201);
} catch (PDOException $e) {
    @unlink($caminho);
    jsonErro('Erro ao registrar documento: ' . $e->getMessage(), 500);
}
