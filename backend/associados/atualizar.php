<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) jsonErro('ID inválido ou não informado', 400);

$body = json_decode(file_get_contents('php://input'), true);
if (!$body) jsonErro('Corpo da requisição inválido', 400);

$pdo = obterConexao();

// Verifica se existe
$stmtCheck = $pdo->prepare("SELECT id_associado FROM associado WHERE id_associado = :id");
$stmtCheck->execute([':id' => $id]);
if (!$stmtCheck->fetch()) jsonErro('Associado não encontrado', 404);

try {
    $pdo->beginTransaction();

    // Atualiza associado
    $stmt = $pdo->prepare("
        UPDATE associado SET
            nome            = :nome,
            email           = :email,
            cpf_cnpj        = :cpf_cnpj,
            telefone        = :telefone,
            celular         = :celular,
            data_nascimento = :data_nascimento,
            genero          = :genero,
            id_profissao    = :id_profissao,
            id_estadocivil  = :id_estadocivil,
            id_status       = :id_status,
            ativo           = :ativo,
            atualizado_em   = NOW()
        WHERE id_associado = :id
    ");

    $stmt->execute([
        ':nome'            => $body['nome'],
        ':email'           => $body['email']           ?? null,
        ':cpf_cnpj'        => $body['cpf_cnpj'],
        ':telefone'        => $body['telefone']        ?? null,
        ':celular'         => $body['celular']         ?? null,
        ':data_nascimento' => $body['data_nascimento'] ?? null,
        ':genero'          => $body['genero']          ?? null,
        ':id_profissao'    => $body['id_profissao']    ?? null,
        ':id_estadocivil'  => $body['id_estadocivil']  ?? null,
        ':id_status'       => $body['id_status']       ?? null,
        ':ativo'           => isset($body['ativo']) ? (bool) $body['ativo'] : true,
        ':id'              => $id,
    ]);

    // Atualiza ou insere endereço
    if (!empty($body['endereco'])) {
        $end = $body['endereco'];

        $stmtEndCheck = $pdo->prepare("SELECT id_endereco FROM endereco WHERE id_associado = :id");
        $stmtEndCheck->execute([':id' => $id]);
        $endExiste = $stmtEndCheck->fetch();

        if ($endExiste) {
            $stmtEnd = $pdo->prepare("
                UPDATE endereco SET
                    logradouro  = :logradouro,
                    numero      = :numero,
                    complemento = :complemento,
                    bairro      = :bairro,
                    cidade      = :cidade,
                    uf          = :uf,
                    cep         = :cep
                WHERE id_associado = :id_associado
            ");
        } else {
            $stmtEnd = $pdo->prepare("
                INSERT INTO endereco (
                    id_associado, logradouro, numero, complemento,
                    bairro, cidade, uf, cep
                ) VALUES (
                    :id_associado, :logradouro, :numero, :complemento,
                    :bairro, :cidade, :uf, :cep
                )
            ");
        }

        $stmtEnd->execute([
            ':id_associado' => $id,
            ':logradouro'   => $end['logradouro']  ?? null,
            ':numero'       => $end['numero']       ?? null,
            ':complemento'  => $end['complemento'] ?? null,
            ':bairro'       => $end['bairro']       ?? null,
            ':cidade'       => $end['cidade']       ?? null,
            ':uf'           => $end['uf']           ?? null,
            ':cep'          => $end['cep']          ?? null,
        ]);
    }

    $pdo->commit();

    jsonResposta(['mensagem' => 'Associado atualizado com sucesso']);

} catch (Exception $e) {
    $pdo->rollBack();
    jsonErro('Erro ao atualizar associado: ' . $e->getMessage(), 500);
}
