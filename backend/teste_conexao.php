<?php
declare(strict_types=1);
require_once __DIR__ . '/config/database.php';

try {
    $pdo  = obterConexao();
    $rows = $pdo->query('SELECT nome, email FROM usuario')->fetchAll(PDO::FETCH_ASSOC);

    echo "Conexão OK! Usuários encontrados: " . count($rows) . PHP_EOL;
    foreach ($rows as $r) {
        echo '  - ' . $r['nome'] . ' (' . $r['email'] . ')' . PHP_EOL;
    }
} catch (Exception $e) {
    echo 'ERRO: ' . $e->getMessage() . PHP_EOL;
}
