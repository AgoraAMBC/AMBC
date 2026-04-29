/* =========================================================
   Pagina: Financeiro
   Projeto: AMBC-V2
   Descricao: Logica das telas financeiras.
========================================================= */

import Toast from '../componentes/toast.js';

const lancamentos = [
  { id: 1, descricao: 'Mensalidade - Maria Oliveira', conta: 'Receitas associativas', subconta: 'Mensalidades', tipo: 'receita', status: 'pago', vencimento: '2026-04-05', valor: 85.00, pessoa: 'Maria Oliveira' },
  { id: 2, descricao: 'Reserva do salao comunitario', conta: 'Eventos e reservas', subconta: 'Reserva de espaco', tipo: 'receita', status: 'pendente', vencimento: '2026-04-18', valor: 260.00, pessoa: 'Carlos Mendes' },
  { id: 3, descricao: 'Conta de energia da sede', conta: 'Despesas administrativas', subconta: 'Contas de consumo', tipo: 'despesa', status: 'pago', vencimento: '2026-04-12', valor: 418.72, pessoa: 'Companhia de energia' },
  { id: 4, descricao: 'Compra de material de limpeza', conta: 'Manutencao e obras', subconta: 'Material de consumo', tipo: 'despesa', status: 'pago', vencimento: '2026-04-14', valor: 173.35, pessoa: 'Mercado Central' },
  { id: 5, descricao: 'Mensalidade - Joao Souza', conta: 'Receitas associativas', subconta: 'Mensalidades', tipo: 'receita', status: 'atrasado', vencimento: '2026-04-10', valor: 85.00, pessoa: 'Joao Souza' },
  { id: 6, descricao: 'Servico de pintura da quadra', conta: 'Manutencao e obras', subconta: 'Servicos contratados', tipo: 'despesa', status: 'pendente', vencimento: '2026-04-25', valor: 980.00, pessoa: 'Pinturas Alfa' },
];

const contasRegentes = [
  { id: 1, nome: 'Receitas associativas', tipo: 'receita', subcontas: 2, status: 'ativo' },
  { id: 2, nome: 'Eventos e reservas', tipo: 'receita', subcontas: 2, status: 'ativo' },
  { id: 3, nome: 'Despesas administrativas', tipo: 'despesa', subcontas: 3, status: 'ativo' },
  { id: 4, nome: 'Manutencao e obras', tipo: 'despesa', subcontas: 4, status: 'ativo' },
];

const contasSubordinadas = [
  { id: 1, nome: 'Mensalidades', regente: 'Receitas associativas', movimentos: 38, status: 'ativo' },
  { id: 2, nome: 'Taxas extraordinarias', regente: 'Receitas associativas', movimentos: 7, status: 'ativo' },
  { id: 3, nome: 'Reserva de espaco', regente: 'Eventos e reservas', movimentos: 12, status: 'ativo' },
  { id: 4, nome: 'Contas de consumo', regente: 'Despesas administrativas', movimentos: 9, status: 'ativo' },
  { id: 5, nome: 'Material de consumo', regente: 'Manutencao e obras', movimentos: 16, status: 'ativo' },
  { id: 6, nome: 'Servicos contratados', regente: 'Manutencao e obras', movimentos: 5, status: 'ativo' },
];

let cleanup = [];

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

function iniciarVisaoGeral() {
  renderizarMetricas('financeiro-metricas', calcularResumo(lancamentos));
  renderizarLancamentos();

  const filtros = [
    document.getElementById('filtro-tipo-lancamento'),
    document.getElementById('filtro-status-lancamento'),
  ].filter(Boolean);

  filtros.forEach((filtro) => {
    const handler = () => renderizarLancamentos();
    filtro.addEventListener('change', handler);
    cleanup.push(() => filtro.removeEventListener('change', handler));
  });
}

function renderizarLancamentos() {
  const tbody = document.getElementById('financeiro-lancamentos-tbody');
  const vazio = document.getElementById('financeiro-lancamentos-vazio');
  if (!tbody) return;

  const tipo = document.getElementById('filtro-tipo-lancamento')?.value || 'todos';
  const status = document.getElementById('filtro-status-lancamento')?.value || 'todos';
  const filtrados = lancamentos.filter((item) => {
    if (tipo !== 'todos' && item.tipo !== tipo) return false;
    if (status !== 'todos' && item.status !== status) return false;
    return true;
  });

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

function iniciarNovoLancamento() {
  const form = document.getElementById('form-lancamento');
  if (!form) return;

  const campos = ['lancamento-tipo', 'lancamento-status', 'lancamento-valor']
    .map((id) => document.getElementById(id))
    .filter(Boolean);

  const atualizar = () => {
    const tipo = document.getElementById('lancamento-tipo')?.value || 'receita';
    const status = document.getElementById('lancamento-status')?.value || 'pendente';
    const valor = Number(document.getElementById('lancamento-valor')?.value || 0);

    document.getElementById('resumo-tipo').textContent = capitalizar(tipo);
    document.getElementById('resumo-status').textContent = capitalizar(status);
    document.getElementById('resumo-valor').textContent = formatarMoeda(valor);
  };

  campos.forEach((campo) => {
    campo.addEventListener('input', atualizar);
    campo.addEventListener('change', atualizar);
    cleanup.push(() => {
      campo.removeEventListener('input', atualizar);
      campo.removeEventListener('change', atualizar);
    });
  });

  const submit = (evento) => {
    evento.preventDefault();
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }
    Toast.sucesso('Lancamento financeiro salvo em memoria.');
    form.reset();
    atualizar();
  };

  form.addEventListener('submit', submit);
  cleanup.push(() => form.removeEventListener('submit', submit));
  atualizar();
}

function iniciarRelatorios() {
  renderizarMetricas('relatorio-metricas', calcularResumo(lancamentos));
  renderizarBarrasRelatorio();
  renderizarResumoContas();

  const btn = document.getElementById('btn-exportar-relatorio');
  if (btn) {
    const handler = () => Toast.info('Exportacao preparada para integracao com backend.');
    btn.addEventListener('click', handler);
    cleanup.push(() => btn.removeEventListener('click', handler));
  }
}

function renderizarBarrasRelatorio() {
  const container = document.getElementById('relatorio-barras');
  if (!container) return;

  const meses = [
    { mes: 'Jan', valor: 1840 },
    { mes: 'Fev', valor: 2260 },
    { mes: 'Mar', valor: 1985 },
    { mes: 'Abr', valor: 2650 },
  ];
  const maior = Math.max(...meses.map((m) => m.valor));

  container.innerHTML = meses.map((item) => `
    <div class="financeiro__barra">
      <span>${item.mes}</span>
      <div class="financeiro__barra-trilho">
        <div class="financeiro__barra-valor" style="width: ${(item.valor / maior) * 100}%"></div>
      </div>
      <strong>${formatarMoeda(item.valor)}</strong>
    </div>
  `).join('');
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

function iniciarContasRegentes() {
  renderizarContasRegentes();

  const busca = document.getElementById('busca-conta-regente');
  if (busca) {
    const handler = () => renderizarContasRegentes();
    busca.addEventListener('input', handler);
    cleanup.push(() => busca.removeEventListener('input', handler));
  }

  const form = document.getElementById('form-conta-regente');
  if (form) {
    const handler = (evento) => {
      evento.preventDefault();
      Toast.sucesso('Conta regente pronta para salvar no backend.');
      form.reset();
    };
    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
  }
}

function renderizarContasRegentes() {
  const tbody = document.getElementById('contas-regentes-tbody');
  if (!tbody) return;

  const termo = (document.getElementById('busca-conta-regente')?.value || '').toLowerCase();
  const lista = contasRegentes.filter((conta) => conta.nome.toLowerCase().includes(termo));

  tbody.innerHTML = lista.map((conta) => `
    <tr>
      <td>${escaparHtml(conta.nome)}</td>
      <td>${badgeTipo(conta.tipo)}</td>
      <td>${conta.subcontas}</td>
      <td>${badgeStatus(conta.status)}</td>
      <td>
        <div class="tabela__acoes">
          <button class="btn-icone" type="button" aria-label="Editar"><span class="material-icons">edit</span></button>
          <button class="btn-icone btn-icone-perigo" type="button" aria-label="Inativar"><span class="material-icons">block</span></button>
        </div>
      </td>
    </tr>
  `).join('');
}

function iniciarContasSubordinadas() {
  preencherSelectsRegentes();
  renderizarContasSubordinadas();

  const filtro = document.getElementById('filtro-subordinada-regente');
  if (filtro) {
    const handler = () => renderizarContasSubordinadas();
    filtro.addEventListener('change', handler);
    cleanup.push(() => filtro.removeEventListener('change', handler));
  }

  const form = document.getElementById('form-conta-subordinada');
  if (form) {
    const handler = (evento) => {
      evento.preventDefault();
      Toast.sucesso('Conta subordinada pronta para salvar no backend.');
      form.reset();
    };
    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
  }
}

function preencherSelectsRegentes() {
  const opcoes = contasRegentes.map((conta) => `<option value="${escaparHtml(conta.nome)}">${escaparHtml(conta.nome)}</option>`).join('');
  const cadastro = document.getElementById('subordinada-regente');
  const filtro = document.getElementById('filtro-subordinada-regente');
  if (cadastro) cadastro.innerHTML = opcoes;
  if (filtro) filtro.innerHTML = `<option value="todas">Todas as regentes</option>${opcoes}`;
}

function renderizarContasSubordinadas() {
  const tbody = document.getElementById('contas-subordinadas-tbody');
  if (!tbody) return;

  const regente = document.getElementById('filtro-subordinada-regente')?.value || 'todas';
  const lista = contasSubordinadas.filter((conta) => regente === 'todas' || conta.regente === regente);

  tbody.innerHTML = lista.map((conta) => `
    <tr>
      <td>${escaparHtml(conta.nome)}</td>
      <td>${escaparHtml(conta.regente)}</td>
      <td>${conta.movimentos}</td>
      <td>${badgeStatus(conta.status)}</td>
      <td>
        <div class="tabela__acoes">
          <button class="btn-icone" type="button" aria-label="Editar"><span class="material-icons">edit</span></button>
          <button class="btn-icone btn-icone-perigo" type="button" aria-label="Inativar"><span class="material-icons">block</span></button>
        </div>
      </td>
    </tr>
  `).join('');
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
      <div class="card-stat__rodape">Atualizado com dados locais</div>
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

function formatarMoeda(valor) {
  return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function formatarData(iso) {
  if (!iso) return '-';
  const [ano, mes, dia] = iso.split('-');
  return `${dia}/${mes}/${ano}`;
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
