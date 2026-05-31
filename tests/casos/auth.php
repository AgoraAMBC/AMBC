<?php
declare(strict_types=1);

suite('AUTH — Login', function () {
    // Login válido
    $r = req('POST', '/backend/auth/login.php', [
        'email' => 'leonardo.leote0909@gmail.com',
        'senha' => 'admin',
    ]);
    ok('Login válido → 200',                  $r['status'] === 200,        "status {$r['status']}");
    ok('Resposta contém [usuario]',           isset($r['corpo']['usuario']));
    ok('usuario.id_usuario presente',         isset($r['corpo']['usuario']['id_usuario']));
    ok('senha_hash não vaza na resposta',     !isset($r['corpo']['usuario']['senha_hash']));

    // Credenciais erradas
    $r2 = req('POST', '/backend/auth/login.php', [
        'email' => 'naoexiste@ambc.tst',
        'senha' => 'errada123',
    ]);
    ok('Credenciais erradas → 401',           $r2['status'] === 401, "status {$r2['status']}");

    // Campos vazios
    $r3 = req('POST', '/backend/auth/login.php', ['email' => '', 'senha' => '']);
    ok('Campos vazios → 4xx',                 $r3['status'] >= 400, "status {$r3['status']}");

    // Método errado
    $r4 = req('GET', '/backend/auth/login.php');
    ok('GET em endpoint POST → 405',          $r4['status'] === 405, "status {$r4['status']}");
});
