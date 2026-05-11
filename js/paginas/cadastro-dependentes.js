/* =========================================================
   cadastro-dependentes.js
   Projeto: AMBC-V2
   Pagina: Listagem de Dependentes
========================================================= */

import Toast from '../componentes/toast.js';
import { formatarData } from '../core/formatadores.js';

/* ---------------------------------------------------------
   DADOS MOCK (temporário até integração com API)
--------------------------------------------------------- */
const dependentesMock = [
  { id_dependente: 1, nome: 'João Silva Jr.', id_associado: 1, associado: 'João Silva', parentesco: 'filho', data_nascimento: '2010-05-15', genero: 'M', rua: 'Rua A', id_associado_ativo: true },
  { id_dependente: 2, nome: 'Maria Silva', id_associado: 1, associado: 'João Silva', parentesco: 'filha', data_nascimento: '2012-08-22', genero: 'F', rua: 'Rua A', id_associado_ativo: true },
  { id_dependente: 3, nome: 'Ana Silva', id_associado: 1, associado: 'João Silva', parentesco: 'conjuge', data_nascimento: '1975-03-10', genero: 'F', rua: 'Rua A', id_associado_ativo: true },
  { id_dependente: 4, nome: 'Carlos Santos', id_associado: 2, associado: 'Pedro Santos', parentesco: 'filho', data_nascimento: '2008-12-01', genero: 'M', rua: 'Rua B', id_associado_ativo: true },
  { id_dependente: 5, nome: 'Juliana Santos', id_associado: 2, associado: 'Pedro Santos', parentesco: 'filha', data_nascimento: '2015-06-18', genero: 'F', rua: 'Rua B', id_associado_ativo: true },
  { id_dependente: 6, nome: 'Roberto Oliveira', id_associado: 3, associado: 'Marina Oliveira', parentesco: 'conjuge', data_nascimento: '1972-11-25', genero: 'M', rua: 'Rua C', id_associado_ativo: true },
  { id_dependente: 7, nome: 'Lucas Oliveira', id_associado: 3, associado: 'Marina Oliveira', parentesco: 'filho', data_nascimento: '2006-09-03', genero: 'M', rua: 'Rua C', id_associado_ativo: true },
  { id_dependente: 8, nome: 'Sofia Costa', id_associado: 4, associado: 'Felipe Costa', parentesco: 'filha', data_nascimento: '2016-02-14', genero: 'F', rua: 'Rua D', id_associado_ativo: true },
  { id_dependente: 9, nome: 'Gustavo Pereira', id_associado: 5, associado: 'Camila Pereira', parentesco: 'filho', data_nascimento: '2011-07-29', genero: 'M', rua: 'Rua E', id_associado_ativo: true },
  { id_dependente: 10, nome: 'Fernanda Alves', id_associado: 5, associado: 'Camila Pereira', parentesco: 'filha', data_nascimento: '2013-04-17', genero: 'F', rua: 'Rua E', id_associado_ativo: true },
  { id_dependente: 11, nome: 'Thiago Martins', id_associado: 6, associado: 'Rafael Martins', parentesco: 'genro', data_nascimento: '1985-10-05', genero: 'M', rua: 'Rua A', id_associado_ativo: true },
  { id_dependente: 12, nome: 'Isabela Martins', id_associado: 6, associado: 'Rafael Martins', parentesco: 'filha', data_nascimento: '2017-01-22', genero: 'F', rua: 'Rua A', id_associado_ativo: true },
];

/* ---------------------------------------------------------
   ESTADO INTERNO
--------------------------------------------------------- */
const estado = {
  termoBusca: '',
  filtroParentesco: '',
  filtroGenero: '',
  filtroIdadeMin: null,
  filtroIdadeMax: null,
  filtroRua: '',
  filtroStatus: '',
  paginaAtual: 1,
  itensPorPagina: 10,
  totalPaginas: 1,
  total: 0,
  carregando: false,
  dependentesAtual: [],
};

/* ---------------------------------------------------------
   REFERÊNCIAS DOM
--------------------------------------------------------- */
const refs = {
  inputBusca: null,
  filtroParentesco: null,
  filtroGenero: null,
  filtroIdadeMin: null,
  filtroIdadeMax: null,
  filtroRua: null,
  filtroStatus: null,
  btnBuscar: null,
  btnLimparFiltros: null,
  tbody: null,
  contador: null,
  contadorTotal: null,
  paginacao: null,
  estadoVazio: null,
  btnGerarRelatorio: null,
  modalRelatorio: null,
  btnConfirmarRelatorio: null,
};

/* ---------------------------------------------------------
   INIT / DESTROY
--------------------------------------------------------- */
function init() {
  refs.inputBusca = document.getElementById('input-busca');
  refs.filtroParentesco = document.getElementById('filtro-parentesco');
  refs.filtroGenero = document.getElementById('filtro-genero');
  refs.filtroIdadeMin = document.getElementById('filtro-idade-min');
  refs.filtroIdadeMax = document.getElementById('filtro-idade-max');
  refs.filtroRua = document.getElementById('filtro-rua');
  refs.filtroStatus = document.getElementById('filtro-status');
  refs.btnBuscar = document.getElementById('btn-buscar');
  refs.btnLimparFiltros = document.getElementById('btn-limpar-filtros');
  refs.tbody = document.getElementById('tbody-dependentes');
  refs.contador = document.getElementById('contador-registros');
  refs.contadorTotal = document.getElementById('contador-total');
  refs.paginacao = document.getElementById('paginacao');
  refs.estadoVazio = document.getElementById('estado-vazio');
  refs.btnGerarRelatorio = document.getElementById('btn-gerar-relatorio');
  refs.modalRelatorio = document.getElementById('modal-relatorio');
  refs.btnConfirmarRelatorio = document.getElementById('btn-confirmar-relatorio');

  estado.termoBusca = '';
  estado.filtroParentesco = '';
  estado.filtroGenero = '';
  estado.filtroIdadeMin = null;
  estado.filtroIdadeMax = null;
  estado.filtroRua = '';
  estado.filtroStatus = '';
  estado.paginaAtual = 1;

  preencherSelectRuas();
  ativarFiltros();
  ativarBotaoBuscar();
  ativarBotaoLimpar();
  ativarRelatorio();
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
    refs.tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; padding: 2rem;">Carregando…</td></tr>`;
  }

  try {
    const dependentesFiltrados = aplicarFiltros(dependentesMock);
    estado.total = dependentesFiltrados.length;
    estado.totalPaginas = Math.ceil(estado.total / estado.itensPorPagina) || 1;

    const inicio = (estado.paginaAtual - 1) * estado.itensPorPagina;
    const fim = inicio + estado.itensPorPagina;
    estado.dependentesAtual = dependentesFiltrados.slice(inicio, fim);

    renderizarLinhas(estado.dependentesAtual);
    renderizarContador();
    renderizarPaginacao();
    alternarEstadoVazio(estado.dependentesAtual.length === 0);
  } catch (erro) {
    console.error('[DependentesListar] Erro ao buscar dependentes:', erro);
    Toast.erro('Não foi possível carregar os dependentes.');
    if (refs.tbody) {
      refs.tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; padding: 2rem;">Erro ao carregar dados.</td></tr>`;
    }
  } finally {
    estado.carregando = false;
  }
}

/* ---------------------------------------------------------
   FILTROS
--------------------------------------------------------- */
function aplicarFiltros(dados) {
  return dados.filter(d => {
    const nome = (d.nome ?? '').toLowerCase();
    const termoBusca = estado.termoBusca.toLowerCase();
    if (termoBusca && !nome.includes(termoBusca)) return false;

    if (estado.filtroParentesco && d.parentesco !== estado.filtroParentesco) return false;
    if (estado.filtroGenero && d.genero !== estado.filtroGenero) return false;
    if (estado.filtroRua && d.rua !== estado.filtroRua) return false;
    if (estado.filtroStatus === 'ativo' && !d.id_associado_ativo) return false;
    if (estado.filtroStatus === 'inativo' && d.id_associado_ativo) return false;

    const idade = calcularIdade(d.data_nascimento);
    if (estado.filtroIdadeMin !== null && idade < estado.filtroIdadeMin) return false;
    if (estado.filtroIdadeMax !== null && idade > estado.filtroIdadeMax) return false;

    return true;
  });
}

function calcularIdade(dataNascimento) {
  if (!dataNascimento) return 0;
  const hoje = new Date();
  const nasc = new Date(dataNascimento);
  let idade = hoje.getFullYear() - nasc.getFullYear();
  const mesAtual = hoje.getMonth();
  const mesNasc = nasc.getMonth();
  if (mesAtual < mesNasc || (mesAtual === mesNasc && hoje.getDate() < nasc.getDate())) {
    idade--;
  }
  return idade;
}

function preencherSelectRuas() {
  if (!refs.filtroRua) return;

  const ruas = [...new Set(dependentesMock.map(d => d.rua))].sort();
  const options = ruas.map(rua => `<option value="${rua}">${rua}</option>`).join('');

  refs.filtroRua.innerHTML = '<option value="">Rua: Todas</option>' + options;
}

/* ---------------------------------------------------------
   RENDERIZAÇÃO
--------------------------------------------------------- */
function renderizarLinhas(dependentes) {
  if (!refs.tbody) return;

  if (dependentes.length === 0) {
    refs.tbody.innerHTML = '';
    return;
  }

  refs.tbody.innerHTML = dependentes.map(d => {
    const idade = calcularIdade(d.data_nascimento);
    const dataNasc = d.data_nascimento ? formatarData(d.data_nascimento) : '—';
    const genero = d.genero === 'M' ? 'Masculino' : d.genero === 'F' ? 'Feminino' : 'Outro';
    const iconeGenero = d.genero === 'M' ? 'male' : d.genero === 'F' ? 'female' : 'help';

    return `
      <tr data-id="${d.id_dependente}">
        <td>#${String(d.id_dependente).padStart(3, '0')}</td>
        <td>${escaparHtml(d.nome)}</td>
        <td>
          <button type="button" class="dependentes__link-associado" data-acao="ver-associado" data-id="${d.id_associado}">
            ${escaparHtml(d.associado)}
          </button>
        </td>
        <td>
          <span class="dependentes__badge dependentes__badge--${d.parentesco}">
            ${capitalize(d.parentesco)}
          </span>
        </td>
        <td>${idade} anos</td>
        <td>${dataNasc}</td>
        <td>${escaparHtml(d.rua)}</td>
        <td>
          <span class="dependentes__genero">
            <span class="material-icons">${iconeGenero}</span>
            ${genero}
          </span>
        </td>
        <td class="dependentes__col-acoes">
          <div class="dependentes__acoes">
            <button type="button" class="dependentes__acao dependentes__acao--editar" data-acao="editar" data-id="${d.id_dependente}" data-id-associado="${d.id_associado}" aria-label="Editar dependente">
              <span class="material-icons">edit</span>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');

  refs.tbody.addEventListener('click', tratarCliqueAcao);
}

function renderizarContador() {
  if (!refs.contador) return;
  const exibindo = estado.dependentesAtual.length;
  refs.contador.textContent = `Exibindo ${exibindo} de ${estado.total} ${estado.total === 1 ? 'dependente' : 'dependentes'}`;

  if (refs.contadorTotal) {
    refs.contadorTotal.innerHTML = `<strong>Total: ${estado.total} ${estado.total === 1 ? 'dependente' : 'dependentes'}</strong>`;
  }
}

function renderizarPaginacao() {
  if (!refs.paginacao) return;

  const atual = estado.paginaAtual;
  const total = estado.totalPaginas;
  let html = '';

  html += `
    <button type="button" class="dependentes__pagina-btn"
            data-pagina="${atual - 1}" ${atual === 1 ? 'disabled' : ''} aria-label="Página anterior">
      <span class="material-icons">chevron_left</span>
    </button>
  `;

  const paginas = calcularPaginasVisiveis(atual, total);
  for (const p of paginas) {
    if (p === '...') {
      html += `<button type="button" class="dependentes__pagina-btn" disabled>…</button>`;
    } else {
      html += `
        <button type="button"
                class="dependentes__pagina-btn ${p === atual ? 'dependentes__pagina-btn--ativo' : ''}"
                data-pagina="${p}">
          ${p}
        </button>
      `;
    }
  }

  html += `
    <button type="button" class="dependentes__pagina-btn"
            data-pagina="${atual + 1}" ${atual === total ? 'disabled' : ''} aria-label="Próxima página">
      <span class="material-icons">chevron_right</span>
    </button>
  `;

  refs.paginacao.innerHTML = html;
  refs.paginacao.addEventListener('click', tratarCliquePaginacao);
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

/* ---------------------------------------------------------
   EVENTOS: FILTROS
--------------------------------------------------------- */
function ativarFiltros() {
  // Permite Enter no input de busca
  if (refs.inputBusca) {
    refs.inputBusca.addEventListener('keypress', e => {
      if (e.key === 'Enter') {
        executarBusca();
      }
    });
  }
}

function ativarBotaoBuscar() {
  refs.btnBuscar?.addEventListener('click', executarBusca);
}

function executarBusca() {
  estado.termoBusca = (refs.inputBusca?.value ?? '').trim();
  estado.filtroParentesco = refs.filtroParentesco?.value ?? '';
  estado.filtroGenero = refs.filtroGenero?.value ?? '';
  estado.filtroIdadeMin = refs.filtroIdadeMin?.value ? parseInt(refs.filtroIdadeMin.value, 10) : null;
  estado.filtroIdadeMax = refs.filtroIdadeMax?.value ? parseInt(refs.filtroIdadeMax.value, 10) : null;
  estado.filtroRua = refs.filtroRua?.value ?? '';
  estado.filtroStatus = refs.filtroStatus?.value ?? '';
  estado.paginaAtual = 1;
  buscarEAtualizar();
}

function ativarBotaoLimpar() {
  refs.btnLimparFiltros?.addEventListener('click', () => {
    if (refs.inputBusca) refs.inputBusca.value = '';
    if (refs.filtroParentesco) refs.filtroParentesco.value = '';
    if (refs.filtroGenero) refs.filtroGenero.value = '';
    if (refs.filtroIdadeMin) refs.filtroIdadeMin.value = '';
    if (refs.filtroIdadeMax) refs.filtroIdadeMax.value = '';
    if (refs.filtroRua) refs.filtroRua.value = '';
    if (refs.filtroStatus) refs.filtroStatus.value = '';

    estado.termoBusca = '';
    estado.filtroParentesco = '';
    estado.filtroGenero = '';
    estado.filtroIdadeMin = null;
    estado.filtroIdadeMax = null;
    estado.filtroRua = '';
    estado.filtroStatus = '';
    estado.paginaAtual = 1;

    buscarEAtualizar();
  });
}

function tratarCliquePaginacao(e) {
  const btn = e.target.closest('[data-pagina]');
  if (!btn || btn.disabled) return;

  const pagina = parseInt(btn.dataset.pagina, 10);
  if (isNaN(pagina) || pagina < 1 || pagina > estado.totalPaginas) return;

  estado.paginaAtual = pagina;
  buscarEAtualizar();
  document.querySelector('.dependentes__tabela-wrapper')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function tratarCliqueAcao(e) {
  const btn = e.target.closest('[data-acao]');
  if (!btn) return;

  const acao = btn.dataset.acao;
  const id = parseInt(btn.dataset.id, 10);
  const idAssociado = parseInt(btn.dataset.idAssociado, 10);

  switch (acao) {
    case 'editar': aoEditar(idAssociado, id); break;
    case 'ver-associado': aoVerAssociado(idAssociado); break;
  }
}

function aoEditar(idAssociado, idDependente) {
  window.location.hash = `#/cadastro/novo-associado?id=${idAssociado}&tab=dependentes&dep=${idDependente}`;
}

function aoVerAssociado(idAssociado) {
  window.location.hash = `#/cadastro/novo-associado?id=${idAssociado}`;
}

/* ---------------------------------------------------------
   MODAL RELATÓRIO
--------------------------------------------------------- */
function ativarRelatorio() {
  refs.btnGerarRelatorio?.addEventListener('click', () => {
    refs.modalRelatorio?.removeAttribute('hidden');
  });

  document.querySelectorAll('[data-close-modal]').forEach(el => {
    el.addEventListener('click', () => {
      refs.modalRelatorio?.setAttribute('hidden', '');
    });
  });

  refs.btnConfirmarRelatorio?.addEventListener('click', () => {
    const tipoRelatorio = document.querySelector('input[name="tipo-relatorio"]:checked')?.value;
    const formatos = Array.from(document.querySelectorAll('input[name="formato"]:checked')).map(el => el.value);

    if (!tipoRelatorio) {
      Toast.aviso('Selecione um tipo de relatório.');
      return;
    }

    if (formatos.length === 0) {
      Toast.aviso('Selecione pelo menos um formato.');
      return;
    }

    gerarRelatorio(tipoRelatorio, formatos);
    refs.modalRelatorio?.setAttribute('hidden', '');
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !refs.modalRelatorio?.hidden) {
      refs.modalRelatorio?.setAttribute('hidden', '');
    }
  });
}

function gerarRelatorio(tipo, formatos) {
  const dados = aplicarFiltros(dependentesMock);

  if (dados.length === 0) {
    Toast.aviso('Nenhum dependente para gerar relatório com os filtros aplicados.');
    return;
  }

  try {
    if (formatos.includes('pdf')) gerarPDF(tipo, dados);
    if (formatos.includes('excel')) gerarExcel(tipo, dados);
    Toast.sucesso(`Relatório(s) gerado(s) com sucesso!`);
  } catch (erro) {
    console.error('[DependentesListar] Erro ao gerar relatório:', erro);
    Toast.erro('Erro ao gerar relatório.');
  }
}

function gerarPDF(tipo, dados) {
  let conteudo = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Relatório de Dependentes</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; font-size: 11px; }
        .cabecalho { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #000; padding-bottom: 10px; }
        .titulo { font-size: 18px; font-weight: bold; margin-bottom: 5px; }
        .subtitulo { font-size: 12px; color: #666; }
        .data { font-size: 10px; color: #999; margin-top: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #f0f0f0; border: 1px solid #ccc; padding: 8px; text-align: left; font-weight: bold; }
        td { border: 1px solid #ccc; padding: 6px; }
        tr:nth-child(even) { background: #f9f9f9; }
        .agrupamento { background: #e8e8e8; font-weight: bold; padding: 10px 0; margin-top: 10px; }
      </style>
    </head>
    <body>
      <div class="cabecalho">
        <div class="titulo">AMBC - Relatório de Dependentes</div>
        <div class="subtitulo">Associação dos Moradores do Bairro Califórnia</div>
      </div>
  `;

  if (tipo === 'completo') {
    conteudo += `
      <h3>Lista Completa de Dependentes</h3>
      <table>
        <thead>
          <tr>
            <th>#ID</th>
            <th>Nome</th>
            <th>Associado</th>
            <th>Parentesco</th>
            <th>Data Nascimento</th>
            <th>Idade</th>
            <th>Gênero</th>
            <th>Rua</th>
          </tr>
        </thead>
        <tbody>
    `;
    dados.forEach(d => {
      const idade = calcularIdade(d.data_nascimento);
      const dataNasc = formatarData(d.data_nascimento);
      conteudo += `
        <tr>
          <td>#${String(d.id_dependente).padStart(3, '0')}</td>
          <td>${escaparHtml(d.nome)}</td>
          <td>${escaparHtml(d.associado)}</td>
          <td>${capitalize(d.parentesco)}</td>
          <td>${dataNasc}</td>
          <td>${idade}</td>
          <td>${d.genero === 'M' ? 'Masculino' : d.genero === 'F' ? 'Feminino' : 'Outro'}</td>
          <td>${escaparHtml(d.rua)}</td>
        </tr>
      `;
    });
    conteudo += `</tbody></table>`;
  } else if (tipo === 'criancas-rua') {
    const criancas = dados.filter(d => calcularIdade(d.data_nascimento) <= 12);
    const porRua = {};
    criancas.forEach(d => {
      if (!porRua[d.rua]) porRua[d.rua] = [];
      porRua[d.rua].push(d);
    });

    conteudo += `<h3>Crianças por Rua (até 12 anos)</h3>`;
    Object.keys(porRua).sort().forEach(rua => {
      conteudo += `
        <div class="agrupamento">Rua: ${rua} (${porRua[rua].length} crianças)</div>
        <table>
          <thead>
            <tr>
              <th>Nome</th>
              <th>Associado</th>
              <th>Idade</th>
              <th>Gênero</th>
            </tr>
          </thead>
          <tbody>
      `;
      porRua[rua].forEach(d => {
        const idade = calcularIdade(d.data_nascimento);
        conteudo += `
          <tr>
            <td>${escaparHtml(d.nome)}</td>
            <td>${escaparHtml(d.associado)}</td>
            <td>${idade}</td>
            <td>${d.genero === 'M' ? 'M' : d.genero === 'F' ? 'F' : 'O'}</td>
          </tr>
        `;
      });
      conteudo += `</tbody></table>`;
    });
  } else if (tipo === 'estatisticas') {
    const stats = calcularEstatisticas(dados);
    conteudo += `<h3>Estatísticas de Dependentes</h3>`;
    conteudo += `<p><strong>Total de Dependentes:</strong> ${stats.total}</p>`;

    conteudo += `<h4>Por Parentesco:</h4><ul>`;
    Object.entries(stats.porParentesco).forEach(([parentesco, count]) => {
      conteudo += `<li>${capitalize(parentesco)}: ${count}</li>`;
    });
    conteudo += `</ul>`;

    conteudo += `<h4>Por Gênero:</h4><ul>`;
    conteudo += `<li>Masculino: ${stats.porGenero.M}</li>`;
    conteudo += `<li>Feminino: ${stats.porGenero.F}</li>`;
    conteudo += `<li>Outro: ${stats.porGenero.O}</li>`;
    conteudo += `</ul>`;

    conteudo += `<h4>Por Faixa Etária:</h4><ul>`;
    conteudo += `<li>0-5 anos: ${stats.porFaixaEtaria['0-5']}</li>`;
    conteudo += `<li>6-12 anos: ${stats.porFaixaEtaria['6-12']}</li>`;
    conteudo += `<li>13-18 anos: ${stats.porFaixaEtaria['13-18']}</li>`;
    conteudo += `<li>19-30 anos: ${stats.porFaixaEtaria['19-30']}</li>`;
    conteudo += `<li>30+ anos: ${stats.porFaixaEtaria['30+']}</li>`;
    conteudo += `</ul>`;
  }

  conteudo += `
      <div class="data">Gerado em: ${new Date().toLocaleString('pt-BR')}</div>
    </body>
    </html>
  `;

  const blob = new Blob([conteudo], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `relatorio-dependentes-${tipo}-${new Date().toISOString().split('T')[0]}.html`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function gerarExcel(tipo, dados) {
  let csv = '';

  if (tipo === 'completo') {
    csv = 'ID,Nome,Associado,Parentesco,Data Nascimento,Idade,Gênero,Rua\n';
    dados.forEach(d => {
      const idade = calcularIdade(d.data_nascimento);
      const dataNasc = formatarData(d.data_nascimento);
      csv += `${d.id_dependente},"${d.nome}","${d.associado}","${capitalize(d.parentesco)}","${dataNasc}",${idade},"${d.genero === 'M' ? 'Masculino' : d.genero === 'F' ? 'Feminino' : 'Outro'}","${d.rua}"\n`;
    });
  } else if (tipo === 'criancas-rua') {
    csv = 'Rua,Nome,Associado,Idade,Gênero\n';
    const criancas = dados.filter(d => calcularIdade(d.data_nascimento) <= 12);
    const porRua = {};
    criancas.forEach(d => {
      if (!porRua[d.rua]) porRua[d.rua] = [];
      porRua[d.rua].push(d);
    });
    Object.keys(porRua).sort().forEach(rua => {
      porRua[rua].forEach(d => {
        const idade = calcularIdade(d.data_nascimento);
        csv += `"${rua}","${d.nome}","${d.associado}",${idade},"${d.genero === 'M' ? 'M' : d.genero === 'F' ? 'F' : 'O'}"\n`;
      });
    });
  } else if (tipo === 'estatisticas') {
    const stats = calcularEstatisticas(dados);
    csv = 'Tipo,Categoria,Quantidade\n';
    csv += `"Geral","Total Dependentes",${stats.total}\n`;
    Object.entries(stats.porParentesco).forEach(([parentesco, count]) => {
      csv += `"Parentesco","${capitalize(parentesco)}",${count}\n`;
    });
    csv += `"Gênero","Masculino",${stats.porGenero.M}\n`;
    csv += `"Gênero","Feminino",${stats.porGenero.F}\n`;
    csv += `"Gênero","Outro",${stats.porGenero.O}\n`;
    csv += `"Faixa Etária","0-5 anos",${stats.porFaixaEtaria['0-5']}\n`;
    csv += `"Faixa Etária","6-12 anos",${stats.porFaixaEtaria['6-12']}\n`;
    csv += `"Faixa Etária","13-18 anos",${stats.porFaixaEtaria['13-18']}\n`;
    csv += `"Faixa Etária","19-30 anos",${stats.porFaixaEtaria['19-30']}\n`;
    csv += `"Faixa Etária","30+ anos",${stats.porFaixaEtaria['30+']}\n`;
  }

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `relatorio-dependentes-${tipo}-${new Date().toISOString().split('T')[0]}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function calcularEstatisticas(dados) {
  const stats = {
    total: dados.length,
    porParentesco: {},
    porGenero: { M: 0, F: 0, O: 0 },
    porFaixaEtaria: { '0-5': 0, '6-12': 0, '13-18': 0, '19-30': 0, '30+': 0 },
  };

  dados.forEach(d => {
    const parentesco = d.parentesco;
    stats.porParentesco[parentesco] = (stats.porParentesco[parentesco] || 0) + 1;

    stats.porGenero[d.genero]++;

    const idade = calcularIdade(d.data_nascimento);
    if (idade <= 5) stats.porFaixaEtaria['0-5']++;
    else if (idade <= 12) stats.porFaixaEtaria['6-12']++;
    else if (idade <= 18) stats.porFaixaEtaria['13-18']++;
    else if (idade <= 30) stats.porFaixaEtaria['19-30']++;
    else stats.porFaixaEtaria['30+']++;
  });

  return stats;
}

/* ---------------------------------------------------------
   HELPERS
--------------------------------------------------------- */

function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
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
