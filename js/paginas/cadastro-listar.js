/* =========================================================
   cadastro-listar.js
   Projeto: AMBC-V2
   Pagina: Listar Todos os Cadastros
   Descricao: Controller da view de listagem (busca, filtros,
              paginacao e acoes de linha).
========================================================= */

import Modal from '../componentes/modal.js';
import Toast from '../componentes/toast.js';
import cadastros from '../mocks/cadastros.js';

/* ---------------------------------------------------------
   CONFIGURACOES
--------------------------------------------------------- */
const ITENS_POR_PAGINA = 25;

/* ---------------------------------------------------------
   ESTADO INTERNO
--------------------------------------------------------- */
const estado = {
  termoBusca: '',
  filtroTipo: 'todos',
  filtroStatus: 'todos',
  paginaAtual: 1,
};

/* ---------------------------------------------------------
   REFERENCIAS DOM (preenchidas no init)
--------------------------------------------------------- */
const refs = {
  inputBusca: null,
  filtroTipo: null,
  filtroStatus: null,
  tbody: null,
  contador: null,
  paginacao: null,
  estadoVazio: null,
  btnNovoCadastro: null,
};

/* ---------------------------------------------------------
   INIT — chamado pelo router apos injetar a view
--------------------------------------------------------- */
function init() {
  console.log('[CadastroListar] Pagina carregada ✅');

  // Captura referencias do DOM
  refs.inputBusca       = document.getElementById('input-busca');
  refs.filtroTipo       = document.getElementById('filtro-tipo');
  refs.filtroStatus     = document.getElementById('filtro-status');
  refs.tbody            = document.getElementById('tbody-cadastros');
  refs.contador         = document.getElementById('contador-registros');
  refs.paginacao        = document.getElementById('paginacao');
  refs.estadoVazio      = document.getElementById('estado-vazio');
  refs.btnNovoCadastro  = document.getElementById('btn-novo-cadastro');

  // Reseta estado (caso o usuario volte para a pagina)
  estado.termoBusca = '';
  estado.filtroTipo = 'todos';
  estado.filtroStatus = 'todos';
  estado.paginaAtual = 1;

  // Ativa interacoes
  ativarFiltros();
  ativarBotaoNovoCadastro();

  // Render inicial
  renderizar();
}

/* ---------------------------------------------------------
   DESTROY — chamado pelo router ao trocar de rota
--------------------------------------------------------- */
function destroy() {
  console.log('[CadastroListar] Pagina destruida 👋');
  // Listeners morrem com o DOM (delegacao no tbody/paginacao via innerHTML).
  // Limpa referencias para liberar memoria.
  Object.keys(refs).forEach(k => refs[k] = null);
}

/* ---------------------------------------------------------
   FILTRAGEM E PAGINACAO
--------------------------------------------------------- */
function obterCadastrosFiltrados() {
  const termo = estado.termoBusca.toLowerCase().trim();

  return cadastros.filter(c => {
    // Filtro por tipo
    if (estado.filtroTipo !== 'todos' && c.tipo !== estado.filtroTipo) {
      return false;
    }
    // Filtro por status
    if (estado.filtroStatus !== 'todos' && c.status !== estado.filtroStatus) {
      return false;
    }
    // Filtro por termo de busca (nome, cpf ou email)
    if (termo) {
      const alvo = `${c.nome} ${c.cpf} ${c.email}`.toLowerCase();
      if (!alvo.includes(termo)) return false;
    }
    return true;
  });
}

function obterPaginaAtual(filtrados) {
  const inicio = (estado.paginaAtual - 1) * ITENS_POR_PAGINA;
  return filtrados.slice(inicio, inicio + ITENS_POR_PAGINA);
}

/* ---------------------------------------------------------
   RENDERIZACAO PRINCIPAL
--------------------------------------------------------- */
function renderizar() {
  const filtrados = obterCadastrosFiltrados();
  const totalPaginas = Math.max(1, Math.ceil(filtrados.length / ITENS_POR_PAGINA));

  // Garante que pagina atual e valida apos um filtro
  if (estado.paginaAtual > totalPaginas) {
    estado.paginaAtual = totalPaginas;
  }

  const pagina = obterPaginaAtual(filtrados);

  renderizarLinhas(pagina);
  renderizarContador(filtrados.length, pagina.length);
  renderizarPaginacao(totalPaginas);
  alternarEstadoVazio(filtrados.length === 0);
}

function renderizarLinhas(linhas) {
  if (!refs.tbody) return;

  if (linhas.length === 0) {
    refs.tbody.innerHTML = '';
    return;
  }

  refs.tbody.innerHTML = linhas.map(c => `
    <tr data-id="${c.id}">
      <td>
        <div class="cadastro-listar__pessoa">
          <div class="cadastro-listar__avatar ${classeCorAvatar(c.nome)}">
            ${obterIniciais(c.nome)}
          </div>
          <div class="cadastro-listar__pessoa-textos">
            <span class="cadastro-listar__pessoa-nome">${escaparHtml(c.nome)}</span>
            <span class="cadastro-listar__pessoa-email">${escaparHtml(c.email)}</span>
          </div>
        </div>
      </td>
      <td>
        <span class="cadastro-listar__badge cadastro-listar__badge--${c.tipo}">
          ${capitalizar(c.tipo)}
        </span>
      </td>
      <td>
        <span class="cadastro-listar__badge cadastro-listar__badge--${c.status}">
          ${capitalizar(c.status)}
        </span>
      </td>
      <td>${formatarData(c.cadastradoEm)}</td>
      <td class="cadastro-listar__col-acoes">
        <div class="cadastro-listar__acoes">
          <button type="button" class="cadastro-listar__acao" data-acao="visualizar" data-id="${c.id}" aria-label="Visualizar">
            <span class="material-icons">visibility</span>
          </button>
          <button type="button" class="cadastro-listar__acao" data-acao="editar" data-id="${c.id}" aria-label="Editar">
            <span class="material-icons">edit</span>
          </button>
          <button type="button" class="cadastro-listar__acao cadastro-listar__acao--excluir" data-acao="excluir" data-id="${c.id}" aria-label="Excluir">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');

  // Delegacao de eventos para acoes (1 listener no tbody)
  refs.tbody.onclick = tratarCliqueAcao;
}

function renderizarContador(total, exibindo) {
  if (!refs.contador) return;
  refs.contador.textContent = `Exibindo ${exibindo} de ${total} ${total === 1 ? 'cadastro' : 'cadastros'}`;
}

function renderizarPaginacao(totalPaginas) {
  if (!refs.paginacao) return;

  const atual = estado.paginaAtual;
  let html = '';

  // Botao anterior
  html += `
    <button type="button" class="cadastro-listar__pagina-btn"
            data-pagina="${atual - 1}" ${atual === 1 ? 'disabled' : ''} aria-label="Pagina anterior">
      <span class="material-icons">chevron_left</span>
    </button>
  `;

  // Numeros de pagina (estrategia simples: mostra todos se <= 7, senao "1 ... atual ... ultima")
  const paginas = calcularPaginasVisiveis(atual, totalPaginas);
  for (const p of paginas) {
    if (p === '...') {
      html += `<button type="button" class="cadastro-listar__pagina-btn" disabled>...</button>`;
    } else {
      html += `
        <button type="button"
                class="cadastro-listar__pagina-btn ${p === atual ? 'cadastro-listar__pagina-btn--ativo' : ''}"
                data-pagina="${p}">
          ${p}
        </button>
      `;
    }
  }

  // Botao proximo
  html += `
    <button type="button" class="cadastro-listar__pagina-btn"
            data-pagina="${atual + 1}" ${atual === totalPaginas ? 'disabled' : ''} aria-label="Proxima pagina">
      <span class="material-icons">chevron_right</span>
    </button>
  `;

  refs.paginacao.innerHTML = html;
  refs.paginacao.onclick = tratarCliquePaginacao;
}

function calcularPaginasVisiveis(atual, total) {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  const paginas = [1];
  if (atual > 3) paginas.push('...');

  const inicio = Math.max(2, atual - 1);
  const fim = Math.min(total - 1, atual + 1);
  for (let i = inicio; i <= fim; i++) paginas.push(i);

  if (atual < total - 2) paginas.push('...');
  paginas.push(total);

  return paginas;
}

function alternarEstadoVazio(vazio) {
  if (!refs.estadoVazio) return;
  refs.estadoVazio.hidden = !vazio;
}

/* ---------------------------------------------------------
   EVENT HANDLERS
--------------------------------------------------------- */
function ativarFiltros() {
  if (!refs.inputBusca || !refs.filtroTipo || !refs.filtroStatus) return;

  // Busca com debounce simples
  let timeoutBusca;
  refs.inputBusca.addEventListener('input', (e) => {
    clearTimeout(timeoutBusca);
    timeoutBusca = setTimeout(() => {
      estado.termoBusca = e.target.value;
      estado.paginaAtual = 1;
      renderizar();
    }, 200);
  });

  refs.filtroTipo.addEventListener('change', (e) => {
    estado.filtroTipo = e.target.value;
    estado.paginaAtual = 1;
    renderizar();
  });

  refs.filtroStatus.addEventListener('change', (e) => {
    estado.filtroStatus = e.target.value;
    estado.paginaAtual = 1;
    renderizar();
  });
}

function ativarBotaoNovoCadastro() {
  if (!refs.btnNovoCadastro) return;

  refs.btnNovoCadastro.addEventListener('click', () => {
    // Por enquanto, leva para "Novo Associado" (futuramente: modal de escolha)
    window.location.hash = '#/cadastro/novo-associado';
  });
}

function tratarCliquePaginacao(e) {
  const btn = e.target.closest('[data-pagina]');
  if (!btn || btn.disabled) return;

  const pagina = parseInt(btn.dataset.pagina, 10);
  if (isNaN(pagina)) return;

  estado.paginaAtual = pagina;
  renderizar();

  // Scroll suave para o topo da tabela
  document.querySelector('.cadastro-listar__tabela-wrapper')?.scrollIntoView({
    behavior: 'smooth',
    block: 'start',
  });
}

function tratarCliqueAcao(e) {
  const btn = e.target.closest('[data-acao]');
  if (!btn) return;

  const acao = btn.dataset.acao;
  const id = parseInt(btn.dataset.id, 10);
  const cadastro = cadastros.find(c => c.id === id);
  if (!cadastro) return;

  switch (acao) {
    case 'visualizar': aoVisualizar(cadastro); break;
    case 'editar':     aoEditar(cadastro);     break;
    case 'excluir':    aoExcluir(cadastro);    break;
  }
}

/* ---------------------------------------------------------
   ACOES DE LINHA
--------------------------------------------------------- */
function aoVisualizar(cadastro) {
  Toast.info(`Visualizar ${cadastro.nome} (em construção)`);
}

function aoEditar(cadastro) {
  Toast.info(`Editar ${cadastro.nome} (em construção)`);
}

function aoExcluir(cadastro) {
  Modal.confirmar({
    titulo: 'Excluir cadastro?',
    mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(cadastro.nome)}</strong>? Esta ação não pode ser desfeita.`,
    icone: 'delete_forever',
    variante: 'erro',
    textoConfirmar: 'Sim, excluir',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'perigo',
    aoConfirmar: () => {
      // Remove do mock (somente em memoria — nao persiste)
      const idx = cadastros.findIndex(c => c.id === cadastro.id);
      if (idx !== -1) cadastros.splice(idx, 1);

      Toast.sucesso(`${cadastro.nome} foi excluído com sucesso`);
      renderizar();
    },
  });
}

/* ---------------------------------------------------------
   HELPERS
--------------------------------------------------------- */
function obterIniciais(nome) {
  const partes = nome.trim().split(/\s+/);
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase();
  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
}

function classeCorAvatar(nome) {
  // Hash simples para distribuir cores entre 1 e 6
  let hash = 0;
  for (let i = 0; i < nome.length; i++) {
    hash = (hash + nome.charCodeAt(i)) % 6;
  }
  return `cadastro-listar__avatar--cor-${hash + 1}`;
}

function capitalizar(texto) {
  if (!texto) return '';
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

function formatarData(iso) {
  if (!iso) return '—';
  const [ano, mes, dia] = iso.split('-');
  return `${dia}/${mes}/${ano}`;
}

function escaparHtml(texto) {
  if (texto == null) return '';
  return String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/* ---------------------------------------------------------
   EXPORT (padrao ES6 Module)
--------------------------------------------------------- */
export default {
  init,
  destroy,
};
