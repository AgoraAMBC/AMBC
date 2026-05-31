<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();

$nome        = trim($dados['nome'] ?? '');
$email       = trim($dados['email'] ?? '');
$perfil      = (int)($dados['fk_perfil'] ?? 0);
$senha       = $dados['senha'] ?? '';
$fkAssociado = !empty($dados['fk_associado']) ? (int)$dados['fk_associado'] : null;
$permissoes  = $dados['permissoes'] ?? [];

if ($nome === '')  jsonErro('Nome é obrigatório');
if ($email === '') jsonErro('E-mail é obrigatório');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) jsonErro('E-mail inválido');
if ($perfil <= 0)  jsonErro('Perfil é obrigatório');

$stmt = $pdo->prepare('SELECT id_usuario FROM usuario WHERE email = :email');
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) jsonErro('E-mail já cadastrado');

$senhaHash      = null;
$primeiroAcesso = true;
if ($senha !== '') {
    $senhaHash      = password_hash($senha, PASSWORD_BCRYPT, ['cost' => 10]);
    $primeiroAcesso = false;
}

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('
        INSERT INTO usuario (nome, email, senha_hash, fk_perfil, fk_associado, primeiro_acesso)
        VALUES (:nome, :email, :senha_hash, :fk_perfil, :fk_associado, :primeiro_acesso)
    ');
    $stmt->execute([
        ':nome'            => $nome,
        ':email'           => $email,
        ':senha_hash'      => $senhaHash,
        ':fk_perfil'       => $perfil,
        ':fk_associado'    => $fkAssociado,
        ':primeiro_acesso' => $primeiroAcesso ? 1 : 0,
    ]);
    $idUsuario = (int)$pdo->lastInsertId();

    $stmtPerm = $pdo->prepare('
        INSERT INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar)
        VALUES (:fk_usuario, :fk_modulo, :pode_acessar, :pode_editar)
    ');
    foreach ($permissoes as $perm) {
        $stmtPerm->execute([
            ':fk_usuario'   => $idUsuario,
            ':fk_modulo'    => (int)$perm['fk_modulo'],
            ':pode_acessar' => ($perm['pode_acessar'] ?? false) ? 1 : 0,
            ':pode_editar'  => ($perm['pode_editar'] ?? false) ? 1 : 0,
        ]);
    }

    $pdo->commit();
    jsonResposta(['mensagem' => 'Usuário cadastrado com sucesso', 'id_usuario' => $idUsuario], 201);
} catch (Exception $e) {
    $pdo->rollBack();
    jsonErro('Erro ao cadastrar usuário: ' . $e->getMessage(), 500);
}
