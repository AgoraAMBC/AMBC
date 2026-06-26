/* =========================================================
   cadastro-dependentes.js
   Projeto: AMBC-V2
   Pagina: Listagem de Dependentes
========================================================= */

import Toast from '../componentes/toast.js';
import { formatarData } from '../core/formatadores.js';
import { DependentesService } from '../services/dependentes-service.js';
import { api } from '../services/api.js';

/* ---------------------------------------------------------
   ESTADO INTERNO
--------------------------------------------------------- */
const estado = {
  termoBusca:       '',
  filtroParentesco: '',
  filtroGenero:     '',
  filtroIdadeMin:   null,
  filtroIdadeMax:   null,
  filtroRua:        '',
  filtroStatus:     '',
  paginaAtual:      1,
  totalPaginas:     1,
  total:            0,
  carregando:       false,
  dependentesAtual: [],
};

/* ---------------------------------------------------------
   REFERÊNCIAS DOM
--------------------------------------------------------- */
const refs = {
  inputBusca:          null,
  filtroParentesco:    null,
  filtroGenero:        null,
  filtroIdadeMin:      null,
  filtroIdadeMax:      null,
  filtroRua:           null,
  filtroStatus:        null,
  btnBuscar:           null,
  btnLimparFiltros:    null,
  tbody:               null,
  contador:            null,
  contadorTotal:       null,
  paginacao:           null,
  estadoVazio:         null,
  btnGerarRelatorio:   null,
  modalRelatorio:      null,
  btnConfirmarRelatorio: null,
};

/* ---------------------------------------------------------
   INIT / DESTROY
--------------------------------------------------------- */
function init() {
  refs.inputBusca           = document.getElementById('input-busca');
  refs.filtroParentesco     = document.getElementById('filtro-parentesco');
  refs.filtroGenero         = document.getElementById('filtro-genero');
  refs.filtroIdadeMin       = document.getElementById('filtro-idade-min');
  refs.filtroIdadeMax       = document.getElementById('filtro-idade-max');
  refs.filtroRua            = document.getElementById('filtro-rua');
  refs.filtroStatus         = document.getElementById('filtro-status');
  refs.btnBuscar            = document.getElementById('btn-buscar');
  refs.btnLimparFiltros     = document.getElementById('btn-limpar-filtros');
  refs.tbody                = document.getElementById('tbody-dependentes');
  refs.contador             = document.getElementById('contador-registros');
  refs.contadorTotal        = document.getElementById('contador-total');
  refs.paginacao            = document.getElementById('paginacao');
  refs.estadoVazio          = document.getElementById('estado-vazio');
  refs.btnGerarRelatorio    = document.getElementById('btn-gerar-relatorio');
  refs.modalRelatorio       = document.getElementById('modal-relatorio');
  refs.btnConfirmarRelatorio = document.getElementById('btn-confirmar-relatorio');

  estado.termoBusca       = '';
  estado.filtroParentesco = '';
  estado.filtroGenero     = '';
  estado.filtroIdadeMin   = null;
  estado.filtroIdadeMax   = null;
  estado.filtroRua        = '';
  estado.filtroStatus     = '';
  estado.paginaAtual      = 1;

  preencherSelectsAuxiliares();
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
   SELECTS AUXILIARES (parentesco + gênero)
--------------------------------------------------------- */
async function preencherSelectsAuxiliares() {
  try {
    const [parentescos, generos] = await Promise.all([
      api.get('/parentesco/listar.php'),
      api.get('/generos/listar.php'),
    ]);

    if (refs.filtroParentesco) {
      refs.filtroParentesco.innerHTML = '<option value="">Parentesco: Todos</option>' +
        parentescos.map(p => `<option value="${p.id}">${escaparHtml(p.descricao)}</option>`).join('');
    }

    if (refs.filtroGenero) {
      refs.filtroGenero.innerHTML = '<option value="">Gênero: Todos</option>' +
        generos.map(g => `<option value="${g.id}">${escaparHtml(g.descricao)}</option>`).join('');
    }
  } catch (err) {
    console.error('[DependentesListar] Erro ao carregar selects auxiliares:', err);
  }
}

/* ---------------------------------------------------------
   BUSCA E RENDERIZAÇÃO
--------------------------------------------------------- */
async function buscarEAtualizar() {
  if (estado.carregando) return;
  estado.carregando = true;

  if (refs.tbody) {
    refs.tbody.innerHTML = `<tr><td colspan="9" style="text-align:center;padding:2rem">Carregando…</td></tr>`;
  }

  const filtros = {
    pagina:        estado.paginaAtual,
    busca:         estado.termoBusca       || undefined,
    status:        estado.filtroStatus     || undefined,
    id_parentesco: estado.filtroParentesco || undefined,
    id_genero:     estado.filtroGenero     || undefined,
    idade_min:     estado.filtroIdadeMin   ?? undefined,
    idade_max:     estado.filtroIdadeMax   ?? undefined,
    logradouro:    estado.filtroRua        || undefined,
  };

  try {
    const resp = await DependentesService.listar(filtros);
    estado.total            = resp.total   ?? 0;
    estado.totalPaginas     = resp.paginas ?? 1;
    estado.dependentesAtual = resp.dados   ?? [];

    renderizarLinhas(estado.dependentesAtual);
    renderizarContador(estado.dependentesAtual.length);
    renderizarPaginacao();
    alternarEstadoVazio(estado.dependentesAtual.length === 0);
  } catch (erro) {
    console.error('[DependentesListar] Erro ao buscar dependentes:', erro);
    Toast.erro('Não foi possível carregar os dependentes.');
    if (refs.tbody) {
      refs.tbody.innerHTML = `<tr><td colspan="9" style="text-align:center;padding:2rem">Erro ao carregar dados.</td></tr>`;
    }
  } finally {
    estado.carregando = false;
  }
}

/* ---------------------------------------------------------
   RENDERIZAÇÃO
--------------------------------------------------------- */
function renderizarLinhas(dependentes) {
  if (!refs.tbody) return;
  if (!dependentes.length) { refs.tbody.innerHTML = ''; return; }

  refs.tbody.innerHTML = dependentes.map(d => {
    const idade       = calcularIdade(d.data_nascimento);
    const dataNasc    = d.data_nascimento ? formatarData(d.data_nascimento) : '—';
    const generoDescr = d.genero ?? '—';
    const iconeGenero = generoDescr === 'Masculino' ? 'male' : generoDescr === 'Feminino' ? 'female' : 'person';
    const parentesco  = d.parentesco  ?? '—';
    const logradouro  = d.logradouro  ?? '—';

    return `
      <tr data-id="${d.id_dependente}">
        <td>#${String(d.id_dependente).padStart(3, '0')}</td>
        <td><strong>${escaparHtml(d.nome)}</strong></td>
        <td>
          <button type="button" class="dependentes__link-associado" data-acao="ver-associado" data-id="${d.id_associado_pai}">
            ${escaparHtml(d.nome_associado ?? '—')}
          </button>
        </td>
        <td>
          <span class="dependentes__badge">
            ${escaparHtml(parentesco)}
          </span>
        </td>
        <td><strong>${idade} anos</strong></td>
        <td>${dataNasc}</td>
        <td>${escaparHtml(logradouro)}</td>
        <td>
          <span class="dependentes__genero">
            <span class="material-icons">${iconeGenero}</span>
            ${escaparHtml(generoDescr)}
          </span>
        </td>
        <td class="dependentes__col-acoes">
          <div class="dependentes__acoes">
            <button type="button" class="dependentes__acao dependentes__acao--editar"
              data-acao="editar" data-id="${d.id_dependente}" data-id-associado="${d.id_associado_pai}"
              aria-label="Editar dependente">
              <span class="material-icons">edit</span>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');

  refs.tbody.onclick = tratarCliqueAcao;
}

function renderizarContador(exibindo) {
  if (refs.contador) {
    refs.contador.textContent = `Exibindo ${exibindo} de ${estado.total} ${estado.total === 1 ? 'dependente' : 'dependentes'}`;
  }
  if (refs.contadorTotal) {
    refs.contadorTotal.innerHTML = `<strong>Total: ${estado.total} ${estado.total === 1 ? 'dependente' : 'dependentes'}</strong>`;
  }
}

function renderizarPaginacao() {
  if (!refs.paginacao) return;

  const atual = estado.paginaAtual;
  const total = estado.totalPaginas;
  let html = '';

  html += `<button type="button" class="dependentes__pagina-btn"
    data-pagina="${atual - 1}" ${atual === 1 ? 'disabled' : ''} aria-label="Página anterior">
    <span class="material-icons">chevron_left</span></button>`;

  for (const p of calcularPaginasVisiveis(atual, total)) {
    if (p === '...') {
      html += `<button type="button" class="dependentes__pagina-btn" disabled>…</button>`;
    } else {
      html += `<button type="button"
        class="dependentes__pagina-btn ${p === atual ? 'dependentes__pagina-btn--ativo' : ''}"
        data-pagina="${p}">${p}</button>`;
    }
  }

  html += `<button type="button" class="dependentes__pagina-btn"
    data-pagina="${atual + 1}" ${atual === total ? 'disabled' : ''} aria-label="Próxima página">
    <span class="material-icons">chevron_right</span></button>`;

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
  if (refs.estadoVazio) refs.estadoVazio.hidden = !vazio;
}

/* ---------------------------------------------------------
   EVENTOS: FILTROS
--------------------------------------------------------- */
function ativarFiltros() {
  refs.inputBusca?.addEventListener('keypress', e => {
    if (e.key === 'Enter') executarBusca();
  });
}

function ativarBotaoBuscar() {
  refs.btnBuscar?.addEventListener('click', executarBusca);
}

function executarBusca() {
  estado.termoBusca       = refs.inputBusca?.value.trim()    ?? '';
  estado.filtroParentesco = refs.filtroParentesco?.value      ?? '';
  estado.filtroGenero     = refs.filtroGenero?.value          ?? '';
  estado.filtroIdadeMin   = refs.filtroIdadeMin?.value ? parseInt(refs.filtroIdadeMin.value, 10) : null;
  estado.filtroIdadeMax   = refs.filtroIdadeMax?.value ? parseInt(refs.filtroIdadeMax.value, 10) : null;
  estado.filtroRua        = refs.filtroRua?.value.trim()     ?? '';
  estado.filtroStatus     = refs.filtroStatus?.value          ?? '';
  estado.paginaAtual      = 1;
  buscarEAtualizar();
}

function ativarBotaoLimpar() {
  refs.btnLimparFiltros?.addEventListener('click', () => {
    if (refs.inputBusca)       refs.inputBusca.value       = '';
    if (refs.filtroParentesco) refs.filtroParentesco.value = '';
    if (refs.filtroGenero)     refs.filtroGenero.value     = '';
    if (refs.filtroIdadeMin)   refs.filtroIdadeMin.value   = '';
    if (refs.filtroIdadeMax)   refs.filtroIdadeMax.value   = '';
    if (refs.filtroRua)        refs.filtroRua.value        = '';
    if (refs.filtroStatus)     refs.filtroStatus.value     = '';

    estado.termoBusca       = '';
    estado.filtroParentesco = '';
    estado.filtroGenero     = '';
    estado.filtroIdadeMin   = null;
    estado.filtroIdadeMax   = null;
    estado.filtroRua        = '';
    estado.filtroStatus     = '';
    estado.paginaAtual      = 1;
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
  const acao        = btn.dataset.acao;
  const id          = parseInt(btn.dataset.id, 10);
  const idAssociado = parseInt(btn.dataset.idAssociado, 10);

  switch (acao) {
    case 'editar':        aoEditar(idAssociado, id); break;
    case 'ver-associado': aoVerAssociado(id);        break;
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
    el.addEventListener('click', () => refs.modalRelatorio?.setAttribute('hidden', ''));
  });

  refs.btnConfirmarRelatorio?.addEventListener('click', async () => {
    const tipoRelatorio = document.querySelector('input[name="tipo-relatorio"]:checked')?.value;
    const formatos = Array.from(document.querySelectorAll('input[name="formato"]:checked')).map(el => el.value);

    if (!tipoRelatorio) { Toast.aviso('Selecione um tipo de relatório.'); return; }
    if (!formatos.length) { Toast.aviso('Selecione pelo menos um formato.'); return; }

    refs.modalRelatorio?.setAttribute('hidden', '');
    await gerarRelatorio(tipoRelatorio, formatos);
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !refs.modalRelatorio?.hidden) {
      refs.modalRelatorio?.setAttribute('hidden', '');
    }
  });
}

async function gerarRelatorio(tipo, formatos) {
  let dados;
  try {
    const resp = await DependentesService.listar({
      busca:         estado.termoBusca       || undefined,
      status:        estado.filtroStatus     || undefined,
      id_parentesco: estado.filtroParentesco || undefined,
      id_genero:     estado.filtroGenero     || undefined,
      idade_min:     estado.filtroIdadeMin   ?? undefined,
      idade_max:     estado.filtroIdadeMax   ?? undefined,
      logradouro:    estado.filtroRua        || undefined,
      sem_paginacao: '1',
    });
    dados = resp.dados ?? [];
  } catch (err) {
    Toast.erro('Erro ao buscar dados para o relatório.');
    return;
  }

  if (!dados.length) {
    Toast.aviso('Nenhum dependente para gerar relatório com os filtros aplicados.');
    return;
  }

  try {
    if (formatos.includes('pdf'))   gerarPDF(tipo, dados);
    if (formatos.includes('excel')) gerarExcel(tipo, dados);
    Toast.sucesso('Relatório(s) gerado(s) com sucesso!');
  } catch (erro) {
    console.error('[DependentesListar] Erro ao gerar relatório:', erro);
    Toast.erro('Erro ao gerar relatório.');
  }
}

function gerarPDF(tipo, dados) {
  let conteudo = `
    <!DOCTYPE html><html><head>
    <meta charset="UTF-8">
    <title>Relatório de Dependentes</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; font-size: 11px; }
      .cabecalho { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #000; padding-bottom: 10px; }
      .titulo { font-size: 18px; font-weight: bold; margin-bottom: 5px; }
      .subtitulo { font-size: 12px; color: #666; }
      table { width: 100%; border-collapse: collapse; margin-top: 10px; }
      th { background: #f0f0f0; border: 1px solid #ccc; padding: 8px; text-align: left; font-weight: bold; }
      td { border: 1px solid #ccc; padding: 6px; }
      tr:nth-child(even) { background: #f9f9f9; }
      .agrupamento { background: #e8e8e8; font-weight: bold; padding: 10px; margin-top: 10px; }
    </style>
    </head><body>
    <div class="cabecalho">
      <div class="titulo">AMBC - Relatório de Dependentes</div>
      <div class="subtitulo">Associação dos Moradores do Bairro Califórnia</div>
    </div>
  `;

  if (tipo === 'completo') {
    conteudo += `
      <h3>Lista Completa de Dependentes</h3>
      <table><thead><tr>
        <th>#ID</th><th>Nome</th><th>Associado</th><th>Parentesco</th>
        <th>Nasc.</th><th>Idade</th><th>Gênero</th><th>Logradouro</th>
      </tr></thead><tbody>
    `;
    dados.forEach(d => {
      const idade = calcularIdade(d.data_nascimento);
      conteudo += `<tr>
        <td>#${String(d.id_dependente).padStart(3, '0')}</td>
        <td><strong>${escaparHtml(d.nome)}</strong></td>
        <td>${escaparHtml(d.nome_associado ?? '—')}</td>
        <td>${escaparHtml(d.parentesco ?? '—')}</td>
        <td>${d.data_nascimento ? formatarData(d.data_nascimento) : '—'}</td>
        <td><strong>${idade}</strong></td>
        <td>${escaparHtml(d.genero ?? '—')}</td>
        <td>${escaparHtml(d.logradouro ?? '—')}</td>
      </tr>`;
    });
    conteudo += `</tbody></table>`;

  } else if (tipo === 'criancas-rua') {
    const criancas = dados.filter(d => calcularIdade(d.data_nascimento) <= 12);
    const porRua = {};
    criancas.forEach(d => {
      const rua = d.logradouro ?? 'Sem logradouro';
      if (!porRua[rua]) porRua[rua] = [];
      porRua[rua].push(d);
    });
    conteudo += `<h3>Crianças por Logradouro (até 12 anos)</h3>`;
    Object.keys(porRua).sort().forEach(rua => {
      conteudo += `<div class="agrupamento">${rua} (${porRua[rua].length} crianças)</div>
        <table><thead><tr><th>Nome</th><th>Associado</th><th>Idade</th><th>Gênero</th></tr></thead><tbody>`;
      porRua[rua].forEach(d => {
        conteudo += `<tr>
          <td>${escaparHtml(d.nome)}</td>
          <td>${escaparHtml(d.nome_associado ?? '—')}</td>
          <td>${calcularIdade(d.data_nascimento)}</td>
          <td>${escaparHtml(d.genero ?? '—')}</td>
        </tr>`;
      });
      conteudo += `</tbody></table>`;
    });

  } else if (tipo === 'estatisticas') {
    const stats = calcularEstatisticas(dados);
    conteudo += `<h3>Estatísticas de Dependentes</h3>
      <p><strong>Total:</strong> ${stats.total}</p>
      <h4>Por Parentesco:</h4><ul>`;
    Object.entries(stats.porParentesco).forEach(([p, n]) => { conteudo += `<li>${escaparHtml(p)}: ${n}</li>`; });
    conteudo += `</ul><h4>Por Gênero:</h4><ul>`;
    Object.entries(stats.porGenero).forEach(([g, n]) => { conteudo += `<li>${escaparHtml(g)}: ${n}</li>`; });
    conteudo += `</ul><h4>Por Faixa Etária:</h4><ul>`;
    Object.entries(stats.porFaixaEtaria).forEach(([f, n]) => { conteudo += `<li>${f} anos: ${n}</li>`; });
    conteudo += `</ul>`;
  }

  conteudo += `<div style="font-size:10px;color:#999;margin-top:20px">Gerado em: ${new Date().toLocaleString('pt-BR')}</div></body></html>`;

  _baixar(conteudo, `relatorio-dependentes-${tipo}-${new Date().toISOString().split('T')[0]}.html`, 'text/html');
}

function gerarExcel(tipo, dados) {
  let csv = '';

  if (tipo === 'completo') {
    csv = 'ID,Nome,Associado,Parentesco,Nascimento,Idade,Gênero,Logradouro\n';
    dados.forEach(d => {
      csv += `${d.id_dependente},"${d.nome}","${d.nome_associado ?? ''}","${d.parentesco ?? ''}","${d.data_nascimento ?? ''}",${calcularIdade(d.data_nascimento)},"${d.genero ?? ''}","${d.logradouro ?? ''}"\n`;
    });
  } else if (tipo === 'criancas-rua') {
    csv = 'Logradouro,Nome,Associado,Idade,Gênero\n';
    dados.filter(d => calcularIdade(d.data_nascimento) <= 12).forEach(d => {
      csv += `"${d.logradouro ?? ''}","${d.nome}","${d.nome_associado ?? ''}",${calcularIdade(d.data_nascimento)},"${d.genero ?? ''}"\n`;
    });
  } else if (tipo === 'estatisticas') {
    const stats = calcularEstatisticas(dados);
    csv = 'Tipo,Categoria,Quantidade\n';
    csv += `"Geral","Total",${stats.total}\n`;
    Object.entries(stats.porParentesco).forEach(([p, n]) => { csv += `"Parentesco","${p}",${n}\n`; });
    Object.entries(stats.porGenero).forEach(([g, n]) => { csv += `"Gênero","${g}",${n}\n`; });
    Object.entries(stats.porFaixaEtaria).forEach(([f, n]) => { csv += `"Faixa Etária","${f} anos",${n}\n`; });
  }

  _baixar(csv, `relatorio-dependentes-${tipo}-${new Date().toISOString().split('T')[0]}.csv`, 'text/csv;charset=utf-8;');
}

function _baixar(conteudo, nomeArquivo, tipo) {
  const blob = new Blob([conteudo], { type: tipo });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url;
  a.download = nomeArquivo;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function calcularEstatisticas(dados) {
  const stats = { total: dados.length, porParentesco: {}, porGenero: {}, porFaixaEtaria: { '0-5': 0, '6-12': 0, '13-18': 0, '19-30': 0, '30+': 0 } };
  dados.forEach(d => {
    const p = d.parentesco ?? 'Não informado';
    stats.porParentesco[p] = (stats.porParentesco[p] || 0) + 1;

    const g = d.genero ?? 'Não informado';
    stats.porGenero[g] = (stats.porGenero[g] || 0) + 1;

    const idade = calcularIdade(d.data_nascimento);
    if      (idade <=  5) stats.porFaixaEtaria['0-5']++;
    else if (idade <= 12) stats.porFaixaEtaria['6-12']++;
    else if (idade <= 18) stats.porFaixaEtaria['13-18']++;
    else if (idade <= 30) stats.porFaixaEtaria['19-30']++;
    else                  stats.porFaixaEtaria['30+']++;
  });
  return stats;
}

/* ---------------------------------------------------------
   HELPERS
--------------------------------------------------------- */
function calcularIdade(dataNascimento) {
  if (!dataNascimento) return 0;
  const str  = /^\d{4}-\d{2}-\d{2}$/.test(String(dataNascimento)) ? `${dataNascimento}T12:00:00` : dataNascimento;
  const hoje = new Date();
  const nasc = new Date(str);
  let idade  = hoje.getFullYear() - nasc.getFullYear();
  const m    = hoje.getMonth() - nasc.getMonth();
  if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) idade--;
  return idade;
}

function escaparHtml(texto) {
  if (texto == null) return '';
  return String(texto)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
}

/* ---------------------------------------------------------
   EXPORT
--------------------------------------------------------- */
export default { init, destroy };
