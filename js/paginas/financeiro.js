/* =========================================================
   Pagina: Financeiro
   Projeto: AMBC-V2
   Descricao: Logica das telas financeiras.
========================================================= */

import Toast from '../componentes/toast.js';
import Modal from '../componentes/modal.js';
import { api } from '../services/api.js';

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

let modoEdicaoRegente = null;

async function iniciarContasRegentes() {
  await renderizarContasRegentes();

  const busca = document.getElementById('busca-conta-regente');
  if (busca) {
    const handler = () => renderizarContasRegentes();
    busca.addEventListener('input', handler);
    cleanup.push(() => busca.removeEventListener('input', handler));
  }

  const form = document.getElementById('form-conta-regente');
  if (form) {
    const handler = async (evento) => {
      evento.preventDefault();
      const descricao  = document.getElementById('regente-nome')?.value.trim();
      const tipo       = document.getElementById('regente-tipo')?.value;
      const observacao = document.getElementById('regente-descricao')?.value.trim();
      try {
        if (modoEdicaoRegente) {
          await api.put('/financeiro/contas-regentes/editar.php', { id_conta_regente: modoEdicaoRegente, descricao, tipo, observacao });
          Toast.sucesso('Conta regente atualizada com sucesso!');
          modoEdicaoRegente = null;
          document.querySelector('#form-conta-regente button[type=submit]').textContent = 'Adicionar conta';
        } else {
          await api.post('/financeiro/contas-regentes/cadastrar.php', { descricao, tipo, observacao });
          Toast.sucesso('Conta regente cadastrada com sucesso!');
        }
        form.reset();
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
        document.getElementById('regente-nome').value       = btn.dataset.nome;
        document.getElementById('regente-tipo').value       = btn.dataset.tipo;
        document.getElementById('regente-descricao').value  = btn.dataset.obs || '';
        modoEdicaoRegente = id;
        document.querySelector('#form-conta-regente button[type=submit]').textContent = 'Salvar alterações';
        document.getElementById('regente-nome').focus();
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
  tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:1rem">Carregando…</td></tr>';

  try {
    const params = new URLSearchParams();
    if (busca) params.set('busca', busca);
    const { dados } = await api.get(`/financeiro/contas-regentes/listar.php?${params}`);

    if (!dados.length) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:1rem">Nenhuma conta encontrada.</td></tr>';
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
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:1rem;color:red">${escaparHtml(err.message)}</td></tr>`;
  }
}

async function abrirDetalheRegente(id, nome, tipo, obs, ativo) {
  const dialog = document.createElement('dialog');
  dialog.className = 'modal modal-lg';

  dialog.innerHTML = `
    <div class="modal__cabecalho">
      <div style="flex:1;min-width:0">
        <h2 class="modal__titulo">${escaparHtml(nome)}</h2>
        <div style="display:flex;gap:.5rem;align-items:center;margin-top:.25rem">
          ${badgeTipo(tipo)}
          ${badgeStatus(ativo ? 'ativo' : 'inativo')}
        </div>
      </div>
      <button type="button" class="modal__fechar" data-acao="fechar" aria-label="Fechar">
        <span class="material-icons">close</span>
      </button>
    </div>
    <div class="modal__corpo">
      ${obs ? `<p style="color:var(--texto-secundario);margin-bottom:var(--esp-md)">${escaparHtml(obs)}</p>` : ''}
      <p style="font-size:var(--fs-xs);font-weight:var(--fw-semibold);text-transform:uppercase;letter-spacing:.5px;color:var(--texto-secundario);margin-bottom:var(--esp-sm)">Subcontas vinculadas</p>
      <div id="detalhe-subcontas-lista"><p style="text-align:center;color:var(--texto-secundario)">Carregando…</p></div>
    </div>
    <div class="modal__rodape">
      <button type="button" class="btn btn-secundario" data-acao="fechar">Fechar</button>
    </div>
  `;

  document.body.appendChild(dialog);

  dialog.querySelectorAll('[data-acao="fechar"]').forEach((btn) =>
    btn.addEventListener('click', () => dialog.close())
  );
  dialog.addEventListener('close', () => setTimeout(() => dialog.remove(), 200));

  dialog.showModal();
  Modal._configurarFechamentoBackdrop(dialog);

  const lista = dialog.querySelector('#detalhe-subcontas-lista');
  try {
    const { dados } = await api.get(`/financeiro/contas-subordinadas/listar.php?fk_conta_regente=${id}`);

    if (!dados.length) {
      lista.innerHTML = '<p style="text-align:center;color:var(--texto-secundario)">Nenhuma subconta cadastrada.</p>';
      return;
    }

    lista.innerHTML = `
      <div class="tabela-responsiva">
        <table class="tabela tabela-compacta">
          <thead>
            <tr>
              <th>Nome</th>
              <th>Movimentos</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            ${dados.map((s) => `
              <tr>
                <td>
                  ${escaparHtml(s.descricao)}
                  ${s.observacao ? `<span class="tabela__sub">${escaparHtml(s.observacao)}</span>` : ''}
                </td>
                <td>${s.total_movimentos}</td>
                <td>${badgeStatus(s.ativo ? 'ativo' : 'inativo')}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    lista.innerHTML = `<p style="color:var(--cor-erro-escura)">Erro ao carregar: ${escaparHtml(err.message)}</p>`;
  }
}

let modoEdicaoSubordinada = null;

async function iniciarContasSubordinadas() {
  await preencherSelectsRegentes();
  await renderizarContasSubordinadas();

  const filtro = document.getElementById('filtro-subordinada-regente');
  if (filtro) {
    const handler = () => renderizarContasSubordinadas();
    filtro.addEventListener('change', handler);
    cleanup.push(() => filtro.removeEventListener('change', handler));
  }

  const form = document.getElementById('form-conta-subordinada');
  if (form) {
    const handler = async (evento) => {
      evento.preventDefault();
      const fkRegente  = parseInt(document.getElementById('subordinada-regente')?.value);
      const descricao  = document.getElementById('subordinada-nome')?.value.trim();
      const observacao = document.getElementById('subordinada-descricao')?.value.trim();
      try {
        if (modoEdicaoSubordinada) {
          await api.put('/financeiro/contas-subordinadas/editar.php', { id_conta_subordinada: modoEdicaoSubordinada, fk_conta_regente: fkRegente, descricao, observacao });
          Toast.sucesso('Conta subordinada atualizada com sucesso!');
          modoEdicaoSubordinada = null;
          document.querySelector('#form-conta-subordinada button[type=submit]').textContent = 'Adicionar subconta';
        } else {
          await api.post('/financeiro/contas-subordinadas/cadastrar.php', { fk_conta_regente: fkRegente, descricao, observacao });
          Toast.sucesso('Conta subordinada cadastrada com sucesso!');
        }
        form.reset();
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
        document.getElementById('subordinada-regente').value    = btn.dataset.regente;
        document.getElementById('subordinada-nome').value       = btn.dataset.nome;
        document.getElementById('subordinada-descricao').value  = btn.dataset.obs || '';
        modoEdicaoSubordinada = id;
        document.querySelector('#form-conta-subordinada button[type=submit]').textContent = 'Salvar alterações';
        document.getElementById('subordinada-nome').focus();
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
    const filtro   = document.getElementById('filtro-subordinada-regente');
    if (cadastro) cadastro.innerHTML = opcoes;
    if (filtro)   filtro.innerHTML   = `<option value="0">Todas as regentes</option>${opcoes}`;
  } catch (_) {}
}

async function renderizarContasSubordinadas() {
  const tbody = document.getElementById('contas-subordinadas-tbody');
  if (!tbody) return;

  const regente = parseInt(document.getElementById('filtro-subordinada-regente')?.value || '0');
  tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:1rem">Carregando…</td></tr>';

  try {
    const params = new URLSearchParams();
    if (regente > 0) params.set('fk_conta_regente', String(regente));
    const { dados } = await api.get(`/financeiro/contas-subordinadas/listar.php?${params}`);

    if (!dados.length) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:1rem">Nenhuma subconta encontrada.</td></tr>';
      return;
    }

    tbody.innerHTML = dados.map((c) => `
      <tr>
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
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:1rem;color:red">${escaparHtml(err.message)}</td></tr>`;
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
