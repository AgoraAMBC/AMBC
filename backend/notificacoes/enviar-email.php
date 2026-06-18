<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../mail/mailer.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body  = corpoJson();
$tipo  = $body['tipo']  ?? '';
$para  = filter_var($body['para'] ?? '', FILTER_VALIDATE_EMAIL);
$dados = $body['dados'] ?? [];

$tiposPermitidos = ['novos_cadastros', 'vencimentos', 'inadimplencia', 'resumo_semanal'];
if (!in_array($tipo, $tiposPermitidos, true)) jsonErro('Tipo de notificação inválido', 400);
if (!$para) jsonErro('E-mail de destino inválido', 400);

try {
    $pdo = obterConexao();

    // Garante que o destinatário é um usuário ativo do sistema
    $stmtUser = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE email = :email AND ativo = 1');
    $stmtUser->execute([':email' => $para]);
    if ((int)$stmtUser->fetchColumn() === 0) jsonErro('Destinatário não é um usuário ativo', 403);

    // Verifica se as duas configurações necessárias estão habilitadas
    $chaveTipo = 'notif_' . $tipo;
    $stmt = $pdo->prepare(
        "SELECT chave, valor FROM configuracoes WHERE chave IN ('notif_enviar_email', :chave_tipo)"
    );
    $stmt->execute([':chave_tipo' => $chaveTipo]);
    $configs = array_column($stmt->fetchAll(), 'valor', 'chave');

    if (($configs['notif_enviar_email'] ?? 'false') !== 'true') {
        jsonResposta(['enviado' => false, 'motivo' => 'Envio por e-mail desativado']);
    }
    if (($configs[$chaveTipo] ?? 'false') !== 'true') {
        jsonResposta(['enviado' => false, 'motivo' => 'Notificação do tipo desativada']);
    }

    [$assunto, $corpo] = montarConteudo($tipo, $dados);

    $mailer = new Mailer();
    $mailer->enviar($para, $assunto, $corpo);

    jsonResposta(['enviado' => true]);

} catch (RuntimeException $e) {
    jsonErro($e->getMessage(), 500);
} catch (Exception $e) {
    jsonErro('Erro interno ao processar notificação', 500);
}

/* -------------------------------------------------------
   Monta assunto + corpo HTML por tipo de notificação
------------------------------------------------------- */
function montarConteudo(string $tipo, array $dados): array
{
    $dataFormatada = date('d/m/Y \à\s H:i');

    switch ($tipo) {
        case 'novos_cadastros':
            $nome      = htmlspecialchars($dados['nome']      ?? '—', ENT_QUOTES, 'UTF-8');
            $matricula = htmlspecialchars($dados['matricula'] ?? '—', ENT_QUOTES, 'UTF-8');
            $assunto   = 'Novo associado cadastrado — AMBC';
            $corpo     = templateBase(
                'Novo Associado Cadastrado',
                "Um novo associado foi registrado no sistema em {$dataFormatada}.",
                [
                    'Nome'       => $nome,
                    'Matrícula'  => $matricula,
                    'Cadastrado' => $dataFormatada,
                ]
            );
            break;

        default:
            $assunto = 'Notificação AMBC';
            $corpo   = templateBase('Notificação', 'Evento registrado em ' . $dataFormatada . '.', []);
    }

    return [$assunto, $corpo];
}

function templateBase(string $titulo, string $intro, array $campos): string
{
    $linhas = '';
    $fundo  = '#f8fafc';
    foreach ($campos as $label => $valor) {
        $linhas .= "
            <tr style=\"background:{$fundo}\">
              <td style=\"padding:10px 14px;font-weight:600;color:#374151;border:1px solid #e2e8f0;white-space:nowrap\">{$label}</td>
              <td style=\"padding:10px 14px;color:#475569;border:1px solid #e2e8f0\">{$valor}</td>
            </tr>";
        $fundo = $fundo === '#f8fafc' ? '#fff' : '#f8fafc';
    }

    $tabelaHtml = $linhas
        ? "<table style=\"width:100%;border-collapse:collapse;margin:20px 0\">{$linhas}</table>"
        : '';

    return "<!DOCTYPE html>
<html lang=\"pt-BR\">
<head><meta charset=\"UTF-8\"></head>
<body style=\"margin:0;padding:0;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif\">
  <div style=\"max-width:600px;margin:32px auto;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)\">
    <div style=\"background:#2563eb;padding:24px 32px\">
      <h1 style=\"color:#fff;margin:0;font-size:18px;font-weight:600;letter-spacing:.5px\">AMBC — Sistema de Gestão</h1>
    </div>
    <div style=\"padding:32px\">
      <h2 style=\"color:#1e293b;margin-top:0;font-size:20px\">{$titulo}</h2>
      <p style=\"color:#475569;margin-bottom:4px\">{$intro}</p>
      {$tabelaHtml}
      <p style=\"color:#94a3b8;font-size:11px;margin-top:28px\">
        E-mail automático gerado pelo sistema AMBC. Não responda esta mensagem.
      </p>
    </div>
  </div>
</body>
</html>";
}
