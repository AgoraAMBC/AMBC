<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$cpf_cnpj = trim($_GET['cpf_cnpj'] ?? '');
$ignorar_id = isset($_GET['ignorar_id']) ? (int)$_GET['ignorar_id'] : null;

if (!$cpf_cnpj) jsonErro('CPF/CNPJ é obrigatório', 400);

// Remove máscara
$cpf_cnpj = preg_replace('/\D/', '', $cpf_cnpj);

if (strlen($cpf_cnpj) < 11) jsonErro('CPF/CNPJ inválido', 400);

try {
    $pdo = obterConexao();

    $sql = 'SELECT id_associado FROM associado WHERE cpf_cnpj = :cpf';
    $params = [':cpf' => $cpf_cnpj];

    if ($ignorar_id) {
        $sql .= ' AND id_associado != :id';
        $params[':id'] = $ignorar_id;
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $resultado = $stmt->fetch();

    if ($resultado) {
        jsonErro('CPF/CNPJ já cadastrado', 409);
    }

    jsonResposta(['disponivel' => true, 'mensagem' => 'CPF/CNPJ disponível']);
} catch (Exception $e) {
    jsonErro('Erro ao verificar CPF: ' . $e->getMessage(), 500);
}
