/* =========================================================
   Página: Financeiro
   Projeto: AMBC-V2
   Descrição: Lógica das telas financeiras.
========================================================= */

import Toast from '../componentes/toast.js';
import Modal from '../componentes/modal.js';
import { api } from '../services/api.js';

const lancamentos = [
  { id: 1, descricao: 'Mensalidade - Maria Oliveira', conta: 'Receitas associativas', subconta: 'Mensalidades', tipo: 'receita', status: 'pago', vencimento: '2026-04-05', valor: 85.00, pessoa: 'Maria Oliveira' },
  { id: 2, descricao: 'Reserva do salão comunitário', conta: 'Eventos e reservas', subconta: 'Reserva de espaço', tipo: 'receita', status: 'pendente', vencimento: '2026-04-18', valor: 260.00, pessoa: 'Carlos Mendes' },
  { id: 3, descricao: 'Conta de energia da sede', conta: 'Despesas administrativas', subconta: 'Contas de consumo', tipo: 'despesa', status: 'pago', vencimento: '2026-04-12', valor: 418.72, pessoa: 'Companhia de energia' },
  { id: 4, descricao: 'Compra de material de limpeza', conta: 'Manutenção e obras', subconta: 'Material de consumo', tipo: 'despesa', status: 'pago', vencimento: '2026-04-14', valor: 173.35, pessoa: 'Mercado Central' },
  { id: 5, descricao: 'Mensalidade - João Souza', conta: 'Receitas associativas', subconta: 'Mensalidades', tipo: 'receita', status: 'atrasado', vencimento: '2026-04-10', valor: 85.00, pessoa: 'João Souza' },
  { id: 6, descricao: 'Serviço de pintura da quadra', conta: 'Manutenção e obras', subconta: 'Serviços contratados', tipo: 'despesa', status: 'pendente', vencimento: '2026-04-25', valor: 980.00, pessoa: 'Pinturas Alfa' },
];

const contasRegentes = [
  { id: 1, nome: 'Receitas associativas', tipo: 'receita', subcontas: 2, status: 'ativo' },
  { id: 2, nome: 'Eventos e reservas', tipo: 'receita', subcontas: 2, status: 'ativo' },
  { id: 3, nome: 'Despesas administrativas', tipo: 'despesa', subcontas: 3, status: 'ativo' },
  { id: 4, nome: 'Manutenção e obras', tipo: 'despesa', subcontas: 4, status: 'ativo' },
];

const contasSubordinadas = [
  { id: 1, nome: 'Mensalidades', regente: 'Receitas associativas', movimentos: 38, status: 'ativo' },
  { id: 2, nome: 'Taxas extraordinárias', regente: 'Receitas associativas', movimentos: 7, status: 'ativo' },
  { id: 3, nome: 'Reserva de espaço', regente: 'Eventos e reservas', movimentos: 12, status: 'ativo' },
  { id: 4, nome: 'Contas de consumo', regente: 'Despesas administrativas', movimentos: 9, status: 'ativo' },
  { id: 5, nome: 'Material de consumo', regente: 'Manutenção e obras', movimentos: 16, status: 'ativo' },
  { id: 6, nome: 'Serviços contratados', regente: 'Manutenção e obras', movimentos: 5, status: 'ativo' },
];

lancamentos.splice(0, lancamentos.length);

let cleanup = [];
let dominiosFinanceiros = null;

function init() {
  cleanup = [];
  const view = document.querySelector('[data-financeiro-view]')?.dataset.financeiroView;

  if (view === 'visao-geral') iniciarVisaoGeral();
  if (view === 'novo-lancamento') iniciarNovoLancamento();
  if (view === 'relatorios') iniciarRelatorios();
  if (view === 'contas-regentes') iniciarContasRegentes();
  if (view === 'contas-subordinadas') iniciarContasSubordinadas();

  console.log(`[FinanceiroPage] Tela carregada: ${view}`);
}

function destroy() {
  cleanup.forEach((fn) => fn());
  cleanup = [];
}

async function iniciarVisaoGeral() {
  await carregarLancamentos();
  renderizarMetricas('financeiro-metricas', calcularResumo(lancamentos));
  renderizarLancamentos();

  const filtros = [
    document.getElementById('filtro-tipo-lancamento'),
    document.getElementById('filtro-status-lancamento'),
  ].filter(Boolean);

  filtros.forEach((filtro) => {
    const handler = () => {
      const filtrados = filtrarLancamentos();
      renderizarMetricas('financeiro-metricas', calcularResumo(filtrados));
      renderizarLancamentos();
    };
    filtro.addEventListener('change', handler);
    cleanup.push(() => filtro.removeEventListener('change', handler));
  });
}

function renderizarLancamentos() {
  const tbody = document.getElementById('financeiro-lancamentos-tbody');
  const vazio = document.getElementById('financeiro-lancamentos-vazio');
  if (!tbody) return;

  const filtrados = filtrarLancamentos();

  tbody.innerHTML = filtrados.map((item) => `
    <tr>
      <td>
        <span class="financeiro__linha-principal">${escaparHtml(item.descricao)}</span>
        <span class="financeiro__linha-secundaria">${escaparHtml(item.pessoa)}</span>
      </td>
      <td>${escaparHtml(item.conta)}</td>
      <td>${formatarData(item.vencimento)}</td>
      <td>${badgeStatus(item.status)}</td>
      <td class="tabela__num ${item.tipo === 'receita' ? 'financeiro__valor-receita' : 'financeiro__valor-despesa'}">
        ${item.tipo === 'receita' ? '+' : '-'} ${formatarMoeda(item.valor)}
      </td>
    </tr>
  `).join('');

  if (vazio) vazio.hidden = filtrados.length > 0;
}

async function carregarLancamentos(filtros = {}) {
  try {
    const params = new URLSearchParams();
    params.set('limite', String(filtros.limite || 100));
    if (filtros.tipo && filtros.tipo !== 'todos') params.set('tipo', filtros.tipo);
    if (filtros.status && filtros.status !== 'todos') params.set('status', filtros.status);
    if (filtros.inicio) params.set('inicio', filtros.inicio);
    if (filtros.fim) params.set('fim', filtros.fim);

    const resposta = await api.get(`/financeiro/lancamentos/listar.php?${params.toString()}`);
    const dados = normalizarLancamentos(resposta.dados || resposta.lancamentos || []);
    lancamentos.splice(0, lancamentos.length, ...dados);
  } catch (erro) {
    lancamentos.splice(0, lancamentos.length);
    Toast.erro(erro.message || 'Nao foi possivel carregar os lancamentos.');
  }
}

function filtrarLancamentos() {
  const tipo = document.getElementById('filtro-tipo-lancamento')?.value || 'todos';
  const status = document.getElementById('filtro-status-lancamento')?.value || 'todos';

  return lancamentos.filter((item) => {
    if (tipo !== 'todos' && item.tipo !== tipo) return false;
    if (status !== 'todos' && item.status !== status) return false;
    return true;
  });
}

function normalizarLancamentos(lista) {
  return lista.map((item) => ({
    ...item,
    id: Number(item.id || item.id_lancamento),
    descricao: item.descricao || '',
    conta: item.conta || item.conta_regente || '',
    subconta: item.subconta || item.conta_subordinada || '',
    tipo: normalizarTipo(item.tipo),
    status: normalizarStatus(item.status || item.status_conta, item.vencimento || item.data_vencimento),
    vencimento: item.vencimento || item.data_vencimento || item.data_lancamento || '',
    valor: Number(item.valor || 0),
    pessoa: item.pessoa || '',
  }));
}

function normalizarTipo(tipo) {
  const texto = String(tipo || '').toLowerCase();
  return texto === 'despesa' ? 'despesa' : 'receita';
}

function normalizarStatus(status, vencimento = '') {
  const texto = String(status || '').toLowerCase();
  if (texto.includes('liquidado') || texto.includes('pago')) return 'pago';
  if (texto.includes('cancelado')) return 'cancelado';
  if (texto.includes('atrasado')) return 'atrasado';
  if (vencimento && vencimento < new Date().toISOString().slice(0, 10)) return 'atrasado';
  return 'pendente';
}

async function carregarDominiosFinanceiros() {
  if (dominiosFinanceiros) return dominiosFinanceiros;
  dominiosFinanceiros = await api.get('/financeiro/dominios.php');
  return dominiosFinanceiros;
}

async function carregarTiposLancamento() {
  const select = document.getElementById('lancamento-tipo');
  if (!select) return;

  try {
    const resultado = await carregarDominiosFinanceiros();
    const tipos = resultado.tipos || resultado.data || [];

    select.innerHTML = '<option value="">Selecione...</option>';
    tipos.forEach(tipo => {
      const option = document.createElement('option');
      option.value = tipo.id_tipo_lancamento;
      option.textContent = tipo.descricao;
      select.appendChild(option);
    });
  } catch (erro) {
    console.error('[Financeiro] Erro ao carregar tipos:', erro);
    select.innerHTML = '<option value="">Erro ao carregar tipos</option>';
  }
}

async function preencherSelectsNovoLancamento() {
  try {
    const dominios = await carregarDominiosFinanceiros();
    preencherSelect('lancamento-forma-pagamento', dominios.formas_pagamento || [], 'id_forma_pagamento', 'descricao');
    preencherSelect('lancamento-conta', dominios.contas_regentes || [], 'id_conta_regente', 'descricao');
    atualizarSubcontasNovoLancamento();
  } catch (erro) {
    Toast.erro(erro.message || 'Nao foi possivel carregar os campos financeiros.');
  }
}

function atualizarSubcontasNovoLancamento() {
  const select = document.getElementById('lancamento-subconta');
  const regente = document.getElementById('lancamento-conta')?.value || '';
  if (!select || !dominiosFinanceiros) return;

  const subordinadas = (dominiosFinanceiros.contas_subordinadas || [])
    .filter((item) => !regente || String(item.fk_conta_regente) === String(regente));

  preencherSelect('lancamento-subconta', subordinadas, 'id_conta_subordinada', 'descricao', 'Selecione...');
}

function preencherSelect(id, itens, campoValor, campoTexto, textoVazio = null) {
  const select = document.getElementById(id);
  if (!select) return;

  select.innerHTML = [
    textoVazio ? `<option value="">${textoVazio}</option>` : '',
    ...itens.map((item) => `<option value="${item[campoValor]}">${escaparHtml(item[campoTexto])}</option>`),
  ].join('');
}

function iniciarNovoLancamento() {
  const form = document.getElementById('form-lancamento');
  if (!form) return;

  carregarTiposLancamento();
  preencherSelectsNovoLancamento();
  carregarListaLancamentos();

  const formatarDataISO = (data) => {
    const ano = data.getFullYear();
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    const dia = String(data.getDate()).padStart(2, '0');
    return `${ano}-${mes}-${dia}`;
  };

  const formatarDataLocal = (iso) => {
    if (!iso) return '-';
    const [ano, mes, dia] = iso.split('-');
    return `${dia}/${mes}/${ano}`;
  };

  const criarDataLocal = (iso) => {
    const [ano, mes, dia] = String(iso || '').split('-').map(Number);
    if (!ano || !mes || !dia) return null;
    return new Date(ano, mes - 1, dia);
  };

  const calcularParcelas = (valorTotal, primeiroVencimento, totalParcelas) => {
    if (!valorTotal || totalParcelas <= 1 || !primeiroVencimento) return [];

    const base = Math.floor((valorTotal / totalParcelas) * 100) / 100;
    const resto = Number((valorTotal - base * totalParcelas).toFixed(2));
    const parcelas = [];
    const dataBase = criarDataLocal(primeiroVencimento);
    if (!dataBase || Number.isNaN(dataBase.getTime())) return [];

    for (let i = 1; i <= totalParcelas; i += 1) {
      const valorParcela = i === totalParcelas ? Number((base + resto).toFixed(2)) : Number(base.toFixed(2));
      const data = new Date(dataBase);
      data.setMonth(data.getMonth() + (i - 1));
      parcelas.push({
        numero_parcela: i,
        valor: valorParcela,
        data_vencimento: formatarDataISO(data),
      });
    }

    return parcelas;
  };

  const pagamentoModoSelect = document.getElementById('lancamento-pagamento-modo');
  const totalParcelasInput = document.getElementById('lancamento-total-parcelas');
  const valorParcelaInput = document.getElementById('lancamento-valor-parcela');
  const primeiraParcelaInput = document.getElementById('lancamento-primeira-parcela');
  const parcelamentoPanel = document.getElementById('parcelamento-panel');

  const atualizarParcelamento = () => {
    const valor = Number(document.getElementById('lancamento-valor')?.value || 0);
    const modo = pagamentoModoSelect?.value || 'avista';
    const totalParcelas = Math.max(1, parseInt(totalParcelasInput?.value, 10) || 1);
    const primeiraParcela = primeiraParcelaInput?.value;
    const parcelado = modo === 'parcelado';

    if (parcelado) {
      parcelamentoPanel?.removeAttribute('hidden');
      if (totalParcelasInput) totalParcelasInput.disabled = false;
      const parcelas = calcularParcelas(valor, primeiraParcela, totalParcelas);
      valorParcelaInput.value = parcelas.length > 0 ? formatarMoeda(parcelas[0].valor) : '';
    } else {
      parcelamentoPanel?.setAttribute('hidden', '');
      if (totalParcelasInput) totalParcelasInput.disabled = true;
      if (totalParcelasInput) totalParcelasInput.value = '1';
      if (valorParcelaInput) valorParcelaInput.value = '';
    }
  };

  const atualizarPreview = () => {
    const tipoSelect = document.getElementById('lancamento-tipo');
    const tipoTexto = tipoSelect?.selectedOptions[0]?.textContent || '-';
    const valor = Number(document.getElementById('lancamento-valor')?.value || 0);
    const vencimento = document.getElementById('lancamento-vencimento')?.value || '';
    const contaSelect = document.getElementById('lancamento-conta');
    const contaTexto = contaSelect?.selectedOptions[0]?.textContent || '-';
    const subSelect = document.getElementById('lancamento-subconta');
    const subTexto = subSelect?.selectedOptions[0]?.textContent || '-';

    document.getElementById('resumo-tipo').textContent = tipoTexto;
    document.getElementById('resumo-valor').textContent = formatarMoeda(valor);
    document.getElementById('resumo-vencimento').textContent = formatarDataLocal(vencimento);
    document.getElementById('resumo-conta').textContent = contaTexto;
    document.getElementById('resumo-subconta').textContent = subTexto;
    document.getElementById('resumo-status').textContent = 'Liquidado';
    atualizarParcelamento();
  };

  const camposPreview = ['lancamento-tipo', 'lancamento-valor', 'lancamento-vencimento', 'lancamento-conta', 'lancamento-subconta', 'lancamento-pagamento-modo', 'lancamento-primeira-parcela']
    .map((id) => document.getElementById(id))
    .filter(Boolean);

  camposPreview.forEach((campo) => {
    campo.addEventListener('input', atualizarPreview);
    campo.addEventListener('change', atualizarPreview);
    cleanup.push(() => {
      campo.removeEventListener('input', atualizarPreview);
      campo.removeEventListener('change', atualizarPreview);
    });
  });

  if (pagamentoModoSelect) {
    const handler = () => atualizarPreview();
    pagamentoModoSelect.addEventListener('change', handler);
    cleanup.push(() => pagamentoModoSelect.removeEventListener('change', handler));
  }

  if (totalParcelasInput) {
    const handler = () => atualizarPreview();
    totalParcelasInput.addEventListener('input', handler);
    totalParcelasInput.addEventListener('change', handler);
    cleanup.push(() => {
      totalParcelasInput.removeEventListener('input', handler);
      totalParcelasInput.removeEventListener('change', handler);
    });
  }

  const contaSelect = document.getElementById('lancamento-conta');
  if (contaSelect) {
    const handler = () => {
      atualizarSubcontasNovoLancamento();
      atualizarPreview();
    };
    contaSelect.addEventListener('change', handler);
    cleanup.push(() => contaSelect.removeEventListener('change', handler));
  }

  const subSelect = document.getElementById('lancamento-subconta');
  if (subSelect) {
    const handler = () => atualizarPreview();
    subSelect.addEventListener('change', handler);
    cleanup.push(() => subSelect.removeEventListener('change', handler));
  }

  const tipoSelectEl = document.getElementById('lancamento-tipo');
  if (tipoSelectEl) {
    const handler = async () => {
      const tipoId = tipoSelectEl.value;
      atualizarPreview();
      if (!tipoId) {
        preencherSelectsNovoLancamento();
        return;
      }
      try {
        const response = await api.get(`/relacionamentos/obter-por-tipo.php?fk_tipo_lancamento=${tipoId}`);
        const regra = response.data;
        if (regra?.fk_conta_regente) {
          if (contaSelect) contaSelect.value = regra.fk_conta_regente;
          atualizarSubcontasNovoLancamento();
          if (regra.fk_conta_subordinada && subSelect) {
            subSelect.value = regra.fk_conta_subordinada;
          }
          atualizarPreview();
        }
      } catch (erro) {
        console.error('[Financeiro] Erro ao carregar regra do tipo:', erro);
        preencherSelectsNovoLancamento();
      }
    };
    tipoSelectEl.addEventListener('change', handler);
    cleanup.push(() => tipoSelectEl.removeEventListener('change', handler));
  }

  const montarPayload = (modo) => {
    const statusConta = modo === 'liquidar' ? 2 : 1;
    const totalParcelas = Number(document.getElementById('lancamento-total-parcelas')?.value || 1);
    const pagamentoModo = document.getElementById('lancamento-pagamento-modo')?.value || 'avista';
    const valorTotal = Number(document.getElementById('lancamento-valor')?.value || 0);
    const dataVencimento = document.getElementById('lancamento-vencimento')?.value;
    const primeiraParcela = document.getElementById('lancamento-primeira-parcela')?.value || dataVencimento;
    const dataPagamento = modo === 'liquidar'
      ? document.getElementById('lancamento-pagamento')?.value || formatarDataISO(new Date())
      : null;

    const payload = {
      fk_tipo_lancamento: parseInt(document.getElementById('lancamento-tipo')?.value) || null,
      fk_status_conta: statusConta,
      fk_forma_pagamento: parseInt(document.getElementById('lancamento-forma-pagamento')?.value),
      valor: valorTotal,
      descricao: document.getElementById('lancamento-descricao')?.value,
      pessoa: document.getElementById('lancamento-pessoa')?.value,
      observacao: document.getElementById('lancamento-observacao')?.value,
      fk_conta_regente: document.getElementById('lancamento-conta')?.value || null,
      fk_conta_subordinada: document.getElementById('lancamento-subconta')?.value || null,
      dataLancamento: formatarDataISO(new Date()),
      data_pagamento: dataPagamento,
      valor_pago: dataPagamento ? valorTotal : null,
      data_vencimento: pagamentoModo === 'parcelado' ? primeiraParcela || dataVencimento : dataVencimento,
      modo_pagamento: pagamentoModo,
    };

    if (pagamentoModo === 'parcelado' && totalParcelas > 1) {
      payload.total_parcelas = totalParcelas;
      payload.parcelas = calcularParcelas(valorTotal, primeiraParcela, totalParcelas);
    }

    return payload;
  };

  const salvarLancamento = async (modo) => {
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    const payload = montarPayload(modo);
    const totalParcelas = Number(document.getElementById('lancamento-total-parcelas')?.value || 1);
    const pagamentoModo = document.getElementById('lancamento-pagamento-modo')?.value || 'avista';

    if (pagamentoModo === 'parcelado' && totalParcelas > 1) {
      if (!payload.parcelas || payload.parcelas.length !== totalParcelas) {
        Toast.erro('Preencha corretamente a data da primeira parcela e o número de parcelas.');
        return;
      }
    }

    try {
      await api.post('/financeiro/lancamentos/cadastrar.php', payload);

      const mensagem = modo === 'liquidar'
        ? 'Lançamento cadastrado e liquidado com sucesso!'
        : 'Lançamento salvo em aberto com sucesso!';
      Toast.sucesso(mensagem);

      form.reset();
      atualizarPreview();
      carregarListaLancamentos();
    } catch (err) {
      Toast.erro(err.message);
    }
  };

  const btnAberto = document.getElementById('btn-salvar-aberto');
  const handlerAberto = () => salvarLancamento('aberto');
  btnAberto?.addEventListener('click', handlerAberto);
  cleanup.push(() => btnAberto?.removeEventListener('click', handlerAberto));

  const btnSalvarLiquidar = document.getElementById('btn-salvar-liquidar');
  const handlerSalvarLiquidar = () => salvarLancamento('liquidar');
  btnSalvarLiquidar?.addEventListener('click', handlerSalvarLiquidar);
  cleanup.push(() => btnSalvarLiquidar?.removeEventListener('click', handlerSalvarLiquidar));

  const btnLiquidar = document.getElementById('btn-liquidar');
  const handlerLiquidar = () => salvarLancamento('liquidar');
  btnLiquidar?.addEventListener('click', handlerLiquidar);
  cleanup.push(() => btnLiquidar?.removeEventListener('click', handlerLiquidar));

  const btnLimpar = document.getElementById('btn-limpar');
  const handlerLimpar = () => {
    form.reset();
    document.getElementById('lancamento-pagamento').value = '';
    atualizarPreview();
  };
  btnLimpar?.addEventListener('click', handlerLimpar);
  cleanup.push(() => btnLimpar?.removeEventListener('click', handlerLimpar));

  atualizarPreview();
}

async function carregarListaLancamentos() {
  const tbody = document.getElementById('lancamentos-listagem-tbody');
  if (!tbody) return;

  try {
    const resposta = await api.get('/financeiro/lancamentos/listar.php?limite=50');
    const dados = resposta.dados || resposta.lancamentos || [];

    if (!dados.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="financeiro__estado-tabela">Nenhum lançamento encontrado.</td></tr>';
      return;
    }

    tbody.innerHTML = dados.map((item) => {
      const valor = Number(item.valor || 0);
      const vencimento = item.data_vencimento || item.vencimento || '';
      const [ano, mes, dia] = vencimento.split('-');
      const vencFormatado = vencimento ? `${dia}/${mes}/${ano}` : '-';
      const status = item.status_conta || item.status || '';
      const statusLower = String(status).toLowerCase();
      const badgeCls = statusLower.includes('liquidado') || statusLower.includes('pago') ? 'badge-verde'
        : statusLower.includes('cancelado') ? 'badge-vermelho'
        : 'badge-amarelo';
      const statusLabel = (statusLower.includes('liquidado') || statusLower.includes('pago')) ? 'Liquidado'
        : statusLower.includes('cancelado') ? 'Cancelado'
        : 'Aberto';
      const tipo = item.tipo || '';

      return `<tr>
        <td>${escaparHtml(item.descricao || '')}</td>
        <td>${formatarMoeda(valor)}</td>
        <td>${vencFormatado}</td>
        <td><span class="badge badge-pilula ${badgeCls}">${statusLabel}</span></td>
        <td>${tipo ? (tipo === 'receita' ? 'Receita' : 'Despesa') : '-'}</td>
      </tr>`;
    }).join('');
  } catch (erro) {
    tbody.innerHTML = `<tr><td colspan="5" class="financeiro__estado-tabela financeiro__estado-tabela--erro">${escaparHtml(erro.message)}</td></tr>`;
  }
}

async function iniciarRelatorios() {
  await carregarLancamentos({ limite: 200 });
  renderizarMetricas('relatorio-metricas', calcularResumo(lancamentos));
  renderizarBarrasRelatorio();
  renderizarResumoContas();

  const filtros = [
    document.getElementById('relatorio-inicio'),
    document.getElementById('relatorio-fim'),
    document.getElementById('relatorio-tipo'),
  ].filter(Boolean);

  filtros.forEach((filtro) => {
    const handler = async () => {
      await atualizarRelatorio();
    };
    filtro.addEventListener('change', handler);
    cleanup.push(() => filtro.removeEventListener('change', handler));
  });

  const btn = document.getElementById('btn-exportar-relatorio');
  if (btn) {
    const handler = () => Toast.info('Exportação preparada para integração com o backend.');
    btn.addEventListener('click', handler);
    cleanup.push(() => btn.removeEventListener('click', handler));
  }
}

async function atualizarRelatorio() {
  const mesInicio = document.getElementById('relatorio-inicio')?.value || '';
  const mesFim = document.getElementById('relatorio-fim')?.value || '';
  const tipo = document.getElementById('relatorio-tipo')?.value || 'todos';

  await carregarLancamentos({
    limite: 200,
    tipo,
    inicio: mesInicio ? `${mesInicio}-01` : '',
    fim: mesFim ? ultimoDiaMes(mesFim) : '',
  });

  renderizarMetricas('relatorio-metricas', calcularResumo(lancamentos));
  renderizarBarrasRelatorio();
  renderizarResumoContas();
}

function renderizarBarrasRelatorio() {
  const container = document.getElementById('relatorio-barras');
  if (!container) return;

  const meses = agruparLancamentosPorMes(lancamentos);
  const maior = Math.max(1, ...meses.map((m) => Math.abs(m.valor)));

  container.innerHTML = meses.map((item) => `
    <div class="financeiro__barra">
      <span>${item.mes}</span>
      <div class="financeiro__barra-trilho">
        <div class="financeiro__barra-valor" style="width: ${(Math.abs(item.valor) / maior) * 100}%"></div>
      </div>
      <strong>${formatarMoeda(item.valor)}</strong>
    </div>
  `).join('');
}

function agruparLancamentosPorMes(lista) {
  const mapa = new Map();

  lista.forEach((item) => {
    const data = item.vencimento || item.data_lancamento || '';
    const chave = data.slice(0, 7) || 'Sem data';
    const valor = item.tipo === 'receita' ? item.valor : -item.valor;
    mapa.set(chave, (mapa.get(chave) || 0) + valor);
  });

  const itens = [...mapa.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([mes, valor]) => ({ mes: formatarMes(mes), valor }));

  return itens.length ? itens : [{ mes: '-', valor: 0 }];
}

function renderizarResumoContas() {
  const container = document.getElementById('relatorio-contas');
  if (!container) return;

  const porConta = lancamentos.reduce((acc, item) => {
    acc[item.conta] = (acc[item.conta] || 0) + (item.tipo === 'receita' ? item.valor : -item.valor);
    return acc;
  }, {});

  container.innerHTML = Object.entries(porConta).map(([conta, valor]) => `
    <div class="financeiro__conta-item">
      <span>${escaparHtml(conta)}</span>
      <strong class="${valor >= 0 ? 'financeiro__valor-receita' : 'financeiro__valor-despesa'}">${formatarMoeda(valor)}</strong>
    </div>
  `).join('');
}

function abrirModalRegente(conta = null) {
  document.getElementById('modal-regente-titulo').textContent   = conta ? 'Editar Conta Regente' : 'Nova Conta Regente';
  document.getElementById('regente-id').value                   = conta?.id_conta_regente ?? '';
  document.getElementById('regente-nome').value                 = conta?.descricao ?? '';
  document.getElementById('regente-tipo').value                 = conta?.tipo ?? 'receita';
  document.getElementById('regente-descricao').value            = conta?.observacao ?? '';
  document.getElementById('modal-conta-regente').hidden         = false;
  setTimeout(() => document.getElementById('regente-nome')?.focus(), 50);
}

function fecharModalRegente() {
  document.getElementById('modal-conta-regente').hidden = true;
  document.getElementById('form-conta-regente')?.reset();
  document.getElementById('regente-id').value = '';
}

async function iniciarContasRegentes() {
  await renderizarContasRegentes();

  const busca = document.getElementById('busca-conta-regente');
  if (busca) {
    const handler = () => renderizarContasRegentes();
    busca.addEventListener('input', handler);
    cleanup.push(() => busca.removeEventListener('input', handler));
  }

  document.getElementById('btn-nova-conta-regente')?.addEventListener('click', () => abrirModalRegente());
  document.getElementById('modal-regente-fechar')?.addEventListener('click', fecharModalRegente);
  document.getElementById('modal-regente-fundo')?.addEventListener('click', fecharModalRegente);
  document.getElementById('modal-regente-cancelar')?.addEventListener('click', fecharModalRegente);

  document.getElementById('modal-detalhe-regente-fechar')?.addEventListener('click', fecharDetalheRegente);
  document.getElementById('modal-detalhe-regente-fundo')?.addEventListener('click', fecharDetalheRegente);
  document.getElementById('modal-detalhe-regente-cancelar')?.addEventListener('click', fecharDetalheRegente);

  const form = document.getElementById('form-conta-regente');
  if (form) {
    const handler = async (evento) => {
      evento.preventDefault();
      const id         = document.getElementById('regente-id')?.value;
      const descricao  = document.getElementById('regente-nome')?.value.trim();
      const tipo       = document.getElementById('regente-tipo')?.value;
      const observacao = document.getElementById('regente-descricao')?.value.trim();
      try {
        if (id) {
          await api.put('/financeiro/contas-regentes/editar.php', { id_conta_regente: parseInt(id), descricao, tipo, observacao });
          Toast.sucesso('Conta regente atualizada com sucesso!');
        } else {
          await api.post('/financeiro/contas-regentes/cadastrar.php', { descricao, tipo, observacao });
          Toast.sucesso('Conta regente cadastrada com sucesso!');
        }
        fecharModalRegente();
        await renderizarContasRegentes();
      } catch (err) {
        Toast.erro(err.message);
      }
    };
    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
  }

  const tbody = document.getElementById('contas-regentes-tbody');
  if (tbody) {
    const handler = async (e) => {
      const btn = e.target.closest('[data-acao]');
      if (!btn) return;
      const id = parseInt(btn.dataset.id);
      if (btn.dataset.acao === 'editar-regente') {
        abrirModalRegente({
          id_conta_regente: id,
          descricao:  btn.dataset.nome,
          tipo:       btn.dataset.tipo,
          observacao: btn.dataset.obs || '',
        });
      }
      if (btn.dataset.acao === 'alternar-regente') {
        try {
          const resp = await api.patch('/financeiro/contas-regentes/alternar-status.php', { id_conta_regente: id });
          Toast.sucesso(resp.mensagem);
          await renderizarContasRegentes();
        } catch (err) {
          Toast.erro(err.message);
        }
      }
      if (btn.dataset.acao === 'ver-regente') {
        abrirDetalheRegente(id, btn.dataset.nome, btn.dataset.tipo, btn.dataset.obs || '', btn.dataset.ativo === 'true');
      }
      if (btn.dataset.acao === 'deletar-regente') {
        const nome = btn.dataset.nome;
        const idRegente = id;
        Modal.confirmar({
          titulo: 'Excluir conta regente?',
          mensagem: `A conta <strong>${nome}</strong> será excluída permanentemente. Esta ação não pode ser desfeita.`,
          icone: 'delete_forever',
          variante: 'erro',
          textoConfirmar: 'Sim, excluir',
          textoCancelar: 'Cancelar',
          estiloConfirmar: 'perigo',
          aoConfirmar: () => {
            api.delete('/financeiro/contas-regentes/deletar.php', { id_conta_regente: idRegente })
              .then(resp => {
                Toast.sucesso(resp.mensagem || 'Conta excluída com sucesso.');
                renderizarContasRegentes();
              })
              .catch(err => {
                if (err.status === 409) {
                  Modal.confirmar({
                    titulo: 'Exclusão não permitida',
                    mensagem: err.message,
                    icone: 'warning',
                    variante: 'alerta',
                    textoConfirmar: 'Entendi',
                    textoCancelar: 'Fechar',
                    estiloConfirmar: 'secundario',
                  });
                } else {
                  Toast.erro(err.message || 'Não foi possível excluir a conta.');
                }
              });
          },
        });
      }
    };
    tbody.addEventListener('click', handler);
    cleanup.push(() => tbody.removeEventListener('click', handler));
  }
}

async function renderizarContasRegentes() {
  const tbody = document.getElementById('contas-regentes-tbody');
  if (!tbody) return;

  const busca = document.getElementById('busca-conta-regente')?.value.trim() || '';
  tbody.innerHTML = linhaEstadoTabela('Carregando...');

  try {
    const params = new URLSearchParams();
    if (busca) params.set('busca', busca);
    const { dados } = await api.get(`/financeiro/contas-regentes/listar.php?${params}`);

    if (!dados.length) {
      tbody.innerHTML = linhaEstadoTabela('Nenhuma conta encontrada.');
      return;
    }

    tbody.innerHTML = dados.map((c) => `
      <tr data-acao="ver-regente" data-id="${c.id_conta_regente}"
          data-nome="${escaparHtml(c.descricao)}" data-tipo="${c.tipo}"
          data-obs="${escaparHtml(c.observacao || '')}" data-ativo="${c.ativo}"
          style="cursor:pointer" title="Clique para ver detalhes">
        <td>${escaparHtml(c.descricao)}</td>
        <td>${badgeTipo(c.tipo)}</td>
        <td>${c.total_subcontas}</td>
        <td>${badgeStatus(c.ativo ? 'ativo' : 'inativo')}</td>
        <td>
          <div class="tabela__acoes">
            <button class="btn-icone" type="button" data-acao="editar-regente"
              data-id="${c.id_conta_regente}" data-nome="${escaparHtml(c.descricao)}"
              data-tipo="${c.tipo}" data-obs="${escaparHtml(c.observacao || '')}"
              aria-label="Editar"><span class="material-icons">edit</span></button>
            <button class="btn-icone btn-icone-perigo" type="button" data-acao="alternar-regente"
              data-id="${c.id_conta_regente}"
              aria-label="${c.ativo ? 'Inativar' : 'Ativar'}">
              <span class="material-icons">${c.ativo ? 'block' : 'check_circle'}</span>
            </button>
            <button class="btn-icone btn-icone-perigo" type="button" data-acao="deletar-regente"
              data-id="${c.id_conta_regente}" data-nome="${escaparHtml(c.descricao)}"
              aria-label="Excluir">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = linhaEstadoTabela(err.message, true);
  }
}

function fecharDetalheRegente() {
  document.getElementById('modal-detalhe-regente').hidden = true;
}

async function abrirDetalheRegente(id, nome, tipo, obs, ativo) {
  document.getElementById('detalhe-regente-titulo').textContent = nome;
  document.getElementById('detalhe-regente-badges').innerHTML =
    `${badgeTipo(tipo)} ${badgeStatus(ativo ? 'ativo' : 'inativo')}`;

  const corpo = document.getElementById('detalhe-regente-corpo');
  corpo.innerHTML = `
    <div style="background:var(--fundo-secao);border:var(--borda-padrao);border-radius:var(--raio-sm);padding:var(--esp-md)">
      <p style="font-size:var(--fs-xs);font-weight:var(--fw-semibold);text-transform:uppercase;letter-spacing:.5px;color:var(--texto-secundario);margin:0 0 var(--esp-sm)">Descrição</p>
      ${obs
        ? `<p style="color:var(--texto-principal);line-height:var(--lh-base);margin:0">${escaparHtml(obs)}</p>`
        : `<p style="color:var(--texto-suave);font-style:italic;margin:0">Sem descrição cadastrada.</p>`
      }
    </div>
    <div style="background:var(--fundo-secao);border:var(--borda-padrao);border-radius:var(--raio-sm);padding:var(--esp-md)">
      <p style="font-size:var(--fs-xs);font-weight:var(--fw-semibold);text-transform:uppercase;letter-spacing:.5px;color:var(--texto-secundario);margin:0 0 var(--esp-sm)">Subcontas vinculadas</p>
      <div id="detalhe-subcontas-lista"><p style="text-align:center;color:var(--texto-secundario)">Carregando…</p></div>
    </div>
  `;

  document.getElementById('modal-detalhe-regente').hidden = false;

  const lista = document.getElementById('detalhe-subcontas-lista');
  try {
    const { dados } = await api.get(`/financeiro/contas-subordinadas/listar.php?fk_conta_regente=${id}`);
    if (!dados.length) {
      lista.innerHTML = '<p style="text-align:center;color:var(--texto-secundario)">Nenhuma subconta cadastrada.</p>';
      return;
    }
    lista.innerHTML = `
      <div class="tabela-responsiva">
        <table class="tabela tabela-compacta">
          <thead><tr><th>Nome</th><th>Movimentos</th><th>Status</th></tr></thead>
          <tbody>
            ${dados.map((s) => `
              <tr>
                <td>${escaparHtml(s.descricao)}${s.observacao ? `<span class="tabela__sub">${escaparHtml(s.observacao)}</span>` : ''}</td>
                <td>${s.total_movimentos}</td>
                <td>${badgeStatus(s.ativo ? 'ativo' : 'inativo')}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    lista.innerHTML = `<p style="color:var(--cor-erro-escura)">Erro ao carregar: ${escaparHtml(err.message)}</p>`;
  }
}

function fecharDetalheSubordinada() {
  document.getElementById('modal-detalhe-subordinada').hidden = true;
}

function abrirDetalheSubordinada(nome, regenteNome, obs, ativo, movimentos) {
  document.getElementById('detalhe-subordinada-titulo').textContent = nome;
  document.getElementById('detalhe-subordinada-badges').innerHTML = badgeStatus(ativo ? 'ativo' : 'inativo');

  const label = (txt) =>
    `<p style="font-size:var(--fs-xs);font-weight:var(--fw-semibold);text-transform:uppercase;letter-spacing:.5px;color:var(--texto-secundario);margin:0 0 var(--esp-sm)">${txt}</p>`;

  document.getElementById('detalhe-subordinada-corpo').innerHTML = `
    <div style="background:var(--fundo-secao);border:var(--borda-padrao);border-radius:var(--raio-sm);padding:var(--esp-md)">
      ${label('Conta regente')}
      <p style="color:var(--texto-principal);margin:0">${escaparHtml(regenteNome)}</p>
    </div>
    <div style="background:var(--fundo-secao);border:var(--borda-padrao);border-radius:var(--raio-sm);padding:var(--esp-md)">
      ${label('Descrição')}
      ${obs
        ? `<p style="color:var(--texto-principal);line-height:var(--lh-base);margin:0">${escaparHtml(obs)}</p>`
        : `<p style="color:var(--texto-suave);font-style:italic;margin:0">Sem descrição cadastrada.</p>`
      }
    </div>
    <div style="background:var(--fundo-secao);border:var(--borda-padrao);border-radius:var(--raio-sm);padding:var(--esp-md)">
      ${label('Movimentos financeiros')}
      <p style="color:var(--texto-principal);margin:0">${movimentos} movimento${movimentos !== 1 ? 's' : ''} vinculado${movimentos !== 1 ? 's' : ''}</p>
    </div>
  `;

  document.getElementById('modal-detalhe-subordinada').hidden = false;
}

function abrirModalSubordinada(conta = null) {
  document.getElementById('modal-subordinada-titulo').textContent  = conta ? 'Editar Subconta' : 'Nova Subconta';
  document.getElementById('subordinada-id').value                  = conta?.id_conta_subordinada ?? '';
  document.getElementById('subordinada-regente').value             = conta?.fk_conta_regente ?? '';
  document.getElementById('subordinada-nome').value                = conta?.descricao ?? '';
  document.getElementById('subordinada-descricao').value           = conta?.observacao ?? '';
  document.getElementById('modal-conta-subordinada').hidden        = false;
  setTimeout(() => document.getElementById('subordinada-nome')?.focus(), 50);
}

function fecharModalSubordinada() {
  document.getElementById('modal-conta-subordinada').hidden = true;
  document.getElementById('form-conta-subordinada')?.reset();
  document.getElementById('subordinada-id').value = '';
}

async function iniciarContasSubordinadas() {
  await preencherSelectsRegentes();
  await renderizarContasSubordinadas();

  const busca = document.getElementById('busca-conta-subordinada');
  if (busca) {
    const handler = () => renderizarContasSubordinadas();
    busca.addEventListener('input', handler);
    cleanup.push(() => busca.removeEventListener('input', handler));
  }

  document.getElementById('btn-nova-conta-subordinada')?.addEventListener('click', () => abrirModalSubordinada());
  document.getElementById('modal-subordinada-fechar')?.addEventListener('click', fecharModalSubordinada);
  document.getElementById('modal-subordinada-fundo')?.addEventListener('click', fecharModalSubordinada);
  document.getElementById('modal-subordinada-cancelar')?.addEventListener('click', fecharModalSubordinada);

  document.getElementById('modal-detalhe-subordinada-fechar')?.addEventListener('click', fecharDetalheSubordinada);
  document.getElementById('modal-detalhe-subordinada-fundo')?.addEventListener('click', fecharDetalheSubordinada);
  document.getElementById('modal-detalhe-subordinada-cancelar')?.addEventListener('click', fecharDetalheSubordinada);

  const form = document.getElementById('form-conta-subordinada');
  if (form) {
    const handler = async (evento) => {
      evento.preventDefault();
      const id         = document.getElementById('subordinada-id')?.value;
      const fkRegente  = parseInt(document.getElementById('subordinada-regente')?.value);
      const descricao  = document.getElementById('subordinada-nome')?.value.trim();
      const observacao = document.getElementById('subordinada-descricao')?.value.trim();
      try {
        if (id) {
          await api.put('/financeiro/contas-subordinadas/editar.php', { id_conta_subordinada: parseInt(id), fk_conta_regente: fkRegente, descricao, observacao });
          Toast.sucesso('Conta subordinada atualizada com sucesso!');
        } else {
          await api.post('/financeiro/contas-subordinadas/cadastrar.php', { fk_conta_regente: fkRegente, descricao, observacao });
          Toast.sucesso('Conta subordinada cadastrada com sucesso!');
        }
        fecharModalSubordinada();
        await renderizarContasSubordinadas();
      } catch (err) {
        Toast.erro(err.message);
      }
    };
    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
  }

  const tbody = document.getElementById('contas-subordinadas-tbody');
  if (tbody) {
    const handler = async (e) => {
      const btn = e.target.closest('[data-acao]');
      if (!btn) return;
      const id = parseInt(btn.dataset.id);
      if (btn.dataset.acao === 'editar-subordinada') {
        abrirModalSubordinada({
          id_conta_subordinada: id,
          fk_conta_regente:     btn.dataset.regente,
          descricao:            btn.dataset.nome,
          observacao:           btn.dataset.obs || '',
        });
      }
      if (btn.dataset.acao === 'alternar-subordinada') {
        try {
          const resp = await api.patch('/financeiro/contas-subordinadas/alternar-status.php', { id_conta_subordinada: id });
          Toast.sucesso(resp.mensagem);
          await renderizarContasSubordinadas();
        } catch (err) {
          Toast.erro(err.message);
        }
      }
      if (btn.dataset.acao === 'ver-subordinada') {
        abrirDetalheSubordinada(btn.dataset.nome, btn.dataset.regenteNome, btn.dataset.obs || '', btn.dataset.ativo === 'true', parseInt(btn.dataset.movimentos));
      }
      if (btn.dataset.acao === 'deletar-subordinada') {
        const nome = btn.dataset.nome;
        const idSubordinada = id;
        Modal.confirmar({
          titulo: 'Excluir subconta?',
          mensagem: `A subconta <strong>${nome}</strong> será excluída permanentemente. Esta ação não pode ser desfeita.`,
          icone: 'delete_forever',
          variante: 'erro',
          textoConfirmar: 'Sim, excluir',
          textoCancelar: 'Cancelar',
          estiloConfirmar: 'perigo',
          aoConfirmar: () => {
            api.delete('/financeiro/contas-subordinadas/deletar.php', { id_conta_subordinada: idSubordinada })
              .then(resp => {
                Toast.sucesso(resp.mensagem || 'Subconta excluída com sucesso.');
                renderizarContasSubordinadas();
              })
              .catch(err => {
                if (err.status === 409) {
                  Modal.confirmar({
                    titulo: 'Exclusão não permitida',
                    mensagem: err.message,
                    icone: 'warning',
                    variante: 'alerta',
                    textoConfirmar: 'Entendi',
                    textoCancelar: 'Fechar',
                    estiloConfirmar: 'secundario',
                  });
                } else {
                  Toast.erro(err.message || 'Não foi possível excluir a subconta.');
                }
              });
          },
        });
      }
    };
    tbody.addEventListener('click', handler);
    cleanup.push(() => tbody.removeEventListener('click', handler));
  }
}

async function preencherSelectsRegentes() {
  try {
    const { dados } = await api.get('/financeiro/contas-regentes/listar.php?ativos=1');
    const opcoes = dados.map((c) => `<option value="${c.id_conta_regente}">${escaparHtml(c.descricao)}</option>`).join('');
    const cadastro = document.getElementById('subordinada-regente');
    if (cadastro) cadastro.innerHTML = opcoes;
  } catch (_) {}
}

async function renderizarContasSubordinadas() {
  const tbody = document.getElementById('contas-subordinadas-tbody');
  if (!tbody) return;

  const busca = document.getElementById('busca-conta-subordinada')?.value.trim() || '';
  tbody.innerHTML = linhaEstadoTabela('Carregando...');

  try {
    const params = new URLSearchParams();
    if (busca) params.set('busca', busca);
    const { dados } = await api.get(`/financeiro/contas-subordinadas/listar.php?${params}`);

    if (!dados.length) {
      tbody.innerHTML = linhaEstadoTabela('Nenhuma subconta encontrada.');
      return;
    }

    tbody.innerHTML = dados.map((c) => `
      <tr data-acao="ver-subordinada" data-id="${c.id_conta_subordinada}"
          data-nome="${escaparHtml(c.descricao)}" data-regente-nome="${escaparHtml(c.regente)}"
          data-obs="${escaparHtml(c.observacao || '')}" data-ativo="${c.ativo}"
          data-movimentos="${c.total_movimentos}"
          style="cursor:pointer" title="Clique para ver detalhes">
        <td>${escaparHtml(c.descricao)}</td>
        <td>${escaparHtml(c.regente)}</td>
        <td>${c.total_movimentos}</td>
        <td>${badgeStatus(c.ativo ? 'ativo' : 'inativo')}</td>
        <td>
          <div class="tabela__acoes">
            <button class="btn-icone" type="button" data-acao="editar-subordinada"
              data-id="${c.id_conta_subordinada}" data-nome="${escaparHtml(c.descricao)}"
              data-regente="${c.fk_conta_regente}" data-obs="${escaparHtml(c.observacao || '')}"
              aria-label="Editar"><span class="material-icons">edit</span></button>
            <button class="btn-icone btn-icone-perigo" type="button" data-acao="alternar-subordinada"
              data-id="${c.id_conta_subordinada}"
              aria-label="${c.ativo ? 'Inativar' : 'Ativar'}">
              <span class="material-icons">${c.ativo ? 'block' : 'check_circle'}</span>
            </button>
            <button class="btn-icone btn-icone-perigo" type="button" data-acao="deletar-subordinada"
              data-id="${c.id_conta_subordinada}" data-nome="${escaparHtml(c.descricao)}"
              aria-label="Excluir">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = linhaEstadoTabela(err.message, true);
  }
}

function calcularResumo(lista) {
  const receitas = somar(lista.filter((item) => item.tipo === 'receita'), 'valor');
  const despesas = somar(lista.filter((item) => item.tipo === 'despesa'), 'valor');
  const pendentes = somar(lista.filter((item) => item.status !== 'pago'), 'valor');
  return { receitas, despesas, saldo: receitas - despesas, pendentes };
}

function renderizarMetricas(id, resumo) {
  const container = document.getElementById(id);
  if (!container) return;

  const cards = [
    { label: 'Receitas', valor: resumo.receitas, icone: 'trending_up', classe: 'card-stat__icone-sucesso', valorClasse: 'financeiro__valor-receita' },
    { label: 'Despesas', valor: resumo.despesas, icone: 'trending_down', classe: 'card-stat__icone-erro', valorClasse: 'financeiro__valor-despesa' },
    { label: 'Saldo previsto', valor: resumo.saldo, icone: 'account_balance', classe: 'card-stat__icone-info', valorClasse: resumo.saldo >= 0 ? 'financeiro__valor-receita' : 'financeiro__valor-despesa' },
    { label: 'Em aberto', valor: resumo.pendentes, icone: 'pending_actions', classe: 'card-stat__icone-alerta', valorClasse: 'financeiro__valor-neutro' },
  ];

  container.innerHTML = cards.map((card) => `
    <article class="card-stat">
      <div class="card-stat__topo">
        <span class="card-stat__label">${card.label}</span>
        <span class="card-stat__icone ${card.classe}"><span class="material-icons">${card.icone}</span></span>
      </div>
      <p class="card-stat__valor ${card.valorClasse}">${formatarMoeda(card.valor)}</p>
      <div class="card-stat__rodape">Atualizado com dados do banco</div>
    </article>
  `).join('');
}

function somar(lista, campo) {
  return lista.reduce((total, item) => total + Number(item[campo] || 0), 0);
}

function badgeStatus(status) {
  const classes = {
    pago: 'badge-verde',
    pendente: 'badge-amarelo',
    atrasado: 'badge-vermelho',
    ativo: 'badge-verde',
  };
  return `<span class="badge badge-pilula ${classes[status] || 'badge-cinza'}">${capitalizar(status)}</span>`;
}

function badgeTipo(tipo) {
  return `<span class="badge badge-pilula ${tipo === 'receita' ? 'badge-verde' : 'badge-vermelho'}">${capitalizar(tipo)}</span>`;
}


function linhaEstadoTabela(mensagem, erro = false) {
  return `
    <tr>
      <td colspan="5" class="financeiro__estado-tabela ${erro ? 'financeiro__estado-tabela--erro' : ''}">
        ${escaparHtml(mensagem)}
      </td>
    </tr>
  `;
}

function formatarMoeda(valor) {
  return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function formatarData(iso) {
  if (!iso) return '-';
  const [ano, mes, dia] = iso.split('-');
  return `${dia}/${mes}/${ano}`;
}

function formatarMes(anoMes) {
  if (!anoMes || anoMes === 'Sem data') return '-';
  const [ano, mes] = anoMes.split('-').map(Number);
  const data = new Date(ano, mes - 1, 1);
  return data.toLocaleDateString('pt-BR', { month: 'short', year: '2-digit' });
}

function ultimoDiaMes(anoMes) {
  const [ano, mes] = anoMes.split('-').map(Number);
  const data = new Date(ano, mes, 0);
  return data.toISOString().slice(0, 10);
}

function capitalizar(texto) {
  return String(texto || '').charAt(0).toUpperCase() + String(texto || '').slice(1);
}

function escaparHtml(texto) {
  const div = document.createElement('div');
  div.textContent = String(texto ?? '');
  return div.innerHTML;
}

export default {
  init,
  destroy,
};
