import Toast from '../componentes/toast.js';
import { AssociadosService } from '../services/associados-service.js?v=4';
import { AuxiliaresService } from '../services/associados-auxiliares-service.js?v=5';
console.log('[AMBC] cadastro-novo-associado.js carregado');

const refs = {
  form: null,
  tituloModo: null,
  matricula: null,
  fkStatus: null,
  nome: null,
  cpf: null,
  dataNascimento: null,
  fkGenero: null,
  fkEstadoCivil: null,
  fkProfissao: null,
  fkCategoria: null,
  dataEntrada: null,
  email: null,
  observacao: null,
  cep: null,
  btnBuscarCep: null,
  logradouro: null,
  numero: null,
  complemento: null,
  bairro: null,
  cidade: null,
  uf: null,
  btnCancelar: null,

  btnAddTelefone: null,
  btnAddDependente: null,
  btnAddLancamento: null,

  modalTelefone: null,
  modalDependente: null,
  modalLancamento: null,

  btnSalvarTelefoneModal: null,
  btnSalvarDependenteModal: null,
  btnSalvarLancamentoModal: null,

  botoesTipoLancamento: []
};

let estado = {
  modo: 'novo',
  idAssociado: null,
  tipoLancamento: 'receber'
};

// ── Utilitários ────────────────────────────────────────────

function parsearHashParams() {
  const hash = window.location.hash || '';
  const [, query] = hash.split('?');
  return new URLSearchParams(query || '');
}

function formatarDataHoje() {
  const hoje = new Date();
  const ano = hoje.getFullYear();
  const mes = String(hoje.getMonth() + 1).padStart(2, '0');
  const dia = String(hoje.getDate()).padStart(2, '0');
  return `${ano}-${mes}-${dia}`;
}

function preencherSelect(select, itens = [], valueKey = 'id', labelKey = 'descricao', placeholder = 'Selecione...') {
  if (!select) return;
  const opcoes = itens.map(item => {
    const value = item[valueKey] ?? '';
    const label = item[labelKey] ?? '';
    return `<option value="${value}">${label}</option>`;
  }).join('');
  select.innerHTML = `<option value="">${placeholder}</option>${opcoes}`;
}

function aplicarMascaraCpf(event) {
  const input = event.target;
  const valor = input.value.replace(/\D/g, '').slice(0, 11);
  if (valor.length <= 3) { input.value = valor; return; }
  if (valor.length <= 6) { input.value = `${valor.slice(0, 3)}.${valor.slice(3)}`; return; }
  if (valor.length <= 9) { input.value = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6)}`; return; }
  input.value = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6, 9)}-${valor.slice(9, 11)}`;
}

function aplicarMascaraCep(event) {
  const input = event.target;
  const valor = input.value.replace(/\D/g, '').slice(0, 8);
  input.value = valor.length > 5 ? `${valor.slice(0, 5)}-${valor.slice(5)}` : valor;
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

async function aoBuscarCep() {
  const cep = refs.cep?.value?.trim() || '';
  if (!cep) { Toast.alerta('Informe o CEP para buscar.'); return; }
  try {
    const dados = await buscarCep(cep);
    if (!dados) { Toast.erro('CEP não encontrado.'); return; }
    if (refs.logradouro) refs.logradouro.value = dados.logradouro;
    if (refs.bairro) refs.bairro.value = dados.bairro;
    if (refs.cidade) refs.cidade.value = dados.cidade;
    if (refs.uf) refs.uf.value = dados.uf;
    Toast.sucesso('Endereço preenchido com sucesso.');
  } catch (erro) {
    Toast.erro(erro.message || 'Erro ao consultar CEP.');
  }
}

function coletarDadosFormulario() {
  return {
    // ── Dados pessoais ──────────────────────────────────────
    nome:            refs.nome?.value.trim()            || null,
    cpf_cnpj:        refs.cpf?.value.replace(/\D/g, '') || null, // ✅ apenas números
    data_nascimento: refs.dataNascimento?.value         || null,
    email:           refs.email?.value.trim()           || null,
    observacao:      refs.observacao?.value.trim()       || null,
    ativo:           refs.fkStatus?.value
                       ? Number(refs.fkStatus.value) === 1
                       : true,
    data_entrada:    refs.dataEntrada?.value            || null,

    // ── FKs com nomes que o backend espera ─────────────────
    genero:         parseInt(refs.fkGenero?.value,      10) || null,
    id_estadocivil: parseInt(refs.fkEstadoCivil?.value, 10) || null,
    id_profissao:   parseInt(refs.fkProfissao?.value,   10) || null,
    id_status:      parseInt(refs.fkStatus?.value,      10) || null,

    // ── Endereço aninhado ───────────────────────────────────
    endereco: {
      logradouro:  refs.logradouro?.value.trim()               || null,
      numero:      refs.numero?.value.trim()                    || null,
      complemento: refs.complemento?.value.trim()               || null,
      bairro:      refs.bairro?.value.trim()                    || null,
      cidade:      refs.cidade?.value.trim()                    || null,
      uf:          refs.uf?.value.trim()                        || null,
      cep:         refs.cep?.value.replace(/\D/g, '')           || null, // ✅ apenas números
    }
  };
}


// ── Selects ────────────────────────────────────────────────

function _preencherSelectsMock() {
  console.warn('[NovoAssociado] Backend offline — usando dados mock.');

  preencherSelect(refs.fkGenero, [
    { id_genero: 1, descricao: 'Masculino' },
    { id_genero: 2, descricao: 'Feminino' },
    { id_genero: 3, descricao: 'Outro' }
  ], 'id_genero', 'descricao', 'Selecione...');

  preencherSelect(refs.fkEstadoCivil, [
    { id_estadocivil: 1, descricao: 'Solteiro(a)' },
    { id_estadocivil: 2, descricao: 'Casado(a)' },
    { id_estadocivil: 3, descricao: 'Divorciado(a)' },
    { id_estadocivil: 4, descricao: 'Viúvo(a)' },
    { id_estadocivil: 5, descricao: 'União Estável' }
  ], 'id_estadocivil', 'descricao', 'Selecione...');

  preencherSelect(refs.fkProfissao, [
    { id_profissao: 1, descricao: 'Autônomo' },
    { id_profissao: 2, descricao: 'Comerciante' },
    { id_profissao: 3, descricao: 'Funcionário Público' },
    { id_profissao: 4, descricao: 'Aposentado' },
    { id_profissao: 5, descricao: 'Outros' }
  ], 'id_profissao', 'descricao', 'Selecione...');

  preencherSelect(refs.fkStatus, [
    { id_status: 1, descricao: 'Ativo' },
    { id_status: 2, descricao: 'Inativo' },
    { id_status: 3, descricao: 'Suspenso' }
  ], 'id_status', 'descricao', 'Selecione...');

  preencherSelect(refs.fkCategoria, [
    { id_categoria: 1, descricao: 'Titular' },
    { id_categoria: 2, descricao: 'Dependente' },
    { id_categoria: 3, descricao: 'Honorário' }
  ], 'id_categoria', 'descricao', 'Selecione...');

  preencherSelect(refs.uf, [
    { sigla: 'AC' }, { sigla: 'AL' }, { sigla: 'AP' }, { sigla: 'AM' },
    { sigla: 'BA' }, { sigla: 'CE' }, { sigla: 'DF' }, { sigla: 'ES' },
    { sigla: 'GO' }, { sigla: 'MA' }, { sigla: 'MT' }, { sigla: 'MS' },
    { sigla: 'MG' }, { sigla: 'PA' }, { sigla: 'PB' }, { sigla: 'PR' },
    { sigla: 'PE' }, { sigla: 'PI' }, { sigla: 'RJ' }, { sigla: 'RN' },
    { sigla: 'RS' }, { sigla: 'RO' }, { sigla: 'RR' }, { sigla: 'SC' },
    { sigla: 'SP' }, { sigla: 'SE' }, { sigla: 'TO' }
  ], 'sigla', 'sigla', 'UF');
}

async function carregarSelects() {
  try {
    const dados = await AuxiliaresService.carregarTodas();

    // Backend retorna { id, descricao } — usamos 'id' como value
    preencherSelect(refs.fkGenero,      dados.generos,      'id', 'descricao', 'Selecione...');
    preencherSelect(refs.fkEstadoCivil, dados.estadosCivis, 'id', 'descricao', 'Selecione...');
    preencherSelect(refs.fkProfissao,   dados.profissoes,   'id', 'descricao', 'Selecione...');
    preencherSelect(refs.fkStatus,      dados.statusPessoa, 'id', 'descricao', 'Selecione...');
    preencherSelect(refs.uf,            dados.ufs,          'id', 'descricao', 'UF');

  } catch (erro) {
    console.warn('[NovoAssociado] Falha ao carregar selects da API:', erro.message);
    _preencherSelectsMock();
  }
}

async function gerarMatricula() {
  try {
    const resposta = await AssociadosService.proximaMatricula();
    const matricula = resposta?.matricula ?? resposta?.data?.matricula ?? '';
    if (refs.matricula && matricula) refs.matricula.value = matricula;
  } catch {
    if (refs.matricula && !refs.matricula.value) refs.matricula.value = '';
  }
}

async function carregarAssociado(id) {
  try {
    const resposta = await AssociadosService.obter(id);
    const associado = resposta?.data ?? resposta;
    if (!associado) return;
    if (refs.matricula)     refs.matricula.value     = associado.matricula      || '';
    if (refs.nome)          refs.nome.value          = associado.nome           || '';
    if (refs.cpf)           refs.cpf.value           = associado.cpf_cnpj       || '';
    if (refs.dataNascimento) refs.dataNascimento.value = associado.data_nascimento || '';
    if (refs.fkGenero)      refs.fkGenero.value      = associado.fk_genero      || '';
    if (refs.fkEstadoCivil) refs.fkEstadoCivil.value = associado.fk_estadocivil || '';
    if (refs.fkProfissao)   refs.fkProfissao.value   = associado.fk_profissao   || '';
    if (refs.fkCategoria)   refs.fkCategoria.value   = associado.fk_categoria   || '';
    if (refs.fkStatus)      refs.fkStatus.value      = associado.fk_status      || '';
    if (refs.dataEntrada)   refs.dataEntrada.value   = associado.data_entrada   || '';
    if (refs.email)         refs.email.value         = associado.email          || '';
    if (refs.observacao)    refs.observacao.value    = associado.observacao     || '';
    if (refs.cep)           refs.cep.value           = associado.cep            || '';
    if (refs.logradouro)    refs.logradouro.value    = associado.logradouro     || '';
    if (refs.numero)        refs.numero.value        = associado.numero         || '';
    if (refs.complemento)   refs.complemento.value   = associado.complemento    || '';
    if (refs.bairro)        refs.bairro.value        = associado.bairro         || '';
    if (refs.cidade)        refs.cidade.value        = associado.cidade         || '';
    if (refs.uf)            refs.uf.value            = associado.uf             || '';
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao carregar associado:', erro);
    Toast.erro('Não foi possível carregar os dados do associado.');
  }
}

async function aoEnviarFormulario(event) {
  event.preventDefault();
  const dados = coletarDadosFormulario();

  // ── Validações obrigatórias ─────────────────────────────
  if (!dados.nome) {
    Toast.erro('Nome é obrigatório.');
    refs.nome?.focus();
    return;
  }

  if (!dados.cpf_cnpj) {
    Toast.erro('CPF/CNPJ é obrigatório.');
    refs.cpf?.focus();
    return;
  }

  if (!dados.data_nascimento) {
    Toast.erro('Data de nascimento é obrigatória.');
    refs.dataNascimento?.focus();
    return;
  }

  if (!dados.id_status) {
    Toast.erro('Status é obrigatório.');
    refs.fkStatus?.focus();
    return;
  }
  // ───────────────────────────────────────────────────────

  console.log('[NovoAssociado] Payload para salvar:', dados);

  try {
    if (estado.modo === 'editar' && Number.isInteger(estado.idAssociado)) {
      await AssociadosService.atualizar({ ...dados, id_associado: estado.idAssociado });
      Toast.sucesso('Associado atualizado com sucesso.');
    } else {
      await AssociadosService.criar(dados);
      Toast.sucesso('Associado cadastrado com sucesso.');
    }
    window.location.hash = '#/cadastro/listar';
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao salvar:', erro);
    Toast.erro('Não foi possível salvar o associado.');
  }
}

function aoCancelar() {
  window.location.hash = '#/cadastro/listar';
}


// ── Modais ─────────────────────────────────────────────────

function abrirModal(modal) {
  if (!modal || modal.open) return;
  modal.showModal();
}

function fecharModal(modal) {
  if (!modal || !modal.open) return;
  modal.close();
}

function fecharTodosModais() {
  [refs.modalTelefone, refs.modalDependente, refs.modalLancamento].forEach(modal => {
    if (modal?.open) modal.close();
  });
}

// Fecha ao clicar no backdrop (fora do conteúdo do dialog)
function aoClicarBackdropModal(e) {
  if (e.target === e.currentTarget) e.currentTarget.close();
}

function aoAbrirModalTelefone()   { abrirModal(refs.modalTelefone);   }
function aoAbrirModalDependente() { abrirModal(refs.modalDependente); }
function aoAbrirModalLancamento() { abrirModal(refs.modalLancamento); }

function selecionarTipoLancamento(botaoSelecionado) {
  refs.botoesTipoLancamento.forEach(botao => {
    botao.classList.remove('modal__tipo-btn--ativo');
  });
  botaoSelecionado.classList.add('modal__tipo-btn--ativo');
  estado.tipoLancamento = botaoSelecionado.dataset.tipoLancamento || 'receber';
}

function aoSalvarTelefoneModal() {
  if (!estado.idAssociado && estado.modo !== 'editar') {
    Toast.alerta('Salve primeiro o associado para depois adicionar telefones.');
    return;
  }
  Toast.alerta('Integração de telefone será ligada ao backend na próxima etapa.');
}

function aoSalvarDependenteModal() {
  if (!estado.idAssociado && estado.modo !== 'editar') {
    Toast.alerta('Salve primeiro o associado para depois adicionar dependentes.');
    return;
  }
  Toast.alerta('Integração de dependente será ligada ao backend na próxima etapa.');
}

function aoSalvarLancamentoModal() {
  if (!estado.idAssociado && estado.modo !== 'editar') {
    Toast.alerta('Salve primeiro o associado para depois adicionar lançamentos.');
    return;
  }
  Toast.alerta(`Integração de lançamento (${estado.tipoLancamento}) será ligada ao backend na próxima etapa.`);
}

// ── Mapeamento e eventos ───────────────────────────────────

function mapearRefs() {
  refs.form             = document.getElementById('form-associado');
  refs.tituloModo       = document.querySelectorAll('[data-titulo-modo]');
  refs.matricula        = document.getElementById('matricula');
  refs.fkStatus         = document.getElementById('fk_status');
  refs.nome             = document.getElementById('nome');
  refs.cpf              = document.getElementById('cpf_cnpj');
  refs.dataNascimento   = document.getElementById('data_nascimento');
  refs.fkGenero         = document.getElementById('fk_genero');
  refs.fkEstadoCivil    = document.getElementById('fk_estadocivil');
  refs.fkProfissao      = document.getElementById('fk_profissao');
  refs.fkCategoria      = document.getElementById('fk_categoria');
  refs.dataEntrada      = document.getElementById('data_entrada');
  refs.email            = document.getElementById('email');
  refs.observacao       = document.getElementById('observacao');
  refs.cep              = document.getElementById('cep');
  refs.btnBuscarCep     = document.getElementById('btn-buscar-cep');
  refs.logradouro       = document.getElementById('logradouro');
  refs.numero           = document.getElementById('numero');
  refs.complemento      = document.getElementById('complemento');
  refs.bairro           = document.getElementById('bairro');
  refs.cidade           = document.getElementById('cidade');
  refs.uf               = document.getElementById('uf');
  refs.btnCancelar      = document.getElementById('btn-cancelar');

  refs.btnAddTelefone   = document.getElementById('btn-add-telefone');
  refs.btnAddDependente = document.getElementById('btn-add-dependente');
  refs.btnAddLancamento = document.getElementById('btn-add-lancamento');

  refs.modalTelefone    = document.getElementById('modal-telefone');
  refs.modalDependente  = document.getElementById('modal-dependente');
  refs.modalLancamento  = document.getElementById('modal-lancamento');

  refs.btnSalvarTelefoneModal   = document.getElementById('btn-salvar-telefone-modal');
  refs.btnSalvarDependenteModal = document.getElementById('btn-salvar-dependente-modal');
  refs.btnSalvarLancamentoModal = document.getElementById('btn-salvar-lancamento-modal');

  refs.botoesTipoLancamento = Array.from(
    document.querySelectorAll('[data-tipo-lancamento]')
  );

  // ── Diagnóstico (remover após confirmar funcionamento) ──
  console.log('[NovoAssociado] Refs mapeados:');
  console.log('  modal-telefone:',  refs.modalTelefone);
  console.log('  modal-dependente:', refs.modalDependente);
  console.log('  modal-lancamento:', refs.modalLancamento);
}

function registrarEventos() {
  refs.form?.addEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.addEventListener('click', aoCancelar);
  refs.btnBuscarCep?.addEventListener('click', aoBuscarCep);
  refs.cpf?.addEventListener('input', aplicarMascaraCpf);
  refs.cep?.addEventListener('input', aplicarMascaraCep);

  refs.btnAddTelefone?.addEventListener('click', aoAbrirModalTelefone);
  refs.btnAddDependente?.addEventListener('click', aoAbrirModalDependente);
  refs.btnAddLancamento?.addEventListener('click', aoAbrirModalLancamento);

  refs.btnSalvarTelefoneModal?.addEventListener('click', aoSalvarTelefoneModal);
  refs.btnSalvarDependenteModal?.addEventListener('click', aoSalvarDependenteModal);
  refs.btnSalvarLancamentoModal?.addEventListener('click', aoSalvarLancamentoModal);

  [refs.modalTelefone, refs.modalDependente, refs.modalLancamento].forEach(modal => {
    modal?.addEventListener('click', aoClicarBackdropModal);
  });

  refs.botoesTipoLancamento.forEach(botao => {
    botao.addEventListener('click', () => selecionarTipoLancamento(botao));
  });

  document.addEventListener('keydown', aoPressionarTeclaEscape);
}

function removerEventos() {
  refs.form?.removeEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.removeEventListener('click', aoCancelar);
  refs.btnBuscarCep?.removeEventListener('click', aoBuscarCep);
  refs.cpf?.removeEventListener('input', aplicarMascaraCpf);
  refs.cep?.removeEventListener('input', aplicarMascaraCep);

  refs.btnAddTelefone?.removeEventListener('click', aoAbrirModalTelefone);
  refs.btnAddDependente?.removeEventListener('click', aoAbrirModalDependente);
  refs.btnAddLancamento?.removeEventListener('click', aoAbrirModalLancamento);

  refs.btnSalvarTelefoneModal?.removeEventListener('click', aoSalvarTelefoneModal);
  refs.btnSalvarDependenteModal?.removeEventListener('click', aoSalvarDependenteModal);
  refs.btnSalvarLancamentoModal?.removeEventListener('click', aoSalvarLancamentoModal);

  [refs.modalTelefone, refs.modalDependente, refs.modalLancamento].forEach(modal => {
    modal?.removeEventListener('click', aoClicarBackdropModal);
  });

  document.removeEventListener('keydown', aoPressionarTeclaEscape);
}

function aoPressionarTeclaEscape(event) {
  if (event.key === 'Escape') fecharTodosModais();
}

// ── Init / Destroy ─────────────────────────────────────────

async function init() {
  console.log('[NovoAssociado] Inicializando página...');

  mapearRefs();

  // ✅ Garante que nenhum modal está aberto ao iniciar
  [refs.modalTelefone, refs.modalDependente, refs.modalLancamento].forEach(modal => {
    if (modal && modal.open) modal.close();
  });
  registrarEventos();

  const params = parsearHashParams();
  const id = params.get('id');

  if (id) {
    estado.modo = 'editar';
    estado.idAssociado = Number(id);
  }

  // ✅ carregarSelects tem try/catch interno — nunca vai travar
  await carregarSelects();

  if (estado.modo === 'editar' && Number.isInteger(estado.idAssociado)) {
    refs.tituloModo?.forEach(el => { el.textContent = 'Editar Associado'; });
    await carregarAssociado(estado.idAssociado).catch(erro => {
      console.error('[NovoAssociado] Erro ao carregar associado:', erro);
      Toast.erro('Não foi possível carregar os dados do associado.');
    });
  } else {
    refs.tituloModo?.forEach(el => { el.textContent = 'Novo Associado'; });
    await gerarMatricula().catch(() => {});
    if (refs.dataEntrada && !refs.dataEntrada.value) {
      refs.dataEntrada.value = formatarDataHoje();
    }
  }

  console.log('[NovoAssociado] Página pronta');
}


function destroy() {
  removerEventos();
  fecharTodosModais();

  Object.keys(refs).forEach(key => {
    refs[key] = Array.isArray(refs[key]) ? [] : null;
  });

  estado = {
    modo: 'novo',
    idAssociado: null,
    tipoLancamento: 'receber'
  };
}

export default { init, destroy };
