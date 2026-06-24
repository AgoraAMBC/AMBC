/* =========================================================
   app.js
   Projeto: AMBC-V2
   Descricao: Ponto de entrada da aplicacao.
              Inicializa os modulos de layout e o router.
========================================================= */

import Sessao  from './sessao.js?v=2';
import Router  from './router.js?v=3';
import Sidebar from '../layout/sidebar.js';
import Topbar  from '../layout/topbar.js';
import { configurar } from './formatadores.js';
import { ConfiguracoesService } from '../services/configuracoes-service.js';
import { aplicarFavicon, aplicarTema } from '../paginas/configuracoes.js';

/* ---------------------------------------------------------
   1. Guarda de autenticacao
      Se nao houver sessao valida, redireciona pro login.
      Deve ser a PRIMEIRA coisa a executar.
--------------------------------------------------------- */
Sessao.exigirAutenticacao();

/* ---------------------------------------------------------
   2. Carregar logo da associacao ao iniciar
--------------------------------------------------------- */
async function inicializarLogoSidebar() {
  const logoContainer = document.getElementById('sidebar-logo-container');
  if (!logoContainer) return;

  try {
    const config = await ConfiguracoesService.obter();
    if (config.logo) {
      logoContainer.innerHTML = `<img src="${config.logo}" alt="Logo" class="sidebar__logo-img" />`;
    } else {
      logoContainer.innerHTML = '<span class="sidebar__logo-texto">A</span>';
    }
  } catch (erro) {
    console.warn('[App] Erro ao carregar logo:', erro);
    logoContainer.innerHTML = '<span class="sidebar__logo-texto">A</span>';
  }
}

/* ---------------------------------------------------------
   3. Inicializacao da aplicacao
--------------------------------------------------------- */
async function iniciarApp() {
  console.log('[AMBC-V2] Iniciando aplicacao...');
  console.log('[AMBC-V2] Usuario logado:', Sessao.obter()?.nome);

  // Carrega preferências antes do router para que formatadores já estejam configurados
  try {
    const configs = await ConfiguracoesService.obter();
    configurar(configs.fuso_horario, configs.formato_data);
    aplicarFavicon(configs.favicon || null);
    aplicarTema(configs.tema || 'claro');
    if (configs.seg_expirar_sessao === 'true') {
      Sessao.iniciarTimerInatividade();
    }
  } catch {
    // Falha silenciosa — formatadores usam os defaults (America/Sao_Paulo, DD/MM/YYYY)
  }

  // Carregar logo da associação (assíncrono)
  await inicializarLogoSidebar();

  // Modulos de layout (antes do router, pois escutam hashchange)
  Sidebar.iniciar();
  Topbar.iniciar();

  // Oculta itens restritos a administradores para outros perfis
  const perfil = Sessao.obter()?.fk_perfil;
  document.querySelectorAll('[data-apenas-admin]').forEach((el) => {
    el.hidden = perfil !== 1;
  });

  // Oculta itens que exigem permissão de edição no módulo indicado
  document.querySelectorAll('[data-requer-editar]').forEach((el) => {
    const moduloId = Number(el.dataset.requerEditar);
    if (!Sessao.temPermissao(moduloId, 'pode_editar')) {
      el.hidden = true;
    }
  });

  // Roteador SPA
  Router.iniciar();

  console.log('[AMBC-V2] Aplicacao pronta!');
}

/* ---------------------------------------------------------
   4. Aguarda o DOM estar completamente carregado
--------------------------------------------------------- */
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', iniciarApp);
} else {
  iniciarApp();
}
