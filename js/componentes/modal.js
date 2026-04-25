/* ==========================================================================
   AMBC - Componente: Modal
   Arquivo: js/componentes/modal.js
   Descrição: API para abrir/fechar modais <dialog> + modal de confirmação dinâmico
   ========================================================================== */

const Modal = {
  /**
   * Abre um modal pelo ID
   * @param {string} id - ID do elemento <dialog>
   */
  abrir(id) {
    const el = document.getElementById(id);
    if (!el) {
      console.warn(`[Modal] Elemento com ID "${id}" não encontrado.`);
      return;
    }
    if (typeof el.showModal !== 'function') {
      console.warn('[Modal] <dialog> não suportado neste navegador.');
      return;
    }
    el.showModal();
    this._configurarFechamentoBackdrop(el);
  },

  /**
   * Fecha um modal pelo ID
   * @param {string} id - ID do elemento <dialog>
   */
  fechar(id) {
    const el = document.getElementById(id);
    if (el && el.open) el.close();
  },

  /**
   * Abre um modal de confirmação dinâmico (criado via JS)
   * @param {Object} opcoes
   * @param {string} opcoes.titulo - Título do modal
   * @param {string} opcoes.mensagem - Mensagem exibida
   * @param {string} [opcoes.icone='help'] - Ícone (Material Icons)
   * @param {string} [opcoes.variante='info'] - 'info' | 'sucesso' | 'alerta' | 'erro'
   * @param {string} [opcoes.textoConfirmar='Confirmar'] - Texto do botão de confirmar
   * @param {string} [opcoes.textoCancelar='Cancelar'] - Texto do botão de cancelar
   * @param {string} [opcoes.estiloConfirmar='primario'] - 'primario' | 'perigo' | 'sucesso'
   * @param {Function} [opcoes.aoConfirmar] - Callback ao confirmar
   * @param {Function} [opcoes.aoCancelar] - Callback ao cancelar
   */
  confirmar(opcoes = {}) {
    const {
      titulo = 'Confirmar ação',
      mensagem = 'Tem certeza que deseja prosseguir?',
      icone = 'help_outline',
      variante = 'info',
      textoConfirmar = 'Confirmar',
      textoCancelar = 'Cancelar',
      estiloConfirmar = 'primario',
      aoConfirmar = null,
      aoCancelar = null,
    } = opcoes;

    // Cria o dialog dinamicamente
    const dialog = document.createElement('dialog');
    dialog.className = 'modal modal-sm modal-confirmacao';

    dialog.innerHTML = `
      <div class="modal__corpo">
        <div class="modal-confirmacao__icone modal-confirmacao__icone-${variante}">
          <span class="mi material-icons">${icone}</span>
        </div>
        <div class="modal-confirmacao__texto">
          <p class="modal-confirmacao__titulo">${titulo}</p>
          <p class="modal-confirmacao__mensagem">${mensagem}</p>
        </div>
      </div>
      <div class="modal__rodape">
        <button type="button" class="btn btn-secundario" data-acao="cancelar">${textoCancelar}</button>
        <button type="button" class="btn btn-${estiloConfirmar}" data-acao="confirmar">${textoConfirmar}</button>
      </div>
    `;

    document.body.appendChild(dialog);

    // Eventos dos botões
    dialog.querySelector('[data-acao="confirmar"]').addEventListener('click', () => {
      dialog.close('confirmado');
    });

    dialog.querySelector('[data-acao="cancelar"]').addEventListener('click', () => {
      dialog.close('cancelado');
    });

    // Ao fechar — dispara callback e remove do DOM
    dialog.addEventListener('close', () => {
      if (dialog.returnValue === 'confirmado' && typeof aoConfirmar === 'function') {
        aoConfirmar();
      } else if (typeof aoCancelar === 'function') {
        aoCancelar();
      }
      // Remove após animação
      setTimeout(() => dialog.remove(), 200);
    });

    dialog.showModal();
    this._configurarFechamentoBackdrop(dialog);
  },

  /**
   * Configura o fechamento ao clicar no backdrop
   * @private
   */
  _configurarFechamentoBackdrop(dialog) {
    if (dialog.dataset.backdropConfigurado === 'true') return;

    dialog.addEventListener('click', (e) => {
      // Só fecha se o clique for no próprio dialog (backdrop), não no conteúdo
      const rect = dialog.getBoundingClientRect();
      const clicouDentro =
        e.clientX >= rect.left &&
        e.clientX <= rect.right &&
        e.clientY >= rect.top &&
        e.clientY <= rect.bottom;

      if (!clicouDentro) {
        dialog.close('backdrop');
      }
    });

    dialog.dataset.backdropConfigurado = 'true';
  },

  /**
   * Inicializa listeners globais (botões com data-modal-abrir, data-modal-fechar)
   * Chamar uma vez ao carregar a página
   */
  inicializar() {
    // Abrir modal: <button data-modal-abrir="id-do-modal">
    document.addEventListener('click', (e) => {
      const btnAbrir = e.target.closest('[data-modal-abrir]');
      if (btnAbrir) {
        e.preventDefault();
        this.abrir(btnAbrir.dataset.modalAbrir);
        return;
      }

      const btnFechar = e.target.closest('[data-modal-fechar]');
      if (btnFechar) {
        e.preventDefault();
        const dialog = btnFechar.closest('dialog');
        if (dialog) dialog.close();
      }
    });
  },
};

// Auto-inicializa
Modal.inicializar();

export default Modal;
