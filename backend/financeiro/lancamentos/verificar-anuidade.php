<?php
declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();
verificarAutenticacao();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonErro('Método não permitido', 405);

$fkAssociado = isset($_GET['fk_associado']) ? (int)$_GET['fk_associado'] : 0;
$ano         = isset($_GET['ano'])          ? (int)$_GET['ano']          : 0;

if ($fkAssociado <= 0 || $ano <= 0) jsonErro('Parâmetros inválidos', 400);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare('
        SELECT id_lancamento, fk_parcelamento
        FROM lancamento
        WHERE fk_associado       = :fk_associado
          AND fk_tipo_lancamento = 1
          AND YEAR(data_vencimento) = :ano
          AND fk_status_conta   <> 3
        LIMIT 1
    ');
    $stmt->execute([':fk_associado' => $fkAssociado, ':ano' => $ano]);
    $row = $stmt->fetch();

    jsonResposta([
        'existe'          => (bool)$row,
        'fk_parcelamento' => $row ? ($row['fk_parcelamento'] ?? $row['id_lancamento']) : null,
    ]);
} catch (PDOException $e) {
    jsonErro('Erro ao verificar anuidade: ' . $e->getMessage(), 500);
}
