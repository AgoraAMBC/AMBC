<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
if (!$dados) jsonErro('Dados inválidos', 400);

$id = (int)($dados['id_plano'] ?? 0);
if ($id <= 0) jsonErro('ID inválido', 400);

$nome = trim($dados['nome'] ?? '');
if ($nome === '') jsonErro('O nome do plano é obrigatório.', 422);

$preco      = (float)($dados['preco']     ?? 0);
$periodo    = trim($dados['periodo']      ?? 'anuidade');
$beneficios = $dados['beneficios']        ?? [];
$ordem      = (int)($dados['ordem']       ?? 0);

$periodosValidos = ['anuidade', 'mensalidade', 'semestral'];
if (!in_array($periodo, $periodosValidos)) jsonErro('Período inválido.', 422);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("
        UPDATE plano_associacao
        SET nome = :nome, preco = :preco, periodo = :periodo,
            beneficios = :beneficios, ordem = :ordem
        WHERE id_plano = :id
        RETURNING id_plano
    ");
    $stmt->execute([
        ':nome'       => $nome,
        ':preco'      => $preco,
        ':periodo'    => $periodo,
        ':beneficios' => json_encode($beneficios, JSON_UNESCAPED_UNICODE),
        ':ordem'      => $ordem,
        ':id'         => $id,
    ]);

    if (!$stmt->fetch()) jsonErro('Plano não encontrado.', 404);

    jsonResposta(['mensagem' => 'Plano atualizado com sucesso.']);

} catch (PDOException $e) {
    jsonErro('Erro ao editar plano: ' . $e->getMessage(), 500);
}
