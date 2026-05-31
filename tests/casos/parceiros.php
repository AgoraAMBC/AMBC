<?php
declare(strict_types=1);

suite('PARCEIROS — CRUD', function () {
    $uid      = uid();
    $cnpj     = cnpj_fake();
    $idCriado = null;

    // ── Criar ────────────────────────────────────────────────
    $r = req('POST', '/backend/parceiros/cadastrar.php', [
        'nome_razao_social' => "Empresa Teste $uid",
        'cpf_cnpj'          => $cnpj,
        'tipo_pessoa'        => 'PJ',
        'email'              => "parceiro_{$uid}@ambc.tst",
        'telefones'          => [],
        'lancamentos'        => [],
    ]);
    ok('Cadastrar parceiro → 201',            $r['status'] === 201, "status {$r['status']} | " . json_encode($r['corpo']));
    ok('id_parceiro retornado',               isset($r['corpo']['id_parceiro']),  json_encode($r['corpo']));
    $idCriado = $r['corpo']['id_parceiro'] ?? null;

    // ── Nome sem espaço (inválido) ───────────────────────────
    $rv = req('POST', '/backend/parceiros/cadastrar.php', [
        'nome_razao_social' => 'SemEspaco',
        'cpf_cnpj'          => cnpj_fake(),
    ]);
    ok('Nome sem sobrenome/razão → 422',      $rv['status'] === 422, "status {$rv['status']}");

    // ── CNPJ duplicado ───────────────────────────────────────
    $rdup = req('POST', '/backend/parceiros/cadastrar.php', [
        'nome_razao_social' => "Empresa Dup $uid",
        'cpf_cnpj'          => $cnpj,
        'tipo_pessoa'        => 'PJ',
    ]);
    ok('CNPJ duplicado → 409',                $rdup['status'] === 409, "status {$rdup['status']}");

    // ── Listar ───────────────────────────────────────────────
    $rl = req('GET', '/backend/parceiros/listar.php');
    ok('Listar → 200',                        $rl['status'] === 200, "status {$rl['status']}");
    ok('Campo [dados] presente',              isset($rl['corpo']['dados']));

    // Busca por nome
    $rb = req('GET', '/backend/parceiros/listar.php', query: ['busca' => "Empresa Teste $uid"]);
    ok('Busca por nome encontra o registro',  !empty($rb['corpo']['dados'] ?? []), 'busca retornou vazio');

    // ── Parceiro com telefone ────────────────────────────────
    $uid2  = uid();
    $cnpj2 = cnpj_fake();
    $r2 = req('POST', '/backend/parceiros/cadastrar.php', [
        'nome_razao_social' => "Empresa Com Tel $uid2",
        'cpf_cnpj'          => $cnpj2,
        'tipo_pessoa'        => 'PJ',
        'telefones'          => [
            ['ddd' => '11', 'numero' => '999887766', 'fk_tipo_telefone' => 1],
        ],
        'lancamentos' => [],
    ]);
    ok('Parceiro com telefone → 201',         $r2['status'] === 201, "status {$r2['status']}");
    $idCom2 = $r2['corpo']['id_parceiro'] ?? null;

    // ── Excluir (limpeza) ────────────────────────────────────
    foreach (array_filter([$idCriado, $idCom2]) as $idLimpar) {
        $rx = req('DELETE', '/backend/parceiros/excluir.php', ['id_parceiro' => $idLimpar]);
        ok("Excluir parceiro #$idLimpar → 200", $rx['status'] === 200, "status {$rx['status']}");
    }

    if ($idCriado) {
        $rx2 = req('DELETE', '/backend/parceiros/excluir.php', ['id_parceiro' => $idCriado]);
        ok('Excluir inexistente → 404',       $rx2['status'] === 404, "status {$rx2['status']}");
    }
});
