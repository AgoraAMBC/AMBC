<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$fk_associado    = $body['fk_associado']    ?? null;
$nome            = $body['nome']            ?? null;
$data_nascimento = $body['data_nascimento'] ?? null;
$cpf             = $body['cpf']             ?? null;
$fk_parentesco   = $body['fk_parentesco']   ?? null;
$fk_genero       = $body['fk_genero']       ?? null;
$observacao      = $body['observacao']      ?? null;

if (!$fk_associado || !$nome) jsonErro('Associado e nome são obrigatórios', 422);

$cpf = $cpf ? preg_replace('/\D/', '', $cpf) : null;
if ($cpf && strlen($cpf) < 11) jsonErro('CPF inválido', 422);

try {
    $pdo = obterConexao();

    $stmtCheck = $pdo->prepare("SELECT id_associado FROM associado WHERE id_associado = :id");
    $stmtCheck->execute([':id' => $fk_associado]);
    if (!$stmtCheck->fetch()) jsonErro('Associado não encontrado', 404);

    $sql = "
        INSERT INTO dependente (
            fk_associado, nome, data_nascimento, cpf,
            fk_parentesco, fk_genero, observacao
        ) VALUES (
            :fk_associado, :nome, :data_nascimento, :cpf,
            :fk_parentesco, :fk_genero, :observacao
        )
        RETURNING id_dependente
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':fk_associado'    => $fk_associado,
        ':nome'            => $nome,
        ':data_nascimento' => $data_nascimento ?: null,
        ':cpf'             => $cpf ?: null,
        ':fk_parentesco'   => $fk_parentesco ?: null,
        ':fk_genero'       => $fk_genero ?: null,
        ':observacao'      => $observacao,
    ]);

    $row = $stmt->fetch();

    jsonResposta([
        'mensagem'      => 'Dependente cadastrado com sucesso.',
        'id_dependente' => (int)$row['id_dependente']
    ], 201);

} catch (PDOException $e) {
    jsonErro('Erro ao salvar dependente: ' . $e->getMessage(), 500);
}