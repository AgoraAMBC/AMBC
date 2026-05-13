/**
 * ============================================================
 * PAGINA: NOVO PARCEIRO - AMBC V2
 * ============================================================
 * Controller da view de cadastro/edicao de parceiro.
 * ============================================================
 */

import Toast from '../componentes/toast.js';
import Modal from '../componentes/modal.js';
import { ParceirosService } from '../services/parceiros-service.js';

let telefones = [];
let lancamentos = [];
let cleanup = [];
let idParceiro = null;
let modoEdicao = false;
let indiceLancamentoEdicao = null;
let dominiosFinanceiros = {
    tipos: [],
    status: [],
};

function init() {
    console.log('[NovoParceiro] Pagina carregada');

    telefones = [];
    lancamentos = [];
    indiceLancamentoEdicao = null;
    idParceiro = _obterIdDaRota();
    modoEdicao = idParceiro !== null;

    _bindForm();
    _bindTelefones();
    _bindLancamentos();
    _bindCancelamento();
    _carregarDominiosFinanceiros();
    _prepararModoEdicao();
}

function destroy() {
    cleanup.forEach(fn => fn());
    cleanup = [];
    delete window._removerTelefone;
    delete window._editarLancamento;
    delete window._removerLancamento;
    console.log('[NovoParceiro] Pagina destruida');
}

function _bindForm() {
    const form = document.getElementById('form-parceiro');
    if (!form) return;

    const handler = async (e) => {
        e.preventDefault();

        const btnSalvar = form.querySelector('#btn-salvar');
        _setBotaoSalvando(btnSalvar, true);

        const dados = _coletarDados(form);
        if (modoEdicao) {
            dados.id_parceiro = idParceiro;
        }

        try {
            if (modoEdicao) {
                await ParceirosService.editar(dados);
                Toast.sucesso('Parceiro atualizado com sucesso!');
            } else {
                await ParceirosService.cadastrar(dados);
                Toast.sucesso('Parceiro cadastrado com sucesso!');
            }

            setTimeout(() => { window.location.hash = '#/cadastro/listar'; }, 1200);
        } catch (err) {
            Toast.erro(err.message || 'Erro ao salvar parceiro.');
            _setBotaoSalvando(btnSalvar, false);
        }
    };

    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
}

function _coletarDados(form) {
    return {
        nome_razao_social: form.querySelector('#parceiro-nome')?.value.trim() ?? '',
        cpf_cnpj: form.querySelector('#parceiro-cpf-cnpj')?.value.trim() ?? '',
        email: form.querySelector('#parceiro-email')?.value.trim() ?? '',
        tipo_pessoa: form.querySelector('input[name="tipo_pessoa"]:checked')?.value ?? 'PF',
        tipo_servico: form.querySelector('#parceiro-tipo-servico')?.value.trim() ?? '',
        logradouro: form.querySelector('#parceiro-logradouro')?.value.trim() ?? '',
        numero: form.querySelector('#parceiro-numero')?.value.trim() ?? '',
        complemento: form.querySelector('#parceiro-complemento')?.value.trim() ?? '',
        cep: form.querySelector('#parceiro-cep')?.value.trim() ?? '',
        bairro: form.querySelector('#parceiro-bairro')?.value.trim() ?? '',
        cidade: form.querySelector('#parceiro-cidade')?.value.trim() ?? '',
        uf: form.querySelector('#parceiro-uf')?.value ?? '',
        telefones,
        lancamentos: lancamentos.map(({ id_lancamento, ...lancamento }) => lancamento),
    };
}

function _bindTelefones() {
    const btnAdd = document.getElementById('btn-add-telefone');
    if (!btnAdd) return;

    const handler = () => _adicionarTelefone();
    btnAdd.addEventListener('click', handler);
    cleanup.push(() => btnAdd.removeEventListener('click', handler));
}

function _adicionarTelefone() {
    const ddd = document.getElementById('tel-ddd')?.value.trim() ?? '';
    const numero = document.getElementById('tel-numero')?.value.trim() ?? '';
    const tipo = document.getElementById('tel-tipo')?.value ?? null;
    const obs = document.getElementById('tel-obs')?.value.trim() ?? '';

    if (!ddd || !numero) {
        Toast.alerta('Informe o DDD e o numero do telefone.');
        return;
    }

    telefones.push({
        ddd,
        numero,
        fk_tipo_telefone: tipo || null,
        observacao: obs || null,
    });

    _renderizarTelefones();

    document.getElementById('tel-ddd').value = '';
    document.getElementById('tel-numero').value = '';
    document.getElementById('tel-obs').value = '';
}

function _removerTelefone(index) {
    telefones.splice(index, 1);
    _renderizarTelefones();
}

const TIPOS_TELEFONE = {
    '1': 'Celular',
    '2': 'Residencial',
    '3': 'Comercial',
    '4': 'WhatsApp',
    '5': 'Outro',
};

function _renderizarTelefones() {
    const tbody = document.getElementById('lista-telefones');
    if (!tbody) return;

    if (telefones.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="cadastro-associado__estado-vazio">Nenhum telefone adicionado.</td></tr>';
        return;
    }

    tbody.innerHTML = telefones.map((tel, i) => `
        <tr>
            <td>${TIPOS_TELEFONE[tel.fk_tipo_telefone] ?? '-'}</td>
            <td>(${escaparHtml(tel.ddd)}) ${escaparHtml(tel.numero)}</td>
            <td>${escaparHtml(tel.observacao ?? '-')}</td>
            <td class="col-acoes">
                <button type="button" class="btn btn-secundario btn-sm"
                    onclick="window._removerTelefone(${i})" title="Remover">
                    <span class="material-icons">delete</span>
                </button>
            </td>
        </tr>
    `).join('');

    window._removerTelefone = _removerTelefone;
}

function _bindLancamentos() {
    const btnAdd = document.getElementById('btn-add-lancamento');
    if (!btnAdd) return;

    const handler = () => _salvarLancamentoLocal();
    btnAdd.addEventListener('click', handler);
    cleanup.push(() => btnAdd.removeEventListener('click', handler));
}

async function _carregarDominiosFinanceiros() {
    try {
        const dados = await ParceirosService.dominiosLancamentos();
        dominiosFinanceiros = dados;
        _preencherSelectTiposLancamento();
    } catch (err) {
        console.warn('[NovoParceiro] Dominios financeiros indisponiveis:', err);
        dominiosFinanceiros = {
            tipos: [
                { id_tipo_lancamento: 1, descricao: 'Anuidade' },
                { id_tipo_lancamento: 2, descricao: 'Mensalidade' },
                { id_tipo_lancamento: 5, descricao: 'Outro' },
            ],
            status: [
                { id_status_conta: 1, descricao: 'Aberto' },
                { id_status_conta: 2, descricao: 'Liquidado' },
                { id_status_conta: 3, descricao: 'Cancelado' },
            ],
        };
        _preencherSelectTiposLancamento();
    }
}

function _preencherSelectTiposLancamento() {
    const select = document.getElementById('lancamento-tipo');
    if (!select) return;

    select.innerHTML = '<option value="">Tipo</option>' + (dominiosFinanceiros.tipos ?? []).map((tipo) =>
        `<option value="${tipo.id_tipo_lancamento}">${escaparHtml(tipo.descricao)}</option>`
    ).join('');
    _renderizarLancamentos();
}

function _salvarLancamentoLocal() {
    const lancamento = _coletarLancamento();
    if (!lancamento) return;

    if (indiceLancamentoEdicao !== null) {
        lancamentos[indiceLancamentoEdicao] = lancamento;
        indiceLancamentoEdicao = null;
        _setTextoBotaoLancamento('Adicionar');
    } else {
        lancamentos.push(lancamento);
    }

    _limparCamposLancamento();
    _renderizarLancamentos();
}

function _coletarLancamento() {
    const tipo = document.getElementById('lancamento-tipo')?.value ?? '';
    const referencia = document.getElementById('lancamento-referencia')?.value.trim() ?? '';
    const valor = Number(document.getElementById('lancamento-valor')?.value || 0);
    const dataPagamento = document.getElementById('lancamento-data-pagamento')?.value ?? '';
    const status = document.getElementById('lancamento-status')?.value ?? '1';

    if (!tipo || !referencia || valor <= 0) {
        Toast.alerta('Informe tipo, referencia e valor do lancamento.');
        return null;
    }

    return {
        fk_tipo_lancamento: Number(tipo),
        referencia,
        valor,
        data_pagamento: dataPagamento || null,
        fk_status_conta: Number(status),
    };
}

function _editarLancamento(index) {
    const item = lancamentos[index];
    if (!item) return;

    _setValor('#lancamento-tipo', item.fk_tipo_lancamento);
    _setValor('#lancamento-referencia', item.referencia);
    _setValor('#lancamento-valor', item.valor);
    _setValor('#lancamento-data-pagamento', item.data_pagamento);
    _setValor('#lancamento-status', item.fk_status_conta);
    indiceLancamentoEdicao = index;
    _setTextoBotaoLancamento('Salvar');
}

function _removerLancamento(index) {
    lancamentos.splice(index, 1);
    if (indiceLancamentoEdicao === index) {
        indiceLancamentoEdicao = null;
        _limparCamposLancamento();
        _setTextoBotaoLancamento('Adicionar');
    }
    _renderizarLancamentos();
}

function _renderizarLancamentos() {
    const tbody = document.getElementById('lista-lancamentos');
    if (!tbody) return;

    if (lancamentos.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="cadastro-associado__estado-vazio">Nenhum lançamento adicionado.</td></tr>';
        return;
    }

    tbody.innerHTML = lancamentos.map((item, i) => `
        <tr>
            <td><span class="parceiro-financeiro__tipo">${escaparHtml(_obterTipoLancamento(item.fk_tipo_lancamento))}</span></td>
            <td>${escaparHtml(item.referencia)}</td>
            <td>${formatarMoeda(item.valor)}</td>
            <td>${formatarData(item.data_pagamento)}</td>
            <td>${_badgeStatusLancamento(item.fk_status_conta)}</td>
            <td class="col-acoes">
                <button type="button" class="btn btn-secundario btn-sm" onclick="window._editarLancamento(${i})" title="Editar">
                    <span class="material-icons">edit</span>
                </button>
                <button type="button" class="btn btn-secundario btn-sm" onclick="window._removerLancamento(${i})" title="Remover">
                    <span class="material-icons">delete</span>
                </button>
            </td>
        </tr>
    `).join('');

    window._editarLancamento = _editarLancamento;
    window._removerLancamento = _removerLancamento;
}

function _limparCamposLancamento() {
    _setValor('#lancamento-tipo', '');
    _setValor('#lancamento-referencia', '');
    _setValor('#lancamento-valor', '');
    _setValor('#lancamento-data-pagamento', '');
    _setValor('#lancamento-status', '1');
}

function _setTextoBotaoLancamento(texto) {
    const btn = document.getElementById('btn-add-lancamento');
    if (!btn) return;
    btn.innerHTML = texto === 'Salvar'
        ? '<span class="material-icons">check</span>'
        : '<span class="material-icons">add_circle</span>';
}

function _obterTipoLancamento(id) {
    const tipo = (dominiosFinanceiros.tipos ?? []).find((item) => Number(item.id_tipo_lancamento) === Number(id));
    return tipo?.descricao ?? '-';
}

function _badgeStatusLancamento(idStatus) {
    const id = Number(idStatus);
    if (id === 2) return '<span class="parceiro-financeiro__status parceiro-financeiro__status--pago">Pago</span>';
    if (id === 3) return '<span class="parceiro-financeiro__status parceiro-financeiro__status--cancelado">Cancelado</span>';
    return '<span class="parceiro-financeiro__status parceiro-financeiro__status--pendente">Pendente</span>';
}

function _obterIdDaRota() {
    const query = window.location.hash.split('?')[1] ?? '';
    const id = parseInt(new URLSearchParams(query).get('id') ?? '', 10);
    return Number.isInteger(id) && id > 0 ? id : null;
}

async function _prepararModoEdicao() {
    if (!modoEdicao) return;

    const titulo = document.querySelector('.cadastro-associado__titulo');
    const subtitulo = document.querySelector('.cadastro-associado__subtitulo');
    if (titulo) titulo.textContent = 'Editar Parceiro';
    if (subtitulo) subtitulo.textContent = 'Atualize os dados do parceiro, endereco, contatos e lancamentos.';

    const btnSalvar = document.getElementById('btn-salvar');
    if (btnSalvar) {
        btnSalvar.innerHTML = '<span class="material-icons">save</span><span>Salvar Alteracoes</span>';
    }

    try {
        const parceiro = await ParceirosService.buscar(idParceiro);
        _preencherFormulario(parceiro);
    } catch (err) {
        console.error('[NovoParceiro] Erro ao carregar parceiro:', err);
        Toast.erro(err.message || 'Nao foi possivel carregar o parceiro.');
    }
}

function _preencherFormulario(parceiro) {
    const form = document.getElementById('form-parceiro');
    if (!form) return;

    _setValor('#parceiro-nome', parceiro.nome_razao_social);
    _setValor('#parceiro-cpf-cnpj', parceiro.cpf_cnpj);
    _setValor('#parceiro-email', parceiro.email);
    _setValor('#parceiro-tipo-servico', parceiro.tipo_servico);
    _setValor('#parceiro-logradouro', parceiro.logradouro);
    _setValor('#parceiro-numero', parceiro.numero);
    _setValor('#parceiro-complemento', parceiro.complemento);
    _setValor('#parceiro-cep', parceiro.cep);
    _setValor('#parceiro-bairro', parceiro.bairro);
    _setValor('#parceiro-cidade', parceiro.cidade);
    _setValor('#parceiro-uf', parceiro.uf);

    const tipoPessoa = form.querySelector(`input[name="tipo_pessoa"][value="${parceiro.tipo_pessoa ?? 'PF'}"]`);
    if (tipoPessoa) tipoPessoa.checked = true;

    telefones = Array.isArray(parceiro.telefones)
        ? parceiro.telefones.map(tel => ({
            ddd: tel.ddd ?? '',
            numero: tel.numero ?? '',
            fk_tipo_telefone: tel.fk_tipo_telefone ? String(tel.fk_tipo_telefone) : null,
            observacao: tel.observacao ?? null,
        }))
        : [];

    lancamentos = Array.isArray(parceiro.lancamentos)
        ? parceiro.lancamentos.map(item => ({
            id_lancamento: item.id_lancamento ?? null,
            fk_tipo_lancamento: item.fk_tipo_lancamento ? Number(item.fk_tipo_lancamento) : null,
            referencia: item.referencia ?? item.descricao ?? '',
            valor: Number(item.valor || 0),
            data_pagamento: item.data_pagamento ?? null,
            fk_status_conta: item.fk_status_conta ? Number(item.fk_status_conta) : 1,
        }))
        : [];

    _renderizarTelefones();
    _renderizarLancamentos();
}

function _setValor(seletor, valor) {
    const campo = document.querySelector(seletor);
    if (campo) campo.value = valor ?? '';
}

function _setBotaoSalvando(botao, salvando) {
    if (!botao) return;
    botao.disabled = salvando;
    botao.innerHTML = salvando
        ? '<span class="material-icons">hourglass_top</span><span>Salvando...</span>'
        : `<span class="material-icons">save</span><span>${modoEdicao ? 'Salvar Alteracoes' : 'Salvar Cadastro'}</span>`;
}

function _bindCancelamento() {
    const btn = document.getElementById('btn-cancelar');
    if (!btn) return;

    const handler = () => {
        Modal.confirmar({
            titulo: modoEdicao ? 'Cancelar edicao' : 'Cancelar cadastro',
            mensagem: 'Deseja cancelar? Os dados preenchidos serao perdidos.',
            variante: 'alerta',
            textoConfirmar: 'Sim, cancelar',
            estiloConfirmar: 'perigo',
            aoConfirmar: () => { window.location.hash = '#/cadastro/listar'; },
        });
    };

    btn.addEventListener('click', handler);
    cleanup.push(() => btn.removeEventListener('click', handler));
}

function formatarMoeda(valor) {
    return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function formatarData(valor) {
    if (!valor) return '-';
    const [ano, mes, dia] = valor.split('-');
    return `${dia}/${mes}/${ano}`;
}

function escaparHtml(texto) {
    const div = document.createElement('div');
    div.textContent = String(texto ?? '');
    return div.innerHTML;
}

export default { init, destroy };
