<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$fk_associado  = $body['fk_associado'] ?? null;
$ddd           = $body['ddd']         ?? null;
$numero        = $body['numero']      ?? null;
$tipo_valor    = $body['tipo']        ?? null; // texto: "celular", "residencial", etc.
$observacao    = $body['observacao']  ?? null;

if (!$fk_associado || !$ddd || !$numero) jsonErro('Associado, DDD e número são obrigatórios', 422);

$ddd    = preg_replace('/\D/', '', $ddd);
$numero = preg_replace('/\D/', '', $numero);

if (strlen($ddd) !== 2)  jsonErro('DDD inválido', 422);
if (strlen($numero) < 8) jsonErro('Número de telefone inválido', 422);
if (strlen($numero) > 9) jsonErro('Número de telefone muito longo', 422);

$mapTipo = [
    'celular'     => 1,
    'residencial' => 2,
    'comercial'   => 3,
    'whatsapp'    => 4,
    'recado'      => 5,
];
$fk_tipo_tel = $mapTipo[$tipo_valor] ?? null;

try {
    $pdo = obterConexao();

    $stmtCheck = $pdo->prepare("SELECT id_associado FROM associado WHERE id_associado = :id");
    $stmtCheck->execute([':id' => $fk_associado]);
    if (!$stmtCheck->fetch()) jsonErro('Associado não encontrado', 404);

    $sql = "
        INSERT INTO telefone (fk_associado, ddd, numero, fk_tipo_telefone, observacao)
        VALUES (:fk_associado, :ddd, :numero, :fk_tipo_telefone, :observacao)
        RETURNING id_telefone
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':fk_associado'     => $fk_associado,
        ':ddd'              => $ddd,
        ':numero'           => $numero,
        ':fk_tipo_telefone' => $fk_tipo_tel,
        ':observacao'       => $observacao,
    ]);

    $row = $stmt->fetch();

    jsonResposta([
        'mensagem'    => 'Telefone cadastrado com sucesso.',
        'id_telefone' => (int)$row['id_telefone']
    ], 201);

} catch (PDOException $e) {
    if (str_contains($e->getMessage(), 'chk_telefone_numero') ||
        str_contains($e->getMessage(), 'chk_telefone_ddd')) {
        jsonErro('Formato de telefone inválido', 422);
    }
    jsonErro('Erro ao salvar telefone: ' . $e->getMessage(), 500);
}