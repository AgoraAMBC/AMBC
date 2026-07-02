/* =========================================================
   sidebar.js
   Projeto: AMBC-V2
   Descricao: Controla comportamento do menu lateral:
              - Toggle de submenus (accordion)
              - Destaque do item ativo conforme a rota
              - Fechamento automatico no mobile
              - Acao de logout
========================================================= */
import Sessao from '../core/sessao.js';

/* ---------------------------------------------------------
   1. CONSTANTES INTERNAS
--------------------------------------------------------- */
const SELETOR_SIDEBAR = '#sidebar';
const SELETOR_OVERLAY = '#overlay-sidebar';
const CLASSE_ATIVO = 'is-ativo';
const CLASSE_ABERTO = 'is-aberto';
const CLASSE_SIDEBAR_ABERTA = 'is-aberta'; // usada no mobile (ver etapa futura)
const BREAKPOINT_MOBILE = 1024; // px — alinhado com CSS do app-shell


/* ---------------------------------------------------------
   2. FUNCAO: alterna submenu (abre/fecha)
   Comportamento ACCORDION: so um aberto por vez
--------------------------------------------------------- */
function alternarSubmenu(nomeSubmenu) {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (!sidebar) return;

  const itemAlvo = sidebar.querySelector(`[data-submenu-pai="${nomeSubmenu}"]`);
  if (!itemAlvo) return;

  const estaAberto = itemAlvo.classList.contains(CLASSE_ABERTO);

  // Fecha todos os outros submenus (accordion)
  fecharTodosSubmenus();

  // Se o alvo nao estava aberto, abre ele
  if (!estaAberto) {
    abrirSubmenu(itemAlvo);
  }
}

/* ---------------------------------------------------------
   3. FUNCAO: abre um submenu especifico
--------------------------------------------------------- */
function abrirSubmenu(itemLi) {
  itemLi.classList.add(CLASSE_ABERTO);
  const botao = itemLi.querySelector('[data-toggle-submenu]');
  if (botao) botao.setAttribute('aria-expanded', 'true');
}

/* ---------------------------------------------------------
   4. FUNCAO: fecha todos os submenus
--------------------------------------------------------- */
function fecharTodosSubmenus() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (!sidebar) return;

  const itensAbertos = sidebar.querySelectorAll(`.sidebar__item.${CLASSE_ABERTO}`);
  itensAbertos.forEach((item) => {
    item.classList.remove(CLASSE_ABERTO);
    const botao = item.querySelector('[data-toggle-submenu]');
    if (botao) botao.setAttribute('aria-expanded', 'false');
  });
}

/* ---------------------------------------------------------
   5. FUNCAO: destaca o link ativo baseado na rota atual
--------------------------------------------------------- */
function atualizarLinkAtivo() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (!sidebar) return;

  const hashAtual = window.location.hash || '#/dashboard';

  // Remove 'is-ativo' de todos os links
  const linksAtivos = sidebar.querySelectorAll(`.sidebar__link.${CLASSE_ATIVO}`);
  linksAtivos.forEach((link) => link.classList.remove(CLASSE_ATIVO));

  // Encontra o link da rota atual
  const linkAtivo = sidebar.querySelector(`a.sidebar__link[href="${hashAtual}"]`);

  if (!linkAtivo) {
    console.warn(`[Sidebar] Nenhum link corresponde a rota ${hashAtual}`);
    return;
  }

  linkAtivo.classList.add(CLASSE_ATIVO);

  // Se o link estiver dentro de um submenu, abre o submenu pai
  const submenuPai = linkAtivo.closest('.sidebar__submenu');
  if (submenuPai) {
    const itemPai = submenuPai.closest('.sidebar__item');
    if (itemPai) {
      // Fecha outros e abre apenas o pai do ativo
      fecharTodosSubmenus();
      abrirSubmenu(itemPai);
    }
  } else {
    // Link de nivel 1 (sem submenu) → fecha todos os submenus
    fecharTodosSubmenus();
  }
}

/* ---------------------------------------------------------
   6. FUNCAO: fecha sidebar no mobile
--------------------------------------------------------- */
function fecharSidebarMobile() {
  if (window.innerWidth > BREAKPOINT_MOBILE) return;

  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  const overlay = document.querySelector(SELETOR_OVERLAY);

  if (sidebar) sidebar.classList.remove(CLASSE_SIDEBAR_ABERTA);
  if (overlay) {
    overlay.classList.remove('is-visivel');
    overlay.setAttribute('aria-hidden', 'true');
  }
  document.body.style.overflow = '';
}

/* ---------------------------------------------------------
   7. FUNCAO: trata acao de logout
--------------------------------------------------------- */
function tratarLogout() {
  console.log('[Sidebar] Logout solicitado');

  const confirmou = window.confirm('Deseja realmente sair do sistema?');
  if (!confirmou) {
    console.log('[Sidebar] Logout cancelado pelo usuario');
    return;
  }

  console.log('[Sidebar] Encerrando sessao...');
  Sessao.encerrar(); // 🆕 usa o modulo central (limpa storage + redireciona)
}
/* ---------------------------------------------------------
   8. FUNCAO: trata cliques na sidebar (delegation)
--------------------------------------------------------- */
function tratarCliqueSidebar(evento) {
  const alvo = evento.target.closest('[data-toggle-submenu], [data-action="logout"], a.sidebar__link');
  if (!alvo) return;

  // --- Botao de toggle de submenu ---
  if (alvo.hasAttribute('data-toggle-submenu')) {
    evento.preventDefault();
    const nomeSubmenu = alvo.getAttribute('data-toggle-submenu');
    alternarSubmenu(nomeSubmenu);
    return;
  }

  // --- Botao de logout ---
  if (alvo.getAttribute('data-action') === 'logout') {
    evento.preventDefault();
    tratarLogout();
    return;
  }

  // --- Link de navegacao (vai pro router via hashchange) ---
  // Nao precisa de preventDefault — deixa o href atuar normalmente.
  // Apenas fecha a sidebar no mobile.
  fecharSidebarMobile();
}

/* ---------------------------------------------------------
   9. FUNCAO PUBLICA: inicializa a sidebar
--------------------------------------------------------- */
function iniciar() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);

  if (!sidebar) {
    console.error('[Sidebar] Elemento #sidebar nao encontrado no DOM!');
    return;
  }

  // Delegation: um unico listener pra todos os cliques
  sidebar.addEventListener('click', tratarCliqueSidebar);

  // Escuta mudancas de rota pra atualizar item ativo
  window.addEventListener('hashchange', atualizarLinkAtivo);

  // Atualiza na carga inicial
  atualizarLinkAtivo();

  console.log('[Sidebar] Inicializada com sucesso');
}

/* ---------------------------------------------------------
   10. EXPORT
--------------------------------------------------------- */
export default {
  iniciar,
  atualizarLinkAtivo,
  fecharTodosSubmenus
};
