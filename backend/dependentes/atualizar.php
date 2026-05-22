<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$id_dependente   = $body['id_dependente']   ?? null;
$nome            = $body['nome']            ?? null;
$data_nascimento = $body['data_nascimento'] ?? null;
$cpf             = $body['cpf']             ?? null;
$fk_parentesco   = $body['fk_parentesco']   ?? null;
$fk_genero       = $body['fk_genero']       ?? null;
$observacao      = $body['observacao']      ?? null;

if (!$id_dependente || !$nome) jsonErro('ID e nome são obrigatórios', 422);

$cpf = $cpf ? preg_replace('/\D/', '', $cpf) : null;
if ($cpf && strlen($cpf) < 11) jsonErro('CPF inválido', 422);

try {
    $pdo = obterConexao();

    $stmtCheck = $pdo->prepare("SELECT id_dependente FROM dependente WHERE id_dependente = :id");
    $stmtCheck->execute([':id' => $id_dependente]);
    if (!$stmtCheck->fetch()) jsonErro('Dependente não encontrado', 404);

    $sql = "
        UPDATE dependente
        SET nome = :nome,
            data_nascimento = :data_nascimento,
            cpf = :cpf,
            fk_parentesco = :fk_parentesco,
            fk_genero = :fk_genero,
            observacao = :observacao
        WHERE id_dependente = :id_dependente
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':id_dependente'    => $id_dependente,
        ':nome'            => $nome,
        ':data_nascimento' => $data_nascimento ?: null,
        ':cpf'             => $cpf ?: null,
        ':fk_parentesco'   => $fk_parentesco ?: null,
        ':fk_genero'       => $fk_genero ?: null,
        ':observacao'      => $observacao,
    ]);

    jsonResposta(['mensagem' => 'Dependente atualizado com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao atualizar dependente: ' . $e->getMessage(), 500);
}
