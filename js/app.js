import { iniciarPagina as iniciarUsuarios } from './pages/usuarios.js';

const rotas = {
  '#painel':                        { titulo: 'Painel',            iniciar: null },
  '#configuracoes/usuarios':        { titulo: 'Gestão de Usuários', iniciar: iniciarUsuarios },
  '#configuracoes/associacao':      { titulo: 'Associação',         iniciar: null },
  '#configuracoes/relacionamentos': { titulo: 'Relacionamentos',    iniciar: null },
  '#configuracoes/gerais':          { titulo: 'Config. Gerais',     iniciar: null },
  '#cadastro/listar':               { titulo: 'Cadastro',           iniciar: null },
  '#financeiro/visao-geral':        { titulo: 'Financeiro',         iniciar: null },
};

const conteudo   = document.getElementById('conteudo-principal');
const titulo     = document.getElementById('topbar-titulo');
const sidebar    = document.getElementById('sidebar');
const btnToggle  = document.getElementById('btn-toggle-sidebar');
const overlay    = document.getElementById('overlay-sidebar');

async function carregarRota(hash) {
  const rota = rotas[hash];

  // atualiza título e link ativo
  titulo.textContent = rota?.titulo ?? hash.replace('#', '');
  document.querySelectorAll('.sidebar__link').forEach(link => {
    link.classList.toggle('is-ativo', link.getAttribute('href') === hash);
  });

  // abre o sidebar__item pai do link ativo (CSS requer is-aberto no <li>)
  document.querySelectorAll('.sidebar__item').forEach(item => {
    const temAtivo = item.querySelector('.sidebar__submenu .is-ativo');
    item.classList.toggle('is-aberto', !!temAtivo);
  });

  if (rota?.iniciar) {
    await rota.iniciar(conteudo);
  } else if (rota) {
    conteudo.innerHTML = `<h2>${rota.titulo}</h2><p>Em construção.</p>`;
  } else {
    conteudo.innerHTML = '<h2>Painel</h2><p>Bem-vindo ao sistema AMBC.</p>';
  }
}

// sidebar toggle (mobile)
btnToggle.addEventListener('click', () => {
  const aberto = sidebar.classList.toggle('is-aberto');
  btnToggle.setAttribute('aria-expanded', String(aberto));
  overlay.setAttribute('aria-hidden', String(!aberto));
});

overlay.addEventListener('click', () => {
  sidebar.classList.remove('is-aberto');
  btnToggle.setAttribute('aria-expanded', 'false');
  overlay.setAttribute('aria-hidden', 'true');
});

// submenus — CSS exige is-aberto no <li>.sidebar__item, não no <ul>
document.querySelectorAll('.sidebar__link[data-submenu]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const item = link.closest('.sidebar__item');
    item.classList.toggle('is-aberto');
  });
});

window.addEventListener('hashchange', () => carregarRota(location.hash));
carregarRota(location.hash || '#painel');
