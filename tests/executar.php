#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * Runner de testes de integração — AMBC V2
 *
 * Pré-requisitos:
 *   1. Backend rodando:  php -S localhost:8080 router.php
 *   2. Banco importado:  db mysql.sql aplicado no Workbench
 *   3. Seed de usuário:  php backend/seed_usuario.php
 *
 * Uso:
 *   php tests/executar.php
 *
 * Variável de ambiente opcional:
 *   AMBC_BASE_URL=http://localhost:9000 php tests/executar.php
 */

require_once __DIR__ . '/suporte.php';

echo NEGRITO . "\nAMBC V2 — Testes de Integração\n" . RESET;
echo CINZA   . "Servidor: " . BASE_URL . "\n" . RESET;

require_once __DIR__ . '/casos/preflight.php';
require_once __DIR__ . '/casos/auth.php';
require_once __DIR__ . '/casos/usuarios.php';
require_once __DIR__ . '/casos/associados.php';
require_once __DIR__ . '/casos/parceiros.php';

resumo();
