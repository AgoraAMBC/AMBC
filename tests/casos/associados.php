<?php
declare(strict_types=1);

suite('ASSOCIADOS — CRUD', function () {
    $uid      = uid();
    $cpf      = cpf_fake();
    $idCriado = null;

    // ── Criar ────────────────────────────────────────────────
    $r = req('POST', '/backend/associados/criar.php', [
        'nome'     => "Associado Teste $uid",
        'cpf_cnpj' => $cpf,
        'email'    => "assoc_{$uid}@ambc.tst",
    ]);
    ok('Cadastrar associado → 201',           $r['status'] === 201, "status {$r['status']} | " . json_encode($r['corpo']));
    ok('id_associado retornado',              isset($r['corpo']['data']['id_associado']), json_encode($r['corpo']));
    ok('matricula retornada',                 isset($r['corpo']['data']['matricula']),    json_encode($r['corpo']));
    $idCriado = $r['corpo']['data']['id_associado'] ?? null;

    // ── Campos obrigatórios ──────────────────────────────────
    $rv = req('POST', '/backend/associados/criar.php', [
        'nome'     => '',
        'cpf_cnpj' => '',
    ]);
    ok('Nome/CPF vazios → 4xx',               $rv['status'] >= 400, "status {$rv['status']}");

    // ── CPF duplicado ────────────────────────────────────────
    $rdup = req('POST', '/backend/associados/criar.php', [
        'nome'     => "Duplicado $uid",
        'cpf_cnpj' => $cpf,
    ]);
    ok('CPF duplicado → 409',                 $rdup['status'] === 409, "status {$rdup['status']}");

    // ── Listar ───────────────────────────────────────────────
    $rl = req('GET', '/backend/associados/listar.php');
    ok('Listar → 200',                        $rl['status'] === 200, "status {$rl['status']}");
    ok('Campo [dados] presente',              isset($rl['corpo']['dados']));
    ok('Campo [total] presente',              isset($rl['corpo']['total']));

    // Busca por nome
    $rb = req('GET', '/backend/associados/listar.php', query: ['busca' => "Associado Teste $uid"]);
    ok('Busca por nome encontra o registro',  !empty($rb['corpo']['dados'] ?? []), 'busca retornou vazio');

    // ── Excluir (limpeza) ────────────────────────────────────
    if ($idCriado) {
        $rx = req('DELETE', '/backend/associados/excluir.php', null, ['id' => $idCriado]);
        ok('Excluir associado → 200',         $rx['status'] === 200, "status {$rx['status']}");

        $rx2 = req('DELETE', '/backend/associados/excluir.php', null, ['id' => $idCriado]);
        ok('Excluir inexistente → 404',       $rx2['status'] === 404, "status {$rx2['status']}");
    } else {
        ok('Excluir associado → 200',         false, 'id não foi criado, limpeza ignorada');
        ok('Excluir inexistente → 404',       false, 'id não foi criado');
    }
});
