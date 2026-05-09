<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/headers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['sucesso' => false, 'mensagem' => 'Método não permitido.']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);

if (!$body) {
    http_response_code(400);
    echo json_encode(['sucesso' => false, 'mensagem' => 'Payload inválido.']);
    exit;
}

// ── Dados pessoais ──────────────────────────────────────────
$nome            = $body['nome']            ?? null;
$cpf_cnpj        = $body['cpf_cnpj']        ?? null;
$data_nascimento = $body['data_nascimento'] ?? null;
$email           = $body['email']           ?? null;
$observacao      = $body['observacao']      ?? null;
$ativo           = isset($body['ativo']) ? (bool)$body['ativo'] : true;
$data_entrada    = $body['data_entrada']    ?? date('Y-m-d');

// ✅ Remove máscara do CPF/CNPJ (deixa só números)
$cpf_cnpj = preg_replace('/\D/', '', $cpf_cnpj);


// ── FKs ────────────────────────────────────────────────────
$fk_genero      = $body['genero']         ?? null;
$fk_estadocivil = $body['id_estadocivil'] ?? null;
$fk_profissao   = $body['id_profissao']   ?? null;
$fk_status      = $body['id_status']      ?? null;

// ── Endereço ───────────────────────────────────────────────
$end         = $body['endereco']    ?? [];
$logradouro  = $end['logradouro']  ?? null;
$numero      = $end['numero']      ?? null;
$complemento = $end['complemento'] ?? null;
$bairro      = $end['bairro']      ?? null;
$cidade      = $end['cidade']      ?? null;
$uf          = $end['uf']          ?? null;
$cep         = $end['cep']         ?? null;

// ── Validações básicas ─────────────────────────────────────
if (!$nome || !$cpf_cnpj) {
    http_response_code(422);
    echo json_encode(['sucesso' => false, 'mensagem' => 'Nome e CPF são obrigatórios.']);
    exit;
}

try {
    $pdo = conectarBanco();

    // ── Verifica se CPF já existe ──────────────────────────
    $stmtVerifica = $pdo->prepare("SELECT id_associado FROM associado WHERE cpf_cnpj = :cpf");
    $stmtVerifica->execute([':cpf' => $cpf_cnpj]);
    if ($stmtVerifica->fetch()) {
        http_response_code(409);
        echo json_encode(['sucesso' => false, 'mensagem' => 'CPF/CNPJ já cadastrado.']);
        exit;
    }

    // ── Gera matrícula sequencial ──────────────────────────
    $stmtMatricula = $pdo->query("SELECT MAX(CAST(matricula AS INTEGER)) FROM associado WHERE matricula ~ '^[0-9]+$'");
    $ultimaMatricula = $stmtMatricula->fetchColumn();
    $novaMatricula = str_pad(($ultimaMatricula ?? 0) + 1, 4, '0', STR_PAD_LEFT); // ex: "0001"

    // ── Insert ─────────────────────────────────────────────
    $sql = "
        INSERT INTO associado (
            matricula, nome, cpf_cnpj, data_nascimento, email, observacao,
            ativo, criado_em,
            fk_genero, fk_estadocivil, fk_profissao, fk_status,
            logradouro, numero, complemento, bairro, cidade, uf, cep
        ) VALUES (
            :matricula, :nome, :cpf_cnpj, :data_nascimento, :email, :observacao,
            :ativo, :criado_em,
            :fk_genero, :fk_estadocivil, :fk_profissao, :fk_status,
            :logradouro, :numero, :complemento, :bairro, :cidade, :uf, :cep
        )
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':matricula'       => $novaMatricula,
        ':nome'            => $nome,
        ':cpf_cnpj'        => $cpf_cnpj,
        ':data_nascimento' => $data_nascimento ?: null,
        ':email'           => $email,
        ':observacao'      => $observacao,
        ':ativo'           => $ativo ? 'true' : 'false',
        ':criado_em'       => $data_entrada,  // data_entrada do form → criado_em no banco
        ':fk_genero'       => $fk_genero,
        ':fk_estadocivil'  => $fk_estadocivil,
        ':fk_profissao'    => $fk_profissao,
        ':fk_status'       => $fk_status,
        ':logradouro'      => $logradouro,
        ':numero'          => $numero,
        ':complemento'     => $complemento,
        ':bairro'          => $bairro,
        ':cidade'          => $cidade,
        ':uf'              => $uf,
        ':cep'             => $cep,
    ]);

    $idNovo = $pdo->lastInsertId();

    http_response_code(201);
    echo json_encode([
        'sucesso'      => true,
        'mensagem'     => 'Associado cadastrado com sucesso.',
        'id_associado' => (int)$idNovo,
        'matricula'    => $novaMatricula
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'sucesso'  => false,
        'mensagem' => 'Erro ao salvar no banco.',
        'detalhe'  => $e->getMessage()
    ]);
}
