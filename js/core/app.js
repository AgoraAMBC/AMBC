/* =========================================================
   app.js
   Projeto: AMBC-V2
   Descricao: Ponto de entrada da aplicacao.
              Inicializa os modulos de layout e o router.
========================================================= */

import Sessao  from './sessao.js';
import Router  from './router.js';
import Sidebar from '../layout/sidebar.js';
import Topbar  from '../layout/topbar.js';

/* ---------------------------------------------------------
   1. Guarda de autenticacao
      Se nao houver sessao valida, redireciona pro login.
      Deve ser a PRIMEIRA coisa a executar.
--------------------------------------------------------- */
Sessao.exigirAutenticacao();

/* ---------------------------------------------------------
   2. Inicializacao da aplicacao
--------------------------------------------------------- */
function iniciarApp() {
  console.log('[AMBC-V2] Iniciando aplicacao...');
  console.log('[AMBC-V2] Usuario logado:', Sessao.obter()?.nome);

  // Modulos de layout (antes do router, pois escutam hashchange)
  Sidebar.iniciar();
  Topbar.iniciar();

  // Roteador SPA
  Router.iniciar();

  console.log('[AMBC-V2] Aplicacao pronta!');
}

/* ---------------------------------------------------------
   3. Aguarda o DOM estar completamente carregado
--------------------------------------------------------- */
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', iniciarApp);
} else {
  iniciarApp();
}
