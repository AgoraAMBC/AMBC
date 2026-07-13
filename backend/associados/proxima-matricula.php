<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonErro('Método não permitido', 405);
}

try {
    $pdo = obterConexao();
    $ano = date('Y');

    $stmt = $pdo->query("
        SELECT matricula FROM associado
        WHERE matricula IS NOT NULL AND matricula != ''
    ");
    $matriculas = $stmt->fetchAll(PDO::FETCH_COLUMN);

    $maior = 0;
    foreach ($matriculas as $m) {
        if (preg_match('/ASS-(\d{4})-(\d{4})$/', $m, $match)) {
            $num = (int) $match[2];
        } elseif (preg_match('/(\d+)$/', $m, $match)) {
            $num = (int) $match[1];
        } else {
            continue;
        }
        if ($num > $maior) $maior = $num;
    }

    $proxima = sprintf('ASS-%d-%04d', $ano, $maior + 1);

    jsonResposta(['matricula' => $proxima]);

} catch (Exception $e) {
    jsonErro('Erro ao gerar matrícula: ' . $e->getMessage(), 500);
}
