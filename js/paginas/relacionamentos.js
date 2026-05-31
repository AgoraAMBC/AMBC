/* =========================================================
relacionamentos.js
   Projeto: AMBC-V2
   Tela: Configuração de Relacionamentos de Lançamentos
========================================================= */

import Toast from '../componentes/toast.js';
import { API_BASE } from '../core/config.js';

const refs = {};
const estado = {
  editandoId: null,
  contasRegentes: [],
  contasSubordinadas: [],
  relacionamentos: [],
};

function init() {
  console.log('[Relacionamentos] Inicializando...');
  mapearRefs();
  registrarEventos();
  carregarDados();
}

function destroy() {
  console.log('[Relacionamentos] Destruindo...');
  Object.keys(refs).forEach(k => (refs[k] = null));
}

/* ─────────── MAPEAR REFERÊNCIAS DOM ─────────── */
function mapearRefs() {
  refs.btnNovaRegra = document.getElementById('btn-nova-regra');
  refs.modal = document.getElementById('modal-regra');
  refs.modalFundo = document.getElementById('modal-regra-fundo');
  refs.modalFechar = document.getElementById('modal-regra-fechar');
  refs.form = document.getElementById('form-regra');
  refs.tipo = document.getElementById('regra-tipo');
  refs.contaRegente = document.getElementById('regra-conta-regente');
  refs.contaSubordinada = document.getElementById('regra-conta-subordinada');
  refs.natureza = document.getElementById('regra-natureza');
  refs.modo = document.getElementById('regra-modo');
  refs.observacao = document.getElementById('regra-observacao');
  refs.btnCancelar = document.getElementById('modal-regra-cancelar');
  refs.loading = document.getElementById('cfg-rel-loading');
  refs.vazio = document.getElementById('cfg-rel-vazio');
  refs.lista = document.getElementById('cfg-rel-lista');
  refs.contador = document.getElementById('cfg-rel-contador');

  console.log('[Relacionamentos] Refs mapeados:', {
    contaRegente: !!refs.contaRegente,
    contaSubordinada: !!refs.contaSubordinada,
    tipo: !!refs.tipo,
    modal: !!refs.modal,
  });
}

/* ─────────── EVENTOS ─────────── */
function registrarEventos() {
  refs.btnNovaRegra?.addEventListener('click', () => abrirModal(null));
  refs.modalFundo?.addEventListener('click', fecharModal);
  refs.modalFechar?.addEventListener('click', fecharModal);
  refs.btnCancelar?.addEventListener('click', fecharModal);
  refs.form?.addEventListener('submit', salvarRelacionamento);
  refs.contaRegente?.addEventListener('change', carregarSubordinadas);

  // Fechar com ESC
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !refs.modal?.hasAttribute('hidden')) {
      fecharModal();
    }
  });

  // Editar e excluir (delegado)
  document.addEventListener('click', (e) => {
    if (e.target.closest('[data-acao="editar"]')) {
      const id = e.target.closest('button').dataset.id;
      abrirModal(parseInt(id));
    }
    if (e.target.closest('[data-acao="excluir"]')) {
      const id = e.target.closest('button').dataset.id;
      excluirRelacionamento(parseInt(id));
    }
  });
}

/* ─────────── CARREGAR DADOS ─────────── */
async function carregarDados() {
  try {
    console.log('[Relacionamentos] Carregando dados...');
    console.log('[Relacionamentos] refs.loading:', refs.loading);
    mostrarLoading(true);

    await carregarContasRegentes();
    await carregarRelacionamentos();

    console.log('[Relacionamentos] Dados carregados com sucesso');
    mostrarLoading(false);
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao carregar:', erro);
    mostrarLoading(false);
    Toast.erro('Erro ao carregar dados.');
  }
}

async function carregarRelacionamentos() {
  try {
    const response = await fetch(`${API_BASE}/relacionamentos/listar.php`);
    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const resultado = await response.json();
    estado.relacionamentos = resultado.data || [];

    console.log('[Relacionamentos] Relacionamentos carregados:', estado.relacionamentos.length);
    renderizarRelacionamentos();
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao carregar relacionamentos:', erro);
    estado.relacionamentos = [];
  }
}

function renderizarRelacionamentos() {
  console.log('[Relacionamentos] renderizarRelacionamentos chamado');
  console.log('[Relacionamentos] refs.lista:', refs.lista);
  console.log('[Relacionamentos] estado.relacionamentos:', estado.relacionamentos);
  console.log('[Relacionamentos] refs.vazio:', refs.vazio);

  if (!refs.lista) {
    console.warn('[Relacionamentos] refs.lista não encontrado!');
    return;
  }

  if (estado.relacionamentos.length === 0) {
    console.log('[Relacionamentos] Nenhum relacionamento, mostrando vazio');
    if (refs.vazio) refs.vazio.style.display = 'flex';
    refs.lista.innerHTML = '';
    refs.contador.textContent = '0 regras ativas';
    return;
  }

  console.log('[Relacionamentos] Renderizando', estado.relacionamentos.length, 'relacionamentos');
  if (refs.vazio) refs.vazio.style.display = 'none';
  refs.lista.innerHTML = '';

  const ativas = estado.relacionamentos.filter(r => r.ativo).length;
  refs.contador.textContent = `${ativas} regra${ativas !== 1 ? 's' : ''} ativa${ativas !== 1 ? 's' : ''}`;

  estado.relacionamentos.forEach(rel => {
    console.log('[Relacionamentos] Renderizando regra:', rel);
    const div = document.createElement('div');
    div.className = `cfg-rel__regra ${!rel.ativo ? 'cfg-rel__regra--inativo' : ''}`;
    div.innerHTML = `
      <div class="cfg-rel__regra-info">
        <div class="cfg-rel__regra-titulo">${rel.tipo_lancamento}</div>
        <div class="cfg-rel__regra-descricao">
          ${rel.conta_regente || '—'} <span class="cfg-rel__regra-seta"></span> ${rel.conta_subordinada || '—'}
        </div>
        <div class="cfg-rel__regra-descricao">
          ${rel.natureza} / ${rel.modo}${rel.observacao ? ` • ${rel.observacao}` : ''}
        </div>
      </div>
      <div class="cfg-rel__regra-acoes">
        <button type="button" class="btn btn-pequeno" data-acao="editar" data-id="${rel.id_relacionamento}" aria-label="Editar" title="Editar">
          <span class="material-icons">edit</span>
        </button>
        <button type="button" class="btn btn-pequeno btn-perigo" data-acao="excluir" data-id="${rel.id_relacionamento}" aria-label="Excluir" title="Excluir">
          <span class="material-icons">delete</span>
        </button>
      </div>
    `;
    refs.lista.appendChild(div);
  });
  console.log('[Relacionamentos] Renderização concluída');
}

async function carregarContasRegentes() {
  try {
    const response = await fetch(`${API_BASE}/financeiro/contas-regentes/listar.php`);
    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const resultado = await response.json();
    estado.contasRegentes = resultado.dados || [];

    console.log('[Relacionamentos] Contas regentes carregadas:', estado.contasRegentes);
    preencherSelectRegentes();
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao carregar regentes:', erro);
    estado.contasRegentes = [];
  }
}

async function carregarSubordinadas() {
  const regenteId = refs.contaRegente?.value;

  if (!regenteId) {
    refs.contaSubordinada.innerHTML = '<option value="">Selecione a conta regente primeiro</option>';
    return;
  }

  try {
    const url = `${API_BASE}/financeiro/contas-subordinadas/listar.php?fk_conta_regente=${regenteId}`;
    console.log('[Relacionamentos] Buscando subordinadas:', url);
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const resultado = await response.json();
    estado.contasSubordinadas = resultado.dados || [];

    console.log('[Relacionamentos] Subordinadas carregadas:', estado.contasSubordinadas);
    preencherSelectSubordinadas();
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao carregar subordinadas:', erro);
    estado.contasSubordinadas = [];
  }
}

function preencherSelectRegentes() {
  if (!refs.contaRegente) {
    console.warn('[Relacionamentos] refs.contaRegente não encontrado');
    return;
  }

  refs.contaRegente.innerHTML = '<option value="">Selecione a conta regente...</option>';

  console.log('[Relacionamentos] Preenchendo regentes, total:', estado.contasRegentes.length);
  estado.contasRegentes.forEach(regente => {
    const option = document.createElement('option');
    option.value = regente.id_conta_regente;
    option.textContent = regente.descricao;
    refs.contaRegente.appendChild(option);
  });
}

function preencherSelectSubordinadas() {
  if (!refs.contaSubordinada) {
    console.warn('[Relacionamentos] refs.contaSubordinada não encontrado');
    return;
  }

  refs.contaSubordinada.innerHTML = '<option value="">Selecione a conta subordinada...</option>';

  console.log('[Relacionamentos] Preenchendo subordinadas, total:', estado.contasSubordinadas.length);
  estado.contasSubordinadas.forEach(subordinada => {
    const option = document.createElement('option');
    option.value = subordinada.id_conta_subordinada;
    option.textContent = subordinada.descricao;
    refs.contaSubordinada.appendChild(option);
  });
}

/* ─────────── MODAL ─────────── */
function abrirModal(id = null) {
  estado.editandoId = id;
  limparFormulario();

  console.log('[Relacionamentos] Abrindo modal, editandoId:', id);
  console.log('[Relacionamentos] Contas regentes disponíveis:', estado.contasRegentes.length);

  const modalTitulo = document.querySelector('.gu-modal__titulo');
  if (modalTitulo) {
    if (id) {
      modalTitulo.textContent = 'Editar Relacionamento';
      carregarRelacionamentoPara(id);
    } else {
      modalTitulo.textContent = 'Nova Regra de Relacionamento';
    }
  }

  refs.modal?.removeAttribute('hidden');
}

async function carregarRelacionamentoPara(id) {
  try {
    const response = await fetch(`${API_BASE}/relacionamentos/obter.php?id=${id}`);
    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const resultado = await response.json();
    const rel = resultado.data;

    console.log('[Relacionamentos] Carregando relacionamento para edição:', rel);

    refs.tipo.value = rel.tipo_lancamento || '';
    refs.contaRegente.value = rel.fk_conta_regente;
    refs.natureza.value = rel.natureza;
    refs.modo.value = rel.modo;
    refs.observacao.value = rel.observacao || '';

    await carregarSubordinadas();
    refs.contaSubordinada.value = rel.fk_conta_subordinada;
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao carregar para edição:', erro);
    Toast.erro('Erro ao carregar dados para edição.');
  }
}

function fecharModal() {
  refs.modal?.setAttribute('hidden', '');
  estado.editandoId = null;
  limparFormulario();
}

function limparFormulario() {
  refs.form?.reset();
  refs.contaSubordinada.innerHTML = '<option value="">Selecione a conta regente primeiro</option>';
  console.log('[Relacionamentos] Formulário limpo');
}

/* ─────────── SALVAR ─────────── */
async function salvarRelacionamento(e) {
  e.preventDefault();

  const dados = {
    tipo: refs.tipo.value.trim(),
    fk_conta_regente: refs.contaRegente.value,
    fk_conta_subordinada: refs.contaSubordinada.value,
    natureza: refs.natureza.value,
    modo: refs.modo.value,
    observacao: refs.observacao.value || null,
  };

  console.log('[Relacionamentos] Salvando:', dados);

  if (!dados.tipo || !dados.fk_conta_regente || !dados.fk_conta_subordinada || !dados.natureza || !dados.modo) {
    Toast.alerta('Preencha todos os campos obrigatórios.');
    return;
  }

  try {
    const endpoint = estado.editandoId
      ? `${API_BASE}/relacionamentos/atualizar.php?id=${estado.editandoId}`
      : `${API_BASE}/relacionamentos/criar.php`;

    console.log('[Relacionamentos] Endpoint:', endpoint);
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dados)
    });

    const resultado = await response.json();
    console.log('[Relacionamentos] Resposta do servidor:', resultado);

    if (!response.ok) {
      throw new Error(resultado.erro || 'Erro ao salvar');
    }

    Toast.sucesso(estado.editandoId ? 'Relacionamento atualizado.' : 'Relacionamento criado.');
    fecharModal();
    carregarDados();
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao salvar:', erro);
    Toast.erro('Erro ao salvar relacionamento.');
  }
}

/* ─────────── EXCLUIR ─────────── */
async function excluirRelacionamento(id) {
  if (!confirm('Tem certeza que deseja excluir este relacionamento?')) return;

  try {
    console.log('[Relacionamentos] Excluindo relacionamento:', id);
    const response = await fetch(`${API_BASE}/relacionamentos/deletar.php?id=${id}`, {
      method: 'DELETE'
    });

    const resultado = await response.json();

    if (!response.ok) {
      throw new Error(resultado.erro || 'Erro ao excluir');
    }

    Toast.sucesso('Relacionamento excluído.');
    carregarDados();
  } catch (erro) {
    console.error('[Relacionamentos] Erro ao excluir:', erro);
    Toast.erro('Erro ao excluir relacionamento.');
  }
}

/* ─────────── HELPERS ─────────── */
function mostrarLoading(show) {
  if (!refs.loading) return;
  refs.loading.style.display = show ? 'flex' : 'none';
}

export default { init, destroy };
