<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$pdo   = obterConexao();
$dados = corpoJson();

$chavesPermitidas = [
    'idioma', 'fuso_horario', 'formato_data', 'moeda',
    'notif_vencimentos', 'notif_inadimplencia', 'notif_resumo_semanal', 'notif_novos_cadastros',
    'seg_2fa', 'seg_expirar_sessao',
    'dias_alerta_vencimento',
];

$recebidas = array_intersect_key($dados, array_flip($chavesPermitidas));

if (empty($recebidas)) jsonErro('Nenhuma configuração válida recebida');

try {
    $stmt = $pdo->prepare(
        'INSERT INTO configuracao_sistema (chave, valor, atualizado_em)
         VALUES (:chave, :valor, NOW())
         ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor, atualizado_em = NOW()'
    );

    foreach ($recebidas as $chave => $valor) {
        $stmt->execute([':chave' => $chave, ':valor' => (string) $valor]);
    }

    jsonResposta(['mensagem' => 'Configurações salvas com sucesso']);
} catch (PDOException $e) {
    jsonErro('Erro ao salvar configurações: ' . $e->getMessage(), 500);
}
