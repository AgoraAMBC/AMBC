/* =========================================================
   sessao.js
   Projeto: AMBC-V2
   Descricao: Modulo central de autenticacao/sessao.
              Cuida de obter, validar, salvar e encerrar
              a sessao do usuario logado.

   Uso:
     import Sessao from './sessao.js';
     Sessao.exigirAutenticacao();      // protege a pagina
     const usuario = Sessao.obter();   // dados do logado
     Sessao.encerrar();                // logout
========================================================= */

const CHAVE_SESSAO = 'ambc_sessao';

/* ---------------------------------------------------------
   Obter sessao salva (localStorage OU sessionStorage)
--------------------------------------------------------- */
function obter() {
  const raw =
    localStorage.getItem(CHAVE_SESSAO) ||
    sessionStorage.getItem(CHAVE_SESSAO);

  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    // Sessao corrompida — limpa pra evitar loop
    encerrar(false);
    return null;
  }
}

/* ---------------------------------------------------------
   Salvar sessao
   @param {Object}  usuario  Dados do usuario logado
   @param {boolean} lembrar  true = localStorage, false = sessionStorage
--------------------------------------------------------- */
function salvar(usuario, lembrar = false) {
  const storage = lembrar ? localStorage : sessionStorage;
  storage.setItem(CHAVE_SESSAO, JSON.stringify(usuario));
  console.log('[Sessao] Sessao salva em', lembrar ? 'localStorage' : 'sessionStorage');
}

/* ---------------------------------------------------------
   Verificar se ha sessao ativa
--------------------------------------------------------- */
function estaAutenticado() {
  return obter() !== null;
}

/* ---------------------------------------------------------
   Encerrar sessao (logout)
   @param {boolean} redirecionar  Se true, vai pra login.html
--------------------------------------------------------- */
function encerrar(redirecionar = true) {
  console.log('[Sessao] Limpando storage...');
  localStorage.removeItem(CHAVE_SESSAO);
  sessionStorage.removeItem(CHAVE_SESSAO);

  if (redirecionar) {
    // 🆕 Resolve o caminho do login.html relativo a pagina atual
    // Funciona em http://, https:// e file://
    const urlLogin = new URL('login.html', window.location.href).href;
    console.log('[Sessao] Redirecionando para:', urlLogin);
    window.location.replace(urlLogin);
  }
}

/* ---------------------------------------------------------
   Guarda de rota — usar no topo das paginas protegidas
   Se nao houver sessao, redireciona pra login imediatamente.
--------------------------------------------------------- */
function exigirAutenticacao() {
  if (!estaAutenticado()) {
    console.warn('[Sessao] Nao autenticado — redirecionando para login');
    const urlLogin = new URL('login.html', window.location.href).href;
    window.location.replace(urlLogin);
    // Lanca erro pra interromper a execucao do script atual
    throw new Error('[Sessao] Nao autenticado — redirecionando para login');
  }
}

/* ---------------------------------------------------------
   Helpers de exibicao
--------------------------------------------------------- */

// Iniciais do nome (ex: "Fabio Silva" -> "FS")
function obterIniciais() {
  const u = obter();
  if (!u || !u.nome) return '?';

  const partes = u.nome.trim().split(/\s+/);
  if (partes.length === 1) return partes[0][0].toUpperCase();

  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
}

/* ---------------------------------------------------------
   Timer de inatividade
   Encerra a sessão após 30 min sem interação do usuário.
   Exibe aviso 2 minutos antes de expirar.
--------------------------------------------------------- */
const _INATIVIDADE_MS  = 30 * 60 * 1000;
const _AVISO_MS        =  2 * 60 * 1000;
const _THROTTLE_MS     = 30 * 1000;
const _EVENTOS         = ['mousemove', 'keydown', 'click', 'touchstart', 'scroll'];

let _timerExpiracao  = null;
let _timerAviso      = null;
let _ultimaAtividade = 0;
let _avisoAtivo      = false;

function _removerAviso() {
  document.getElementById('sessao-aviso-inatividade')?.remove();
  _avisoAtivo = false;
}

function _exibirAviso() {
  if (_avisoAtivo) return;
  _avisoAtivo = true;

  const div = document.createElement('div');
  div.id = 'sessao-aviso-inatividade';
  div.style.cssText = `
    position:fixed;bottom:24px;right:24px;z-index:9999;
    background:var(--cor-alerta-clara);border:1px solid var(--cor-alerta);
    border-radius:var(--raio-md);padding:14px 18px;max-width:320px;
    box-shadow:var(--sombra-md);display:flex;align-items:center;gap:12px;
  `;
  div.innerHTML = `
    <span class="material-icons" style="color:var(--cor-alerta);flex-shrink:0">timer</span>
    <div style="flex:1;font-size:var(--fs-sm)">
      <strong>Sessão expirando</strong><br>
      Você será desconectado em 2 minutos por inatividade.
    </div>
    <button onclick="document.getElementById('sessao-aviso-inatividade').remove()"
      style="background:none;border:none;cursor:pointer;padding:0;line-height:1">
      <span class="material-icons" style="font-size:18px;color:var(--cor-alerta-escura)">close</span>
    </button>
  `;
  document.body.appendChild(div);
}

function _resetarTimer() {
  const agora = Date.now();
  if (agora - _ultimaAtividade < _THROTTLE_MS) return;
  _ultimaAtividade = agora;

  clearTimeout(_timerExpiracao);
  clearTimeout(_timerAviso);
  _removerAviso();

  _timerAviso = setTimeout(_exibirAviso, _INATIVIDADE_MS - _AVISO_MS);
  _timerExpiracao = setTimeout(() => encerrar(true), _INATIVIDADE_MS);
}

function iniciarTimerInatividade() {
  _ultimaAtividade = Date.now() - _THROTTLE_MS; // força reset imediato
  _EVENTOS.forEach(ev => document.addEventListener(ev, _resetarTimer, { passive: true }));
  _resetarTimer();
  console.log('[Sessao] Timer de inatividade iniciado (30 min)');
}

function pararTimerInatividade() {
  clearTimeout(_timerExpiracao);
  clearTimeout(_timerAviso);
  _removerAviso();
  _EVENTOS.forEach(ev => document.removeEventListener(ev, _resetarTimer));
  console.log('[Sessao] Timer de inatividade parado');
}

/* ---------------------------------------------------------
   Verifica permissão de acesso a um módulo
   @param {number} moduloId  ID do módulo (tabela modulo_sistema)
   @param {string} tipo      'pode_acessar' ou 'pode_editar'
--------------------------------------------------------- */
function temPermissao(moduloId, tipo = 'pode_acessar') {
  const sessao = obter();
  if (!sessao) return false;
  if (sessao.fk_perfil === 1) return true; // Administrador tem acesso total
  const perms = sessao.permissoes || [];
  const perm = perms.find(p => Number(p.fk_modulo) === Number(moduloId));
  return perm ? Boolean(Number(perm[tipo])) : false;
}

/* ---------------------------------------------------------
   Exporta API publica
--------------------------------------------------------- */
const Sessao = {
  obter,
  salvar,
  estaAutenticado,
  encerrar,
  exigirAutenticacao,
  obterIniciais,
  iniciarTimerInatividade,
  pararTimerInatividade,
  temPermissao,
};

export default Sessao;
