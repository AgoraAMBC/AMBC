/* =========================================================
   Pagina: Dependentes
   Descricao: Listagem e gestão de dependentes dos associados
========================================================= */

function abrirModalDependente() {
  const modal = document.getElementById('modal-dependente');
  if (modal) modal.hidden = false;
}

function fecharModalDependente() {
  const modal = document.getElementById('modal-dependente');
  if (modal) {
    modal.hidden = true;
    document.getElementById('form-dependente')?.reset();
  }
}

function registrarEventos() {
  document.getElementById('btn-novo-dependente')?.addEventListener('click', abrirModalDependente);
  document.getElementById('modal-dependente-fechar')?.addEventListener('click', fecharModalDependente);
  document.getElementById('modal-dependente-cancelar')?.addEventListener('click', fecharModalDependente);
  document.getElementById('modal-dependente-fundo')?.addEventListener('click', fecharModalDependente);

  document.getElementById('btn-limpar-filtros-dep')?.addEventListener('click', () => {
    const ids = ['dep-busca', 'dep-filtro-parentesco', 'dep-idade-min', 'dep-idade-max'];
    ids.forEach(id => {
      const el = document.getElementById(id);
      if (el) el.value = '';
    });
  });
}

const CadastroDependentesPage = {
  init() {
    registrarEventos();
  },

  destroy() {},
};

export default CadastroDependentesPage;
