<?php
require_once __DIR__ . '/config/database.php';

$pdo = obterConexao();

$modulos = ['Painel', 'Associados', 'Financeiro', 'Parceiros', 'Configuracoes'];
$stmt = $pdo->prepare('INSERT IGNORE INTO modulo_sistema (descricao) VALUES (?)');
foreach ($modulos as $m) {
    $stmt->execute([$m]);
}

$perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario WHERE descricao LIKE 'Administrador' LIMIT 1")->fetch();

$senhaHash = password_hash('admin123', PASSWORD_BCRYPT, ['cost' => 10]);

$stmt = $pdo->prepare("INSERT INTO usuario (nome, email, senha_hash, fk_perfil, ativo, primeiro_acesso) VALUES (:nome, :email, :senha_hash, :fk_perfil, 1, 0) ON DUPLICATE KEY UPDATE email = email");
$stmt->execute([
    ':nome'       => 'Admin Master',
    ':email'      => 'admin@ambc.com',
    ':senha_hash' => $senhaHash,
    ':fk_perfil'  => $perfil['id_perfil'],
]);

$modulosIds = $pdo->query('SELECT id_modulo FROM modulo_sistema')->fetchAll();
$stmtPerm = $pdo->prepare('INSERT IGNORE INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar) VALUES (:id, :modulo, 1, 1)');

$usuarios = $pdo->query('SELECT id_usuario FROM usuario')->fetchAll();
foreach ($usuarios as $u) {
    foreach ($modulosIds as $m) {
        $stmtPerm->execute([':id' => $u['id_usuario'], ':modulo' => $m['id_modulo']]);
    }
}

echo "Usuarios e modulos configurados com sucesso!\n";
