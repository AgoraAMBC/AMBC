/* =========================================================
   app.js
   Projeto: AMBC-V2
   Descricao: Ponto de entrada da aplicacao.
              Inicializa os modulos de layout e o router.
========================================================= */

import Router from './router.js';
import Sidebar from '../layout/sidebar.js';
import Topbar from '../layout/topbar.js';

/* ---------------------------------------------------------
   Guarda de autenticacao
   Se nao houver sessao valida, redireciona para login.html
--------------------------------------------------------- */
const CHAVE_SESSAO = 'ambc_sessao';

function obterSessao() {
  const raw = localStorage.getItem(CHAVE_SESSAO) || sessionStorage.getItem(CHAVE_SESSAO);
  try { return raw ? JSON.parse(raw) : null; } catch { return null; }
}

const sessao = obterSessao();
if (!sessao) {
  window.location.replace('login.html');
  throw new Error('[Auth] Sessao nao encontrada — redirecionando para login');
}

/* ---------------------------------------------------------
   Inicializacao da aplicacao
--------------------------------------------------------- */
function iniciarApp() {
  console.log('[AMBC-V2] Iniciando aplicacao...');

  // 1. Modulos de layout (devem ser iniciados ANTES do router,
  //    pois escutam 'hashchange' e precisam estar prontos
  //    quando o router disparar a primeira rota)
  Sidebar.iniciar();
  Topbar.iniciar();

  // 2. Roteador SPA
  Router.iniciar();

  console.log('[AMBC-V2] Aplicacao pronta!');
}

/* ---------------------------------------------------------
   Aguarda o DOM estar completamente carregado
--------------------------------------------------------- */
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', iniciarApp);
} else {
  iniciarApp();
}
