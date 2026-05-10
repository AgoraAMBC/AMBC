/* =========================================================
   Pagina: Tabelas Auxiliares
   Descricao: Gerencia as abas e formulários inline das tabelas auxiliares
========================================================= */

function inicializarAbas() {
  const abas = document.querySelectorAll('[data-tabaux-aba]');
  if (!abas.length) return;

  abas.forEach(aba => {
    aba.addEventListener('click', () => {
      const alvo = aba.dataset.tabauxAba;

      abas.forEach(a => {
        a.classList.remove('tabaux__aba--ativa');
        a.setAttribute('aria-selected', 'false');
      });

      document.querySelectorAll('.tabaux__painel').forEach(painel => {
        painel.classList.remove('tabaux__painel--ativo');
        painel.hidden = true;
      });

      aba.classList.add('tabaux__aba--ativa');
      aba.setAttribute('aria-selected', 'true');

      const painelAlvo = document.getElementById(`tabaux-${alvo}`);
      if (painelAlvo) {
        painelAlvo.classList.add('tabaux__painel--ativo');
        painelAlvo.hidden = false;
      }
    });
  });
}

const TabelasPage = {
  init() {
    inicializarAbas();
  },

  destroy() {},
};

export default TabelasPage;
