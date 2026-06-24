<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonErro('Método não permitido', 405);
}

$corpo = corpoJson();
$email = trim($corpo['email'] ?? '');
$senha = $corpo['senha'] ?? '';

if ($email === '' || $senha === '') {
    jsonErro('E-mail e senha são obrigatórios');
}

$pdo = obterConexao();

$stmt = $pdo->prepare(
    'SELECT id_usuario, nome, email, senha_hash, fk_perfil, ativo
       FROM usuario
      WHERE email = :email
      LIMIT 1'
);
$stmt->execute([':email' => $email]);
$usuario = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$usuario || !password_verify($senha, $usuario['senha_hash'])) {
    jsonErro('E-mail ou senha inválidos', 401);
}

if (!(bool)$usuario['ativo']) {
    jsonErro('Usuário inativo. Contate o administrador.', 403);
}

$pdo->prepare('UPDATE usuario SET ultimo_acesso = NOW() WHERE id_usuario = :id')
    ->execute([':id' => $usuario['id_usuario']]);

unset($usuario['senha_hash']);

iniciarSessao();
$_SESSION['id_usuario'] = $usuario['id_usuario'];
$_SESSION['fk_perfil']  = $usuario['fk_perfil'];

// Carrega permissões do perfil (graceful: retorna [] se a tabela ainda não existe)
try {
    $stmtPerms = $pdo->prepare(
        'SELECT fk_modulo, pode_acessar, pode_editar FROM permissao_perfil WHERE fk_perfil = :perfil'
    );
    $stmtPerms->execute([':perfil' => $usuario['fk_perfil']]);
    $usuario['permissoes'] = $stmtPerms->fetchAll();
} catch (PDOException $e) {
    $usuario['permissoes'] = [];
}

jsonResposta(['usuario' => $usuario]);
