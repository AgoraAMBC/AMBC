/**
 * ============================================================
 * PÁGINA: NOVO PARCEIRO — AMBC V2
 * ============================================================
 * Controller da view de cadastro de parceiro.
 * Segue o mesmo padrão das outras páginas do projeto.
 * ============================================================
 */

import Toast  from '../componentes/toast.js';
import Modal  from '../componentes/modal.js';
import { ParceirosService } from '../services/parceiros-service.js';

/* ----------------------------------------------------------
   ESTADO INTERNO
---------------------------------------------------------- */
let telefones  = [];   // lista de telefones adicionados
let cleanup    = [];   // listeners para remover no destroy

/* ----------------------------------------------------------
   INIT — chamado pelo router após injetar a view
---------------------------------------------------------- */
function init() {
    console.log('[NovoParceiro] Página carregada ✅');

    telefones = [];

    _bindForm();
    _bindTelefones();
    _bindCancelamento();
}

/* ----------------------------------------------------------
   DESTROY — chamado pelo router antes de trocar de rota
---------------------------------------------------------- */
function destroy() {
    cleanup.forEach(fn => fn());
    cleanup = [];
    console.log('[NovoParceiro] Página destruída 👋');
}

/* ----------------------------------------------------------
   FORMULÁRIO PRINCIPAL
---------------------------------------------------------- */
function _bindForm() {
    const form = document.getElementById('form-parceiro');
    if (!form) return;

    const handler = async (e) => {
        e.preventDefault();

        const btnSalvar = form.querySelector('#btn-salvar');
        btnSalvar.disabled = true;
        btnSalvar.textContent = 'Salvando…';

        const dados = _coletarDados(form);

        try {
            await ParceirosService.cadastrar(dados);
            Toast.sucesso('Parceiro cadastrado com sucesso!');
            // Redireciona para listagem após cadastro
            setTimeout(() => { window.location.hash = '#/cadastro/listar'; }, 1200);
        } catch (err) {
            Toast.erro(err.message || 'Erro ao cadastrar parceiro.');
            btnSalvar.disabled = false;
            btnSalvar.textContent = 'Salvar';
        }
    };

    form.addEventListener('submit', handler);
    cleanup.push(() => form.removeEventListener('submit', handler));
}

/* ----------------------------------------------------------
   COLETA DADOS DO FORMULÁRIO
---------------------------------------------------------- */
function _coletarDados(form) {
    return {
        nome_razao_social : form.querySelector('#parceiro-nome')?.value.trim()       ?? '',
        cpf_cnpj          : form.querySelector('#parceiro-cpf-cnpj')?.value.trim()   ?? '',
        email             : form.querySelector('#parceiro-email')?.value.trim()       ?? '',
        tipo_pessoa       : form.querySelector('#parceiro-tipo-pessoa')?.value        ?? 'PF',
        tipo_servico      : form.querySelector('#parceiro-tipo-servico')?.value.trim()?? '',
        logradouro        : form.querySelector('#parceiro-logradouro')?.value.trim()  ?? '',
        numero            : form.querySelector('#parceiro-numero')?.value.trim()      ?? '',
        complemento       : form.querySelector('#parceiro-complemento')?.value.trim() ?? '',
        cep               : form.querySelector('#parceiro-cep')?.value.trim()         ?? '',
        bairro            : form.querySelector('#parceiro-bairro')?.value.trim()      ?? '',
        cidade            : form.querySelector('#parceiro-cidade')?.value.trim()      ?? '',
        uf                : form.querySelector('#parceiro-uf')?.value                 ?? '',
        telefones,
    };
}

/* ----------------------------------------------------------
   GERENCIAMENTO DE TELEFONES
---------------------------------------------------------- */
function _bindTelefones() {
    const btnAdd = document.getElementById('btn-add-telefone');
    if (!btnAdd) return;

    const handler = () => _adicionarTelefone();
    btnAdd.addEventListener('click', handler);
    cleanup.push(() => btnAdd.removeEventListener('click', handler));
}

function _adicionarTelefone() {
    const ddd    = document.getElementById('tel-ddd')?.value.trim()    ?? '';
    const numero = document.getElementById('tel-numero')?.value.trim() ?? '';
    const tipo   = document.getElementById('tel-tipo')?.value          ?? null;
    const obs    = document.getElementById('tel-obs')?.value.trim()    ?? '';

    if (!ddd || !numero) {
        Toast.alerta('Informe o DDD e o número do telefone.');
        return;
    }

    telefones.push({ ddd, numero, fk_tipo_telefone: tipo || null, observacao: obs || null });

    _renderizarTelefones();

    // Limpa os campos
    document.getElementById('tel-ddd').value    = '';
    document.getElementById('tel-numero').value = '';
    document.getElementById('tel-obs').value    = '';
}

function _removerTelefone(index) {
    telefones.splice(index, 1);
    _renderizarTelefones();
}

function _renderizarTelefones() {
    const lista = document.getElementById('lista-telefones');
    if (!lista) return;

    if (telefones.length === 0) {
        lista.innerHTML = '<p class="form-vazio">Nenhum telefone adicionado.</p>';
        return;
    }

    lista.innerHTML = telefones.map((tel, i) => `
        <div class="telefone-item">
            <span>(${tel.ddd}) ${tel.numero}</span>
            <button type="button" class="botao botao--perigo botao--pequeno" onclick="window._removerTelefone(${i})">
                <span class="material-icons">delete</span>
            </button>
        </div>
    `).join('');

    // Expõe globalmente para o onclick inline
    window._removerTelefone = _removerTelefone;
}

/* ----------------------------------------------------------
   CANCELAMENTO
---------------------------------------------------------- */
function _bindCancelamento() {
    const btn = document.getElementById('btn-cancelar');
    if (!btn) return;

    const handler = () => {
        Modal.confirmar({
            titulo         : 'Cancelar cadastro',
            mensagem       : 'Deseja cancelar? Os dados preenchidos serão perdidos.',
            variante       : 'alerta',
            textoConfirmar : 'Sim, cancelar',
            estiloConfirmar: 'perigo',
            aoConfirmar    : () => { window.location.hash = '#/cadastro/listar'; },
        });
    };

    btn.addEventListener('click', handler);
    cleanup.push(() => btn.removeEventListener('click', handler));
}

export default { init, destroy };
