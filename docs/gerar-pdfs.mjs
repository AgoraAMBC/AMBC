import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import puppeteer from 'puppeteer';

const __dir = dirname(fileURLToPath(import.meta.url));

const diagramas = [
  {
    arquivo: 'diagrama-casos-de-uso.mmd',
    titulo: 'Diagrama de Casos de Uso',
    subtitulo: 'AMBC — Associação de Moradores do Bairro Califórnia',
    saida: 'diagrama-casos-de-uso.pdf',
    largura: 2400,
    altura: 1600,
  },
  {
    arquivo: 'modelo-conceitual.mmd',
    titulo: 'Modelo Conceitual do Banco de Dados',
    subtitulo: 'AMBC — Associação de Moradores do Bairro Califórnia',
    saida: 'modelo-conceitual.pdf',
    largura: 2200,
    altura: 2800,
  },
];

function escaparHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function gerarHtml(titulo, subtitulo, mermaidCode, largura, altura) {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background: #fff;
      padding: 32px 40px 40px;
      width: ${largura}px;
    }
    .cabecalho {
      border-bottom: 3px solid #2563eb;
      padding-bottom: 16px;
      margin-bottom: 28px;
    }
    .cabecalho h1 {
      font-size: 26px;
      font-weight: 700;
      color: #0f172a;
    }
    .cabecalho p {
      font-size: 14px;
      color: #64748b;
      margin-top: 4px;
    }
    .cabecalho .meta {
      font-size: 12px;
      color: #94a3b8;
      margin-top: 6px;
    }
    .diagrama {
      display: flex;
      justify-content: center;
      align-items: flex-start;
    }
    .diagrama svg {
      max-width: 100%;
      height: auto;
    }
    .rodape {
      border-top: 1px solid #e2e8f0;
      padding-top: 12px;
      margin-top: 28px;
      font-size: 11px;
      color: #94a3b8;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="cabecalho">
    <h1>${titulo}</h1>
    <p>${subtitulo}</p>
    <p class="meta">Gerado em ${new Date().toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })}</p>
  </div>
  <div class="diagrama">
    <pre class="mermaid">${escaparHtml(mermaidCode)}</pre>
  </div>
  <div class="rodape">AMBC V2 — Sistema de Gestão da Associação de Moradores do Bairro Califórnia</div>
  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
    mermaid.initialize({
      startOnLoad: true,
      theme: 'default',
      themeVariables: {
        primaryColor: '#dbeafe',
        primaryTextColor: '#0f172a',
        primaryBorderColor: '#2563eb',
        lineColor: '#64748b',
        secondaryColor: '#f1f5f9',
        tertiaryColor: '#f8fafc',
        fontSize: '14px',
      },
      er: { useMaxWidth: false },
      flowchart: { useMaxWidth: false },
    });
  </script>
</body>
</html>`;
}

async function gerarPdf({ arquivo, titulo, subtitulo, saida, largura, altura }) {
  const mmd = readFileSync(join(__dir, arquivo), 'utf8');
  const html = gerarHtml(titulo, subtitulo, mmd, largura, altura);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();

  await page.setViewport({ width: largura, height: altura });
  await page.setContent(html, { waitUntil: 'networkidle0' });

  // Aguarda o Mermaid renderizar
  await page.waitForSelector('.mermaid svg', { timeout: 30000 });
  await new Promise(r => setTimeout(r, 1500));

  // Altura real do conteúdo
  const alturaReal = await page.evaluate(() => document.body.scrollHeight);

  const pdf = await page.pdf({
    width: `${largura}px`,
    height: `${alturaReal + 40}px`,
    printBackground: true,
    margin: { top: '0', right: '0', bottom: '0', left: '0' },
  });

  await browser.close();

  const caminhoSaida = join(__dir, saida);
  writeFileSync(caminhoSaida, pdf);
  console.log(`✓ ${saida} gerado (${(pdf.length / 1024).toFixed(0)} KB)`);
}

(async () => {
  for (const d of diagramas) {
    console.log(`→ Gerando ${d.saida}...`);
    await gerarPdf(d);
  }
  console.log('\nPDFs salvos em docs/');
})();
