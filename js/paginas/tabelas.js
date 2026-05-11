import { AuxiliaresService } from '../services/associados-auxiliares-service.js';
import Toast from '../componentes/toast.js';
import Modal from '../componentes/modal.js';

/* Configuração de cada tabela: endpoints, labels e campos */
const CONFIGS = {
  genero: {
    label: 'Gênero',
    listar:  ()        => AuxiliaresService.listarGeneros(),
    criar:   (desc)    => AuxiliaresService.criarGenero(desc),
    editar:  (id, desc)=> AuxiliaresService.editarGenero(id, desc),
    excluir: (id)      => AuxiliaresService.excluirGenero(id),
  },
  parentesco: {
    label: 'Parentesco',
    listar:  ()        => AuxiliaresService.listarParentescos(),
    criar:   (desc)    => AuxiliaresService.criarParentesco(desc),
    editar:  (id, desc)=> AuxiliaresService.editarParentesco(id, desc),
    excluir: (id)      => AuxiliaresService.excluirParentesco(id),
  },
  profissao: {
    label: 'Profissão',
    listar:  ()        => AuxiliaresService.listarProfissoes(),
    criar:   (desc)    => AuxiliaresService.criarProfissao(desc),
    editar:  (id, desc)=> AuxiliaresService.editarProfissao(id, desc),
    excluir: (id)      => AuxiliaresService.excluirProfissao(id),
  },
  estadocivil: {
    label: 'Estado Civil',
    listar:  ()        => AuxiliaresService.listarEstadosCivis(),
    criar:   (desc)    => AuxiliaresService.criarEstadoCivil(desc),
    editar:  (id, desc)=> AuxiliaresService.editarEstadoCivil(id, desc),
    excluir: (id)      => AuxiliaresService.excluirEstadoCivil(id),
  },
  status: {
    label: 'Status',
    listar:  ()        => AuxiliaresService.listarStatusPessoa(),
    criar:   (desc)    => AuxiliaresService.criarStatus(desc),
    editar:  (id, desc)=> AuxiliaresService.editarStatus(id, desc),
    excluir: (id)      => AuxiliaresService.excluirStatus(id),
  },
};

const TabelasPage = {
  _dados: {},
  _abaAtual: 'genero',
  _editandoChave: null,
  _editandoId: null,

  async init() {
    this._inicializarAbas();
    this._registrarEventos();
    await this._carregarAba('genero');
  },

  /* ── Abas ── */
  _inicializarAbas() {
    document.querySelectorAll('[data-tabaux-aba]').forEach(aba => {
      aba.addEventListener('click', async () => {
        const chave = aba.dataset.tabauxAba;

        document.querySelectorAll('[data-tabaux-aba]').forEach(a => {
          a.classList.remove('tabaux__aba--ativa');
          a.setAttribute('aria-selected', 'false');
        });
        document.querySelectorAll('.tabaux__painel').forEach(p => {
          p.classList.remove('tabaux__painel--ativo');
          p.hidden = true;
        });

        aba.classList.add('tabaux__aba--ativa');
        aba.setAttribute('aria-selected', 'true');
        const painel = document.getElementById(`tabaux-${chave}`);
        if (painel) { painel.classList.add('tabaux__painel--ativo'); painel.hidden = false; }

        this._abaAtual = chave;
        if (!this._dados[chave]) await this._carregarAba(chave);
      });
    });
  },

  /* ── Carregar dados do backend ── */
  async _carregarAba(chave) {
    try {
      const dados = await CONFIGS[chave].listar();
      this._dados[chave] = dados;
      this._renderTabela(chave, dados);
    } catch (e) {
      Toast.erro(`Erro ao carregar ${CONFIGS[chave].label}: ${e.message}`);
    }
  },

  /* ── Renderizar tabela ── */
  _renderTabela(chave, dados) {
    const tbody = document.getElementById(`tbody-${chave}`);
    if (!tbody) return;

    if (!dados.length) {
      tbody.innerHTML = `<tr><td colspan="3" style="text-align:center;color:var(--texto-suave);padding:var(--esp-lg)">Nenhum registro cadastrado.</td></tr>`;
    } else {
      tbody.innerHTML = dados.map(item => `
        <tr>
          <td class="tabaux__id">#${String(item.id).padStart(3, '0')}</td>
          <td><strong>${this._esc(item.descricao)}</strong></td>
          <td class="tabela__acoes">
            <button type="button" class="btn-icone" title="Editar"
              data-acao="editar" data-chave="${chave}" data-id="${item.id}" data-desc="${this._esc(item.descricao)}">
              <span class="material-icons">edit</span>
            </button>
            <button type="button" class="btn-icone btn-icone--perigo" title="Excluir"
              data-acao="excluir" data-chave="${chave}" data-id="${item.id}" data-desc="${this._esc(item.descricao)}">
              <span class="material-icons">delete</span>
            </button>
          </td>
        </tr>
      `).join('');
    }

    const badge = document.getElementById(`badge-${chave}`);
    const count = document.getElementById(`count-${chave}`);
    if (badge) badge.textContent = `${dados.length} registros`;
    if (count) count.textContent = `Exibindo ${dados.length} de ${dados.length} registros`;
  },

  /* ── Eventos ── */
  _registrarEventos() {
    /* Botões Adicionar */
    Object.keys(CONFIGS).forEach(chave => {
      const btn   = document.getElementById(`btn-add-${chave}`);
      const input = document.getElementById(`${chave}-novo`);
      if (btn)   btn.addEventListener('click', () => this._adicionar(chave));
      if (input) input.addEventListener('keydown', e => { if (e.key === 'Enter') this._adicionar(chave); });
    });

    /* Delegação: editar / excluir */
    document.addEventListener('click', e => {
      const btn = e.target.closest('[data-acao]');
      if (!btn) return;
      const { acao, chave, id, desc } = btn.dataset;
      if (acao === 'editar')  this._abrirEdicao(chave, Number(id), desc);
      if (acao === 'excluir') this._confirmarExclusao(chave, Number(id), desc);
    });

    /* Modal edição: salvar */
    document.getElementById('btn-salvar-edicao')?.addEventListener('click', () => this._salvarEdicao());
    document.getElementById('campo-edicao')?.addEventListener('keydown', e => {
      if (e.key === 'Enter') this._salvarEdicao();
    });
  },

  /* ── Adicionar ── */
  async _adicionar(chave) {
    const input = document.getElementById(`${chave}-novo`);
    if (!input) return;
    const desc = input.value.trim();
    if (!desc) { Toast.alerta('Informe uma descrição antes de adicionar.'); input.focus(); return; }

    try {
      await CONFIGS[chave].criar(desc);
      input.value = '';
      Toast.sucesso(`${CONFIGS[chave].label} adicionado com sucesso.`);
      delete this._dados[chave];
      await this._carregarAba(chave);
    } catch (e) {
      Toast.erro(e.message || `Erro ao adicionar ${CONFIGS[chave].label}.`);
    }
  },

  /* ── Editar: abrir modal ── */
  _abrirEdicao(chave, id, desc) {
    this._editandoChave = chave;
    this._editandoId    = id;
    const titulo = document.getElementById('edicao-titulo');
    const campo  = document.getElementById('campo-edicao');
    if (titulo) titulo.textContent = `Editar ${CONFIGS[chave].label}`;
    if (campo)  { campo.value = desc; }
    Modal.abrir('modal-edicao');
    setTimeout(() => campo?.focus(), 100);
  },

  /* ── Editar: salvar ── */
  async _salvarEdicao() {
    const campo = document.getElementById('campo-edicao');
    const desc  = campo?.value.trim() ?? '';
    if (!desc) { Toast.alerta('Informe uma descrição.'); campo?.focus(); return; }

    try {
      await CONFIGS[this._editandoChave].editar(this._editandoId, desc);
      Modal.fechar('modal-edicao');
      Toast.sucesso('Registro atualizado com sucesso.');
      delete this._dados[this._editandoChave];
      await this._carregarAba(this._editandoChave);
    } catch (e) {
      Toast.erro(e.message || 'Erro ao atualizar registro.');
    }
  },

  /* ── Excluir: confirmação ── */
  _confirmarExclusao(chave, id, desc) {
    Modal.confirmar({
      titulo: `Excluir ${CONFIGS[chave].label}`,
      mensagem: `Deseja excluir <strong>${this._esc(desc)}</strong>? Esta ação não pode ser desfeita.`,
      variante: 'erro',
      icone: 'delete_forever',
      textoConfirmar: 'Excluir',
      estiloConfirmar: 'perigo',
      aoConfirmar: async () => {
        try {
          await CONFIGS[chave].excluir(id);
          Toast.sucesso('Registro excluído com sucesso.');
          delete this._dados[chave];
          await this._carregarAba(chave);
        } catch (e) {
          Toast.erro(e.message || 'Erro ao excluir registro.');
        }
      },
    });
  },

  _esc(texto) {
    const d = document.createElement('div');
    d.textContent = String(texto ?? '');
    return d.innerHTML;
  },

  destroy() {
    this._dados         = {};
    this._editandoChave = null;
    this._editandoId    = null;
  },
};

export default TabelasPage;
