<?php
declare(strict_types=1);

suite('PREFLIGHT — Servidor e banco', function () {
    // Verifica que o servidor responde
    $r = req('POST', '/backend/auth/login.php', ['email' => '', 'senha' => '']);
    ok(
        'Servidor acessível em ' . BASE_URL,
        $r['status'] > 0,
        $r['erro'] ?? "status {$r['status']}"
    );

    if ($r['status'] === 0) {
        echo AMARELO . "\n  ⚠  Servidor não está no ar. Inicie com:\n"
            . "     php -S localhost:8080 router.php\n"
            . "  Abortando testes.\n" . RESET . "\n";
        resumo();
    }

    // Verifica que a tabela usuario tem ao menos um perfil cadastrado
    $r2 = req('POST', '/backend/auth/login.php', [
        'email' => 'leonardo.leote0909@gmail.com',
        'senha' => 'admin',
    ]);
    ok(
        'Usuário seed (leonardo.leote0909@gmail.com) existe e autentica',
        $r2['status'] === 200,
        "status {$r2['status']} — rode: php backend/seed_usuario.php"
    );

    $GLOBALS['perfil_id_teste'] = $r2['corpo']['usuario']['fk_perfil'] ?? 1;
});
