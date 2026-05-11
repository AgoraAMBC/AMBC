<?php
declare(strict_types=1);
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/helpers.php';

configurarCors();

$pdo = obterConexao();

$tabelas = [
    ['tabela' => 'genero',       'coluna' => 'id_genero'],
    ['tabela' => 'parentesco',   'coluna' => 'id_parentesco'],
    ['tabela' => 'profissao',    'coluna' => 'id_profissao'],
    ['tabela' => 'estado_civil', 'coluna' => 'id_estadocivil'],
    ['tabela' => 'status_pessoa','coluna' => 'id_status'],
    ['tabela' => 'associado',    'coluna' => 'id_associado'],
];

$resultados = [];

foreach ($tabelas as $t) {
    try {
        $sql = "SELECT setval(
            pg_get_serial_sequence('{$t['tabela']}', '{$t['coluna']}'),
            COALESCE((SELECT MAX({$t['coluna']}) FROM {$t['tabela']}), 0) + 1,
            false
        )";
        $pdo->query($sql);
        $resultados[] = ['tabela' => $t['tabela'], 'status' => 'ok'];
    } catch (PDOException $e) {
        $resultados[] = ['tabela' => $t['tabela'], 'status' => 'erro', 'detalhe' => $e->getMessage()];
    }
}

jsonResposta(['resultados' => $resultados]);
