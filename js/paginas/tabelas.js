import { AuxiliaresService } from '../services/associados-auxiliares-service.js';
import Toast from '../componentes/toast.js';

const CONFIGS = {
  genero:      { label: 'Gênero',       listar: () => AuxiliaresService.listarGeneros(),      criar: (d) => AuxiliaresService.criarGenero(d),      editar: (id, d) => AuxiliaresService.editarGenero(id, d),      excluir: (id) => AuxiliaresService.excluirGenero(id) },
  parentesco:  { label: 'Parentesco',   listar: () => AuxiliaresService.listarParentescos(),  criar: (d) => AuxiliaresService.criarParentesco(d),  editar: (id, d) => AuxiliaresService.editarParentesco(id, d),  excluir: (id) => AuxiliaresService.excluirParentesco(id) },
  profissao:   { label: 'Profissão',    listar: () => AuxiliaresService.listarProfissoes(),   criar: (d) => AuxiliaresService.criarProfissao(d),   editar: (id, d) => AuxiliaresService.editarProfissao(id, d),   excluir: (id) => AuxiliaresService.excluirProfissao(id) },
  estadocivil: { label: 'Estado Civil', listar: () => AuxiliaresService.listarEstadosCivis(), criar: (d) => AuxiliaresService.criarEstadoCivil(d), editar: (id, d) => AuxiliaresService.editarEstadoCivil(id, d), excluir: (id) => AuxiliaresService.excluirEstadoCivil(id) },
  status:      { label: 'Status',       listar: () => AuxiliaresService.listarStatusPessoa(), criar: (d) => AuxiliaresService.criarStatus(d),      editar: (id, d) => AuxiliaresService.editarStatus(id, d),      excluir: (id) => AuxiliaresService.excluirStatus(id) },
};

const TabelasPage = {
  _dados: {},
  _abaAtual: 'genero',
  _modalModo: 'adicionar',
  _editandoChave: null,
  _editandoId: null,
  _excluindoChave: null,
  _excluindoId: null,

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

  /* ── Carregar aba ── */
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
    const sub   = document.getElementById(`sub-${chave}`);
    if (!tbody) return;

    if (sub) sub.textContent = `${dados.length} ${dados.length === 1 ? 'registro' : 'registros'} cadastrados`;

    if (!dados.length) {
      tbody.innerHTML = `<tr><td colspan="3" class="gu-tabela__estado">Nenhum registro cadastrado.</td></tr>`;
      return;
    }

    tbody.innerHTML = dados.map(item => `
      <tr>
        <td class="tabaux__id">#${String(item.id).padStart(3, '0')}</td>
        <td>${this._esc(item.descricao)}</td>
        <td>
          <div class="gu-tabela__acoes">
            <button type="button" class="gu-btn gu-btn--icone" title="Editar"
              data-acao="editar" data-chave="${chave}" data-id="${item.id}" data-desc="${this._esc(item.descricao)}">
              <span class="material-icons">edit</span>
            </button>
            <button type="button" class="gu-btn gu-btn--icone gu-btn--icone-perigo" title="Excluir"
              data-acao="excluir" data-chave="${chave}" data-id="${item.id}" data-desc="${this._esc(item.descricao)}">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `).join('');
  },

  /* ── Eventos ── */
  _registrarEventos() {
    /* Botões Adicionar (um por painel) */
    document.addEventListener('click', e => {
      const btnAdd = e.target.closest('[data-tabaux-adicionar]');
      if (btnAdd) { this._abrirModal(btnAdd.dataset.tabauxAdicionar); return; }

      const btn = e.target.closest('[data-acao]');
      if (!btn) return;
      const { acao, chave, id, desc } = btn.dataset;
      if (acao === 'editar')  this._abrirModal(chave, Number(id), desc);
      if (acao === 'excluir') this._abrirConfirmar(chave, Number(id), desc);
    });

    /* Modal adicionar/editar */
    document.getElementById('modal-tabaux-fechar')?.addEventListener('click',  () => this._fecharModal());
    document.getElementById('modal-tabaux-cancelar')?.addEventListener('click', () => this._fecharModal());
    document.getElementById('modal-tabaux-fundo')?.addEventListener('click',    () => this._fecharModal());
    document.getElementById('form-tabaux')?.addEventListener('submit', e => this._salvarModal(e));
    document.getElementById('tabaux-descricao')?.addEventListener('keydown', e => {
      if (e.key === 'Escape') this._fecharModal();
    });

    /* Modal confirmação exclusão */
    document.getElementById('modal-confirmar-cancelar')?.addEventListener('click', () => this._fecharConfirmar());
    document.getElementById('modal-confirmar-fundo')?.addEventListener('click',    () => this._fecharConfirmar());
    document.getElementById('modal-confirmar-ok')?.addEventListener('click',       () => this._executarExclusao());
  },

  /* ── Modal adicionar / editar ── */
  _abrirModal(chave, id = null, desc = '') {
    this._editandoChave = chave;
    this._editandoId    = id;
    this._modalModo     = id ? 'editar' : 'adicionar';

    const cfg    = CONFIGS[chave];
    const titulo = document.getElementById('modal-tabaux-titulo');
    const icone  = document.getElementById('modal-tabaux-icone');
    const campo  = document.getElementById('tabaux-descricao');

    if (titulo) titulo.textContent = id ? `Editar ${cfg.label}` : `Adicionar ${cfg.label}`;
    if (icone)  icone.textContent  = id ? 'edit' : 'add_circle';
    if (campo)  campo.value = desc;

    document.getElementById('modal-tabaux').hidden = false;
    setTimeout(() => campo?.focus(), 50);
  },

  _fecharModal() {
    document.getElementById('modal-tabaux').hidden = true;
  },

  async _salvarModal(e) {
    e.preventDefault();
    const campo = document.getElementById('tabaux-descricao');
    const desc  = campo?.value.trim() ?? '';
    if (!desc) { Toast.alerta('Informe uma descrição.'); campo?.focus(); return; }

    try {
      if (this._modalModo === 'editar') {
        await CONFIGS[this._editandoChave].editar(this._editandoId, desc);
        Toast.sucesso('Registro atualizado com sucesso.');
      } else {
        await CONFIGS[this._editandoChave].criar(desc);
        Toast.sucesso(`${CONFIGS[this._editandoChave].label} adicionado com sucesso.`);
      }
      this._fecharModal();
      delete this._dados[this._editandoChave];
      await this._carregarAba(this._editandoChave);
    } catch (err) {
      Toast.erro(err.message || 'Erro ao salvar registro.');
    }
  },

  /* ── Modal confirmação exclusão ── */
  _abrirConfirmar(chave, id, desc) {
    this._excluindoChave = chave;
    this._excluindoId    = id;
    const msg = document.getElementById('modal-confirmar-msg');
    if (msg) msg.innerHTML = `Deseja excluir <strong>${this._esc(desc)}</strong>? Esta ação não pode ser desfeita.`;
    document.getElementById('modal-tabaux-confirmar').hidden = false;
  },

  _fecharConfirmar() {
    document.getElementById('modal-tabaux-confirmar').hidden = true;
  },

  async _executarExclusao() {
    this._fecharConfirmar();
    try {
      await CONFIGS[this._excluindoChave].excluir(this._excluindoId);
      Toast.sucesso('Registro excluído com sucesso.');
      delete this._dados[this._excluindoChave];
      await this._carregarAba(this._excluindoChave);
    } catch (err) {
      Toast.erro(err.message || 'Erro ao excluir registro.');
    }
  },

  _esc(texto) {
    const d = document.createElement('div');
    d.textContent = String(texto ?? '');
    return d.innerHTML;
  },

  destroy() {
    this._dados          = {};
    this._editandoChave  = null;
    this._editandoId     = null;
    this._excluindoChave = null;
    this._excluindoId    = null;
  },
};

export default TabelasPage;
