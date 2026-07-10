import Toast from '../componentes/toast.js';
import Modal from '../componentes/modal.js';
import { api } from '../services/api.js';
import { AssociadosService } from '../services/associados-service.js?v=4';
import { AuxiliaresService } from '../services/associados-auxiliares-service.js?v=4';
import { ContasService } from '../services/contas-service.js';
import { NotificacoesService } from '../services/notificacoes-service.js';

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
  // Botões de ação
  btnAddTelefone: null,
  btnAddDependente: null,
  btnAddLancamento: null,
  // Modals
  modalTelefone: null,
  modalDependente: null,
  modalLancamento: null,
  // Tabelas
  tabelaTelefones: null,
  tabelaDependentes: null,
  tabelaLancamentos: null,
};

let estado = {
  modo: 'novo',
  idAssociado: null,
  tipoLancamento: 'receber',
  editandoTelefone: null,
  editandoDependente: null,
  editandoLancamento: null
};

// Arrays para armazenar dados em memória
let telefones = [];
let dependentes = [];
let lancamentos = [];

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
  preencherSelect(refs.fkGenero, dados.generos, 'id', 'descricao', 'Selecione...');
  preencherSelect(refs.fkEstadoCivil, dados.estadosCivis, 'id', 'descricao', 'Selecione...');
  preencherSelect(refs.fkProfissao, dados.profissoes, 'id', 'descricao', 'Selecione...');
  preencherSelect(refs.fkStatus, dados.statusPessoa, 'id', 'descricao', 'Selecione...');
  preencherSelect(refs.fkCategoria, dados.categorias, 'id', 'descricao', 'Selecione...');
  preencherSelect(refs.uf, dados.ufs, 'id', 'descricao', 'UF');
  // Popula selects do modal de dependente
  preencherSelect(document.getElementById('dependente-parentesco'), dados.parentescos, 'id', 'descricao', 'Selecione...');
  preencherSelect(document.getElementById('dependente-genero'), dados.generos, 'id', 'descricao', 'Selecione...');
}

async function gerarMatricula() {
  try {
    const resposta = await AssociadosService.proximaMatricula();
    const matricula = resposta?.matricula ?? resposta?.data?.matricula ?? '';
    if (refs.matricula && matricula) refs.matricula.value = matricula;
  } catch {
    if (refs.matricula && !refs.matricula.value) refs.matricula.value = `ASS-${new Date().getFullYear()}-0001`;
  }
}

async function verificarCpfEmTempoReal(cpf) {
  if (!cpf || cpf.replace(/\D/g, '').length < 11) return;
  try {
    const resposta = await AssociadosService.verificarCpf(cpf, estado.idAssociado);
    if (resposta?.erro) {
      Toast.alerta('CPF já cadastrado no sistema.');
      refs.cpf.classList.add('input--erro');
    } else {
      refs.cpf.classList.remove('input--erro');
    }
  } catch { /* ignora */ }
}

let debounceCpf = null;
function aoDigitarCpf(event) {
  aplicarMascaraCpf(event);
  clearTimeout(debounceCpf);
  debounceCpf = setTimeout(() => verificarCpfEmTempoReal(event.target.value), 800);
}

async function carregarAssociado(id) {
  try {
    const resposta = await AssociadosService.obter(id);
    // O backend retorna { data: {...}, telefones: [...], dependentes: [...] }
    const dados = resposta?.data ?? resposta;
    if (!dados) return;

    refs.matricula.value = dados.matricula || '';
    refs.nome.value = dados.nome || '';
    refs.cpf.value = dados.cpf_cnpj || '';
    refs.dataNascimento.value = dados.data_nascimento || '';
    refs.fkGenero.value = dados.fk_genero || '';
    refs.fkEstadoCivil.value = dados.fk_estadocivil || '';
    refs.fkProfissao.value = dados.fk_profissao || '';
    refs.fkCategoria.value = dados.fk_categoria || '';
    refs.fkStatus.value = dados.fk_status || '';
    refs.dataEntrada.value = dados.data_entrada || '';
    refs.email.value = dados.email || '';
    refs.observacao.value = dados.observacao || '';
    refs.cep.value = dados.cep || '';
    refs.logradouro.value = dados.logradouro || '';
    refs.numero.value = dados.numero || '';
    refs.complemento.value = dados.complemento || '';
    refs.bairro.value = dados.bairro || '';
    refs.cidade.value = dados.cidade || '';
    refs.uf.value = dados.uf || '';

    // Telefones e dependentes já vêm do backend no buscar.php
    if (resposta.telefones) {
      telefones = resposta.telefones.map(t => ({ ...t, temp: false }));
      renderizarTelefones();
    }
    if (resposta.dependentes) {
      dependentes = resposta.dependentes.map(d => ({ ...d, temp: false }));
      renderizarDependentes();
    }

    await carregarLancamentos();
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao carregar:', erro);
    Toast.erro('Não foi possível carregar os dados.');
  }
}

// ── TELEFONES ──────────────────────────────────────────────────

async function carregarTelefones() {
  if (!estado.idAssociado) return;
  try {
    const resp = await api.get(`/telefones/listar.php?id_associado=${estado.idAssociado}`);
    telefones = (resp?.telefones || []).map(t => ({ ...t, temp: false }));
    renderizarTelefones();
  } catch {
    telefones = [];
    renderizarTelefones();
  }
}

function formatarTelefone(ddd, numero) {
  if (!ddd || !numero) return '';
  const num = numero.length === 9 ? `${numero.slice(0,5)}-${numero.slice(5)}` : `${numero.slice(0,4)}-${numero.slice(4)}`;
  return `(${ddd}) ${num}`;
}

function renderizarTelefones() {
  if (!refs.tabelaTelefones) return;
  if (telefones.length === 0) {
    refs.tabelaTelefones.innerHTML = `<tr><td colspan="4" class="cadastro-associado__estado-vazio">Nenhum telefone adicionado.</td></tr>`;
    return;
  }
  refs.tabelaTelefones.innerHTML = telefones.map((t, i) => `
    <tr data-index="${i}">
      <td>${t.tipo || t.ddd + '-' + t.numero}</td>
      <td>${formatarTelefone(t.ddd, t.numero)}</td>
      <td>${t.observacao || '-'}</td>
      <td class="col-acoes">
        <button type="button" class="btn-acao btn-acao--editar" onclick="window.__editarTelefone(${i})" title="Editar">
          <span class="material-icons">edit</span>
        </button>
        <button type="button" class="btn-acao btn-acao--excluir" onclick="window.__excluirTelefone(${i})" title="Excluir">
          <span class="material-icons">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

function aoAbrirModalTelefone() {
  estado.editandoTelefone = null; 
  // Limpa edição anterior
  delete refs.telefoneTipo;
  delete refs.telefoneNumero;
  delete refs.telefoneObs;
  refs.modalTelefone.hidden = false;
  // Limpa campos
  const tipo = document.getElementById('telefone-tipo');
  const numero = document.getElementById('telefone-numero');
  const obs = document.getElementById('telefone-observacao');
  if (tipo) tipo.value = 'celular';
  if (numero) numero.value = '';
  if (obs) obs.value = '';
}

function aoFecharModalTelefone() {
  refs.modalTelefone.hidden = true;
}

async function aoSalvarTelefone() {
  const tipo = document.getElementById('telefone-tipo')?.value;
  const numero = document.getElementById('telefone-numero')?.value;
  const obs = document.getElementById('telefone-observacao')?.value;

  if (!numero || numero.replace(/\D/g, '').length < 8) {
    Toast.alerta('Informe um número de telefone válido.');
    return;
  }

  const numeros = numero.replace(/\D/g, '');
  const ddd = numeros.slice(0, 2);
  const num = numeros.slice(2);

  if (estado.editandoTelefone !== null) {
    const idx = estado.editandoTelefone;
    const t = telefones[idx];
    if (t?.id_telefone && !t.temp) {
      try {
        await api.put('/telefones/atualizar.php', {
          id_telefone: t.id_telefone,
          ddd,
          numero: num,
          tipo,
          observacao: obs
        });
        Toast.sucesso('Telefone atualizado com sucesso.');
      } catch (erro) {
        Toast.erro(erro?.mensagem || erro?.erro || 'Erro ao atualizar telefone.');
        return;
      }
    } else {
      telefones[idx] = { ...t, ddd, numero: num, tipo, observacao: obs };
      Toast.sucesso('Telefone atualizado.');
    }
    estado.editandoTelefone = null;
    renderizarTelefones();
    aoFecharModalTelefone();
    return;
  }

  if (estado.idAssociado) {
    try {
      await api.post('/telefones/cadastrar.php', {
        fk_associado: estado.idAssociado,
        ddd,
        numero: num,
        tipo,
        observacao: obs
      });
      Toast.sucesso('Telefone salvo com sucesso.');
      aoFecharModalTelefone();
      await carregarTelefones();
    } catch (erro) {
      Toast.erro(erro?.mensagem || erro?.erro || 'Erro ao salvar telefone.');
    }
  } else {
    telefones.push({
      ddd, numero: num, tipo, observacao: obs, temp: true
    });
    renderizarTelefones();
    Toast.sucesso('Telefone adicionado.');
    aoFecharModalTelefone();
  }
}
window.__editarTelefone = function(index) {
  const t = telefones[index];
  if (!t) return;
  estado.editandoTelefone = index;
  const tipo = document.getElementById('telefone-tipo');
  const numero = document.getElementById('telefone-numero');
  const obs = document.getElementById('telefone-observacao');
  if (tipo) tipo.value = t.tipo || 'celular';
  if (numero) numero.value = formatarTelefone(t.ddd, t.numero).replace(/\D/g, '');
  if (obs) obs.value = t.observacao || '';
  refs.modalTelefone.hidden = false;
};

window.__excluirTelefone = async function(index) {
  const t = telefones[index];
  if (!t) return;

  if (t.id_telefone && !t.temp) {
    try {
      await api.delete('/telefones/deletar.php', { id: t.id_telefone });
      Toast.sucesso('Telefone excluído.');
    } catch {
      Toast.erro('Erro ao excluir telefone.');
    }
  }
  telefones.splice(index, 1);
  renderizarTelefones();
};

// ── DEPENDENTES ───────────────────────────────────────────────

async function carregarDependentes() {
  if (!estado.idAssociado) return;
  try {
    const resp = await api.get(`/dependentes/listar.php?id_associado=${estado.idAssociado}`);
    dependentes = (resp?.dados || []).map(d => ({ ...d, temp: false }));
    renderizarDependentes();
  } catch {
    dependentes = [];
    renderizarDependentes();
  }
}

function renderizarDependentes() {
  if (!refs.tabelaDependentes) return;
  if (dependentes.length === 0) {
    refs.tabelaDependentes.innerHTML = `<tr><td colspan="4" class="cadastro-associado__estado-vazio">Nenhum dependente adicionado.</td></tr>`;
    return;
  }
  refs.tabelaDependentes.innerHTML = dependentes.map((d, i) => `
    <tr data-index="${i}">
      <td><strong>${d.nome}</strong></td>
      <td>${d.parentesco || '-'}</td>
      <td>${d.data_nascimento ? formatarDataBR(d.data_nascimento) : '-'}</td>
      <td class="col-acoes">
        <button type="button" class="btn-acao btn-acao--editar" onclick="window.__editarDependente(${i})" title="Editar">
          <span class="material-icons">edit</span>
        </button>
        <button type="button" class="btn-acao btn-acao--excluir" onclick="window.__excluirDependente(${i})" title="Excluir">
          <span class="material-icons">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

function formatarDataBR(data) {
  if (!data) return '';
  const [a, m, d] = data.split('-');
  return `${d}/${m}/${a}`;
}

function aoAbrirModalDependente() {
  estado.editandoDependente = null;
  refs.modalDependente.hidden = false;
  const nome = document.getElementById('dependente-nome');
  const nasc = document.getElementById('dependente-nascimento');
  const parentesco = document.getElementById('dependente-parentesco');
  const genero = document.getElementById('dependente-genero');
  const cpf = document.getElementById('dependente-cpf');
  const email = document.getElementById('dependente-email');
  const tel = document.getElementById('dependente-telefone');
  if (nome) nome.value = '';
  if (nasc) nasc.value = '';
  if (parentesco) parentesco.value = '';
  if (genero) genero.value = '';
  if (cpf) cpf.value = '';
  if (email) email.value = '';
  if (tel) tel.value = '';
}

function aoFecharModalDependente() {
  refs.modalDependente.hidden = true;
}

async function aoSalvarDependente() {
  const nome = document.getElementById('dependente-nome')?.value.trim();
  const nasc = document.getElementById('dependente-nascimento')?.value;
  const parentesco = document.getElementById('dependente-parentesco')?.value;
  const genero = document.getElementById('dependente-genero')?.value;
  const cpfInput = document.getElementById('dependente-cpf')?.value;
  const email = document.getElementById('dependente-email')?.value.trim();
  const tel = document.getElementById('dependente-telefone')?.value;

  if (!nome) {
    Toast.alerta('Informe o nome do dependente.');
    return;
  }

  if (estado.editandoDependente !== null) {
    const idx = estado.editandoDependente;
    const d = dependentes[idx];
    const dadosAtualizados = {
      nome,
      data_nascimento: nasc,
      fk_parentesco: parentesco,
      fk_genero: genero,
      cpf: cpfInput,
      observacao: `Email: ${email || ''} | Tel: ${tel || ''}` 
    };
    if (d?.id_dependente && !d.temp) {
      try {
        await api.put('/dependentes/atualizar.php', {
          id_dependente: d.id_dependente,
          ...dadosAtualizados
        });
        Toast.sucesso('Dependente atualizado com sucesso.');
      } catch (erro) {
        Toast.erro(erro?.mensagem || erro?.erro || 'Erro ao atualizar dependente.');
        return;
      }
    } else {
      dependentes[idx] = { ...d, ...dadosAtualizados };
      Toast.sucesso('Dependente atualizado.');
    }
    estado.editandoDependente = null;
    renderizarDependentes();
    aoFecharModalDependente();
    return;
  }

  if (estado.idAssociado) {
    try {
      await api.post('/dependentes/cadastrar.php', {
        fk_associado: estado.idAssociado,
        nome,
        data_nascimento: nasc || null,
        cpf: cpfInput || null,
        fk_parentesco: parentesco || null,
        fk_genero: genero || null,
        observacao: `Email: ${email} | Tel: ${tel}` 
      });
      Toast.sucesso('Dependente salvo com sucesso.');
      aoFecharModalDependente();
      await carregarDependentes();
    } catch (erro) {
      Toast.erro(erro?.mensagem || erro?.erro || 'Erro ao salvar dependente.');
    }
  } else {
    dependentes.push({
      nome, data_nascimento: nasc, parentesco, genero, cpf: cpfInput,
      email, telefone: tel, temp: true
    });
    renderizarDependentes();
    Toast.sucesso('Dependente adicionado.');
    aoFecharModalDependente();
  }
}
window.__editarDependente = function(index) {
  const d = dependentes[index];
  if (!d) return;
  estado.editandoDependente = index;
  const nome = document.getElementById('dependente-nome');
  const nasc = document.getElementById('dependente-nascimento');
  const parentesco = document.getElementById('dependente-parentesco');
  const genero = document.getElementById('dependente-genero');
  const cpf = document.getElementById('dependente-cpf');
  if (nome) nome.value = d.nome || '';
  if (nasc) nasc.value = d.data_nascimento || '';
  if (parentesco) {
    // Aceita tanto texto (filho, conjuge) quanto ID numérico
    parentesco.value = d.parentesco || d.fk_parentesco || '';
  }
  if (genero) genero.value = d.genero || d.fk_genero || '';
  if (cpf) cpf.value = d.cpf || '';
  refs.modalDependente.hidden = false;
};

window.__excluirDependente = async function(index) {
  const d = dependentes[index];
  if (!d) return;

  if (d.id_dependente && !d.temp) {
    try {
      await api.delete('/dependentes/deletar.php', { id: d.id_dependente });
      Toast.sucesso('Dependente excluído.');
    } catch {
      Toast.erro('Erro ao excluir dependente.');
    }
  }
  dependentes.splice(index, 1);
  renderizarDependentes();
};

// ── LANÇAMENTOS ──────────────────────────────────────────────

async function carregarLancamentos() {
  if (!estado.idAssociado) return;
  try {
    const resp = await api.get(`/financeiro/lancamentos/listar.php?id_associado=${estado.idAssociado}`);
    lancamentos = resp?.lancamentos || [];
    renderizarLancamentos();
  } catch {
    lancamentos = [];
    renderizarLancamentos();
  }
}

function renderizarLancamentos() {
  if (!refs.tabelaLancamentos) return;
  if (lancamentos.length === 0) {
    refs.tabelaLancamentos.innerHTML = `<tr><td colspan="6" class="cadastro-associado__estado-vazio">Nenhum lançamento encontrado.</td></tr>`;
    return;
  }
  refs.tabelaLancamentos.innerHTML = lancamentos.map((l, i) => {
    const statusClasse = l.fk_status_conta === 2 ? 'status--pago' : l.fk_status_conta === 3 ? 'status--cancelado' : 'status--pendente';
    return `
    <tr data-index="${i}">
      <td>${l.descricao || '-'}</td>
      <td>${l.conta_regente || '-'}</td>
      <td>${l.valor ? formatarBRL(l.valor) : '-'}</td>
      <td>${l.data_vencimento ? formatarDataBR(l.data_vencimento) : '-'}</td>
      <td><span class="status-badge ${statusClasse}">${l.status_conta || 'Aberto'}</span></td>
      <td class="col-acoes">
        <button type="button" class="btn-acao" title="Ver detalhes" onclick="window.__verLancamento(${i})">
          <span class="material-icons">visibility</span>
        </button>
      </td>
    </tr>
  `}).join('');
}

function formatarBRL(valor) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor);
}

async function aoAbrirModalLancamento() {
  if (!estado.idAssociado) {
    Toast.alerta('Salve o associado primeiro para registrar lançamentos.');
    return;
  }

  window.location.hash = `#/financeiro/registrar-lancamento?associado_id=${estado.idAssociado}`;
}

function aoFecharModalLancamento() {
  refs.modalLancamento.hidden = true;
}

async function aoSalvarLancamento() {
  if (!estado.idAssociado) {
    Toast.alerta('Salve o associado primeiro.');
    return;
  }

  const descricao = document.getElementById('lancamento-descricao')?.value.trim();
  const categoria = document.getElementById('lancamento-categoria')?.value;
  const contaSubordinada = document.getElementById('lancamento-conta-subordinada')?.value;
  const valor = document.getElementById('lancamento-valor')?.value;
  const vencimento = document.getElementById('lancamento-vencimento')?.value;
  const pagamento = document.getElementById('lancamento-pagamento')?.value;
  const forma = document.getElementById('lancamento-forma-pagamento')?.value;
  const status = document.getElementById('lancamento-status')?.value || 'aberto';

  if (!descricao || !valor) {
    Toast.alerta('Descrição e valor são obrigatórios.');
    return;
  }

  try {
    await api.post('/financeiro/lancamentos/criar.php', {
      fk_associado: estado.idAssociado,
      tipo: estado.tipoLancamento,
      descricao,
      fk_conta_regente: categoria || null,
      fk_conta_subordinada: contaSubordinada || null,
      valor,
      vencimento: vencimento || null,
      data_pagamento: pagamento || null,
      forma_pagamento: forma || null,
      status
    });
    Toast.sucesso('Lançamento criado com sucesso.');
    aoFecharModalLancamento();
    await carregarLancamentos();
  } catch (erro) {
    console.error('[Lançamento] Erro ao salvar:', erro);
    Toast.erro(erro?.mensagem || erro?.erro || 'Erro ao criar lançamento.');
  }
}

window.__verLancamento = function(index) {
  const l = lancamentos[index];
  if (!l) return;
  Toast.info(`Conta: ${l.descricao}\nValor: ${formatarBRL(l.valor_total)}\nStatus: ${l.status_conta}\n\nParcelas: ${l.parcelas?.length || 0}`);
};

function aoCancelar() {
  window.location.hash = '#/cadastro/listar';
}

function bloquearFormulario() {
  document.querySelectorAll('#form-associado input, #form-associado select, #form-associado textarea')
    .forEach(el => { el.disabled = true; });
  const btnSalvar = document.getElementById('btn-salvar');
  if (btnSalvar) btnSalvar.hidden = true;
  if (refs.btnCancelar) refs.btnCancelar.textContent = 'Fechar';
  if (refs.acoesVisualizacao) refs.acoesVisualizacao.hidden = false;
}

function aoVisualizarEditar() {
  if (!Number.isInteger(estado.idAssociado)) return;
  window.location.hash = `#/cadastro/novo-associado?id=${estado.idAssociado}`;
}

function aoVisualizarExcluir() {
  if (!Number.isInteger(estado.idAssociado)) return;
  const nome = document.getElementById('nome')?.value ?? '';
  Modal.confirmar({
    titulo: 'Excluir associado?',
    mensagem: `Tem certeza que deseja excluir <strong>${escaparHtml(nome)}</strong>? Esta ação não pode ser desfeita.`,
    icone: 'delete_forever',
    variante: 'erro',
    textoConfirmar: 'Sim, excluir',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'perigo',
    aoConfirmar: async () => {
      try {
        await AssociadosService.deletar(estado.idAssociado);
        Toast.sucesso('Associado excluído com sucesso.');
        window.location.hash = '#/cadastro/listar';
      } catch (erro) {
        console.error('[NovoAssociado] Erro ao excluir:', erro);
        Toast.erro(erro.message || 'Não foi possível excluir o associado.');
      }
    },
  });
}

function _validarFormulario() {
  const camposObrigatorios = [
    { el: refs.nome,        label: 'Nome Completo' },
    { el: refs.cpf,         label: 'CPF' },
    { el: refs.fkCategoria, label: 'Categoria' },
    { el: refs.fkStatus,    label: 'Status' },
  ];

  camposObrigatorios.forEach(({ el }) => el?.classList.remove('input--erro'));

  const faltando = camposObrigatorios.filter(({ el }) => !el?.value?.trim());
  if (faltando.length) {
    faltando.forEach(({ el }) => el?.classList.add('input--erro'));
    Toast.alerta('Campos obrigatórios não preenchidos: ' + faltando.map(f => f.label).join(', ') + '.');
    faltando[0].el?.focus();
    return false;
  }
  return true;
}

async function aoEnviarFormulario(event) {
  event.preventDefault();
  if (estado.modo === 'visualizar') { aoCancelar(); return; }

  if (!_validarFormulario()) return;

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
      const resposta = await AssociadosService.criar(dados);
      // Captura o ID do associado criado para salvar telefones e dependentes
      if (resposta?.data?.id_associado) {
        estado.idAssociado = resposta.data.id_associado;
        // Salvar telefones e dependentes em memória
        await salvarTelefonesEDependentesTemporarios();
      }
      Toast.sucesso('Associado cadastrado com sucesso.');
      NotificacoesService.notificarNovoCadastro({
        nome: dados.nome,
        matricula: resposta?.data?.matricula ?? '',
      }).catch(() => {});
    }
    window.location.hash = '#/cadastro/listar';
  } catch (erro) {
    console.error('[NovoAssociado] Erro ao salvar:', erro);
    const msg = erro?.erro || erro?.mensagem || '';
    if (msg.includes('já cadastrado') || msg.includes('409')) {
      Toast.alerta('CPF/CNPJ já cadastrado no sistema.');
    } else {
      Toast.erro('Erro ao salvar. Verifique os dados e tente novamente.');
    }
  }
}

async function salvarTelefonesEDependentesTemporarios() {
  if (!estado.idAssociado) return;
  // Salvar telefones temporários
  for (const t of telefones.filter(t => t.temp)) {
    try {
      await api.post('/telefones/cadastrar.php', {
        fk_associado: estado.idAssociado,
        ddd: t.ddd,
        numero: t.numero,
        fk_tipo_telefone: t.tipo,
        observacao: t.observacao
      });
    } catch { /* ignora */ }
  }
  // Salvar dependentes temporários
  for (const d of dependentes.filter(d => d.temp)) {
    try {
      await api.post('/dependentes/cadastrar.php', {
        fk_associado: estado.idAssociado,
        nome: d.nome,
        data_nascimento: d.data_nascimento || null,
        cpf: d.cpf || null,
        fk_parentesco: d.parentesco || null,
        fk_genero: d.genero || null,
        observacao: `Email: ${d.email || ''} | Tel: ${d.telefone || ''}`
      });
    } catch { /* ignora */ }
  }
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
  // Ações do visualizar
  refs.acoesVisualizacao = document.querySelector('[data-acoes-visualizacao]');
  refs.btnVisualizarEditar = document.getElementById('btn-visualizar-editar');
  refs.btnVisualizarExcluir = document.getElementById('btn-visualizar-excluir');
  // Botões
  refs.btnAddTelefone = document.getElementById('btn-add-telefone');
  refs.btnAddDependente = document.getElementById('btn-add-dependente');
  refs.btnAddLancamento = document.getElementById('btn-add-lancamento');
  // Modals
  refs.modalTelefone = document.getElementById('modal-telefone');
  refs.modalDependente = document.getElementById('modal-dependente');
  refs.modalLancamento = document.getElementById('modal-lancamento');
  // Tabelas
  refs.tabelaTelefones = document.getElementById('tabela-telefones');
  refs.tabelaDependentes = document.getElementById('tabela-dependentes');
  refs.tabelaLancamentos = document.getElementById('tabela-lancamentos');
}

function registrarEventos() {
  refs.form?.addEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.addEventListener('click', aoCancelar);
  refs.btnBuscarCep?.addEventListener('click', aoBuscarCep);
  refs.cpf?.addEventListener('input', aoDigitarCpf);
  refs.cep?.addEventListener('input', aplicarMascaraCep);

  // Limpa borda de erro ao preencher campo obrigatório
  [refs.nome, refs.cpf, refs.fkCategoria, refs.fkStatus].forEach(el => {
    el?.addEventListener('input',  () => el.classList.remove('input--erro'));
    el?.addEventListener('change', () => el.classList.remove('input--erro'));
  });

  // Telefone
  refs.btnAddTelefone?.addEventListener('click', aoAbrirModalTelefone);
  document.getElementById('modal-telefone-fechar')?.addEventListener('click', aoFecharModalTelefone);
  document.getElementById('modal-telefone-fundo')?.addEventListener('click', aoFecharModalTelefone);
  document.getElementById('modal-telefone-cancelar')?.addEventListener('click', aoFecharModalTelefone);
  document.getElementById('btn-salvar-telefone-modal')?.addEventListener('click', aoSalvarTelefone);
  document.getElementById('telefone-numero')?.addEventListener('input', aplicarMascaraTelefone);

  // Dependente
  refs.btnAddDependente?.addEventListener('click', aoAbrirModalDependente);
  document.getElementById('modal-dependente-fechar')?.addEventListener('click', aoFecharModalDependente);
  document.getElementById('modal-dependente-fundo')?.addEventListener('click', aoFecharModalDependente);
  document.getElementById('modal-dependente-cancelar')?.addEventListener('click', aoFecharModalDependente);
  document.getElementById('btn-salvar-dependente-modal')?.addEventListener('click', aoSalvarDependente);

  // Lançamento
  refs.btnAddLancamento?.addEventListener('click', aoAbrirModalLancamento);
  document.getElementById('modal-lancamento-fechar')?.addEventListener('click', aoFecharModalLancamento);
  document.getElementById('modal-lancamento-fundo')?.addEventListener('click', aoFecharModalLancamento);
  document.getElementById('modal-lancamento-cancelar')?.addEventListener('click', aoFecharModalLancamento);
  document.getElementById('btn-salvar-lancamento-modal')?.addEventListener('click', aoSalvarLancamento);

  // Tipo de lançamento
  document.querySelectorAll('[data-tipo-lancamento]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('[data-tipo-lancamento]').forEach(b => b.classList.remove('modal__tipo-btn--ativo'));
      e.currentTarget.classList.add('modal__tipo-btn--ativo');
      estado.tipoLancamento = e.currentTarget.dataset.tipoLancamento;
    });
  });

  // Ações do visualizar
  refs.btnVisualizarEditar?.addEventListener('click', aoVisualizarEditar);
  refs.btnVisualizarExcluir?.addEventListener('click', aoVisualizarExcluir);
}

function removerEventos() {
  refs.form?.removeEventListener('submit', aoEnviarFormulario);
  refs.btnCancelar?.removeEventListener('click', aoCancelar);
  refs.btnBuscarCep?.removeEventListener('click', aoBuscarCep);
  refs.cpf?.removeEventListener('input', aoDigitarCpf);
  refs.cep?.removeEventListener('input', aplicarMascaraCep);
  refs.btnVisualizarEditar?.removeEventListener('click', aoVisualizarEditar);
  refs.btnVisualizarExcluir?.removeEventListener('click', aoVisualizarExcluir);
}

async function init() {
  console.log('[NovoAssociado] Inicializando página...');

  mapearRefs();
  registrarEventos();

  const params = parsearHashParams();
  const id = params.get('id');
  const visualizar = params.get('visualizar') === '1';

  if (id) {
    estado.modo = visualizar ? 'visualizar' : 'editar';
    estado.idAssociado = Number(id);
  }

  try {
    await carregarSelects();

    if (estado.modo === 'visualizar' && Number.isInteger(estado.idAssociado)) {
      refs.tituloModo?.forEach(el => { el.textContent = 'Visualizar Associado'; });
      await carregarAssociado(estado.idAssociado).catch(erro => {
        console.error('[NovoAssociado] Erro ao carregar:', erro);
        Toast.erro('Não foi possível carregar os dados.');
      });
      bloquearFormulario();
    } else if (estado.modo === 'editar' && Number.isInteger(estado.idAssociado)) {
      refs.tituloModo?.forEach(el => { el.textContent = 'Editar Associado'; });
      await carregarAssociado(estado.idAssociado).catch(erro => {
        console.error('[NovoAssociado] Erro ao carregar:', erro);
        Toast.erro('Não foi possível carregar os dados.');
      });
    } else {
      refs.tituloModo?.forEach(el => { el.textContent = 'Novo Associado'; });
      await gerarMatricula().catch(() => {});
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

function escaparHtml(texto) {
  const div = document.createElement('div');
  div.textContent = String(texto ?? '');
  return div.innerHTML;
}

function destroy() {
  removerEventos();
  if (refs.acoesVisualizacao) refs.acoesVisualizacao.hidden = true;
  Object.keys(refs).forEach(key => { refs[key] = null; });
  estado = { modo: 'novo', idAssociado: null, tipoLancamento: 'receber', editandoTelefone: null, editandoDependente: null, editandoLancamento: null };
  telefones = [];
  dependentes = [];
  lancamentos = [];
}

export default { init, destroy };