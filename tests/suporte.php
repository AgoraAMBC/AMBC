<?php
declare(strict_types=1);

define('BASE_URL', getenv('AMBC_BASE_URL') ?: 'http://localhost:8080');

// ─── Cores ───────────────────────────────────────────────────
const VERDE    = "\033[32m";
const VERMELHO = "\033[31m";
const AMARELO  = "\033[33m";
const CINZA    = "\033[90m";
const NEGRITO  = "\033[1m";
const RESET    = "\033[0m";

// ─── Estado global ───────────────────────────────────────────
$GLOBALS['testes'] = ['total' => 0, 'passou' => 0, 'falhou' => 0, 'falhas' => []];

// ─── HTTP via stream context (sem extensão cURL) ─────────────
function req(string $metodo, string $caminho, mixed $corpo = null, array $query = []): array
{
    $url = BASE_URL . $caminho;
    if ($query) $url .= '?' . http_build_query($query);

    $opcoes = [
        'http' => [
            'method'        => strtoupper($metodo),
            'header'        => "Content-Type: application/json\r\nAccept: application/json",
            'ignore_errors' => true,
            'timeout'       => 10,
        ],
    ];

    if ($corpo !== null) {
        $opcoes['http']['content'] = json_encode($corpo);
    }

    $ctx = stream_context_create($opcoes);
    $raw = @file_get_contents($url, false, $ctx);

    if ($raw === false) {
        return ['status' => 0, 'corpo' => null, 'erro' => 'Servidor inacessível em ' . BASE_URL];
    }

    $status = 0;
    foreach ($http_response_header as $h) {
        if (preg_match('/HTTP\/\S+\s+(\d+)/', $h, $m)) {
            $status = (int)$m[1];
        }
    }

    return ['status' => $status, 'corpo' => json_decode($raw, true), 'raw' => $raw];
}

// ─── Assertions ──────────────────────────────────────────────
function ok(string $desc, bool $cond, string $detalhe = ''): void
{
    $GLOBALS['testes']['total']++;
    if ($cond) {
        $GLOBALS['testes']['passou']++;
        echo VERDE . "  ✔ " . RESET . $desc . "\n";
    } else {
        $GLOBALS['testes']['falhou']++;
        $msg = "  ✘ $desc" . ($detalhe ? "  [$detalhe]" : '');
        $GLOBALS['testes']['falhas'][] = $msg;
        echo VERMELHO . $msg . RESET . "\n";
    }
}

// ─── Suite ───────────────────────────────────────────────────
function suite(string $nome, callable $fn): void
{
    echo "\n" . NEGRITO . $nome . RESET . "\n";
    echo CINZA . str_repeat('─', 52) . RESET . "\n";
    $fn();
}

// ─── Resumo final ────────────────────────────────────────────
function resumo(): never
{
    $t = $GLOBALS['testes'];
    echo "\n" . CINZA . str_repeat('═', 52) . RESET . "\n";
    $corFalha = $t['falhou'] > 0 ? VERMELHO : CINZA;
    echo NEGRITO . "Resultado  " . RESET
        . VERDE   . "✔ {$t['passou']} passou" . RESET . "   "
        . $corFalha . "✘ {$t['falhou']} falhou" . RESET . "   "
        . CINZA   . "total {$t['total']}" . RESET . "\n";

    if ($t['falhas']) {
        echo "\n" . VERMELHO . "Detalhes das falhas:" . RESET . "\n";
        foreach ($t['falhas'] as $f) {
            echo VERMELHO . $f . RESET . "\n";
        }
    }
    echo "\n";
    exit($t['falhou'] > 0 ? 1 : 0);
}

// ─── Helpers ─────────────────────────────────────────────────
function cpf_fake(): string  { return sprintf('%011d', mt_rand(10000000, 99999999999)); }
function cnpj_fake(): string { return sprintf('%014d', mt_rand(10000000000000, 99999999999999)); }
function uid(): string       { return substr(md5(uniqid('', true)), 0, 8); }
