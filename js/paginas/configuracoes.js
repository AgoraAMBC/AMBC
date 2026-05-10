/* =========================================================
   Pagina: Configurações (associação, relacionamentos, etc.)
   Projeto: AMBC-V2
   Descricao: Lógica compartilhada das sub-páginas de configurações.
========================================================= */

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
