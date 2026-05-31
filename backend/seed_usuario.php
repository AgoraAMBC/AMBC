<?php
declare(strict_types=1);
require_once __DIR__ . '/config/database.php';

$pdo = obterConexao();

// busca o id do perfil Administrador
$perfil = $pdo->query("SELECT id_perfil FROM perfil_usuario WHERE descricao LIKE 'Administrador' LIMIT 1")->fetch();
if (!$perfil) {
    echo "Perfil 'Administrador' não encontrado. Verifique a tabela perfil_usuario.\n";
    exit(1);
}

$senhaHash = password_hash('Ambc@2026', PASSWORD_BCRYPT, ['cost' => 10]);

$stmt = $pdo->prepare("
    INSERT INTO usuario (nome, email, senha_hash, fk_perfil, ativo, primeiro_acesso)
    VALUES (:nome, :email, :senha_hash, :fk_perfil, 1, 0)
    ON DUPLICATE KEY UPDATE email = email
");
$stmt->execute([
    ':nome'      => 'Fabio Administrador',
    ':email'     => 'fabio@ambc.com.br',
    ':senha_hash'=> $senhaHash,
    ':fk_perfil' => $perfil['id_perfil'],
]);

if ($stmt->rowCount() === 0) {
    echo "Usuário já existia (e-mail duplicado) — nenhuma alteração feita.\n";
    exit(0);
}

$idUsuario = (int)$pdo->lastInsertId();

// insere permissões para todos os módulos
$modulos = $pdo->query('SELECT id_modulo FROM modulo_sistema')->fetchAll();
$stmtPerm = $pdo->prepare("
    INSERT IGNORE INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar)
    VALUES (:id, :modulo, 1, 1)
");
foreach ($modulos as $m) {
    $stmtPerm->execute([':id' => $idUsuario, ':modulo' => $m['id_modulo']]);
}

echo "Usuário criado com sucesso!\n";
echo "  ID      : $idUsuario\n";
echo "  Nome    : Fabio Administrador\n";
echo "  E-mail  : fabio@ambc.com.br\n";
echo "  Senha   : Ambc@2026\n";
echo "  Perfil  : Administrador\n";
echo "  Módulos : " . count($modulos) . " permissões inseridas\n";
