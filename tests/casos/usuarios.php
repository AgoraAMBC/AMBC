<?php
declare(strict_types=1);

suite('USUÁRIOS — CRUD', function () {
    $uid        = uid();
    $email      = "teste_{$uid}@ambc.tst";
    $perfilId   = $GLOBALS['perfil_id_teste'] ?? 1;
    $idCriado   = null;

    // ── Criar ────────────────────────────────────────────────
    $r = req('POST', '/backend/usuarios/cadastrar.php', [
        'nome'       => "Usuário Teste $uid",
        'email'      => $email,
        'fk_perfil'  => $perfilId,
        'senha'      => 'Senha@Teste1',
        'permissoes' => [],
    ]);
    ok('Cadastrar usuário → 201',             $r['status'] === 201, "status {$r['status']} | " . json_encode($r['corpo']));
    ok('id_usuario retornado',                isset($r['corpo']['id_usuario']), json_encode($r['corpo']));
    $idCriado = $r['corpo']['id_usuario'] ?? null;

    // ── Validações de entrada ────────────────────────────────
    $rv = req('POST', '/backend/usuarios/cadastrar.php', [
        'nome'      => '',
        'email'     => 'invalido',
        'fk_perfil' => $perfilId,
    ]);
    ok('Dados inválidos → 4xx',               $rv['status'] >= 400, "status {$rv['status']}");

    // ── E-mail duplicado ─────────────────────────────────────
    $rd = req('POST', '/backend/usuarios/cadastrar.php', [
        'nome'       => "Usuário Dup $uid",
        'email'      => $email,
        'fk_perfil'  => $perfilId,
        'senha'      => 'Senha@Teste1',
        'permissoes' => [],
    ]);
    ok('E-mail duplicado → 4xx',              $rd['status'] >= 400, "status {$rd['status']}");

    // ── Listar ───────────────────────────────────────────────
    $rl = req('GET', '/backend/usuarios/listar.php', query: ['busca' => $email]);
    ok('Listar → 200',                        $rl['status'] === 200, "status {$rl['status']}");
    ok('Campo [dados] presente',              isset($rl['corpo']['dados']));
    ok('Usuário criado aparece na busca',     !empty($rl['corpo']['dados']), 'nenhum resultado retornado');

    // ── Autenticar o usuário criado ──────────────────────────
    $ra = req('POST', '/backend/auth/login.php', [
        'email' => $email,
        'senha' => 'Senha@Teste1',
    ]);
    ok('Usuário recém-criado consegue logar', $ra['status'] === 200, "status {$ra['status']}");

    // ── Excluir (limpeza) ────────────────────────────────────
    if ($idCriado) {
        $rx = req('DELETE', '/backend/usuarios/deletar.php', ['id_usuario' => $idCriado]);
        ok('Excluir usuário → 200',           $rx['status'] === 200, "status {$rx['status']}");

        $rx2 = req('DELETE', '/backend/usuarios/deletar.php', ['id_usuario' => $idCriado]);
        ok('Excluir inexistente → 404',       $rx2['status'] === 404, "status {$rx2['status']}");
    } else {
        ok('Excluir usuário → 200',           false, 'id não foi criado, limpeza ignorada');
        ok('Excluir inexistente → 404',       false, 'id não foi criado');
    }
});
