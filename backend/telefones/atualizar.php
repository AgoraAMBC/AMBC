<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$id_telefone   = $body['id_telefone']   ?? null;
$ddd           = $body['ddd']           ?? null;
$numero        = $body['numero']        ?? null;
$tipo_valor    = $body['tipo']          ?? null;
$observacao    = $body['observacao']    ?? null;

if (!$id_telefone || !$ddd || !$numero) jsonErro('ID, DDD e número são obrigatórios', 422);

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

    $stmtCheck = $pdo->prepare("SELECT id_telefone FROM telefone WHERE id_telefone = :id");
    $stmtCheck->execute([':id' => $id_telefone]);
    if (!$stmtCheck->fetch()) jsonErro('Telefone não encontrado', 404);

    $sql = "
        UPDATE telefone
        SET ddd = :ddd,
            numero = :numero,
            fk_tipo_telefone = :fk_tipo_telefone,
            observacao = :observacao
        WHERE id_telefone = :id_telefone
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':id_telefone'      => $id_telefone,
        ':ddd'              => $ddd,
        ':numero'           => $numero,
        ':fk_tipo_telefone' => $fk_tipo_tel,
        ':observacao'       => $observacao,
    ]);

    jsonResposta(['mensagem' => 'Telefone atualizado com sucesso.']);

} catch (PDOException $e) {
    if (str_contains($e->getMessage(), 'chk_telefone_numero') ||
        str_contains($e->getMessage(), 'chk_telefone_ddd')) {
        jsonErro('Formato de telefone inválido', 422);
    }
    jsonErro('Erro ao atualizar telefone: ' . $e->getMessage(), 500);
}
