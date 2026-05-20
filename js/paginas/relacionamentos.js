/* =========================================================
relacionamentos.js
   Projeto: AMBC-V2
   Tela: Configuração de Relacionamentos de Lançamentos
========================================================= */

import Toast from '../componentes/toast.js';

const refs = {};
const estado = { editandoId: null };

function init() {
  console.log('[Relacionamentos] Inicializando...');
  mapearRefs();
  registrarEventos();
}

function destroy() {
  Object.keys(refs).forEach(k => (refs[k] = null));
}

/* ─────────── MAPEAR REFERÊNCIAS DOM ─────────── */
function mapearRefs() {
  refs.btnNovaRegra = document.getElementById('btn-nova-regra');
  refs.modal = document.getElementById('modal-regra');
  refs.modalFundo = document.getElementById('modal-regra-fundo');
  refs.modalFechar = document.getElementById('modal-regra-fechar');
  refs.form = document.getElementById('form-regra');
  refs.categoria = document.getElementById('regra-categoria');
  refs.conta = document.getElementById('regra-conta');
  refs.tipo = document.getElementById('regra-tipo');
  refs.acao = document.getElementById('regra-acao');
  refs.descricao = document.getElementById('regra-descricao');
  refs.btnCancelar = document.getElementById('modal-regra-cancelar');
}

/* ─────────── EVENTOS ─────────── */
function registrarEventos() {
  refs.btnNovaRegra?.addEventListener('click', abrirModal);
  refs.modalFundo?.addEventListener('click', fecharModal);
  refs.modalFechar?.addEventListener('click', fecharModal);
  refs.btnCancelar?.addEventListener('click', fecharModal);
  refs.form?.addEventListener('submit', salvarRelacionamento);

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

/* ─────────── MODAL ─────────── */
function abrirModal(id = null) {
  estado.editandoId = id;
  limparFormulario();

  if (id) {
    document.querySelector('.gu-modal__titulo').textContent = 'Editar Relacionamento';
  } else {
    document.querySelector('.gu-modal__titulo').textContent = 'Nova Regra de Relacionamento';
  }

  refs.modal?.removeAttribute('hidden');
}

function fecharModal() {
  refs.modal?.setAttribute('hidden', '');
  estado.editandoId = null;
  limparFormulario();
}

function limparFormulario() {
  refs.form?.reset();
}

/* ─────────── SALVAR ─────────── */
function salvarRelacionamento(e) {
  e.preventDefault();

  const dados = {
    categoria: refs.categoria.value,
    conta: refs.conta.value,
    tipo: refs.tipo.value,
    acao: refs.acao.value,
    descricao: refs.descricao.value,
  };

  if (!dados.categoria || !dados.conta || !dados.tipo || !dados.acao) {
    Toast.alerta('Preencha todos os campos obrigatórios.');
    return;
  }

  Toast.sucesso(estado.editandoId ? 'Relacionamento atualizado.' : 'Relacionamento criado.');
  fecharModal();
}

/* ─────────── EXCLUIR ─────────── */
function excluirRelacionamento(id) {
  if (!confirm('Tem certeza que deseja excluir este relacionamento?')) return;
  Toast.sucesso('Relacionamento excluído.');
}

export default { init, destroy };
