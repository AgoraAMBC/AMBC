<?php
declare(strict_types=1);
header('Content-Type: text/plain; charset=utf-8');

echo "=== DEBUG ENV ===\n\n";

// 1. Caminho que o database.php está procurando
$caminhoEnv = dirname(__DIR__) . '/.env';
echo "Caminho esperado do .env:\n$caminhoEnv\n\n";

// 2. Existe?
echo "Arquivo existe? " . (file_exists($caminhoEnv) ? 'SIM ✅' : 'NÃO ❌') . "\n\n";

if (!file_exists($caminhoEnv)) {
    echo "⚠️ O arquivo .env não foi encontrado nesse caminho.\n";
    exit;
}

// 3. Conteúdo bruto
echo "=== CONTEÚDO BRUTO ===\n";
$bruto = file_get_contents($caminhoEnv);
echo $bruto . "\n\n";

// 4. Linhas parseadas
echo "=== LINHAS PARSEADAS ===\n";
foreach (file($caminhoEnv, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $i => $linha) {
    if (str_starts_with(trim($linha), '#')) continue;
    if (!str_contains($linha, '=')) {
        echo "Linha $i SEM '=': [$linha]\n";
        continue;
    }
    [$chave, $valor] = explode('=', $linha, 2);
    echo "Linha $i: chave=[" . trim($chave) . "] valor=[" . trim($valor) . "]\n";
}

// 5. Tenta carregar como o database.php faz
echo "\n=== APÓS CARREGAR ===\n";
foreach (file($caminhoEnv, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $linha) {
    if (str_starts_with(trim($linha), '#')) continue;
    if (!str_contains($linha, '=')) continue;
    [$chave, $valor] = explode('=', $linha, 2);
    $_ENV[trim($chave)] = trim($valor);
}

echo "DB_HOST = [" . ($_ENV['DB_HOST'] ?? 'VAZIO') . "]\n";
echo "DB_PORT = [" . ($_ENV['DB_PORT'] ?? 'VAZIO') . "]\n";
echo "DB_NAME = [" . ($_ENV['DB_NAME'] ?? 'VAZIO') . "]\n";
echo "DB_USER = [" . ($_ENV['DB_USER'] ?? 'VAZIO') . "]\n";
echo "DB_PASS = [" . (isset($_ENV['DB_PASS']) ? '***' . strlen($_ENV['DB_PASS']) . ' caracteres***' : 'VAZIO') . "]\n";
