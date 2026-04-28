<?php
// DELETAR APÓS USO
require_once __DIR__ . '/config/database.php';

$email = 'leonardo.leote0909@gmail.com';
$senha = 'admin';

$pdo  = obterConexao();
$stmt = $pdo->prepare('SELECT id_usuario, nome, email, senha_hash, ativo FROM usuario WHERE email = :email');
$stmt->execute([':email' => $email]);
$usuario = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$usuario) {
    echo "❌ Usuário NÃO encontrado no banco com este e-mail.\n";
    exit;
}

echo "✅ Usuário encontrado:\n";
echo "   Nome  : " . $usuario['nome'] . "\n";
echo "   Ativo : " . ($usuario['ativo'] ? 'Sim' : 'NÃO — este é o problema!') . "\n";
echo "   Hash  : " . substr($usuario['senha_hash'] ?? 'NULL', 0, 20) . "...\n\n";

if (!$usuario['senha_hash']) {
    echo "❌ Sem senha cadastrada (senha_hash é NULL).\n";
    exit;
}

if (password_verify($senha, $usuario['senha_hash'])) {
    echo "✅ Senha CORRETA — o problema está em outro lugar.\n";
} else {
    echo "❌ Senha INCORRETA — o hash não bate com a senha digitada.\n";
    echo "   Solução: redefina a senha pelo criar_usuario_temp.php\n";
}
