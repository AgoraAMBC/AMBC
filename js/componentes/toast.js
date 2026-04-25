/* ==========================================================================
   AMBC - Componente: Toast
   Arquivo: js/componentes/toast.js
   Descrição: Sistema de notificações flutuantes (sucesso, erro, alerta, info)
   ========================================================================== */

const Toast = {
  // ID do container de toasts (criado dinamicamente)
  _containerId: 'ambc-toast-container',

  // Configurações padrão
  _padrao: {
    duracao: 4000,           // ms — tempo até auto-dismiss
    posicao: 'baixo-direita', // 'baixo-direita' | 'topo-direita' | 'topo-esquerda' | 'baixo-esquerda' | 'topo-centro'
  },

  /**
   * Garante que o container exista no DOM
   * @private
   */
  _garantirContainer() {
    let container = document.getElementById(this._containerId);
    if (!container) {
      container = document.createElement('div');
      container.id = this._containerId;
      container.className = 'toast-container';
      this._aplicarPosicao(container, this._padrao.posicao);
      document.body.appendChild(container);
    }
    return container;
  },

  /**
   * Aplica a classe de posição ao container
   * @private
   */
  _aplicarPosicao(container, posicao) {
    container.classList.remove(
      'toast-container--topo-direita',
      'toast-container--topo-esquerda',
      'toast-container--baixo-esquerda',
      'toast-container--topo-centro'
    );
    if (posicao !== 'baixo-direita') {
      container.classList.add(`toast-container--${posicao}`);
    }
  },

  /**
   * Configura opções globais (posição, duração padrão)
   * @param {Object} opcoes
   */
  configurar(opcoes = {}) {
    Object.assign(this._padrao, opcoes);
    if (opcoes.posicao) {
      const container = this._garantirContainer();
      this._aplicarPosicao(container, opcoes.posicao);
    }
  },

  /**
   * Exibe um toast genérico
   * @param {Object} opcoes
   * @param {string} opcoes.tipo - 'sucesso' | 'erro' | 'alerta' | 'info'
   * @param {string} [opcoes.titulo] - Título opcional
   * @param {string} opcoes.mensagem - Mensagem principal
   * @param {string} [opcoes.icone] - Material icon (auto se não fornecido)
   * @param {number} [opcoes.duracao] - Tempo em ms (0 = não some sozinho)
   * @returns {HTMLElement} O elemento toast criado
   */
  exibir(opcoes = {}) {
    const {
      tipo = 'info',
      titulo = '',
      mensagem = '',
      icone = this._iconePadrao(tipo),
      duracao = this._padrao.duracao,
    } = opcoes;

    const container = this._garantirContainer();

    // Cria o toast
    const toast = document.createElement('div');
    toast.className = `toast toast--${tipo}`;
    toast.setAttribute('role', tipo === 'erro' ? 'alert' : 'status');
    toast.setAttribute('aria-live', tipo === 'erro' ? 'assertive' : 'polite');

    toast.innerHTML = `
      <div class="toast__icone">
        <span class="mi material-icons">${icone}</span>
      </div>
      <div class="toast__conteudo">
        ${titulo ? `<p class="toast__titulo">${this._escapar(titulo)}</p>` : ''}
        <p class="toast__mensagem">${this._escapar(mensagem)}</p>
      </div>
      <button class="toast__fechar" aria-label="Fechar notificação">
        <span class="mi material-icons">close</span>
      </button>
      ${duracao > 0 ? `<div class="toast__progresso" style="animation-duration: ${duracao}ms;"></div>` : ''}
    `;

    container.appendChild(toast);

    // Botão fechar
    toast.querySelector('.toast__fechar').addEventListener('click', () => {
      this._remover(toast);
    });

    // Auto-dismiss
    if (duracao > 0) {
      let timeoutId = setTimeout(() => this._remover(toast), duracao);
      let tempoRestante = duracao;
      let inicio = Date.now();

      // Pausa no hover
      toast.addEventListener('mouseenter', () => {
        clearTimeout(timeoutId);
        tempoRestante -= Date.now() - inicio;
      });

      // Retoma ao sair
      toast.addEventListener('mouseleave', () => {
        inicio = Date.now();
        timeoutId = setTimeout(() => this._remover(toast), tempoRestante);
      });
    }

    return toast;
  },

  /**
   * Remove um toast com animação
   * @private
   */
  _remover(toast) {
    if (!toast || toast.classList.contains('toast--saindo')) return;
    toast.classList.add('toast--saindo');
    toast.addEventListener('animationend', () => toast.remove(), { once: true });
  },

  /**
   * Ícone padrão baseado no tipo
   * @private
   */
  _iconePadrao(tipo) {
    const icones = {
      sucesso: 'check_circle',
      erro: 'error',
      alerta: 'warning',
      info: 'info',
    };
    return icones[tipo] || 'info';
  },

  /**
   * Escapa HTML pra prevenir XSS
   * @private
   */
  _escapar(texto) {
    const div = document.createElement('div');
    div.textContent = String(texto);
    return div.innerHTML;
  },

  // ============================================
  // 🎯 ATALHOS POR TIPO
  // ============================================

  sucesso(mensagem, opcoes = {}) {
    return this.exibir({ ...opcoes, tipo: 'sucesso', mensagem });
  },

  erro(mensagem, opcoes = {}) {
    return this.exibir({ ...opcoes, tipo: 'erro', mensagem });
  },

  alerta(mensagem, opcoes = {}) {
    return this.exibir({ ...opcoes, tipo: 'alerta', mensagem });
  },

  info(mensagem, opcoes = {}) {
    return this.exibir({ ...opcoes, tipo: 'info', mensagem });
  },

  /**
   * Limpa todos os toasts ativos
   */
  limparTodos() {
    const container = document.getElementById(this._containerId);
    if (!container) return;
    container.querySelectorAll('.toast').forEach(t => this._remover(t));
  },
};

export default Toast;
