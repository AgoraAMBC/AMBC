/* =========================================================
   cadastro-listar.js
   Projeto: AMBC-V2
   Pagina: Listar Todos os Cadastros
========================================================= */

import Modal from '../componentes/modal.js';
import Toast from '../componentes/toast.js';
import { AssociadosService } from '../services/associados-service.js';
import { formatarData } from '../core/formatadores.js';

/* ---------------------------------------------------------
   ESTADO INTERNO
--------------------------------------------------------- */
const estado = {
  termoBusca: '',
  filtroStatus: 'todos',
  paginaAtual: 1,
  totalPaginas: 1,
  total: 0,
  carregando: false,
};

/* ---------------------------------------------------------
   REFERENCIAS DOM
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
   INIT / DESTROY
--------------------------------------------------------- */
function init() {
  refs.inputBusca      = document.getElementById('input-busca');
  refs.filtroTipo      = document.getElementById('filtro-tipo');
  refs.filtroStatus    = document.getElementById('filtro-status');
  refs.tbody           = document.getElementById('tbody-cadastros');
  refs.contador        = document.getElementById('contador-registros');
  refs.paginacao       = document.getElementById('paginacao');
  refs.estadoVazio     = document.getElementById('estado-vazio');
  refs.btnNovoCadastro = document.getElementById('btn-novo-cadastro');

  estado.termoBusca  = '';
  estado.filtroStatus = 'todos';
  estado.paginaAtual  = 1;

  ativarFiltros();
  ativarBotaoNovoCadastro();
  buscarEAtualizar();
}

function destroy() {
  Object.keys(refs).forEach(k => refs[k] = null);
}

/* ---------------------------------------------------------
   BUSCA E RENDERIZAÇÃO
--------------------------------------------------------- */
async function buscarEAtualizar() {
  if (estado.carregando) return;
  estado.carregando = true;

  if (refs.tbody) {
    refs.tbody.innerHTML = `<tr><td colspan="5" class="cadastro-listar__estado-carregando">Carregando…</td></tr>`;
  }

  try {
    const filtros = {
      pagina: estado.paginaAtual,
      busca:  estado.termoBusca  || undefined,
      status: estado.filtroStatus !== 'todos' ? estado.filtroStatus : undefined,
    };

    const resp = await AssociadosService.listar(filtros);

    estado.total       = resp.total ?? 0;
    estado.totalPaginas = resp.paginas ?? 1;

    renderizarLinhas(resp.dados ?? []);
    renderizarContador(resp.total ?? 0, (resp.dados ?? []).length);
    renderizarPaginacao(estado.totalPaginas);
    alternarEstadoVazio((resp.dados ?? []).length === 0);
  } catch (erro) {
    console.error('[CadastroListar] Erro ao buscar associados:', erro);
    Toast.erro('Não foi possível carregar os cadastros.');
    if (refs.tbody) {
      refs.tbody.innerHTML = `<tr><td colspan="5" class="cadastro-listar__estado-carregando">Erro ao carregar dados.</td></tr>`;
    }
  } finally {
    estado.carregando = false;
  }
}

/* ---------------------------------------------------------
   RENDERIZAÇÃO
--------------------------------------------------------- */
function renderizarLinhas(associados) {
  if (!refs.tbody) return;

  if (associados.length === 0) {
    refs.tbody.innerHTML = '';
    return;
  }

  refs.tbody.innerHTML = associados.map(a => {
    const status = a.ativo ? 'ativo' : 'inativo';
    const cpf    = a.cpf_cnpj ? formatarCpfCnpj(a.cpf_cnpj) : '—';
    const data   = a.criado_em ? formatarData(a.criado_em) : '—';

    return `
      <tr data-id="${a.id_associado}" data-tipo="associado">
        <td>
          <div class="cadastro-listar__pessoa">
            <div class="cadastro-listar__avatar ${classeCorAvatar(a.nome)}">
              ${obterIniciais(a.nome)}
            </div>
            <div class="cadastro-listar__pessoa-textos">
              <span class="cadastro-listar__pessoa-nome">${escaparHtml(a.nome)}</span>
              <span class="cadastro-listar__pessoa-email">${escaparHtml(a.email ?? cpf)}</span>
            </div>
          </div>
        </td>
        <td>
          <span class="cadastro-listar__badge cadastro-listar__badge--associado">Associado</span>
        </td>
        <td>
          <span class="cadastro-listar__badge cadastro-listar__badge--${status}">
            ${status === 'ativo' ? 'Ativo' : 'Inativo'}
          </span>
        </td>
        <td>${data}</td>
        <td class="cadastro-listar__col-acoes">
          <div class="cadastro-listar__acoes">
            <button type="button" class="cadastro-listar__acao" data-acao="visualizar" data-id="${a.id_associado}" aria-label="Visualizar">
              <span class="material-icons">visibility</span>
            </button>
            <button type="button" class="cadastro-listar__acao" data-acao="editar" data-id="${a.id_associado}" aria-label="Editar">
              <span class="material-icons">edit</span>
            </button>
            <button type="button" class="cadastro-listar__acao cadastro-listar__acao--excluir" data-acao="excluir" data-id="${a.id_associado}" data-nome="${escaparHtml(a.nome)}" aria-label="Excluir">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');

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

  html += `
    <button type="button" class="cadastro-listar__pagina-btn"
            data-pagina="${atual - 1}" ${atual === 1 ? 'disabled' : ''} aria-label="Página anterior">
      <span class="material-icons">chevron_left</span>
    </button>
  `;

  const paginas = calcularPaginasVisiveis(atual, totalPaginas);
  for (const p of paginas) {
    if (p === '...') {
      html += `<button type="button" class="cadastro-listar__pagina-btn" disabled>…</button>`;
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

  html += `
    <button type="button" class="cadastro-listar__pagina-btn"
            data-pagina="${atual + 1}" ${atual === totalPaginas ? 'disabled' : ''} aria-label="Próxima página">
      <span class="material-icons">chevron_right</span>
    </button>
  `;

  refs.paginacao.innerHTML = html;
  refs.paginacao.onclick = tratarCliquePaginacao;
}

function calcularPaginasVisiveis(atual, total) {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

  const paginas = [1];
  if (atual > 3) paginas.push('...');

  const inicio = Math.max(2, atual - 1);
  const fim    = Math.min(total - 1, atual + 1);
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
   EVENTOS
--------------------------------------------------------- */
function ativarFiltros() {
  if (!refs.inputBusca || !refs.filtroStatus) return;

  let timeoutBusca;
  refs.inputBusca.addEventListener('input', e => {
    clearTimeout(timeoutBusca);
    timeoutBusca = setTimeout(() => {
      estado.termoBusca  = e.target.value.trim();
      estado.paginaAtual = 1;
      buscarEAtualizar();
    }, 200);
  });

  refs.filtroStatus.addEventListener('change', e => {
    estado.filtroStatus = e.target.value;
    estado.paginaAtual  = 1;
    buscarEAtualizar();
  });
}

function ativarBotaoNovoCadastro() {
  refs.btnNovoCadastro?.addEventListener('click', () => {
    window.location.hash = '#/cadastro/novo-associado';
  });
}

function tratarCliquePaginacao(e) {
  const btn = e.target.closest('[data-pagina]');
  if (!btn || btn.disabled) return;

  const pagina = parseInt(btn.dataset.pagina, 10);
  if (isNaN(pagina) || pagina < 1 || pagina > estado.totalPaginas) return;

  estado.paginaAtual = pagina;
  buscarEAtualizar();
  document.querySelector('.cadastro-listar__tabela-wrapper')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function tratarCliqueAcao(e) {
  const btn = e.target.closest('[data-acao]');
  if (!btn) return;

  const acao = btn.dataset.acao;
  const id   = parseInt(btn.dataset.id, 10);
  const nome = btn.dataset.nome ?? '';

  switch (acao) {
    case 'visualizar': aoVisualizar(id);        break;
    case 'editar':     aoEditar(id);            break;
    case 'excluir':    aoExcluir(id, nome);     break;
  }
}

/* ---------------------------------------------------------
   AÇÕES DE LINHA
--------------------------------------------------------- */
function aoVisualizar(id) {
  window.location.hash = `#/cadastro/novo-associado?id=${id}&visualizar=1`;
}

function aoEditar(id) {
  window.location.hash = `#/cadastro/novo-associado?id=${id}`;
}

function aoExcluir(id, nome) {
  Modal.confirmar({
    titulo: 'Excluir associado?',
    mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(nome)}</strong>? Esta ação não pode ser desfeita.`,
    icone: 'delete_forever',
    variante: 'erro',
    textoConfirmar: 'Sim, excluir',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'perigo',
    aoConfirmar: async () => {
      try {
        await AssociadosService.deletar(id);
        Toast.sucesso(`${nome} foi excluído com sucesso.`);
        buscarEAtualizar();
      } catch (erro) {
        console.error('[CadastroListar] Erro ao excluir:', erro);
        Toast.erro('Não foi possível excluir o associado.');
      }
    },
  });
}

/* ---------------------------------------------------------
   HELPERS
--------------------------------------------------------- */
function obterIniciais(nome) {
  const partes = (nome ?? '').trim().split(/\s+/);
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase();
  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
}

function classeCorAvatar(nome) {
  let hash = 0;
  for (let i = 0; i < (nome ?? '').length; i++) {
    hash = (hash + nome.charCodeAt(i)) % 6;
  }
  return `cadastro-listar__avatar--cor-${hash + 1}`;
}


function formatarCpfCnpj(valor) {
  if (!valor) return '—';
  const v = valor.replace(/\D/g, '');
  if (v.length === 11) return v.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  if (v.length === 14) return v.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
  return valor;
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
   EXPORT
--------------------------------------------------------- */
export default { init, destroy };
