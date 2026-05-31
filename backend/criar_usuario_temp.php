<?php
// ATENÇÃO: deletar este arquivo após usar!
require_once __DIR__ . '/config/database.php';

$pdo   = obterConexao();
$email = 'usuario@usuario.com';
$nome  = 'Usuario Teste';
$hash  = password_hash('admin', PASSWORD_BCRYPT, ['cost' => 10]);

$perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario WHERE descricao LIKE 'Administrador' LIMIT 1")->fetch();
if (!$perfil) {
    $perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario LIMIT 1")->fetch();
}

$stmt = $pdo->prepare("
    INSERT INTO usuario (nome, email, senha_hash, fk_perfil, ativo, primeiro_acesso)
    VALUES (:nome, :email, :hash, :perfil, 1, 0)
    ON DUPLICATE KEY UPDATE senha_hash = VALUES(senha_hash), ativo = 1
");
$stmt->execute([':nome' => $nome, ':email' => $email, ':hash' => $hash, ':perfil' => $perfil['id_perfil']]);
$id = $pdo->lastInsertId() ?: '(existente)';

echo "✅ Usuário pronto! ID: " . $id . "\n";
echo "   E-mail : $email\n";
echo "   Senha  : admin\n";
