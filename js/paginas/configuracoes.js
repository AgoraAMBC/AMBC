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
   Init / Destroy
--------------------------------------------------------- */
const ConfiguracoesPage = {
  init() {
    registrarEventosRelacionamentos();
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
