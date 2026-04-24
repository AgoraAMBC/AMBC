/* ==========================================================================
   AMBC - Página: Showcase de Componentes
   Arquivo: js/paginas/showcase.js
   Descrição: Controller da página de vitrine dos componentes.
   ========================================================================== */

/**
 * Inicializa interações da página de showcase.
 * Chamado pelo router após o HTML da view ser injetado no DOM.
 */
function init() {
  console.log('[Showcase] Página carregada ✅');

  ativarBotoesFechar();
  ativarDemoValidacao();
}

/**
 * Limpeza ao sair da página (chamado pelo router antes de trocar de rota).
 */
function destroy() {
  console.log('[Showcase] Página destruída 👋');
  // Nada específico a limpar por enquanto — listeners morrem junto com o DOM.
}

/**
 * Faz os alertas com botão "X" desaparecerem ao clicar.
 */
function ativarBotoesFechar() {
  const botoes = document.querySelectorAll('.alerta__fechar');

  botoes.forEach((btn) => {
    btn.addEventListener('click', () => {
      const alerta = btn.closest('.alerta');
      if (!alerta) return;

      alerta.style.transition = 'opacity 200ms ease';
      alerta.style.opacity = '0';

      setTimeout(() => alerta.remove(), 220);
    });
  });
}

/**
 * Demo simples: alterna classe .invalido/.valido no input com data-demo="validacao".
 */
function ativarDemoValidacao() {
  const input = document.querySelector('[data-demo="validacao"]');
  if (!input) return;

  input.addEventListener('blur', () => {
    const valor = input.value.trim();
    input.classList.remove('invalido', 'valido');

    if (valor.length === 0) return;
    if (valor.length < 3) {
      input.classList.add('invalido');
    } else {
      input.classList.add('valido');
    }
  });
}

/* ---------------------------------------------------------
   EXPORT (padrão ES6 Module)
--------------------------------------------------------- */
export default {
  init,
  destroy
};
