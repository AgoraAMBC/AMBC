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
   Exporta API publica
--------------------------------------------------------- */
const Sessao = {
  obter,
  salvar,
  estaAutenticado,
  encerrar,
  exigirAutenticacao,
  obterIniciais,
};

export default Sessao;
