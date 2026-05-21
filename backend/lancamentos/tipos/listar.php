<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers.php';

configurarCors();

try {
    $pdo = obterConexao();

    $sql = "
        SELECT DISTINCT
            tl.id_tipo_lancamento,
            tl.descricao
        FROM tipo_lancamento tl
        INNER JOIN relacionamento_lancamento rl ON rl.fk_tipo_lancamento = tl.id_tipo_lancamento
        WHERE rl.ativo = true
        ORDER BY tl.descricao ASC
    ";

    $stmt = $pdo->query($sql);
    $tipos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    jsonResposta([
        'data' => $tipos,
        'total' => count($tipos)
    ]);

} catch (PDOException $e) {
    jsonErro('Erro ao buscar tipos de lançamento: ' . $e->getMessage(), 500);
}
