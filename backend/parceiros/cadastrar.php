<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/lancamentos/utils.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
if (!$dados) jsonErro('Dados inválidos', 400);

// Campos obrigatórios
$obrigatorios = ['nome_razao_social', 'cpf_cnpj'];
foreach ($obrigatorios as $campo) {
    if (empty(trim($dados[$campo] ?? ''))) {
        jsonErro("Campo obrigatório ausente: {$campo}", 422);
    }
}

// Valida nome composto (mínimo dois nomes)
$nome = trim($dados['nome_razao_social']);
if (!str_contains($nome, ' ')) {
    jsonErro('O nome deve conter pelo menos dois nomes.', 422);
}

// Valida CPF/CNPJ — só números, 11 ou 14 dígitos
$cpfCnpj = preg_replace('/\D/', '', $dados['cpf_cnpj']);
if (!in_array(strlen($cpfCnpj), [11, 14])) {
    jsonErro('CPF deve ter 11 dígitos e CNPJ deve ter 14 dígitos.', 422);
}

$pdo = obterConexao();

// Verifica duplicidade de CPF/CNPJ
$stmtVerifica = $pdo->prepare('SELECT id_parceiro FROM parceiro WHERE cpf_cnpj = :cpf_cnpj');
$stmtVerifica->execute([':cpf_cnpj' => $cpfCnpj]);
if ($stmtVerifica->fetch()) {
    jsonErro('CPF/CNPJ já cadastrado no sistema.', 409);
}

try {
    $pdo->beginTransaction();

    // Insere o parceiro
    $sql = "
        INSERT INTO parceiro (
            nome_razao_social, cpf_cnpj, email,
            tipo_pessoa, tipo_servico,
            logradouro, numero, complemento, cep,
            bairro, cidade, uf,
            ativo
        ) VALUES (
            :nome_razao_social, :cpf_cnpj, :email,
            :tipo_pessoa, :tipo_servico,
            :logradouro, :numero, :complemento, :cep,
            :bairro, :cidade, :uf,
            1
        )
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
    ]);

    $idParceiro = (int)$pdo->lastInsertId();

    // Insere telefones (pode ter vários)
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
                ':fk_parceiro'      => $idParceiro,
                ':ddd'              => $ddd,
                ':numero'           => $numero,
                ':fk_tipo_telefone' => $tel['fk_tipo_telefone'] ?? null,
                ':observacao'       => trim($tel['observacao'] ?? '') ?: null,
            ]);
        }
    }

    if (!empty($dados['lancamentos']) && is_array($dados['lancamentos'])) {
        foreach ($dados['lancamentos'] as $lancamento) {
            salvarLancamentoParceiro($pdo, $idParceiro, $lancamento);
        }
    }

    $pdo->commit();

    jsonResposta(['id_parceiro' => $idParceiro, 'mensagem' => 'Parceiro cadastrado com sucesso.'], 201);

} catch (PDOException $e) {
    $pdo->rollBack();
    jsonErro('Erro ao cadastrar parceiro: ' . $e->getMessage(), 500);
}
