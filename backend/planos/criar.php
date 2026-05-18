<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$dados = json_decode(file_get_contents('php://input'), true);
if (!$dados) jsonErro('Dados inválidos', 400);

$nome = trim($dados['nome'] ?? '');
if ($nome === '') jsonErro('O nome do plano é obrigatório.', 422);

$preco     = (float)($dados['preco']     ?? 0);
$periodo   = trim($dados['periodo']      ?? 'anuidade');
$beneficios = $dados['beneficios']       ?? [];
$ordem     = (int)($dados['ordem']       ?? 0);

$periodosValidos = ['anuidade', 'mensalidade', 'semestral'];
if (!in_array($periodo, $periodosValidos)) jsonErro('Período inválido.', 422);

try {
    $pdo = obterConexao();

    $stmt = $pdo->prepare("
        INSERT INTO plano_associacao (nome, preco, periodo, beneficios, ativo, ordem)
        VALUES (:nome, :preco, :periodo, :beneficios, TRUE, :ordem)
        RETURNING id_plano
    ");
    $stmt->execute([
        ':nome'       => $nome,
        ':preco'      => $preco,
        ':periodo'    => $periodo,
        ':beneficios' => json_encode($beneficios, JSON_UNESCAPED_UNICODE),
        ':ordem'      => $ordem,
    ]);

    $id = (int)$stmt->fetchColumn();
    jsonResposta(['id_plano' => $id, 'mensagem' => 'Plano criado com sucesso.'], 201);

} catch (PDOException $e) {
    jsonErro('Erro ao criar plano: ' . $e->getMessage(), 500);
}
