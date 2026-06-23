<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../mail/mailer.php';

configurarCors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonErro('Método não permitido', 405);

$body  = corpoJson();
$email = filter_var($body['email'] ?? '', FILTER_VALIDATE_EMAIL);

if (!$email) jsonErro('Informe um e-mail válido.', 400);

try {
    $pdo = obterConexao();

    // Verifica se o e-mail pertence a um usuário ativo
    $stmt = $pdo->prepare('SELECT id_usuario, nome FROM usuario WHERE email = :email AND ativo = 1');
    $stmt->execute([':email' => $email]);
    $usuario = $stmt->fetch();

    if (!$usuario) {
        // Não revela se o e-mail existe ou não por segurança
        jsonResposta(['enviado' => true, 'mensagem' => 'Se o e-mail existir no sistema, você receberá as instruções.']);
    }

    // Gera token seguro
    $token = bin2hex(random_bytes(32));
    $expira = date('Y-m-d H:i:s', strtotime('+1 hour'));

    $stmt = $pdo->prepare('UPDATE usuario SET token_reset = :token, token_expira_em = :expira WHERE id_usuario = :id');
    $stmt->execute([':token' => $token, ':expira' => $expira, ':id' => $usuario['id_usuario']]);

    // Tenta enviar e-mail
    try {
        $mailer = new Mailer();
        $link = "http://localhost:5500/redefinir-senha.html?token=" . urlencode($token) . "&email=" . urlencode($email);

        $assunto = 'Recuperação de Senha — AMBC';
        $corpo = "<!DOCTYPE html>
<html lang=\"pt-BR\">
<head><meta charset=\"UTF-8\"></head>
<body style=\"margin:0;padding:0;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif\">
  <div style=\"max-width:600px;margin:32px auto;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)\">
    <div style=\"background:#2563eb;padding:24px 32px\">
      <h1 style=\"color:#fff;margin:0;font-size:18px;font-weight:600\">AMBC — Recuperação de Senha</h1>
    </div>
    <div style=\"padding:32px\">
      <h2 style=\"color:#1e293b;margin-top:0;font-size:20px\">Olá, " . htmlspecialchars($usuario['nome'], ENT_QUOTES, 'UTF-8') . "</h2>
      <p style=\"color:#475569\">Recebemos uma solicitação de recuperação de senha para sua conta.</p>
      <p style=\"color:#475569\">Clique no link abaixo para redefinir sua senha. Este link expira em 1 hora.</p>
      <div style=\"text-align:center;margin:28px 0\">
        <a href=\"{$link}\" style=\"display:inline-block;padding:14px 32px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;font-weight:600\">Redefinir Senha</a>
      </div>
      <p style=\"color:#475569;font-size:13px\">Se você não solicitou esta recuperação, ignore este e-mail.</p>
      <p style=\"color:#94a3b8;font-size:11px;margin-top:28px\">
        E-mail automático gerado pelo sistema AMBC. Não responda esta mensagem.
      </p>
    </div>
  </div>
</body>
</html>";

        $mailer->enviar($email, $assunto, $corpo);
    } catch (RuntimeException $e) {
        // Falha no envio — não bloqueia a resposta, mas registra
        error_log('[Recuperar Senha] Erro ao enviar e-mail: ' . $e->getMessage());
    }

    jsonResposta(['enviado' => true, 'mensagem' => 'Se o e-mail existir no sistema, você receberá as instruções.']);

} catch (Exception $e) {
    jsonErro('Erro interno ao processar solicitação.', 500);
}
