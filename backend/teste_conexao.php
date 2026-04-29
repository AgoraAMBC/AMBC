<?php
declare(strict_types=1);

require_once __DIR__ . '/config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $pdo = obterConexao();
    
    echo "✅ Conexão com PostgreSQL: OK\n";
    echo "📦 Banco: " . ($_ENV['DB_NAME'] ?? '?') . "\n";
    echo str_repeat('-', 50) . "\n\n";
    
    $rows = $pdo->query('SELECT id_usuario, nome, email FROM usuario ORDER BY id_usuario')
                ->fetchAll();
    
    echo "👥 Usuários cadastrados (" . count($rows) . "):\n\n";
    
    foreach ($rows as $r) {
        echo sprintf(
            "  [%d] %s — %s\n",
            $r['id_usuario'],
            $r['nome'],
            $r['email']
        );
    }
} catch (Throwable $e) {
    echo "❌ Erro: " . $e->getMessage();
}
