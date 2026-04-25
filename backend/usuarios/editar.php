<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();

$idUsuario   = (int)($dados['id_usuario'] ?? 0);
$nome        = trim($dados['nome'] ?? '');
$perfil      = (int)($dados['fk_perfil'] ?? 0);
$senha       = $dados['senha'] ?? '';
$fkAssociado = !empty($dados['fk_associado']) ? (int)$dados['fk_associado'] : null;
$permissoes  = $dados['permissoes'] ?? [];

if ($idUsuario <= 0) jsonErro('Usuário inválido');
if ($nome === '')    jsonErro('Nome é obrigatório');
if ($perfil <= 0)    jsonErro('Perfil é obrigatório');

$stmt = $pdo->prepare('SELECT id_usuario FROM usuario WHERE id_usuario = :id');
$stmt->execute([':id' => $idUsuario]);
if (!$stmt->fetch()) jsonErro('Usuário não encontrado', 404);

try {
    $pdo->beginTransaction();

    if ($senha !== '') {
        $senhaHash = password_hash($senha, PASSWORD_BCRYPT, ['cost' => 10]);
        $pdo->prepare('
            UPDATE usuario
            SET nome = :nome, fk_perfil = :perfil, fk_associado = :fk_associado,
                senha_hash = :senha_hash, primeiro_acesso = FALSE, atualizado_em = NOW()
            WHERE id_usuario = :id
        ')->execute([
            ':nome'         => $nome,
            ':perfil'       => $perfil,
            ':fk_associado' => $fkAssociado,
            ':senha_hash'   => $senhaHash,
            ':id'           => $idUsuario,
        ]);
    } else {
        $pdo->prepare('
            UPDATE usuario
            SET nome = :nome, fk_perfil = :perfil, fk_associado = :fk_associado, atualizado_em = NOW()
            WHERE id_usuario = :id
        ')->execute([
            ':nome'         => $nome,
            ':perfil'       => $perfil,
            ':fk_associado' => $fkAssociado,
            ':id'           => $idUsuario,
        ]);
    }

    // recria permissões
    $pdo->prepare('DELETE FROM permissao_usuario WHERE fk_usuario = :id')
        ->execute([':id' => $idUsuario]);

    $stmtPerm = $pdo->prepare('
        INSERT INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar)
        VALUES (:fk_usuario, :fk_modulo, :pode_acessar, :pode_editar)
    ');
    foreach ($permissoes as $perm) {
        $stmtPerm->execute([
            ':fk_usuario'   => $idUsuario,
            ':fk_modulo'    => (int)$perm['fk_modulo'],
            ':pode_acessar' => ($perm['pode_acessar'] ?? false) ? 'TRUE' : 'FALSE',
            ':pode_editar'  => ($perm['pode_editar'] ?? false) ? 'TRUE' : 'FALSE',
        ]);
    }

    $pdo->commit();
    jsonResposta(['mensagem' => 'Usuário atualizado com sucesso']);
} catch (Exception $e) {
    $pdo->rollBack();
    jsonErro('Erro ao atualizar usuário: ' . $e->getMessage(), 500);
}
