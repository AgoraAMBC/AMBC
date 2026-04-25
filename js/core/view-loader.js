/* ═══════════════════════════════════════════════════════════
   VIEW LOADER
   ═══════════════════════════════════════════════════════════
   Responsável por carregar arquivos HTML de views via fetch
   e injetá-los em um container do DOM.
   
   Usa cache em memória para evitar requisições repetidas.
   ═══════════════════════════════════════════════════════════ */

const ViewLoader = (function () {
  'use strict';

  // Cache de views já carregadas (evita refetch)
  const cache = new Map();

  /**
   * Carrega uma view e injeta no container especificado.
   * @param {string} caminho - Ex: 'views/listar-todos.html'
   * @param {string|HTMLElement} container - ID ou elemento alvo
   * @returns {Promise<void>}
   */
  async function carregar(caminho, container) {
    const alvo = typeof container === 'string'
      ? document.getElementById(container)
      : container;

    if (!alvo) {
      throw new Error(`[ViewLoader] Container não encontrado: ${container}`);
    }

    try {
      const html = await obterHtml(caminho);
      alvo.innerHTML = html;
    } catch (erro) {
      alvo.innerHTML = montarHtmlErro(caminho, erro.message);
      throw erro;
    }
  }

  /**
   * Obtém o HTML — do cache ou via fetch.
   */
  async function obterHtml(caminho) {
    if (cache.has(caminho)) {
      return cache.get(caminho);
    }

    const resposta = await fetch(caminho);
    if (!resposta.ok) {
      throw new Error(`HTTP ${resposta.status} ao carregar ${caminho}`);
    }

    const html = await resposta.text();
    cache.set(caminho, html);
    return html;
  }

  /**
   * HTML de fallback quando uma view falha ao carregar.
   */
  function montarHtmlErro(caminho, mensagem) {
    return `
      <div style="padding: 2rem; text-align: center; color: #991b1b;">
        <span class="material-icons" style="font-size: 3rem;">error_outline</span>
        <h2>Erro ao carregar a página</h2>
        <p><strong>View:</strong> ${caminho}</p>
        <p><small>${mensagem}</small></p>
        <p><small>Verifique se você está rodando via servidor local (não <code>file://</code>).</small></p>
      </div>
    `;
  }

  /**
   * Limpa o cache (útil em desenvolvimento).
   */
  function limparCache() {
    cache.clear();
  }

  return {
    carregar:    carregar,
    limparCache: limparCache
  };

})();
