<?php
// ATENÇÃO: deletar este arquivo após usar!
require_once __DIR__ . '/config/database.php';

$pdo   = obterConexao();
$email = 'usuario@usuario.com';
$nome  = 'Usuario Teste';
$hash  = password_hash('admin', PASSWORD_BCRYPT, ['cost' => 10]);

$perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario WHERE descricao ILIKE 'Administrador' LIMIT 1")->fetch();
if (!$perfil) {
    $perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario LIMIT 1")->fetch();
}

$stmt = $pdo->prepare("
    INSERT INTO usuario (nome, email, senha_hash, fk_perfil, ativo, primeiro_acesso)
    VALUES (:nome, :email, :hash, :perfil, TRUE, FALSE)
    ON CONFLICT (email) DO UPDATE SET senha_hash = :hash, ativo = TRUE
    RETURNING id_usuario
");
$stmt->execute([':nome' => $nome, ':email' => $email, ':hash' => $hash, ':perfil' => $perfil['id_perfil']]);
$row = $stmt->fetch();

echo "✅ Usuário pronto! ID: " . $row['id_usuario'] . "\n";
echo "   E-mail : $email\n";
echo "   Senha  : admin\n";
