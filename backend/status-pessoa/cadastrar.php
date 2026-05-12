<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();

$descricao = trim($dados['descricao'] ?? '');
if ($descricao === '') jsonErro('Descrição é obrigatória');

try {
    $stmt = $pdo->prepare('SELECT id_status FROM status_pessoa WHERE descricao = :descricao');
    $stmt->execute([':descricao' => $descricao]);
    if ($stmt->fetch()) jsonErro('Já existe um status com esta descrição');

    $stmt = $pdo->prepare('INSERT INTO status_pessoa (descricao) VALUES (:descricao) RETURNING id_status AS id, descricao');
    $stmt->execute([':descricao' => $descricao]);
    $row = $stmt->fetch();

    jsonResposta($row ?: ['mensagem' => 'Status cadastrado com sucesso'], 201);
} catch (PDOException $e) {
    jsonErro('Erro no banco: ' . $e->getMessage(), 500);
}
