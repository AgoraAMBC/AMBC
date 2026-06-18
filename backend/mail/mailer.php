<?php
declare(strict_types=1);

/**
 * Cliente SMTP puro para Gmail (STARTTLS na porta 587).
 * Sem dependências externas — usa apenas funções nativas do PHP.
 *
 * Requer no .env:
 *   MAIL_HOST, MAIL_PORT, MAIL_USER, MAIL_PASS, MAIL_FROM, MAIL_FROM_NAME
 */
class Mailer
{
    private string $host;
    private int    $port;
    private string $user;
    private string $pass;
    private string $from;
    private string $fromName;

    public function __construct()
    {
        $this->host     = $_ENV['MAIL_HOST']      ?? 'smtp.gmail.com';
        $this->port     = (int)($_ENV['MAIL_PORT'] ?? 587);
        $this->user     = $_ENV['MAIL_USER']      ?? '';
        $this->pass     = $_ENV['MAIL_PASS']      ?? '';
        $this->from     = $_ENV['MAIL_FROM']      ?? $this->user;
        $this->fromName = $_ENV['MAIL_FROM_NAME'] ?? 'AMBC';
    }

    public function configurado(): bool
    {
        return $this->user !== '' && $this->pass !== ''
            && $this->user !== 'seuemail@gmail.com';
    }

    /**
     * @throws RuntimeException em caso de falha SMTP
     */
    public function enviar(string $para, string $assunto, string $corpoHtml): void
    {
        if (!$this->configurado()) {
            throw new RuntimeException('Credenciais SMTP não configuradas no .env');
        }

        $socket = @stream_socket_client(
            "tcp://{$this->host}:{$this->port}",
            $errno, $errstr, 15
        );
        if (!$socket) {
            throw new RuntimeException("Falha ao conectar ao SMTP: {$errstr} ({$errno})");
        }

        stream_set_timeout($socket, 15);

        try {
            $this->ler($socket);                              // 220 greeting
            $this->cmd($socket, 'EHLO localhost');            // 250-...
            $this->cmd($socket, 'STARTTLS');                  // 220 Go ahead
            stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT);
            $this->cmd($socket, 'EHLO localhost');            // 250-... (pós-TLS)
            $this->cmd($socket, 'AUTH LOGIN');                // 334 Username:
            $this->cmd($socket, base64_encode($this->user));  // 334 Password:
            $this->cmd($socket, base64_encode($this->pass));  // 235 Authenticated
            $this->cmd($socket, "MAIL FROM:<{$this->from}>"); // 250 OK
            $this->cmd($socket, "RCPT TO:<{$para}>");         // 250 OK
            $this->cmd($socket, 'DATA');                      // 354 Start input

            $mensagem = $this->montarMensagem($para, $assunto, $corpoHtml);
            fwrite($socket, $mensagem . "\r\n.\r\n");
            $this->ler($socket); // 250 OK

            $this->cmd($socket, 'QUIT');
        } finally {
            fclose($socket);
        }
    }

    private function montarMensagem(string $para, string $assunto, string $corpoHtml): string
    {
        $nomeFrom   = mb_encode_mimeheader($this->fromName, 'UTF-8', 'B');
        $assuntoCod = mb_encode_mimeheader($assunto, 'UTF-8', 'B');

        return "From: {$nomeFrom} <{$this->from}>\r\n"
             . "To: <{$para}>\r\n"
             . "Subject: {$assuntoCod}\r\n"
             . "Date: " . date('r') . "\r\n"
             . "MIME-Version: 1.0\r\n"
             . "Content-Type: text/html; charset=UTF-8\r\n"
             . "Content-Transfer-Encoding: base64\r\n"
             . "\r\n"
             . chunk_split(base64_encode($corpoHtml));
    }

    private function cmd($socket, string $cmd): string
    {
        fwrite($socket, $cmd . "\r\n");
        return $this->ler($socket);
    }

    private function ler($socket): string
    {
        $resp = '';
        while ($linha = fgets($socket, 515)) {
            $resp .= $linha;
            // Linha final de resposta tem espaço na posição 3 (ex: "250 OK"); continuação tem "-"
            if (strlen($linha) >= 4 && $linha[3] === ' ') break;
        }
        return $resp;
    }
}
