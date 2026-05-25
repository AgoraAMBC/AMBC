/* =========================================================
   cadastro-listar.js
   Pagina: Listar Todos os Cadastros
========================================================= */

import Modal from '../componentes/modal.js';
import Toast from '../componentes/toast.js';
import { CadastrosService } from '../services/cadastros-service.js';
import { AssociadosService } from '../services/associados-service.js';

const estado = {
  termoBusca: '',
  filtroTipo: 'todos',
  filtroStatus: 'todos',
  paginaAtual: 1,
  totalPaginas: 1,
  total: 0,
  carregando: false,
};

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

function init() {
  refs.inputBusca = document.getElementById('input-busca');
  refs.filtroTipo = document.getElementById('filtro-tipo');
  refs.filtroStatus = document.getElementById('filtro-status');
  refs.tbody = document.getElementById('tbody-cadastros');
  refs.contador = document.getElementById('contador-registros');
  refs.paginacao = document.getElementById('paginacao');
  refs.estadoVazio = document.getElementById('estado-vazio');
  refs.btnNovoCadastro = document.getElementById('btn-novo-cadastro');

  estado.termoBusca = '';
  estado.filtroTipo = 'todos';
  estado.filtroStatus = 'todos';
  estado.paginaAtual = 1;

  ativarFiltros();
  ativarBotaoNovoCadastro();
  buscarEAtualizar();
}

function destroy() {
  Object.keys(refs).forEach(k => refs[k] = null);
}

async function buscarEAtualizar() {
  if (estado.carregando) return;
  estado.carregando = true;

  if (refs.tbody) {
    refs.tbody.innerHTML = '<tr><td colspan="5" class="cadastro-listar__estado-carregando">Carregando...</td></tr>';
  }

  try {
    const filtros = {
      pagina: estado.paginaAtual,
      busca: estado.termoBusca || undefined,
      status: estado.filtroStatus !== 'todos' ? estado.filtroStatus : undefined,
    };

    const resp = await buscarCadastros(filtros);

    estado.total = resp.total ?? 0;
    estado.totalPaginas = resp.paginas ?? 1;

    renderizarLinhas(resp.dados ?? []);
    renderizarContador(resp.total ?? 0, (resp.dados ?? []).length);
    renderizarPaginacao(estado.totalPaginas);
    alternarEstadoVazio((resp.dados ?? []).length === 0);
  } catch (erro) {
    console.error('[CadastroListar] Erro ao buscar cadastros:', erro);
    Toast.erro('Nao foi possivel carregar os cadastros.');
    if (refs.tbody) {
      refs.tbody.innerHTML = '<tr><td colspan="5" class="cadastro-listar__estado-carregando">Erro ao carregar dados.</td></tr>';
    }
  } finally {
    estado.carregando = false;
  }
}

async function buscarCadastros(filtros) {
  return CadastrosService.listar({
    ...filtros,
    tipo: estado.filtroTipo !== 'todos' ? estado.filtroTipo : undefined,
  });
}

function renderizarLinhas(cadastros) {
  if (!refs.tbody) return;

  if (cadastros.length === 0) {
    refs.tbody.innerHTML = '';
    return;
  }

  refs.tbody.innerHTML = cadastros.map(c => {
    const status = c.ativo ? 'ativo' : 'inativo';
    const cpf = c.cpf_cnpj ? formatarCpfCnpj(c.cpf_cnpj) : '-';
    const data = c.criado_em ? formatarData(c.criado_em) : '-';
    const rotuloTipo = c.tipo === 'parceiro' ? 'Parceiro' : c.tipo === 'dependente' ? 'Dependente' : 'Associado';

    return `
      <tr data-id="${c.id}" data-tipo="${c.tipo}" ${c.tipo === 'dependente' ? `data-associado-id="${c.id_associado_titular}"` : ''}>
        <td>
          <div class="cadastro-listar__pessoa">
            <div class="cadastro-listar__avatar ${classeCorAvatar(c.nome)}">
              ${obterIniciais(c.nome)}
            </div>
            <div class="cadastro-listar__pessoa-textos">
              <span class="cadastro-listar__pessoa-nome">${escaparHtml(c.nome)}</span>
              <span class="cadastro-listar__pessoa-email">${escaparHtml(c.email ?? cpf)}</span>
            </div>
          </div>
        </td>
        <td>
          <span class="cadastro-listar__badge cadastro-listar__badge--${c.tipo}">${rotuloTipo}</span>
        </td>
        <td>
          <span class="cadastro-listar__badge cadastro-listar__badge--${status}">
            ${status === 'ativo' ? 'Ativo' : 'Inativo'}
          </span>
        </td>
        <td>${data}</td>
        <td class="cadastro-listar__col-acoes">
          <div class="cadastro-listar__acoes">
            <button type="button" class="cadastro-listar__acao" data-acao="visualizar" data-id="${c.id}" data-tipo="${c.tipo}" aria-label="Visualizar">
              <span class="material-icons">visibility</span>
            </button>
            <button type="button" class="cadastro-listar__acao" data-acao="editar" data-id="${c.id}" data-tipo="${c.tipo}" aria-label="Editar">
              <span class="material-icons">edit</span>
            </button>
<button type="button" class="cadastro-listar__acao cadastro-listar__acao--excluir" data-acao="excluir" data-id="${c.id}" data-tipo="${c.tipo}" data-ativo="${c.ativo ? '1' : '0'}" data-nome="${escaparHtml(c.nome)}" aria-label="Excluir">
  <span class="material-icons">delete</span>
</button>
            ${c.tipo === 'dependente' ? `<button type="button" class="cadastro-listar__acao" data-acao="ver-associado" data-id="${c.id_associado_titular}" aria-label="Ver associado titular">
              <span class="material-icons">person</span>
            </button>` : ''}
          </div>
        </td>
      </tr>
    `;
  }).join('');

  refs.tbody.onclick = tratarCliqueAcao;

  const linhas = refs.tbody.querySelectorAll('tr');
  linhas.forEach(tr => {
    tr.style.cursor = 'pointer';
    tr.ondblclick = () => {
      const id = parseInt(tr.dataset.id, 10);
      const tipo = tr.dataset.tipo ?? 'associado';
      if (tipo === 'dependente' && tr.dataset.associadoId) {
        aoVisualizar(id, tipo, parseInt(tr.dataset.associadoId, 10));
      } else {
        aoVisualizar(id, tipo);
      }
    };
  });
}

function renderizarContador(total, exibindo) {
  if (!refs.contador) return;
  refs.contador.textContent = `Exibindo ${exibindo} de ${total} ${total === 1 ? 'cadastro' : 'cadastros'}`;
}

function renderizarPaginacao(totalPaginas) {
  if (!refs.paginacao) return;

  const atual = estado.paginaAtual;
  let html = `
    <button type="button" class="cadastro-listar__pagina-btn"
            data-pagina="${atual - 1}" ${atual === 1 ? 'disabled' : ''} aria-label="Pagina anterior">
      <span class="material-icons">chevron_left</span>
    </button>
  `;

  for (const p of calcularPaginasVisiveis(atual, totalPaginas)) {
    html += p === '...'
      ? '<button type="button" class="cadastro-listar__pagina-btn" disabled>...</button>'
      : `
        <button type="button"
                class="cadastro-listar__pagina-btn ${p === atual ? 'cadastro-listar__pagina-btn--ativo' : ''}"
                data-pagina="${p}">
          ${p}
        </button>
      `;
  }

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
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

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

function ativarFiltros() {
  if (!refs.inputBusca || !refs.filtroStatus || !refs.filtroTipo) return;

  let timeoutBusca;
  refs.inputBusca.addEventListener('input', e => {
    clearTimeout(timeoutBusca);
    timeoutBusca = setTimeout(() => {
      estado.termoBusca = e.target.value.trim();
      estado.paginaAtual = 1;
      buscarEAtualizar();
    }, 200);
  });

  refs.filtroTipo.addEventListener('change', e => {
    estado.filtroTipo = e.target.value;
    estado.paginaAtual = 1;
    buscarEAtualizar();
  });

  refs.filtroStatus.addEventListener('change', e => {
    estado.filtroStatus = e.target.value;
    estado.paginaAtual = 1;
    buscarEAtualizar();
  });
}

function ativarBotaoNovoCadastro() {
  refs.btnNovoCadastro?.addEventListener('click', () => {
    window.location.hash = estado.filtroTipo === 'parceiro'
      ? '#/cadastro/novo-parceiro'
      : '#/cadastro/novo-associado';
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
  const id = parseInt(btn.dataset.id, 10);
  const tipo = btn.dataset.tipo ?? 'associado';
  const nome = btn.dataset.nome ?? '';
  const ativo = btn.dataset.ativo === '1';
  const linha = btn.closest('tr');
  const associadoId = linha?.dataset?.associadoId ? parseInt(linha.dataset.associadoId, 10) : null;

  switch (acao) {
    case 'visualizar': aoVisualizar(id, tipo, associadoId); break;
    case 'editar': aoEditar(id, tipo, associadoId); break;
    case 'excluir': aoExcluir(id, nome, tipo, ativo, associadoId); break;
    case 'ver-associado': aoVisualizar(associadoId ?? id, 'associado'); break;
  }
}

function aoVisualizar(id, tipo, associadoId) {
  if (tipo === 'dependente') {
    if (associadoId) {
      window.location.hash = `#/cadastro/novo-associado?id=${associadoId}&tab=dependentes`;
    } else {
      Toast.erro('Associado titular nao encontrado para este dependente.');
    }
    return;
  }
  window.location.hash = tipo === 'parceiro'
    ? `#/cadastro/novo-parceiro?id=${id}&visualizar=1`
    : `#/cadastro/novo-associado?id=${id}&visualizar=1`;
}

function aoEditar(id, tipo, associadoId) {
  if (tipo === 'dependente' && associadoId) {
    window.location.hash = `#/cadastro/novo-associado?id=${associadoId}&tab=dependentes`;
    return;
  }
  if (tipo === 'dependente' && !associadoId) {
    Toast.erro('Associado titular nÃ£o encontrado para este dependente.');
    return;
  }
  window.location.hash = tipo === 'parceiro'
    ? `#/cadastro/novo-parceiro?id=${id}`
    : `#/cadastro/novo-associado?id=${id}`;
}

function aoExcluir(id, nome, tipo, ativo, associadoId) {
  if (tipo === 'dependente') {
    Modal.confirmar({
      titulo: 'Excluir dependente?',
      mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(nome)}</strong>? Esta acao nao pode ser desfeita.`,
      icone: 'delete_forever',
      variante: 'erro',
      textoConfirmar: 'Sim, excluir',
      textoCancelar: 'Cancelar',
      estiloConfirmar: 'perigo',
      aoConfirmar: async () => {
        try {
          await CadastrosService.excluir(id, 'dependente');
          Toast.sucesso(`${nome} foi excluido com sucesso.`);
          buscarEAtualizar();
        } catch (erro) {
          console.error('[CadastroListar] Erro ao excluir dependente:', erro);
          Toast.erro('Nao foi possivel excluir o dependente.');
        }
      },
    });
    return;
  }

  Modal.confirmar({
    titulo: tipo === 'parceiro' ? 'Excluir parceiro?' : 'Excluir associado?',
    mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(nome)}</strong>? Esta acao nao pode ser desfeita.`,
    icone: 'delete_forever',
    variante: 'erro',
    textoConfirmar: 'Sim, excluir',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'perigo',
    aoConfirmar: async () => {
      try {
        if (tipo === 'parceiro') {
          await CadastrosService.excluir(id, 'parceiro');
        } else {
          await AssociadosService.deletar(id);
        }
        Toast.sucesso(`${nome} foi excluido com sucesso.`);
        buscarEAtualizar();
      } catch (erro) {
        console.error('[CadastroListar] Erro ao excluir:', erro);
        Toast.erro('Nao foi possivel excluir o ' + (tipo === 'parceiro' ? 'parceiro' : 'associado') + '.');
      }
    },
  });
}

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

function formatarData(valor) {
  if (!valor) return '-';
  return new Date(valor).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' });
}

function formatarCpfCnpj(valor) {
  if (!valor) return '-';
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

export default { init, destroy };
