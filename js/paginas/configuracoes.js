/* =========================================================
   Pagina: Configurações (associação, relacionamentos, etc.)
   Projeto: AMBC-V2
   Descricao: Lógica compartilhada das sub-páginas de configurações.
========================================================= */

import Toast from '../componentes/toast.js';
import { ConfiguracoesService } from '../services/configuracoes-service.js';

/* ---------------------------------------------------------
   Funções de Logo da Associação
--------------------------------------------------------- */
async function carregarConfiguracoes() {
  try {
    return await ConfiguracoesService.obter();
  } catch (erro) {
    console.error('[Configuracoes] Erro ao carregar configurações:', erro);
    return {};
  }
}

function atualizarLogoSidebar(logoBase64) {
  const logoContainer = document.getElementById('sidebar-logo-container');
  if (!logoContainer) return;

  if (logoBase64) {
    logoContainer.innerHTML = `<img src="${logoBase64}" alt="Logo" class="sidebar__logo-img" />`;
  } else {
    logoContainer.innerHTML = '<span class="sidebar__logo-texto">A</span>';
  }
}

async function salvarLogo(base64) {
  console.log('[Config] Iniciando salvamento do logo...');
  const config = await carregarConfiguracoes();
  console.log('[Config] Config carregada:', config);
  config.logo = base64;

  try {
    console.log('[Config] Salvando no banco...');
    await ConfiguracoesService.salvar(config);
    console.log('[Config] Salvo com sucesso!');
    Toast.success('Logo atualizado com sucesso!');
  } catch (erro) {
    console.error('[Configuracoes] Erro ao salvar logo:', erro);
    Toast.error('Erro ao salvar. Tente novamente.');
  }

  atualizarLogoSidebar(base64);
}

function processarUploadLogo(event) {
  const file = event.target.files[0];
  if (!file) return;

  if (file.size > 2 * 1024 * 1024) {
    alert('O arquivo excede o limite de 2 MB.');
    return;
  }

  const reader = new FileReader();
  reader.onload = function(e) {
    salvarLogo(e.target.result);
  };
  reader.readAsDataURL(file);
}

async function inicializarUploadLogo() {
  const input = document.getElementById('logo-input');
  if (input) {
    input.addEventListener('change', processarUploadLogo);
  }

  const config = await carregarConfiguracoes();
  atualizarLogoSidebar(config.logo || null);
}

/* ---------------------------------------------------------
   Modal de Relacionamentos — Nova Regra
--------------------------------------------------------- */
function abrirModalRegra() {
  const modal = document.getElementById('modal-regra');
  if (modal) modal.hidden = false;
}

function fecharModalRegra() {
  const modal = document.getElementById('modal-regra');
  if (modal) modal.hidden = true;
}

function registrarEventosRelacionamentos() {
  document.getElementById('btn-nova-regra')
    ?.addEventListener('click', abrirModalRegra);

  document.getElementById('modal-regra-fechar')
    ?.addEventListener('click', fecharModalRegra);

  document.getElementById('modal-regra-cancelar')
    ?.addEventListener('click', fecharModalRegra);

  document.getElementById('modal-regra-fundo')
    ?.addEventListener('click', fecharModalRegra);
}

/* ---------------------------------------------------------
   Toggles — Configurações Gerais
--------------------------------------------------------- */
function inicializarToggles() {
  document.querySelectorAll('.cfg-gerais__toggle').forEach(btn => {
    btn.addEventListener('click', () => {
      const ativo = btn.classList.toggle('cfg-gerais__toggle--ativo');
      btn.setAttribute('aria-pressed', ativo);
    });
  });
}

function inicializarPermissoes() {
  document.querySelectorAll('.cfg-gerais__perm').forEach(btn => {
    btn.addEventListener('click', () => {
      const eSim = btn.classList.contains('cfg-gerais__perm--sim');
      btn.classList.toggle('cfg-gerais__perm--sim', !eSim);
      btn.classList.toggle('cfg-gerais__perm--nao', eSim);
      btn.setAttribute('aria-pressed', !eSim);
      btn.querySelector('.material-icons').textContent = eSim ? 'remove_circle' : 'check_circle';
    });
  });
}

/* ---------------------------------------------------------
   Init / Destroy
--------------------------------------------------------- */
const ConfiguracoesPage = {
  init() {
    registrarEventosRelacionamentos();
    inicializarToggles();
    inicializarPermissoes();
    inicializarUploadLogo();
  },

  destroy() {
    document.getElementById('btn-nova-regra')
      ?.removeEventListener('click', abrirModalRegra);

    document.getElementById('modal-regra-fechar')
      ?.removeEventListener('click', fecharModalRegra);

    document.getElementById('modal-regra-cancelar')
      ?.removeEventListener('click', fecharModalRegra);

    document.getElementById('modal-regra-fundo')
      ?.removeEventListener('click', fecharModalRegra);
  }
};

export default ConfiguracoesPage;
