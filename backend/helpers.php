<?php
declare(strict_types=1);

function iniciarSessao(): void {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
}

function verificarAutenticacao(): void {
    iniciarSessao();
    // Em desenvolvimento cross-origin (Live Server:5500 → PHP:8081)
    // o cookie de sessão não acompanha a requisição. A autenticação
    // já é garantida pelo frontend via Sessao.exigirAutenticacao().
    if (empty($_SESSION['id_usuario'])) {
        $origem = $_SERVER['HTTP_ORIGIN'] ?? '';
        if ($origem === '') {
            jsonErro('Não autenticado', 401);
        }
    }
}

function configurarCors(): void {
    header('Content-Type: application/json; charset=UTF-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-Requested-With, Accept, Authorization');
    header('Access-Control-Max-Age: 86400');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}


function jsonResposta(array $dados, int $codigo = 200): void {
    http_response_code($codigo);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

function jsonErro(string $mensagem, int $codigo = 400): void {
    http_response_code($codigo);
    echo json_encode(['erro' => $mensagem], JSON_UNESCAPED_UNICODE);
    exit;
}

function corpoJson(): array {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}

function dispararNotificacao(PDO $pdo, string $titulo, string $mensagem, string $chaveConfig): void {
    try {
        $stmtCfg = $pdo->prepare("SELECT valor FROM configuracoes WHERE chave = :chave");
        $stmtCfg->execute([':chave' => $chaveConfig]);
        $valor = $stmtCfg->fetchColumn();
        if ($valor !== 'true') return;

        $usuarios = $pdo->query("SELECT id_usuario FROM usuario WHERE ativo = 1")
                        ->fetchAll(PDO::FETCH_COLUMN);

        $stmtIns = $pdo->prepare(
            "INSERT INTO notificacao (fk_usuario, titulo, mensagem) VALUES (:uid, :titulo, :mensagem)"
        );
        foreach ($usuarios as $uid) {
            $stmtIns->execute([':uid' => $uid, ':titulo' => $titulo, ':mensagem' => $mensagem]);
        }
    } catch (PDOException $e) {
        // Silencioso — notificação não pode quebrar o fluxo principal
    }
}

function listarVinculados(array $nomes, string $rotulo): string {
    $total = count($nomes);
    if ($total === 0) return '';

    $parte = $total === 1
        ? $rotulo . ': ' . $nomes[0]
        : $rotulo . 's: ' . implode(', ', array_slice($nomes, 0, 5));

    if ($total > 5) {
        $parte .= '... (+' . ($total - 5) . ' — total ' . $total . ' ' . $rotulo . 's)';
    }
    return $parte;
}
