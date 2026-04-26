<<<<<<< HEAD
import { API_BASE } from '../core/config.js';

const TEMPLATE = 'views/configuracoes/usuarios.html';

let estadoAtual = { pagina: 1, busca: '', perfil: '', status: '' };
let modulos     = [];
let perfis      = [];

// ── Cores para avatares ───────────────────────────────────────────────────────
const CORES_AVATAR = [
=======
/* =========================================================
   Pagina: Gestão de Usuários
   Projeto: AMBC-V2
   Descricao: CRUD completo de usuários do sistema.
              O router já injeta o HTML da view antes de
              chamar init(), então apenas carregamos dados
              e registramos eventos aqui.
========================================================= */

import { API_BASE } from '../core/config.js';

/* ---------------------------------------------------------
   Estado local da página
--------------------------------------------------------- */
let estado   = { pagina: 1, busca: '', perfil: '', status: '' };
let modulos  = [];
let perfis   = [];
let debounce = null;

/* ---------------------------------------------------------
   Cores para avatares (hash do nome)
--------------------------------------------------------- */
const CORES = [
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  '#1E5BA8','#0F766E','#7C3AED','#B45309','#BE185D',
  '#1D4ED8','#047857','#9333EA','#C2410C','#0369A1',
];

function corAvatar(nome) {
<<<<<<< HEAD
  let hash = 0;
  for (let i = 0; i < nome.length; i++) hash = nome.charCodeAt(i) + ((hash << 5) - hash);
  return CORES_AVATAR[Math.abs(hash) % CORES_AVATAR.length];
}

function inicialAvatar(nome) {
  const partes = nome.trim().split(' ');
  return partes.length >= 2
    ? (partes[0][0] + partes[partes.length - 1][0]).toUpperCase()
    : nome.slice(0, 2).toUpperCase();
}

// ── Entrada da página ─────────────────────────────────────────────────────────
export async function iniciarPagina(container) {
  const html = await fetch(TEMPLATE).then(r => r.text());
  container.innerHTML = html;

  [modulos, perfis] = await Promise.all([
    api('GET', 'modulos/listar.php'),
    api('GET', 'perfis/listar.php'),
  ]);

  preencherSelectPerfis(document.getElementById('filtro-perfil'), false);
  preencherSelectPerfis(document.getElementById('campo-perfil'), true);

  await carregarTabela();
  registrarEventos();
}

// ── API ───────────────────────────────────────────────────────────────────────
async function api(metodo, endpoint, corpo = null) {
  const opcoes = { method: metodo, headers: { 'Content-Type': 'application/json' } };
  if (corpo) opcoes.body = JSON.stringify(corpo);
  const resp = await fetch(`${API_BASE}/${endpoint}`, opcoes);
=======
  let h = 0;
  for (let i = 0; i < nome.length; i++) h = nome.charCodeAt(i) + ((h << 5) - h);
  return CORES[Math.abs(h) % CORES.length];
}

function iniciais(nome) {
  const p = nome.trim().split(' ');
  return p.length >= 2
    ? (p[0][0] + p[p.length - 1][0]).toUpperCase()
    : nome.slice(0, 2).toUpperCase();
}

/* ---------------------------------------------------------
   API
--------------------------------------------------------- */
async function api(metodo, endpoint, corpo = null) {
  const opts = { method: metodo, headers: { 'Content-Type': 'application/json' } };
  if (corpo) opts.body = JSON.stringify(corpo);
  const resp = await fetch(`${API_BASE}/${endpoint}`, opts);
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  const json = await resp.json();
  if (!resp.ok) throw new Error(json.erro ?? 'Erro desconhecido');
  return json;
}

<<<<<<< HEAD
// ── Tabela ────────────────────────────────────────────────────────────────────
async function carregarTabela() {
  const corpo = document.getElementById('corpo-tabela');
  corpo.innerHTML = '<tr><td colspan="6" class="gu-tabela__estado">Carregando…</td></tr>';

  const { busca, perfil, status, pagina } = estadoAtual;
=======
/* ---------------------------------------------------------
   Tabela
--------------------------------------------------------- */
async function carregarTabela() {
  const corpo = document.getElementById('corpo-tabela');
  if (!corpo) return;
  corpo.innerHTML = '<tr><td colspan="6" class="gu-tabela__estado">Carregando…</td></tr>';

  const { busca, perfil, status, pagina } = estado;
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  const params = new URLSearchParams({ pagina, busca, perfil, status });

  try {
    const dados = await api('GET', `usuarios/listar.php?${params}`);
    renderTabela(dados.dados);
    renderPaginacao(dados.pagina, dados.paginas);
  } catch (e) {
    corpo.innerHTML = `<tr><td colspan="6" class="gu-tabela__estado">${esc(e.message)}</td></tr>`;
  }
}

function renderTabela(usuarios) {
  const corpo = document.getElementById('corpo-tabela');
<<<<<<< HEAD

=======
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  if (!usuarios.length) {
    corpo.innerHTML = '<tr><td colspan="6" class="gu-tabela__estado">Nenhum usuário encontrado.</td></tr>';
    return;
  }

  corpo.innerHTML = usuarios.map(u => {
<<<<<<< HEAD
    const cor     = corAvatar(u.nome);
    const iniciais = inicialAvatar(u.nome);
    const btnStatus = u.ativo
=======
    const cor = corAvatar(u.nome);
    const ini = iniciais(u.nome);
    const btnToggle = u.ativo
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
      ? `<button class="gu-btn gu-btn--icone gu-btn--icone-perigo" title="Desativar"
           data-acao="alternar" data-id="${u.id_usuario}" data-ativo="true" data-nome="${esc(u.nome)}">
           <span class="material-icons">person_off</span>
         </button>`
      : `<button class="gu-btn gu-btn--icone gu-btn--icone-sucesso" title="Ativar"
           data-acao="alternar" data-id="${u.id_usuario}" data-ativo="false" data-nome="${esc(u.nome)}">
           <span class="material-icons">person</span>
         </button>`;

    return `
      <tr>
        <td>
          <div class="gu-usuario-cell">
<<<<<<< HEAD
            <div class="gu-avatar" style="background:${cor}">${iniciais}</div>
=======
            <div class="gu-avatar" style="background:${cor}">${ini}</div>
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
            <div>
              <div class="gu-usuario-nome">${esc(u.nome)}</div>
              <div class="gu-usuario-email">${esc(u.email)}</div>
            </div>
          </div>
        </td>
        <td><span class="gu-badge gu-badge--perfil">${esc(u.perfil)}</span></td>
        <td>
          <span class="gu-badge gu-badge--${u.ativo ? 'ativo' : 'inativo'}">
            <span class="gu-badge__dot"></span>
            ${u.ativo ? 'Ativo' : 'Inativo'}
          </span>
        </td>
<<<<<<< HEAD
        <td><span class="gu-badge gu-badge--${u.primeiro_acesso ? 'sim' : 'nao'}">${u.primeiro_acesso ? 'Pendente' : 'Realizado'}</span></td>
        <td style="color:var(--cor-cinza-500)">${u.ultimo_acesso ? formatarData(u.ultimo_acesso) : '—'}</td>
=======
        <td>
          <span class="gu-badge gu-badge--${u.primeiro_acesso ? 'sim' : 'nao'}">
            ${u.primeiro_acesso ? 'Pendente' : 'Realizado'}
          </span>
        </td>
        <td style="color:var(--cor-cinza-500);font-size:var(--fs-sm)">
          ${u.ultimo_acesso ? formatarData(u.ultimo_acesso) : '—'}
        </td>
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
        <td>
          <div class="gu-tabela__acoes">
            <button class="gu-btn gu-btn--icone" title="Editar"
              data-acao="editar" data-id="${u.id_usuario}">
              <span class="material-icons">edit</span>
            </button>
<<<<<<< HEAD
            ${btnStatus}
=======
            ${btnToggle}
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
          </div>
        </td>
      </tr>`;
  }).join('');
}

function renderPaginacao(paginaAtual, totalPaginas) {
  const el = document.getElementById('paginacao');
<<<<<<< HEAD
=======
  if (!el) return;
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  if (totalPaginas <= 1) { el.innerHTML = ''; return; }

  el.innerHTML = Array.from({ length: totalPaginas }, (_, i) => i + 1)
    .map(i => `<button class="gu-paginacao__btn${i === paginaAtual ? ' is-ativo' : ''}" data-pagina="${i}">${i}</button>`)
    .join('');

<<<<<<< HEAD
  el.querySelectorAll('[data-pagina]').forEach(btn => {
    btn.addEventListener('click', () => {
      estadoAtual.pagina = parseInt(btn.dataset.pagina);
      carregarTabela();
    });
  });
}

// ── Modal Cadastro/Edição ─────────────────────────────────────────────────────
function abrirModal(usuario = null) {
  const modal = document.getElementById('modal-usuario');
=======
  el.querySelectorAll('[data-pagina]').forEach(btn =>
    btn.addEventListener('click', () => {
      estado.pagina = parseInt(btn.dataset.pagina);
      carregarTabela();
    })
  );
}

/* ---------------------------------------------------------
   Modal
--------------------------------------------------------- */
function abrirModal(usuario = null) {
  const modal = document.getElementById('modal-usuario');
  if (!modal) return;
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  document.getElementById('modal-titulo').textContent = usuario ? 'Editar Usuário' : 'Novo Usuário';
  document.getElementById('campo-id').value    = usuario?.id_usuario ?? '';
  document.getElementById('campo-nome').value  = usuario?.nome ?? '';
  document.getElementById('campo-email').value = usuario?.email ?? '';
  document.getElementById('campo-email').readOnly = !!usuario;
  document.getElementById('campo-perfil').value = '';
  document.getElementById('campo-senha').value  = '';
  renderPermissoes();
  modal.hidden = false;
}

function fecharModal() {
<<<<<<< HEAD
  document.getElementById('modal-usuario').hidden = true;
  document.getElementById('form-usuario').reset();
=======
  const modal = document.getElementById('modal-usuario');
  if (modal) modal.hidden = true;
  document.getElementById('form-usuario')?.reset();
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
}

function renderPermissoes() {
  const lista = document.getElementById('lista-permissoes');
<<<<<<< HEAD
=======
  if (!lista) return;
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  lista.innerHTML = modulos.map(m => `
    <div class="gu-permissoes__item">
      <span class="gu-permissoes__modulo">${esc(m.descricao)}</span>
      <label class="gu-permissoes__opcao">
<<<<<<< HEAD
        <input type="checkbox" data-modulo="${m.id_modulo}" data-tipo="acessar" />
        Acessar
      </label>
      <label class="gu-permissoes__opcao">
        <input type="checkbox" data-modulo="${m.id_modulo}" data-tipo="editar" />
        Editar
=======
        <input type="checkbox" data-modulo="${m.id_modulo}" data-tipo="acessar" /> Acessar
      </label>
      <label class="gu-permissoes__opcao">
        <input type="checkbox" data-modulo="${m.id_modulo}" data-tipo="editar" /> Editar
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
      </label>
    </div>
  `).join('');
}

function coletarPermissoes() {
  const mapa = {};
  document.querySelectorAll('#lista-permissoes input[type=checkbox]').forEach(cb => {
    const id = cb.dataset.modulo;
    if (!mapa[id]) mapa[id] = { fk_modulo: parseInt(id), pode_acessar: false, pode_editar: false };
    if (cb.dataset.tipo === 'acessar') mapa[id].pode_acessar = cb.checked;
    if (cb.dataset.tipo === 'editar')  mapa[id].pode_editar  = cb.checked;
  });
  return Object.values(mapa);
}

<<<<<<< HEAD
// ── Modal Confirmação ─────────────────────────────────────────────────────────
=======
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
function confirmar(mensagem, titulo = 'Confirmar ação') {
  return new Promise(resolve => {
    document.getElementById('confirmacao-titulo').textContent   = titulo;
    document.getElementById('confirmacao-mensagem').textContent = mensagem;
    document.getElementById('modal-confirmacao').hidden         = false;

<<<<<<< HEAD
    const fechar = resultado => {
      document.getElementById('modal-confirmacao').hidden = true;
      ['btn-confirmacao-ok', 'btn-confirmacao-cancelar', 'confirmacao-fundo'].forEach(id => {
        const el = document.getElementById(id);
        el.replaceWith(el.cloneNode(true));
      });
      resolve(resultado);
    };

    document.getElementById('btn-confirmacao-ok').addEventListener('click', () => fechar(true));
    document.getElementById('btn-confirmacao-cancelar').addEventListener('click', () => fechar(false));
    document.getElementById('confirmacao-fundo').addEventListener('click', () => fechar(false));
  });
}

// ── Toast ─────────────────────────────────────────────────────────────────────
function toast(mensagem, tipo = 'sucesso') {
  const icone = tipo === 'sucesso' ? 'check_circle' : tipo === 'erro' ? 'error' : 'info';
=======
    const fechar = ok => {
      document.getElementById('modal-confirmacao').hidden = true;
      ['btn-confirmacao-ok', 'btn-confirmacao-cancelar', 'confirmacao-fundo'].forEach(id => {
        const el = document.getElementById(id);
        el?.replaceWith(el.cloneNode(true));
      });
      resolve(ok);
    };

    document.getElementById('btn-confirmacao-ok')?.addEventListener('click', () => fechar(true));
    document.getElementById('btn-confirmacao-cancelar')?.addEventListener('click', () => fechar(false));
    document.getElementById('confirmacao-fundo')?.addEventListener('click', () => fechar(false));
  });
}

function toast(mensagem, tipo = 'sucesso') {
  const icone = { sucesso: 'check_circle', erro: 'error', info: 'info' }[tipo] ?? 'info';
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
  const el = document.createElement('div');
  el.className = `gu-toast gu-toast--${tipo}`;
  el.innerHTML = `<span class="material-icons">${icone}</span>${esc(mensagem)}`;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

<<<<<<< HEAD
// ── Eventos ───────────────────────────────────────────────────────────────────
function registrarEventos() {
  document.getElementById('btn-novo-usuario')
    .addEventListener('click', () => abrirModal());

  document.getElementById('modal-fechar')
    .addEventListener('click', fecharModal);
  document.getElementById('modal-fundo')
    .addEventListener('click', fecharModal);
  document.getElementById('btn-cancelar')
    .addEventListener('click', fecharModal);

  document.getElementById('form-usuario')
    .addEventListener('submit', async e => {
      e.preventDefault();
      const id = document.getElementById('campo-id').value;
      const corpo = {
        nome:       document.getElementById('campo-nome').value.trim(),
        email:      document.getElementById('campo-email').value.trim(),
        fk_perfil:  parseInt(document.getElementById('campo-perfil').value),
        senha:      document.getElementById('campo-senha').value,
        permissoes: coletarPermissoes(),
      };
      try {
        if (id) {
          await api('PUT', 'usuarios/editar.php', { ...corpo, id_usuario: parseInt(id) });
          toast('Usuário atualizado com sucesso!');
        } else {
          await api('POST', 'usuarios/cadastrar.php', corpo);
          toast('Usuário cadastrado com sucesso!');
        }
        fecharModal();
        estadoAtual.pagina = 1;
        carregarTabela();
      } catch (err) {
        toast(err.message, 'erro');
      }
    });

  let debounce;
  document.getElementById('filtro-busca').addEventListener('input', e => {
    clearTimeout(debounce);
    debounce = setTimeout(() => {
      estadoAtual.busca  = e.target.value.trim();
      estadoAtual.pagina = 1;
=======
/* ---------------------------------------------------------
   Preenchimento de selects
--------------------------------------------------------- */
function preencherSelect(select, incluirVazio) {
  if (!select) return;
  const base = incluirVazio
    ? '<option value="">Selecione…</option>'
    : '<option value="">Todos os perfis</option>';
  select.innerHTML = base + perfis.map(p =>
    `<option value="${p.id_perfil}">${esc(p.descricao)}</option>`
  ).join('');
}

/* ---------------------------------------------------------
   Registro de eventos
--------------------------------------------------------- */
function registrarEventos() {
  document.getElementById('btn-novo-usuario')?.addEventListener('click', () => abrirModal());
  document.getElementById('modal-fechar')?.addEventListener('click', fecharModal);
  document.getElementById('modal-fundo')?.addEventListener('click', fecharModal);
  document.getElementById('btn-cancelar')?.addEventListener('click', fecharModal);

  document.getElementById('form-usuario')?.addEventListener('submit', async e => {
    e.preventDefault();
    const id = document.getElementById('campo-id').value;
    const corpo = {
      nome:       document.getElementById('campo-nome').value.trim(),
      email:      document.getElementById('campo-email').value.trim(),
      fk_perfil:  parseInt(document.getElementById('campo-perfil').value),
      senha:      document.getElementById('campo-senha').value,
      permissoes: coletarPermissoes(),
    };
    try {
      if (id) {
        await api('PUT', 'usuarios/editar.php', { ...corpo, id_usuario: parseInt(id) });
        toast('Usuário atualizado com sucesso!');
      } else {
        await api('POST', 'usuarios/cadastrar.php', corpo);
        toast('Usuário cadastrado com sucesso!');
      }
      fecharModal();
      estado.pagina = 1;
      carregarTabela();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });

  document.getElementById('filtro-busca')?.addEventListener('input', e => {
    clearTimeout(debounce);
    debounce = setTimeout(() => {
      estado.busca  = e.target.value.trim();
      estado.pagina = 1;
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
      carregarTabela();
    }, 400);
  });

<<<<<<< HEAD
  document.getElementById('filtro-perfil').addEventListener('change', e => {
    estadoAtual.perfil = e.target.value;
    estadoAtual.pagina = 1;
    carregarTabela();
  });

  document.getElementById('filtro-status').addEventListener('change', e => {
    estadoAtual.status = e.target.value;
    estadoAtual.pagina = 1;
    carregarTabela();
  });

  document.getElementById('corpo-tabela').addEventListener('click', async e => {
=======
  document.getElementById('filtro-perfil')?.addEventListener('change', e => {
    estado.perfil = e.target.value;
    estado.pagina = 1;
    carregarTabela();
  });

  document.getElementById('filtro-status')?.addEventListener('change', e => {
    estado.status = e.target.value;
    estado.pagina = 1;
    carregarTabela();
  });

  document.getElementById('corpo-tabela')?.addEventListener('click', async e => {
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
    const btn = e.target.closest('[data-acao]');
    if (!btn) return;

    if (btn.dataset.acao === 'editar') {
      abrirModal({ id_usuario: parseInt(btn.dataset.id) });
    }

    if (btn.dataset.acao === 'alternar') {
      const ativo = btn.dataset.ativo === 'true';
<<<<<<< HEAD
      const nome  = btn.dataset.nome;
      const ok = await confirmar(
        `Deseja ${ativo ? 'desativar' : 'ativar'} o usuário "${nome}"?`,
=======
      const ok = await confirmar(
        `Deseja ${ativo ? 'desativar' : 'ativar'} o usuário "${btn.dataset.nome}"?`,
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
        ativo ? 'Desativar Usuário' : 'Ativar Usuário'
      );
      if (!ok) return;
      try {
        const resp = await api('PATCH', 'usuarios/alternar-status.php', { id_usuario: parseInt(btn.dataset.id) });
        toast(resp.mensagem);
        carregarTabela();
      } catch (err) {
        toast(err.message, 'erro');
      }
    }
  });
}

<<<<<<< HEAD
// ── Utilitários ───────────────────────────────────────────────────────────────
function preencherSelectPerfis(select, incluirVazio) {
  if (!select) return;
  const base = incluirVazio
    ? '<option value="">Selecione…</option>'
    : '<option value="">Todos os perfis</option>';
  select.innerHTML = base + perfis.map(p =>
    `<option value="${p.id_perfil}">${esc(p.descricao)}</option>`
  ).join('');
}

=======
/* ---------------------------------------------------------
   Módulo exportado (padrão do Router do AMBC)
--------------------------------------------------------- */
const UsuariosPage = {
  async init() {
    estado = { pagina: 1, busca: '', perfil: '', status: '' };

    [modulos, perfis] = await Promise.all([
      api('GET', 'modulos/listar.php'),
      api('GET', 'perfis/listar.php'),
    ]);

    preencherSelect(document.getElementById('filtro-perfil'), false);
    preencherSelect(document.getElementById('campo-perfil'), true);

    await carregarTabela();
    registrarEventos();
  },

  destroy() {
    clearTimeout(debounce);
    modulos = [];
    perfis  = [];
  }
};

export default UsuariosPage;

/* ---------------------------------------------------------
   Utilitários
--------------------------------------------------------- */
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
function formatarData(iso) {
  return new Date(iso).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
}

function esc(str) {
  return String(str ?? '')
<<<<<<< HEAD
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
=======
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
>>>>>>> 0c0a56fe44e720cdd4a6d4ec6e3c06e1d897978d
}
