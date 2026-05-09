<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
if (!$dados) jsonErro('Dados inválidos', 400);

$id = (int)($dados['id_parceiro'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

// Campos obrigatórios
$obrigatorios = ['nome_razao_social', 'cpf_cnpj'];
foreach ($obrigatorios as $campo) {
    if (empty(trim($dados[$campo] ?? ''))) {
        jsonErro("Campo obrigatório ausente: {$campo}", 422);
    }
}

// Valida nome composto
$nome = trim($dados['nome_razao_social']);
if (!str_contains($nome, ' ')) {
    jsonErro('O nome deve conter pelo menos dois nomes.', 422);
}

// Valida CPF/CNPJ
$cpfCnpj = preg_replace('/\D/', '', $dados['cpf_cnpj']);
if (!in_array(strlen($cpfCnpj), [11, 14])) {
    jsonErro('CPF deve ter 11 dígitos e CNPJ deve ter 14 dígitos.', 422);
}

$pdo = obterConexao();

// Verifica duplicidade — ignora o próprio registro
$stmtVerifica = $pdo->prepare('SELECT id_parceiro FROM parceiro WHERE cpf_cnpj = :cpf_cnpj AND id_parceiro != :id');
$stmtVerifica->execute([':cpf_cnpj' => $cpfCnpj, ':id' => $id]);
if ($stmtVerifica->fetch()) {
    jsonErro('CPF/CNPJ já cadastrado por outro parceiro.', 409);
}

try {
    $pdo->beginTransaction();

    $sql = "
        UPDATE parceiro SET
            nome_razao_social = :nome_razao_social,
            cpf_cnpj          = :cpf_cnpj,
            email             = :email,
            tipo_pessoa       = :tipo_pessoa,
            tipo_servico      = :tipo_servico,
            logradouro        = :logradouro,
            numero            = :numero,
            complemento       = :complemento,
            cep               = :cep,
            bairro            = :bairro,
            cidade            = :cidade,
            uf                = :uf
        WHERE id_parceiro = :id
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':nome_razao_social' => $nome,
        ':cpf_cnpj'          => $cpfCnpj,
        ':email'             => trim($dados['email']        ?? '') ?: null,
        ':tipo_pessoa'       => $dados['tipo_pessoa']       ?? 'PF',
        ':tipo_servico'      => trim($dados['tipo_servico'] ?? '') ?: null,
        ':logradouro'        => trim($dados['logradouro']   ?? '') ?: null,
        ':numero'            => trim($dados['numero']       ?? '') ?: null,
        ':complemento'       => trim($dados['complemento']  ?? '') ?: null,
        ':cep'               => preg_replace('/\D/', '', $dados['cep'] ?? '') ?: null,
        ':bairro'            => trim($dados['bairro']       ?? '') ?: null,
        ':cidade'            => trim($dados['cidade']       ?? '') ?: null,
        ':uf'                => trim($dados['uf']           ?? '') ?: null,
        ':id'                => $id,
    ]);

    // Atualiza telefones — apaga os antigos e recadastra
    $pdo->prepare('DELETE FROM telefone_parceiro WHERE fk_parceiro = :id')->execute([':id' => $id]);

    if (!empty($dados['telefones']) && is_array($dados['telefones'])) {
        $stmtTel = $pdo->prepare("
            INSERT INTO telefone_parceiro (fk_parceiro, ddd, numero, fk_tipo_telefone, observacao)
            VALUES (:fk_parceiro, :ddd, :numero, :fk_tipo_telefone, :observacao)
        ");

        foreach ($dados['telefones'] as $tel) {
            $ddd    = preg_replace('/\D/', '', $tel['ddd']    ?? '');
            $numero = preg_replace('/\D/', '', $tel['numero'] ?? '');

            if ($ddd === '' || $numero === '') continue;

            $stmtTel->execute([
                ':fk_parceiro'      => $id,
                ':ddd'              => $ddd,
                ':numero'           => $numero,
                ':fk_tipo_telefone' => $tel['fk_tipo_telefone'] ?? null,
                ':observacao'       => trim($tel['observacao'] ?? '') ?: null,
            ]);
        }
    }

    $pdo->commit();
    jsonResposta(['mensagem' => 'Parceiro atualizado com sucesso.']);

} catch (PDOException $e) {
    $pdo->rollBack();
    jsonErro('Erro ao atualizar parceiro: ' . $e->getMessage(), 500);
}
