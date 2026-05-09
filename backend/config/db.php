<?php
require_once __DIR__ . '/database.php';

// Alias para compatibilidade com os arquivos que usam conectarBanco()
function conectarBanco(): PDO {
    return obterConexao();
}
