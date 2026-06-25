/* =========================================================
   topbar.js
   Projeto: AMBC-V2
   Descricao: Controla comportamento da barra superior:
              - Botao hamburguer (abre/fecha sidebar no mobile)
              - Overlay (fecha sidebar ao clicar fora)
              - Tecla ESC (fecha sidebar)
              - Atualizacao do titulo da pagina conforme a rota
              - Exibicao dos dados do usuario logado
========================================================= */

import Sessao from '../core/sessao.js';
import { api } from '../services/api.js';

/* ---------------------------------------------------------
   1. CONSTANTES INTERNAS
--------------------------------------------------------- */
const SELETOR_SIDEBAR        = '#sidebar';
const SELETOR_OVERLAY        = '#overlay-sidebar';
const SELETOR_BOTAO_TOGGLE   = '#btn-toggle-sidebar';
const SELETOR_TITULO         = '#topbar-titulo';

// 🆕 Seletores do bloco do usuario logado
const SELETOR_USUARIO_NOME   = '.topbar__usuario-nome';
const SELETOR_USUARIO_CARGO  = '.topbar__usuario-cargo';
const SELETOR_USUARIO_AVATAR = '.topbar__usuario-avatar';

const CLASSE_SIDEBAR_ABERTA  = 'is-aberta';
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
  '#/cadastro/dependentes': 'Cadastro — Dependentes',
  '#/financeiro/visao-geral': 'Financeiro — Visão Geral',
  // '#/financeiro/novo-lancamento': 'Financeiro — Novo Lançamento',
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
  const botao   = document.querySelector(SELETOR_BOTAO_TOGGLE);

  if (sidebar) sidebar.classList.add(CLASSE_SIDEBAR_ABERTA);
  if (overlay) {
    overlay.classList.add(CLASSE_OVERLAY_VISIVEL);
    overlay.setAttribute('aria-hidden', 'false');
  }
  if (botao) {
    botao.setAttribute('aria-expanded', 'true');
    botao.setAttribute('aria-label', 'Fechar menu');
  }

  document.body.style.overflow = 'hidden';
}

/* ---------------------------------------------------------
   5. FUNCAO: fecha a sidebar (mobile)
--------------------------------------------------------- */
function fecharSidebar() {
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  const overlay = document.querySelector(SELETOR_OVERLAY);
  const botao   = document.querySelector(SELETOR_BOTAO_TOGGLE);

  if (sidebar) sidebar.classList.remove(CLASSE_SIDEBAR_ABERTA);
  if (overlay) {
    overlay.classList.remove(CLASSE_OVERLAY_VISIVEL);
    overlay.setAttribute('aria-hidden', 'true');
  }
  if (botao) {
    botao.setAttribute('aria-expanded', 'false');
    botao.setAttribute('aria-label', 'Abrir menu');
  }

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

  const hashAtual  = window.location.hash || '#/dashboard';
  const novoTitulo = TITULOS_ROTAS[hashAtual] || 'AMBC';

  tituloEl.textContent = novoTitulo;
  document.title = `${novoTitulo} | AMBC`;
}

/* ---------------------------------------------------------
   8. 🆕 FUNCAO: atualiza dados do usuario logado na topbar
   - Le os dados via Sessao.obter()
   - Preenche nome, cargo e iniciais do avatar
--------------------------------------------------------- */
function atualizarUsuarioLogado() {
  const usuario = Sessao.obter();
  if (!usuario) return; // sem sessao, nada a fazer (guarda ja redireciona)

  const elNome   = document.querySelector(SELETOR_USUARIO_NOME);
  const elCargo  = document.querySelector(SELETOR_USUARIO_CARGO);
  const elAvatar = document.querySelector(SELETOR_USUARIO_AVATAR);

  if (elNome)   elNome.textContent   = usuario.nome   || '—';
  if (elCargo)  elCargo.textContent  = usuario.perfil || '—';
  if (elAvatar) elAvatar.textContent = Sessao.obterIniciais();
}

/* ---------------------------------------------------------
   9. PAINEL DE NOTIFICAÇÕES
--------------------------------------------------------- */
let _painelAberto = false;

function _tempoRelativo(dataStr) {
  const diff = Math.floor((Date.now() - new Date(dataStr).getTime()) / 1000);
  if (diff < 60)   return 'agora mesmo';
  if (diff < 3600) return `há ${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `há ${Math.floor(diff / 3600)}h`;
  return `há ${Math.floor(diff / 86400)} dia(s)`;
}

function _renderizarNotificacoes(notificacoes) {
  const lista = document.getElementById('lista-notificacoes');
  if (!lista) return;

  if (!notificacoes.length) {
    lista.innerHTML = '<li class="topbar__notif-vazia">Nenhuma notificação</li>';
    return;
  }

  lista.innerHTML = notificacoes.map(n => {
    const naoLida = Number(n.lida) === 0;
    return `
      <li class="topbar__notif-item${naoLida ? ' topbar__notif-item--nao-lida' : ''}">
        <div class="topbar__notif-corpo">
          <div class="topbar__notif-item-titulo">${n.titulo}</div>
          ${n.mensagem ? `<div class="topbar__notif-item-msg">${n.mensagem}</div>` : ''}
          <div class="topbar__notif-item-tempo">${_tempoRelativo(n.criado_em)}</div>
        </div>
        ${naoLida ? '<div class="topbar__notif-dot"></div>' : ''}
      </li>`;
  }).join('');
}

async function abrirPainelNotificacoes() {
  const painel = document.getElementById('painel-notificacoes');
  const btn    = document.getElementById('btn-notificacoes');
  if (!painel) return;

  painel.hidden = false;
  _painelAberto = true;
  btn?.setAttribute('aria-expanded', 'true');

  const lista = document.getElementById('lista-notificacoes');
  if (lista) lista.innerHTML = '<li class="topbar__notif-vazia">Carregando…</li>';

  try {
    const { notificacoes } = await api.get('/notificacoes/listar.php');
    _renderizarNotificacoes(notificacoes);
    // Marca tudo como lido em segundo plano ao abrir
    api.post('/notificacoes/marcar-lidas.php', {}).catch(() => {});
  } catch {
    if (lista) lista.innerHTML = '<li class="topbar__notif-vazia">Erro ao carregar</li>';
  }
}

function fecharPainelNotificacoes() {
  const painel = document.getElementById('painel-notificacoes');
  const btn    = document.getElementById('btn-notificacoes');
  if (!painel) return;

  painel.hidden = true;
  _painelAberto = false;
  btn?.setAttribute('aria-expanded', 'false');
}

function inicializarPainelNotificacoes() {
  const btn    = document.getElementById('btn-notificacoes');
  const painel = document.getElementById('painel-notificacoes');
  if (!btn || !painel) return;

  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    if (_painelAberto) fecharPainelNotificacoes();
    else abrirPainelNotificacoes();
  });

  document.getElementById('link-config-notif')
    ?.addEventListener('click', fecharPainelNotificacoes);

  document.addEventListener('click', (e) => {
    if (_painelAberto && !painel.contains(e.target) && e.target !== btn) {
      fecharPainelNotificacoes();
    }
  });
}

/* ---------------------------------------------------------
   10. FUNCAO: trata tecla ESC (fecha sidebar no mobile)
--------------------------------------------------------- */
function tratarTeclaEsc(evento) {
  if (evento.key !== 'Escape') return;

  if (_painelAberto) {
    fecharPainelNotificacoes();
    return;
  }

  if (!ehMobile()) return;
  const sidebar = document.querySelector(SELETOR_SIDEBAR);
  if (sidebar && sidebar.classList.contains(CLASSE_SIDEBAR_ABERTA)) {
    fecharSidebar();
  }
}

/* ---------------------------------------------------------
   10. FUNCAO: trata redimensionamento da janela
--------------------------------------------------------- */
function tratarResize() {
  if (!ehMobile()) {
    fecharSidebar();
  }
}

/* ---------------------------------------------------------
   11. FUNCAO PUBLICA: inicializa a topbar
--------------------------------------------------------- */
function iniciar() {
  const botao   = document.querySelector(SELETOR_BOTAO_TOGGLE);
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

  // Atualizacoes na carga inicial
  atualizarTitulo();
  atualizarUsuarioLogado();
  inicializarPainelNotificacoes();

  console.log('[Topbar] Inicializada com sucesso');
}

/* ---------------------------------------------------------
   12. EXPORT
--------------------------------------------------------- */
export default {
  iniciar,
  abrirSidebar,
  fecharSidebar,
  alternarSidebar,
  atualizarUsuarioLogado // 🆕 exportado pra usar depois (ex: trocar perfil)
};
