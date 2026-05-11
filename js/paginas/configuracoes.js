import { ConfiguracoesService } from '../services/configuracoes-service.js';
import { DocumentosService }   from '../services/documentos-service.js';
import Toast from '../componentes/toast.js';
import { formatarData } from '../core/formatadores.js';

/* =========================================================
   Config Gerais — mapeamento campo → chave no banco
========================================================= */
const CAMPOS_SELECTS = {
    'ger-idioma': 'idioma',
    'ger-fuso':   'fuso_horario',
    'ger-data':   'formato_data',
    'ger-moeda':  'moeda',
};

const CAMPOS_TOGGLES = {
    'tog-vencimentos':   'notif_vencimentos',
    'tog-inadimplencia': 'notif_inadimplencia',
    'tog-resumo':        'notif_resumo_semanal',
    'tog-cadastros':     'notif_novos_cadastros',
    'tog-2fa':           'seg_2fa',
    'tog-sessao':        'seg_expirar_sessao',
};

/* =========================================================
   Relacionamentos — Modal de nova regra
========================================================= */
function abrirModalRegra()  { document.getElementById('modal-regra')?.removeAttribute('hidden'); }
function fecharModalRegra() { document.getElementById('modal-regra')?.setAttribute('hidden', ''); }

function registrarEventosRelacionamentos() {
    document.getElementById('btn-nova-regra')        ?.addEventListener('click', abrirModalRegra);
    document.getElementById('modal-regra-fechar')    ?.addEventListener('click', fecharModalRegra);
    document.getElementById('modal-regra-cancelar')  ?.addEventListener('click', fecharModalRegra);
    document.getElementById('modal-regra-fundo')     ?.addEventListener('click', fecharModalRegra);
}

/* =========================================================
   Config Gerais — toggles e permissões
========================================================= */
function inicializarToggles() {
    document.querySelectorAll('.cfg-gerais__toggle').forEach(btn => {
        btn.addEventListener('click', () => {
            const ativo = btn.classList.toggle('cfg-gerais__toggle--ativo');
            btn.setAttribute('aria-pressed', String(ativo));
        });
    });
}

function inicializarPermissoes() {
    document.querySelectorAll('.cfg-gerais__perm').forEach(btn => {
        btn.addEventListener('click', () => {
            const eSim = btn.classList.contains('cfg-gerais__perm--sim');
            btn.classList.toggle('cfg-gerais__perm--sim', !eSim);
            btn.classList.toggle('cfg-gerais__perm--nao', eSim);
            btn.setAttribute('aria-pressed', String(!eSim));
            btn.querySelector('.material-icons').textContent = eSim ? 'remove_circle' : 'check_circle';
        });
    });
}

async function carregarPreferencias() {
    try {
        const configs = await ConfiguracoesService.listar();
        for (const [id, chave] of Object.entries(CAMPOS_SELECTS)) {
            const el = document.getElementById(id);
            if (el && configs[chave] !== undefined) el.value = configs[chave];
        }
        for (const [id, chave] of Object.entries(CAMPOS_TOGGLES)) {
            const el = document.getElementById(id);
            if (!el) continue;
            const ativo = configs[chave] === 'true';
            el.classList.toggle('cfg-gerais__toggle--ativo', ativo);
            el.setAttribute('aria-pressed', String(ativo));
        }
        const diasEl = document.getElementById('ger-dias-alerta');
        if (diasEl && configs['dias_alerta_vencimento'] !== undefined) {
            diasEl.value = configs['dias_alerta_vencimento'];
        }
    } catch (e) {
        Toast.erro('Erro ao carregar preferências: ' + e.message);
    }
}

async function salvarPreferencias() {
    const dados = {};
    for (const [id, chave] of Object.entries(CAMPOS_SELECTS)) {
        const el = document.getElementById(id);
        if (el) dados[chave] = el.value;
    }
    for (const [id, chave] of Object.entries(CAMPOS_TOGGLES)) {
        const el = document.getElementById(id);
        if (el) dados[chave] = el.classList.contains('cfg-gerais__toggle--ativo') ? 'true' : 'false';
    }
    const diasEl = document.getElementById('ger-dias-alerta');
    if (diasEl) {
        const dias = parseInt(diasEl.value, 10);
        if (isNaN(dias) || dias < 1 || dias > 30) {
            Toast.alerta('Dias para alerta deve ser entre 1 e 30.');
            diasEl.focus();
            return;
        }
        dados['dias_alerta_vencimento'] = String(dias);
    }
    try {
        await ConfiguracoesService.salvar(dados);
        Toast.sucesso('Preferências salvas com sucesso.');
    } catch (e) {
        Toast.erro('Erro ao salvar: ' + e.message);
    }
}

/* =========================================================
   Documentos — estado local
========================================================= */
let _excluindoDocId   = null;
let _excluindoDocNome = null;

function _badgeTipo(ext) {
    if (!ext) return '';
    const cor = ext === 'pdf' ? 'badge-azul' : 'badge-cinza';
    return `<span class="badge ${cor}">${ext.toUpperCase()}</span>`;
}

function _extArquivo(path) {
    if (!path) return '';
    return (path.split('.').pop() || '').toLowerCase();
}

function _renderDocumentos(docs) {
    const tbody = document.getElementById('tbody-documentos');
    if (!tbody) return;

    if (!docs.length) {
        tbody.innerHTML = '<tr><td colspan="5" class="gu-tabela__estado">Nenhum documento cadastrado.</td></tr>';
        return;
    }

    tbody.innerHTML = docs.map(d => {
        const ext  = _extArquivo(d.arquivo_path);
        const nome = d.assunto ?? '—';
        const tr   = document.createElement('tr');
        tr.innerHTML = `
          <td style="font-weight:var(--fw-semibold)">${nome}</td>
          <td>${_badgeTipo(ext)} ${d.tipo ?? ''}</td>
          <td style="color:var(--texto-suave)">${d.versao ?? '—'}</td>
          <td style="color:var(--texto-suave)">${formatarData(d.data_documento)}</td>
          <td class="tabela__num">
            <button type="button" class="btn btn-secundario btn-sm" title="Baixar"
              data-doc-acao="baixar" data-doc-id="${d.id_documento}">
              <span class="material-icons">download</span>
            </button>
            <button type="button" class="btn btn-secundario btn-sm" title="Excluir"
              data-doc-acao="excluir" data-doc-id="${d.id_documento}">
              <span class="material-icons">delete</span>
            </button>
          </td>`;
        tr.querySelector('[data-doc-acao="excluir"]').dataset.docNome = nome;
        return tr.outerHTML;
    }).join('');
}

async function carregarDocumentos() {
    const tbody = document.getElementById('tbody-documentos');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="5" class="gu-tabela__estado">Carregando…</td></tr>';
    try {
        const docs = await DocumentosService.listar('institucional');
        _renderDocumentos(docs);
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="5" class="gu-tabela__estado">Erro ao carregar documentos.</td></tr>';
        Toast.erro('Erro ao carregar documentos: ' + e.message);
    }
}

async function _popularTipos() {
    const sel = document.getElementById('doc-tipo');
    if (!sel) return;
    try {
        const tipos = await DocumentosService.listarTipos();
        sel.innerHTML = '<option value="">Selecione o tipo…</option>' +
            tipos.map(t => `<option value="${t.id}">${t.descricao}</option>`).join('');
    } catch {
        sel.innerHTML = '<option value="">Erro ao carregar tipos</option>';
    }
}

function _abrirModalDocumento() {
    document.getElementById('doc-assunto').value  = '';
    document.getElementById('doc-versao').value   = '';
    document.getElementById('doc-arquivo').value  = '';
    document.getElementById('modal-documento').hidden = false;
    _popularTipos();
    setTimeout(() => document.getElementById('doc-assunto')?.focus(), 50);
}

function _fecharModalDocumento() {
    document.getElementById('modal-documento').hidden = true;
}

async function _enviarDocumento(e) {
    e.preventDefault();
    const assunto  = document.getElementById('doc-assunto').value.trim();
    const tipoId   = document.getElementById('doc-tipo').value;
    const versao   = document.getElementById('doc-versao').value.trim();
    const arquivo  = document.getElementById('doc-arquivo').files[0];

    if (!assunto)  { Toast.alerta('Informe o nome do documento.'); return; }
    if (!tipoId)   { Toast.alerta('Selecione o tipo.'); return; }
    if (!arquivo)  { Toast.alerta('Selecione um arquivo.'); return; }

    const btnEnviar = document.getElementById('btn-doc-salvar');
    btnEnviar.disabled = true;
    btnEnviar.innerHTML = '<span class="material-icons">hourglass_empty</span> Enviando…';

    const fd = new FormData();
    fd.append('assunto',            assunto);
    fd.append('fk_tipo_documento',  tipoId);
    fd.append('versao',             versao);
    fd.append('categoria',          'institucional');
    fd.append('arquivo',            arquivo);

    try {
        await DocumentosService.enviar(fd);
        Toast.sucesso('Documento enviado com sucesso.');
        _fecharModalDocumento();
        await carregarDocumentos();
    } catch (err) {
        Toast.erro(err.message || 'Erro ao enviar documento.');
    } finally {
        btnEnviar.disabled = false;
        btnEnviar.innerHTML = '<span class="material-icons">upload</span> Enviar';
    }
}

function _abrirConfirmarExclusao(id, nome) {
    _excluindoDocId   = id;
    _excluindoDocNome = nome;
    const msg = document.getElementById('modal-doc-confirmar-msg');
    if (msg) msg.innerHTML = `Deseja excluir <strong>${nome}</strong>? O arquivo será removido permanentemente.`;
    document.getElementById('modal-doc-confirmar').hidden = false;
}

function _fecharConfirmarExclusao() {
    document.getElementById('modal-doc-confirmar').hidden = true;
}

async function _executarExclusao() {
    _fecharConfirmarExclusao();
    try {
        await DocumentosService.excluir(_excluindoDocId);
        Toast.sucesso('Documento excluído com sucesso.');
        await carregarDocumentos();
    } catch (err) {
        Toast.erro(err.message || 'Erro ao excluir documento.');
    }
}

async function inicializarDocumentos() {
    await carregarDocumentos();

    document.getElementById('btn-enviar-documento')
        ?.addEventListener('click', _abrirModalDocumento);

    document.getElementById('modal-documento-fechar')
        ?.addEventListener('click', _fecharModalDocumento);
    document.getElementById('modal-documento-cancelar')
        ?.addEventListener('click', _fecharModalDocumento);
    document.getElementById('modal-documento-fundo')
        ?.addEventListener('click', _fecharModalDocumento);
    document.getElementById('form-documento')
        ?.addEventListener('submit', _enviarDocumento);

    document.getElementById('modal-doc-confirmar-cancelar')
        ?.addEventListener('click', _fecharConfirmarExclusao);
    document.getElementById('modal-doc-confirmar-fundo')
        ?.addEventListener('click', _fecharConfirmarExclusao);
    document.getElementById('modal-doc-confirmar-ok')
        ?.addEventListener('click', _executarExclusao);

    document.getElementById('tbody-documentos')
        ?.addEventListener('click', e => {
            const btn = e.target.closest('[data-doc-acao]');
            if (!btn) return;
            const { docAcao, docId, docNome } = btn.dataset;
            if (docAcao === 'baixar') {
                window.open(DocumentosService.urlBaixar(docId), '_blank');
            }
            if (docAcao === 'excluir') {
                _abrirConfirmarExclusao(Number(docId), docNome);
            }
        });
}

/* =========================================================
   Init / Destroy
========================================================= */
const ConfiguracoesPage = {
    async init() {
        registrarEventosRelacionamentos();
        inicializarToggles();
        inicializarPermissoes();

        if (document.getElementById('btn-salvar-gerais')) {
            await carregarPreferencias();
            document.getElementById('btn-salvar-gerais')
                ?.addEventListener('click', salvarPreferencias);
            document.getElementById('btn-salvar-gerais-rodape')
                ?.addEventListener('click', salvarPreferencias);
        }

        if (document.getElementById('tbody-documentos')) {
            await inicializarDocumentos();
        }
    },

    destroy() {
        document.getElementById('btn-nova-regra')
            ?.removeEventListener('click', abrirModalRegra);
        document.getElementById('modal-regra-fechar')
            ?.removeEventListener('click', fecharModalRegra);
        document.getElementById('modal-regra-cancelar')
            ?.removeEventListener('click', fecharModalRegra);
        document.getElementById('modal-regra-fundo')
            ?.removeEventListener('click', fecharModalRegra);
        _excluindoDocId   = null;
        _excluindoDocNome = null;
    }
};

export default ConfiguracoesPage;
