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
import { CadastrosService } from '../services/cadastros-service.js';

let telefones = [];
let lancamentos = [];
let cleanup = [];
let idParceiro = null;
let modoEdicao = false;
let modoVisualizar = false;
let indiceTelefoneEdicao = null;

function init() {
    console.log('[NovoParceiro] Pagina carregada');

    telefones = [];
    lancamentos = [];
    indiceTelefoneEdicao = null;
    idParceiro = _obterIdDaRota();
    modoEdicao = idParceiro !== null;
    modoVisualizar = _obterVisualizarDaRota();

    _bindForm();
    _bindTelefones();
    _bindCancelamento();
    _bindAcoesVisualizacao();
    _bindTipoPessoa();
    _bindBuscarCep();
    _bindMascaras();
    _prepararModoEdicao();
}

function destroy() {
    cleanup.forEach(fn => fn());
    cleanup = [];
    const acoes = document.querySelector('[data-acoes-visualizacao]');
    if (acoes) acoes.hidden = true;
    console.log('[NovoParceiro] Pagina destruida');
}

function _bindForm() {
    const form = document.getElementById('form-parceiro');
    if (!form) return;

    const handler = async (e) => {
        e.preventDefault();

        if (!_validarFormulario(form)) return;

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

function _validarFormulario(form) {
    const nome = form.querySelector('#parceiro-nome')?.value.trim();
    const cpfCnpj = form.querySelector('#parceiro-cpf-cnpj')?.value.trim();

    if (!nome) {
        Toast.alerta('Informe o nome / razão social do parceiro.');
        form.querySelector('#parceiro-nome')?.focus();
        return false;
    }

    if (!cpfCnpj) {
        Toast.alerta('Informe o CPF / CNPJ do parceiro.');
        form.querySelector('#parceiro-cpf-cnpj')?.focus();
        return false;
    }

    return true;
}

function _coletarDados(form) {
    return {
        nome_razao_social: form.querySelector('#parceiro-nome')?.value.trim() ?? '',
        cpf_cnpj: form.querySelector('#parceiro-cpf-cnpj')?.value.replace(/\D/g, '') ?? '',
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
    };
}

function _bindTelefones() {
    const btnAdd = document.getElementById('btn-add-telefone');
    const btnSalvar = document.getElementById('btn-salvar-telefone-parceiro');
    const btnFechar = document.getElementById('modal-telefone-parceiro-fechar');
    const btnCancelar = document.getElementById('modal-telefone-parceiro-cancelar');
    const fundo = document.getElementById('modal-telefone-parceiro-fundo');
    const numero = document.getElementById('telefone-parceiro-numero');
    const tbody = document.getElementById('lista-telefones');

    if (btnAdd) {
        const handler = () => _abrirModalTelefone();
        btnAdd.addEventListener('click', handler);
        cleanup.push(() => btnAdd.removeEventListener('click', handler));
    }

    if (btnSalvar) {
        const handler = () => _salvarTelefoneModal();
        btnSalvar.addEventListener('click', handler);
        cleanup.push(() => btnSalvar.removeEventListener('click', handler));
    }

    [btnFechar, btnCancelar, fundo].forEach((el) => {
        if (!el) return;
        const handler = () => _fecharModalTelefone();
        el.addEventListener('click', handler);
        cleanup.push(() => el.removeEventListener('click', handler));
    });

    if (numero) {
        const handler = aplicarMascaraTelefone;
        numero.addEventListener('input', handler);
        cleanup.push(() => numero.removeEventListener('input', handler));
    }

    if (tbody) {
        const handler = (e) => {
            const btn = e.target.closest('.btn-acao-telefone');
            if (!btn) return;
            const indice = parseInt(btn.dataset.indice, 10);
            if (btn.dataset.acao === 'editar') _editarTelefone(indice);
            if (btn.dataset.acao === 'remover') _removerTelefone(indice);
        };
        tbody.addEventListener('click', handler);
        cleanup.push(() => tbody.removeEventListener('click', handler));
    }
}

function _abrirModalTelefone(index = null) {
    indiceTelefoneEdicao = Number.isInteger(index) ? index : null;
    const telefone = indiceTelefoneEdicao !== null ? telefones[indiceTelefoneEdicao] : null;
    const modal = document.getElementById('modal-telefone-parceiro');
    const titulo = document.getElementById('modal-telefone-parceiro-titulo');
    const tipo = document.getElementById('telefone-parceiro-tipo');
    const numero = document.getElementById('telefone-parceiro-numero');
    const obs = document.getElementById('telefone-parceiro-observacao');
    const btnSalvar = document.getElementById('btn-salvar-telefone-parceiro');

    if (titulo) titulo.textContent = telefone ? 'Editar Contato' : 'Adicionar Contato';
    if (tipo) tipo.value = telefone?.fk_tipo_telefone ? String(telefone.fk_tipo_telefone) : '1';
    if (numero) numero.value = telefone ? formatarTelefone(telefone.ddd, telefone.numero) : '';
    if (obs) obs.value = telefone?.observacao ?? '';
    if (btnSalvar) btnSalvar.innerHTML = '<span class="material-icons">save</span><span>Salvar Contato</span>';
    if (modal) modal.hidden = false;
}

function _fecharModalTelefone() {
    const modal = document.getElementById('modal-telefone-parceiro');
    if (modal) modal.hidden = true;
    indiceTelefoneEdicao = null;
}

function _salvarTelefoneModal() {
    const numeroCampo = document.getElementById('telefone-parceiro-numero');
    const tipo = document.getElementById('telefone-parceiro-tipo')?.value ?? '1';
    const obs = document.getElementById('telefone-parceiro-observacao')?.value.trim() ?? '';
    const digitos = numeroCampo?.value.replace(/\D/g, '').slice(0, 11) ?? '';

    if (digitos.length < 10) {
        Toast.alerta('Informe um numero de telefone valido.');
        return;
    }

    const telefone = {
        ddd: digitos.slice(0, 2),
        numero: digitos.slice(2),
        fk_tipo_telefone: tipo || null,
        observacao: obs || null,
    };

    if (indiceTelefoneEdicao !== null) {
        telefones[indiceTelefoneEdicao] = telefone;
    } else {
        telefones.push(telefone);
    }

    _renderizarTelefones();
    _fecharModalTelefone();
}

function _editarTelefone(index) {
    _abrirModalTelefone(index);
}

function _removerTelefone(index) {
    telefones.splice(index, 1);
    if (indiceTelefoneEdicao === index) {
        indiceTelefoneEdicao = null;
    }
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
            <td>${escaparHtml(formatarTelefone(tel.ddd, tel.numero))}</td>
            <td>${escaparHtml(tel.observacao ?? '-')}</td>
            <td class="col-acoes">
                <button type="button" class="btn btn-secundario btn-sm btn-acao-telefone"
                    data-acao="editar" data-indice="${i}" title="Editar">
                    <span class="material-icons">edit</span>
                </button>
                <button type="button" class="btn btn-secundario btn-sm btn-acao-telefone"
                    data-acao="remover" data-indice="${i}" title="Remover">
                    <span class="material-icons">delete</span>
                </button>
            </td>
        </tr>
    `).join('');
}

async function _carregarLancamentosFinanceiros() {
    if (!idParceiro) return;
    try {
        const resp = await ParceirosService.listarLancamentos(idParceiro);
        lancamentos = resp?.lancamentos || resp?.dados || [];
    } catch {
        lancamentos = [];
    }
    _renderizarLancamentos();
}

function _renderizarLancamentos() {
    const tbody = document.getElementById('lista-lancamentos');
    if (!tbody) return;

    if (lancamentos.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="cadastro-associado__estado-vazio">Nenhum lançamento encontrado.</td></tr>';
        return;
    }

    tbody.innerHTML = lancamentos.map((item) => {
        const statusId = Number(item.fk_status_conta || item.status_conta || 1);
        const statusClasse = statusId === 2 ? 'parceiro-financeiro__status--pago' : statusId === 3 ? 'parceiro-financeiro__status--cancelado' : 'parceiro-financeiro__status--pendente';
        const statusLabel = statusId === 2 ? 'Pago' : statusId === 3 ? 'Cancelado' : 'Pendente';
        return `
        <tr>
            <td>${escaparHtml(item.descricao || item.referencia || '-')}</td>
            <td>${formatarMoeda(Number(item.valor || 0))}</td>
            <td>${formatarData(item.data_vencimento || item.data_pagamento)}</td>
            <td><span class="parceiro-financeiro__status ${statusClasse}">${statusLabel}</span></td>
        </tr>
    `}).join('');
}

function acharInputTipoPessoa() {
    return document.querySelector('input[name="tipo_pessoa"]:checked');
}

function _bindTipoPessoa() {
    document.querySelectorAll('input[name="tipo_pessoa"]').forEach((radio) => {
        const handler = () => {
            const cpfInput = document.getElementById('parceiro-cpf-cnpj');
            if (!cpfInput) return;
            cpfInput.value = '';
            if (radio.value === 'PJ') {
                cpfInput.placeholder = '00.000.000/0000-00';
                cpfInput.maxLength = 18;
            } else {
                cpfInput.placeholder = '000.000.000-00';
                cpfInput.maxLength = 18;
            }
        };
        radio.addEventListener('change', handler);
        cleanup.push(() => radio.removeEventListener('change', handler));
    });
}

function _bindBuscarCep() {
    const btn = document.getElementById('btn-buscar-cep');
    if (!btn) return;
    const handler = async () => {
        const cep = document.getElementById('parceiro-cep')?.value?.trim() || '';
        if (!cep) { Toast.alerta('Informe o CEP para buscar.'); return; }
        try {
            const dados = await buscarCep(cep);
            if (!dados) { Toast.erro('CEP não encontrado.'); return; }
            _setValor('#parceiro-logradouro', dados.logradouro);
            _setValor('#parceiro-bairro', dados.bairro);
            _setValor('#parceiro-cidade', dados.cidade);
            _setValor('#parceiro-uf', dados.uf);
            Toast.sucesso('Endereço preenchido com sucesso.');
        } catch (erro) {
            Toast.erro(erro.message || 'Erro ao consultar CEP.');
        }
    };
    btn.addEventListener('click', handler);
    cleanup.push(() => btn.removeEventListener('click', handler));
}

function _bindMascaras() {
    const cpfInput = document.getElementById('parceiro-cpf-cnpj');
    if (cpfInput) {
        const handler = (e) => aplicarMascaraCpfCnpj(e);
        cpfInput.addEventListener('input', handler);
        cleanup.push(() => cpfInput.removeEventListener('input', handler));
    }
    const cepInput = document.getElementById('parceiro-cep');
    if (cepInput) {
        const handler = (e) => aplicarMascaraCep(e);
        cepInput.addEventListener('input', handler);
        cleanup.push(() => cepInput.removeEventListener('input', handler));
    }
}

function aplicarMascaraCep(event) {
    const input = event.target;
    const valor = input.value.replace(/\D/g, '').slice(0, 8);
    input.value = valor.length > 5 ? `${valor.slice(0, 5)}-${valor.slice(5)}` : valor;
}

function aplicarMascaraCpfCnpj(event) {
    const input = event.target;
    const tipo = acharInputTipoPessoa()?.value ?? 'PF';
    const digitos = input.value.replace(/\D/g, '');

    if (tipo === 'PJ') {
        const v = digitos.slice(0, 14);
        if (v.length <= 2) { input.value = v; return; }
        if (v.length <= 5) { input.value = `${v.slice(0, 2)}.${v.slice(2)}`; return; }
        if (v.length <= 8) { input.value = `${v.slice(0, 2)}.${v.slice(2, 5)}.${v.slice(5)}`; return; }
        if (v.length <= 12) { input.value = `${v.slice(0, 2)}.${v.slice(2, 5)}.${v.slice(5, 8)}/${v.slice(8)}`; return; }
        input.value = `${v.slice(0, 2)}.${v.slice(2, 5)}.${v.slice(5, 8)}/${v.slice(8, 12)}-${v.slice(12, 14)}`;
    } else {
        const v = digitos.slice(0, 11);
        if (v.length <= 3) { input.value = v; return; }
        if (v.length <= 6) { input.value = `${v.slice(0, 3)}.${v.slice(3)}`; return; }
        if (v.length <= 9) { input.value = `${v.slice(0, 3)}.${v.slice(3, 6)}.${v.slice(6)}`; return; }
        input.value = `${v.slice(0, 3)}.${v.slice(3, 6)}.${v.slice(6, 9)}-${v.slice(9, 11)}`;
    }
}

async function buscarCep(cep) {
    const cepLimpo = (cep || '').replace(/\D/g, '');
    if (cepLimpo.length !== 8) throw new Error('CEP deve conter 8 dígitos.');
    const resposta = await fetch(`https://viacep.com.br/ws/${cepLimpo}/json/`);
    const dados = await resposta.json();
    if (dados.erro) return null;
    return {
        logradouro: dados.logradouro || '',
        bairro: dados.bairro || '',
        cidade: dados.localidade || '',
        uf: dados.uf || ''
    };
}

function _obterIdDaRota() {
    const query = window.location.hash.split('?')[1] ?? '';
    const id = parseInt(new URLSearchParams(query).get('id') ?? '', 10);
    return Number.isInteger(id) && id > 0 ? id : null;
}

function _obterVisualizarDaRota() {
    const query = window.location.hash.split('?')[1] ?? '';
    return new URLSearchParams(query).get('visualizar') === '1';
}

async function _prepararModoEdicao() {
    if (!modoEdicao && !modoVisualizar) return;

    const titulo = document.querySelectorAll('[data-titulo-modo]');
    const subtitulo = document.querySelectorAll('[data-subtitulo-modo]');

    if (modoVisualizar) {
        titulo.forEach(el => { el.textContent = 'Visualizar Parceiro'; });
        subtitulo.forEach(el => { el.textContent = 'Visualize os dados do parceiro, endereco, contatos e lancamentos.'; });
        _bloquearFormularioParceiro();
        if (idParceiro) await _carregarLancamentosFinanceiros();
        return;
    }

    titulo.forEach(el => { el.textContent = 'Editar Parceiro'; });
    subtitulo.forEach(el => { el.textContent = 'Atualize os dados do parceiro, endereco, contatos e lancamentos.'; });

    const btnSalvar = document.getElementById('btn-salvar');
    if (btnSalvar) {
        btnSalvar.innerHTML = '<span class="material-icons">save</span><span>Salvar Alteracoes</span>';
    }

    try {
        const parceiro = await ParceirosService.buscar(idParceiro);
        _preencherFormulario(parceiro);
        await _carregarLancamentosFinanceiros();
    } catch (err) {
        console.error('[NovoParceiro] Erro ao carregar parceiro:', err);
        Toast.erro(err.message || 'Nao foi possivel carregar o parceiro.');
    }
}

function _bloquearFormularioParceiro() {
    document.querySelectorAll('#form-parceiro input, #form-parceiro select, #form-parceiro textarea')
        .forEach(el => { el.disabled = true; });
    const btnSalvar = document.getElementById('btn-salvar');
    if (btnSalvar) btnSalvar.hidden = true;
    const btnCancelar = document.getElementById('btn-cancelar');
    if (btnCancelar) btnCancelar.textContent = 'Fechar';
    const acoes = document.querySelector('[data-acoes-visualizacao]');
    if (acoes) acoes.hidden = false;
}

function _bindAcoesVisualizacao() {
    const btnEditar = document.getElementById('btn-visualizar-editar');
    const btnExcluir = document.getElementById('btn-visualizar-excluir');

    if (btnEditar) {
        const handler = () => {
            if (!idParceiro) return;
            window.location.hash = `#/cadastro/novo-parceiro?id=${idParceiro}`;
        };
        btnEditar.addEventListener('click', handler);
        cleanup.push(() => btnEditar.removeEventListener('click', handler));
    }

    if (btnExcluir) {
        const handler = () => {
            if (!idParceiro) return;
            const nome = document.getElementById('parceiro-nome')?.value ?? '';
            Modal.confirmar({
                titulo: 'Excluir parceiro?',
                mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(nome)}</strong>? Esta acao nao pode ser desfeita.`,
                icone: 'delete_forever',
                variante: 'erro',
                textoConfirmar: 'Sim, excluir',
                textoCancelar: 'Cancelar',
                estiloConfirmar: 'perigo',
                aoConfirmar: async () => {
                    try {
                        await CadastrosService.excluir(idParceiro, 'parceiro');
                        Toast.sucesso('Parceiro excluido com sucesso.');
                        window.location.hash = '#/cadastro/listar';
                    } catch (erro) {
                        console.error('[NovoParceiro] Erro ao excluir:', erro);
                        Toast.erro(erro.message || 'Nao foi possivel excluir o parceiro.');
                    }
                },
            });
        };
        btnExcluir.addEventListener('click', handler);
        cleanup.push(() => btnExcluir.removeEventListener('click', handler));
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

    _renderizarTelefones();
    _carregarLancamentosFinanceiros();
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
        if (modoVisualizar) {
            window.location.hash = '#/cadastro/listar';
            return;
        }
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

function aplicarMascaraTelefone(event) {
    const input = event.target;
    const valor = input.value.replace(/\D/g, '').slice(0, 11);
    if (valor.length <= 2) {
        input.value = valor.length > 0 ? `(${valor}` : '';
        return;
    }
    if (valor.length <= 6) {
        input.value = `(${valor.slice(0, 2)}) ${valor.slice(2)}`;
        return;
    }
    if (valor.length <= 10) {
        input.value = `(${valor.slice(0, 2)}) ${valor.slice(2, 6)}-${valor.slice(6)}`;
        return;
    }
    input.value = `(${valor.slice(0, 2)}) ${valor.slice(2, 7)}-${valor.slice(7, 11)}`;
}

function formatarTelefone(ddd, numero) {
    if (!ddd || !numero) return '';
    const digitos = String(numero).replace(/\D/g, '');
    const numeroFormatado = digitos.length === 9
        ? `${digitos.slice(0, 5)}-${digitos.slice(5)}`
        : `${digitos.slice(0, 4)}-${digitos.slice(4)}`;
    return `(${String(ddd).replace(/\D/g, '')}) ${numeroFormatado}`;
}

function escaparHtml(texto) {
    const div = document.createElement('div');
    div.textContent = String(texto ?? '');
    return div.innerHTML;
}

export default { init, destroy };
