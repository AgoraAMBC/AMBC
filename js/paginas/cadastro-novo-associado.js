import Toast from '../componentes/toast.js';
import { AssociadosService } from '../services/associados-service.js?v=4';
import { AuxiliaresService } from '../services/associados-auxiliares-service.js?v=4';

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
  btnCancelar: null
};

let estado = {
  modo: 'novo',
  idAssociado: null
};

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

  if (valor.length <= 3) {
    input.value = valor;
    return;
  }

  if (valor.length <= 6) {
    input.value = `${valor.slice(0, 3)}.${valor.slice(3)}`;
    return;
  }

  if (valor.length <= 9) {
    input.value = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6)}`;
    return;
  }

  input.value = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6, 9)}-${valor.slice(9, 11)}`;
}

function aplicarMascaraCep(event) {
  const input = event.target;
  const valor = input.value.replace(/\D/g, '').slice(0, 8);
  input.value = valor.length > 5 ? `${valor.slice(0, 5)}-${valor.slice(5)}` : valor;
}

async function buscarCep(cep) {
  const cepLimpo = (cep || '').replace(/\D/g, '');

  if (cepLimpo.length !== 8) {
    throw new Error('CEP deve conter 8 dígitos.');
  }

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

  if (!cep) {
    Toast.alerta('Informe o CEP para buscar.');
    return;
  }

  try {
    const dados = await buscarCep(cep);

    if (!dados) {
      Toast.erro('CEP não encontrado.');
      return;
    }

    refs.logradouro.value = dados.logradouro;
    refs.bairro.value = dados.bairro;
    refs.cidade.value = dados.cidade;
    refs.uf.value = dados.uf;

    Toast.sucesso('Endereço preenchido com sucesso.');
  } catch (erro) {
    Toast.erro(erro.message || 'Erro ao consultar CEP.');
  }
}

function coletarDadosFormulario() {
  return {
    matricula: refs.matricula?.value.trim() || null,
    nome: refs.nome?.value.trim() || null,
    cpf_cnpj: refs.cpf?.value.trim() || null,
    data_nascimento: refs.dataNascimento?.value || null,
    email: refs.email?.value.trim() || null,
    observacao: refs.observacao?.value.trim() || null,
    ativo: refs.fkStatus?.value ? Number(refs.fkStatus.value) === 1 : true,
    logradouro: refs.logradouro?.value.trim() || null,
    numero: refs.numero?.value.trim() || null,
    complemento: refs.complemento?.value.trim() || null,
    cep: refs.cep?.value.trim() || null,
    bairro: refs.bairro?.value.trim() || null,
    cidade: refs.cidade?.value.trim() || null,
    uf: refs.uf?.value || null,
    fk_genero: parseInt(refs.fkGenero?.value, 10) || null,
    fk_estadocivil: parseInt(refs.fkEstadoCivil?.value, 10) || null,
    fk_profissao: parseInt(refs.fkProfissao?.value, 10) || null,
    fk_categoria: parseInt(refs.fkCategoria?.value, 10) || null,
    fk_status: parseInt(refs.fkStatus?.value, 10) || null,
    data_entrada: refs.dataEntrada?.value || null
  };
}

async function carregarSelects() {
  const dados = await AuxiliaresService.carregarTodas();

  preencherSelect(refs.fkGenero, dados.generos, 'id_genero', 'descricao', 'Selecione...');
  preencherSelect(refs.fkEstadoCivil, dados.estadosCivis, 'id_estadocivil', 'descricao', 'Selecione...');
  preencherSelect(refs.fkProfissao, dados.profissoes, 'id_profissao', 'descricao', 'Selecione...');
  preencherSelect(refs.fkStatus, dados.statusPessoa, 'id_status', 'descricao', 'Selecione...');
  preencherSelect(refs.fkCategoria, dados.categorias, 'id_categoria', 'descricao', 'Selecione...');
  preencherSelect(refs.uf, dados.ufs, 'sigla', 'sigla', 'UF');
}

async function gerarMatricula() {
  try {
    const resposta = await AssociadosService.proximaMatricula();
    const matricula = resposta?.matricula ?? resposta?.data?.matricula ?? '';

    if (refs.matricula && matricula) {
      refs.matricula.value = matricula;
    }
  } catch {
    if (refs.matricula && !refs.matricula.value) {
      refs.matricula.value = `ASS-${new Date().getFullYear()}-0001`;
    }
  }
}

async function carregarAssociado(id) {
  try {
    const resposta = await AssociadosService.obter(id);
    const associado = resposta?.data ?? resposta;

    if (!associado) return;

    refs.matricula.value = associado.matricula || '';
    refs.nome.value = associado.nome || '';
    refs.cpf.value = associado.cpf_cnpj || '';
    refs.dataNascimento.value = associado.data_nascimento || '';
    refs.fkGenero.value = associado.fk_genero || '';
    refs.fkEstadoCivil.value = associado.fk_estadocivil || '';
    refs.fkProfissao.value = associado.fk_profissao || '';
    refs.fkCategoria.value = associado.fk_categoria || '';
    refs.fkStatus.value = associado.fk_status || '';
    refs.dataEntrada.value = associado.data_entrada || '';
    refs.email.value = associado.email || '';
    refs.observacao.value = associado.observacao || '';
    refs.cep.value = associado.cep || '';
    refs.logradouro.value = associado.logradouro || '';
    refs.numero.value = associado.numero || '';
    refs.complemento.value = associado.complemento || '';
    refs.bairro.value = associado.bairro || '';
    refs.cidade.value = associado.cidade || '';
    refs.uf.value = associado.uf || '';
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao carregar associado:', erro);
    Toast.erro('Não foi possível carregar os dados do associado.');
  }
}

async function aoEnviarFormulario(event) {
  event.preventDefault();

  const dados = coletarDadosFormulario();
  console.log('[NovoAssociado] Payload para salvar:', dados);

  try {
    if (estado.modo === 'editar' && Number.isInteger(estado.idAssociado)) {
      await AssociadosService.atualizar({
        ...dados,
        id_associado: estado.idAssociado
      });

      Toast.sucesso('Associado atualizado com sucesso.');
    } else {
      await AssociadosService.criar(dados);
      Toast.sucesso('Associado cadastrado com sucesso.');
    }

    window.location.hash = '#/cadastro/listar';
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao salvar:', erro);
    Toast.erro('Salvar disparou, mas o endpoint PHP ainda não foi encontrado.');
  }
}

function aoCancelar() {
  window.location.hash = '#/cadastro/listar';
}

function mapearRefs() {
  refs.form = document.getElementById('form-associado');
  refs.tituloModo = document.querySelectorAll('[data-titulo-modo]');
  refs.matricula = document.getElementById('matricula');
  refs.fkStatus = document.getElementById('fk_status');
  refs.nome = document.getElementById('nome');
  refs.cpf = document.getElementById('cpf_cnpj');
  refs.dataNascimento = document.getElementById('data_nascimento');
  refs.fkGenero = document.getElementById('fk_genero');
  refs.fkEstadoCivil = document.getElementById('fk_estadocivil');
  refs.fkProfissao = document.getElementById('fk_profissao');
  refs.fkCategoria = document.getElementById('fk_categoria');
  refs.dataEntrada = document.getElementById('data_entrada');
  refs.email = document.getElementById('email');
  refs.observacao = document.getElementById('observacao');
  refs.cep = document.getElementById('cep');
  refs.btnBuscarCep = document.getElementById('btn-buscar-cep');
  refs.logradouro = document.getElementById('logradouro');
  refs.numero = document.getElementById('numero');
  refs.complemento = document.getElementById('complemento');
  refs.bairro = document.getElementById('bairro');
  refs.cidade = document.getElementById('cidade');
  refs.uf = document.getElementById('uf');
  refs.btnCancelar = document.getElementById('btn-cancelar');
}

function registrarEventos() {
  refs.form?.addEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.addEventListener('click', aoCancelar);
  refs.btnBuscarCep?.addEventListener('click', aoBuscarCep);
  refs.cpf?.addEventListener('input', aplicarMascaraCpf);
  refs.cep?.addEventListener('input', aplicarMascaraCep);
}

function removerEventos() {
  refs.form?.removeEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.removeEventListener('click', aoCancelar);
  refs.btnBuscarCep?.removeEventListener('click', aoBuscarCep);
  refs.cpf?.removeEventListener('input', aplicarMascaraCpf);
  refs.cep?.removeEventListener('input', aplicarMascaraCep);
}

async function init() {
  console.log('[NovoAssociado] Inicializando página...');

  mapearRefs();
  registrarEventos();

  const params = parsearHashParams();
  const id = params.get('id');

  if (id) {
    estado.modo = 'editar';
    estado.idAssociado = Number(id);
  }

  try {
    await carregarSelects();

    if (estado.modo === 'editar' && Number.isInteger(estado.idAssociado)) {
      refs.tituloModo?.forEach(el => el.textContent = 'Editar Associado');
      await carregarAssociado(estado.idAssociado);
    } else {
      refs.tituloModo?.forEach(el => el.textContent = 'Novo Associado');
      await gerarMatricula();

      if (refs.dataEntrada && !refs.dataEntrada.value) {
        refs.dataEntrada.value = formatarDataHoje();
      }
    }
  } catch (erro) {
    console.error('[NovoAssociado] Erro na inicialização:', erro);
    Toast.erro('Falha ao carregar a tela.');
  }

  console.log('[NovoAssociado] Página pronta');
}

function destroy() {
  removerEventos();
  Object.keys(refs).forEach(key => {
    refs[key] = null;
  });

  estado = {
    modo: 'novo',
    idAssociado: null
  };
}

export default {
  init,
  destroy
};
