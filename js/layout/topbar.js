/* =========================================================
   topbar.js
   Projeto: AMBC-V2
   Descricao: Controla comportamento da barra superior:
              - Botao hamburguer (abre/fecha sidebar no mobile)
              - Overlay (fecha sidebar ao clicar fora)
              - Tecla ESC (fecha sidebar)
              - Atualizacao do titulo da pagina conforme a rota
========================================================= */

/* ---------------------------------------------------------
   1. CONSTANTES INTERNAS
--------------------------------------------------------- */
const SELETOR_SIDEBAR = '#sidebar';
const SELETOR_OVERLAY = '#overlay-sidebar';
const SELETOR_BOTAO_TOGGLE = '#btn-toggle-sidebar';
const SELETOR_TITULO = '#topbar-titulo';

const CLASSE_SIDEBAR_ABERTA = 'is-aberta';
const CLASSE_OVERLAY_VISIVEL = 'is-visivel';

const BREAKPOINT_MOBILE = 1024; // alinhado com o CSS do app-shell

/* ---------------------------------------------------------
   2. MAPA DE TITULOS POR ROTA
   (atualiza o <h1> da topbar conforme a navegacao)
--------------------------------------------------------- */
const TITULOS_ROTAS = {
  '#/dashboard': 'Painel',
  '#/cadastro/listar': 'Cadastro — Listar Todos',
  '#/cadastro/novo-associado': 'Cadastro — Novo Associado',
  '#/cadastro/novo-parceiro': 'Cadastro — Novo Parceiro',
  '#/financeiro/visao-geral': 'Financeiro — Visão Geral',
  '#/financeiro/novo-lancamento': 'Financeiro — Novo Lançamento',
  '#/financeiro/relatorios': 'Financeiro — Relatórios',
  '#/financeiro/contas-regentes': 'Financeiro — Contas Regentes',
  '#/financeiro/contas-subordinadas': 'Financeiro — Contas Subordinadas',
  '#/tabelas/ver': 'Tabelas Auxiliares',
  '#/configuracoes/associacao': 'Configurações — Associação',
  '#/configuracoes/relacionamentos': 'Configurações — Relacionamentos',
  '#/configuracoes/config-gerais': 'Configurações — Gerais'
};

/* ---------------------------------------------------------
   3. FUNCAO: verifica se estamos em tela mobile
--------------------------------------------------------- */
function ehMobile() {
  return window.innerWidth <= BREAKPOINT_MOBILE;
}

/* ---------------------------------------------------------
   4. FUNCAO: abre a sidebar (mobile)
--------------------------------------------------------- */
function abrirSidebar() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  const overlay = document.querySelector(SELETOR_OVERLAY);
  const botao = document.querySelector(SELETOR_BOTAO_TOGGLE);

  if (sidebar) sidebar.classList.add(CLASSE_SIDEBAR_ABERTA);
  if (overlay) {
    overlay.classList.add(CLASSE_OVERLAY_VISIVEL);
    overlay.setAttribute('aria-hidden', 'false');
  }
  if (botao) {
    botao.setAttribute('aria-expanded', 'true');
    botao.setAttribute('aria-label', 'Fechar menu');
  }

  // Trava o scroll do body enquanto o menu esta aberto
  document.body.style.overflow = 'hidden';
}

/* ---------------------------------------------------------
   5. FUNCAO: fecha a sidebar (mobile)
--------------------------------------------------------- */
function fecharSidebar() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  const overlay = document.querySelector(SELETOR_OVERLAY);
  const botao = document.querySelector(SELETOR_BOTAO_TOGGLE);

  if (sidebar) sidebar.classList.remove(CLASSE_SIDEBAR_ABERTA);
  if (overlay) {
    overlay.classList.remove(CLASSE_OVERLAY_VISIVEL);
    overlay.setAttribute('aria-hidden', 'true');
  }
  if (botao) {
    botao.setAttribute('aria-expanded', 'false');
    botao.setAttribute('aria-label', 'Abrir menu');
  }

  // Libera o scroll do body
  document.body.style.overflow = '';
}

/* ---------------------------------------------------------
   6. FUNCAO: alterna abrir/fechar sidebar
--------------------------------------------------------- */
function alternarSidebar() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (!sidebar) return;

  const estaAberta = sidebar.classList.contains(CLASSE_SIDEBAR_ABERTA);

  if (estaAberta) {
    fecharSidebar();
  } else {
    abrirSidebar();
  }
}

/* ---------------------------------------------------------
   7. FUNCAO: atualiza titulo da topbar conforme a rota
--------------------------------------------------------- */
function atualizarTitulo() {
  const tituloEl = document.querySelector(SELETOR_TITULO);
  if (!tituloEl) return;

  const hashAtual = window.location.hash || '#/dashboard';
  const novoTitulo = TITULOS_ROTAS[hashAtual] || 'AMBC';

  tituloEl.textContent = novoTitulo;
  document.title = `${novoTitulo} | AMBC`;
}

/* ---------------------------------------------------------
   8. FUNCAO: trata tecla ESC (fecha sidebar no mobile)
--------------------------------------------------------- */
function tratarTeclaEsc(evento) {
  if (evento.key !== 'Escape') return;
  if (!ehMobile()) return;

  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (sidebar && sidebar.classList.contains(CLASSE_SIDEBAR_ABERTA)) {
    fecharSidebar();
  }
}

/* ---------------------------------------------------------
   9. FUNCAO: trata redimensionamento da janela
   (se o usuario passar do mobile pro desktop com o menu
    aberto, limpa os estilos pra nao travar o scroll)
--------------------------------------------------------- */
function tratarResize() {
  if (!ehMobile()) {
    // Voltou pro desktop: reseta tudo
    fecharSidebar();
  }
}

/* ---------------------------------------------------------
   10. FUNCAO PUBLICA: inicializa a topbar
--------------------------------------------------------- */
function iniciar() {
  const botao = document.querySelector(SELETOR_BOTAO_TOGGLE);
  const overlay = document.querySelector(SELETOR_OVERLAY);

  if (!botao) {
    console.error('[Topbar] Botao #btn-toggle-sidebar nao encontrado!');
    return;
  }

  if (!overlay) {
    console.error('[Topbar] Overlay #overlay-sidebar nao encontrado!');
    return;
  }

  // Botao hamburguer → alterna sidebar
  botao.addEventListener('click', alternarSidebar);

  // Clique no overlay → fecha sidebar
  overlay.addEventListener('click', fecharSidebar);

  // Tecla ESC → fecha sidebar
  document.addEventListener('keydown', tratarTeclaEsc);

  // Redimensionamento → limpa estado se sair do mobile
  window.addEventListener('resize', tratarResize);

  // Atualiza titulo na troca de rota
  window.addEventListener('hashchange', atualizarTitulo);

  // Atualiza titulo na carga inicial
  atualizarTitulo();

  console.log('[Topbar] Inicializada com sucesso');
}

/* ---------------------------------------------------------
   11. EXPORT
--------------------------------------------------------- */
export default {
  iniciar,
  abrirSidebar,
  fecharSidebar,
  alternarSidebar
};
