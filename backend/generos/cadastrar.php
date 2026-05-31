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
    $stmt = $pdo->prepare('SELECT id_genero FROM genero WHERE descricao = :descricao');
    $stmt->execute([':descricao' => $descricao]);
    if ($stmt->fetch()) jsonErro('Já existe um gênero com esta descrição');

    $stmt = $pdo->prepare('INSERT INTO genero (descricao) VALUES (:descricao)');
    $stmt->execute([':descricao' => $descricao]);

    jsonResposta(['id' => (int)$pdo->lastInsertId(), 'descricao' => $descricao], 201);
} catch (PDOException $e) {
    jsonErro('Erro no banco: ' . $e->getMessage(), 500);
}
