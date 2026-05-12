<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido ou não informado', 400);

$body = corpoJson();
if (!$body) jsonErro('Payload inválido', 400);

$cpf_cnpj = preg_replace('/\D/', '', $body['cpf_cnpj'] ?? '');
$uf       = trim($body['uf'] ?? '');
$cep      = preg_replace('/\D/', '', $body['cep'] ?? '');

try {
    $pdo = obterConexao();

    // Verifica duplicidade de CPF (ignora o próprio registro)
    $stmtDupe = $pdo->prepare("SELECT id_associado FROM associado WHERE cpf_cnpj = :cpf AND id_associado != :id");
    $stmtDupe->execute([':cpf' => $cpf_cnpj, ':id' => $id]);
    if ($stmtDupe->fetch()) jsonErro('CPF/CNPJ já cadastrado', 409);

    $sql = "
        UPDATE associado SET
            nome            = :nome,
            email           = :email,
            cpf_cnpj        = :cpf_cnpj,
            data_nascimento = :data_nascimento,
            observacao      = :observacao,
            ativo           = :ativo,
            data_entrada    = :data_entrada,
            fk_genero       = :fk_genero,
            fk_estadocivil  = :fk_estadocivil,
            fk_profissao    = :fk_profissao,
            fk_categoria    = :fk_categoria,
            fk_status       = :fk_status,
            logradouro      = :logradouro,
            numero          = :numero,
            complemento     = :complemento,
            bairro          = :bairro,
            cidade          = :cidade,
            uf              = :uf,
            cep             = :cep,
            atualizado_em   = NOW()
        WHERE id_associado = :id
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':nome'            => $body['nome'] ?? null,
        ':email'           => $body['email'] ?? null,
        ':cpf_cnpj'        => $cpf_cnpj,
        ':data_nascimento' => $body['data_nascimento'] ?? null,
        ':observacao'      => $body['observacao'] ?? null,
        ':ativo'           => isset($body['ativo']) ? ($body['ativo'] ? 'true' : 'false') : 'true',
        ':data_entrada'    => $body['data_entrada'] ?? null,
        ':fk_genero'      => $body['fk_genero'] ?: null,
        ':fk_estadocivil'  => $body['fk_estadocivil'] ?: null,
        ':fk_profissao'    => $body['fk_profissao'] ?: null,
        ':fk_categoria'    => $body['fk_categoria'] ?: null,
        ':fk_status'       => $body['fk_status'] ?: null,
        ':logradouro'      => $body['logradouro'] ?? null,
        ':numero'          => $body['numero'] ?? null,
        ':complemento'     => $body['complemento'] ?? null,
        ':bairro'          => $body['bairro'] ?? null,
        ':cidade'          => $body['cidade'] ?? null,
        ':uf'              => $uf ?: null,
        ':cep'             => $cep ?: null,
        ':id'              => $id,
    ]);

    jsonResposta(['mensagem' => 'Associado atualizado com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao atualizar: ' . $e->getMessage(), 500);
}