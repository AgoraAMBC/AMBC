<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$nome            = $body['nome']            ?? null;
$cpf_cnpj        = $body['cpf_cnpj']        ?? null;
$data_nascimento = $body['data_nascimento'] ?? null;
$email           = $body['email']           ?? null;
$observacao      = $body['observacao']      ?? null;
$ativo           = isset($body['ativo']) ? (bool)$body['ativo'] : true;
$data_entrada    = $body['data_entrada']    ?? date('Y-m-d');

$cpf_cnpj = preg_replace('/\D/', '', $cpf_cnpj);

$fk_genero      = $body['fk_genero']      ?? null;
$fk_estadocivil = $body['fk_estadocivil'] ?? null;
$fk_profissao   = $body['fk_profissao']   ?? null;
$fk_categoria   = $body['fk_categoria']   ?? null;
$fk_status      = $body['fk_status']      ?? null;

$logradouro  = $body['logradouro']  ?? null;
$numero      = $body['numero']      ?? null;
$complemento = $body['complemento'] ?? null;
$bairro      = $body['bairro']      ?? null;
$cidade      = $body['cidade']      ?? null;
$uf  = trim($body['uf'] ?? '');
$cep = preg_replace('/\D/', '', $body['cep'] ?? '');

if (!$nome || !$cpf_cnpj) jsonErro('Nome e CPF são obrigatórios', 422);

try {
    $pdo = obterConexao();

    $stmtVerifica = $pdo->prepare("SELECT id_associado FROM associado WHERE cpf_cnpj = :cpf");
    $stmtVerifica->execute([':cpf' => $cpf_cnpj]);
    if ($stmtVerifica->fetch()) jsonErro('CPF/CNPJ já cadastrado', 409);

    $stmtMatricula = $pdo->query("SELECT MAX(CAST(matricula AS UNSIGNED)) FROM associado WHERE matricula REGEXP '^[0-9]+$'");
    $ultimaMatricula = $stmtMatricula->fetchColumn();
    $novaMatricula = str_pad((string)(($ultimaMatricula ?? 0) + 1), 4, '0', STR_PAD_LEFT);

    $sql = "
        INSERT INTO associado (
            matricula, nome, cpf_cnpj, data_nascimento, email, observacao,
            ativo, criado_em, data_entrada,
            fk_genero, fk_estadocivil, fk_profissao, fk_categoria, fk_status,
            logradouro, numero, complemento, bairro, cidade, uf, cep
        ) VALUES (
            :matricula, :nome, :cpf_cnpj, :data_nascimento, :email, :observacao,
            :ativo, :criado_em, :data_entrada,
            :fk_genero, :fk_estadocivil, :fk_profissao, :fk_categoria, :fk_status,
            :logradouro, :numero, :complemento, :bairro, :cidade, :uf, :cep
        )
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':matricula'      => $novaMatricula,
        ':nome'           => $nome,
        ':cpf_cnpj'       => $cpf_cnpj,
        ':data_nascimento'=> $data_nascimento ?: null,
        ':email'          => $email,
        ':observacao'     => $observacao,
        ':ativo'          => $ativo ? 1 : 0,
        ':criado_em'      => date('Y-m-d H:i:s'),
        ':data_entrada'   => $data_entrada ?: date('Y-m-d'),
        ':fk_genero'      => $fk_genero ?: null,
        ':fk_estadocivil' => $fk_estadocivil ?: null,
        ':fk_profissao'   => $fk_profissao ?: null,
        ':fk_categoria'   => $fk_categoria ?: null,
        ':fk_status'      => $fk_status ?: null,
        ':logradouro'     => $logradouro,
        ':numero'         => $numero,
        ':complemento'    => $complemento,
        ':bairro'         => $bairro,
        ':cidade'         => $cidade,
        ':uf'              => $uf ?: null,
        ':cep'             => $cep ?: null,
    ]);

    jsonResposta([
        'mensagem'     => 'Associado cadastrado com sucesso.',
        'data' => [
            'id_associado' => (int)$pdo->lastInsertId(),
            'matricula'   => $novaMatricula
        ]
    ], 201);

} catch (PDOException $e) {
    jsonErro('Erro ao salvar no banco: ' . $e->getMessage(), 500);
}