/* =========================================================
   router.js
   Projeto: AMBC-V2
   Descricao: Roteador SPA baseado em hash (#/rota).
              Carrega views via fetch() e injeta no <main>.
========================================================= */

import Sessao from './sessao.js?v=2';

/* ---------------------------------------------------------
   1. TABELA DE ROTAS
   ---------------------------------------------------------
   Cada rota define:
   - view: caminho do arquivo HTML da view
   - page: nome do modulo JS em js/paginas/ (sem extensao)
   - titulo: texto exibido na aba do navegador
--------------------------------------------------------- */
const rotas = {
  '#/dashboard': {
    view: 'views/dashboard/dashboard.html',
    page: 'dashboard',
    titulo: 'Painel',
    modulo: 1
  },

  // ----- CADASTRO -----
  '#/cadastro/listar': {
    view: 'views/cadastro/listar.html',
    page: 'cadastro-listar',
    titulo: 'Listar Todos',
    modulo: 2
  },
  '#/cadastro/novo-associado': {
    view: 'views/cadastro/novo-associado.html',
    page: 'cadastro-novo-associado',
    titulo: 'Novo Associado',
    modulo: 2
  },
  '#/cadastro/novo-parceiro': {
    view: 'views/cadastro/novo-parceiro.html',
    page: 'cadastro-novo-parceiro',
    titulo: 'Novo Parceiro',
    modulo: 5
  },
  '#/cadastro/dependentes': {
    view: 'views/cadastro/dependentes.html',
    page: 'cadastro-dependentes',
    titulo: 'Dependentes',
    modulo: 2
  },

  // ----- FINANCEIRO -----
  '#/financeiro/visao-geral': {
    view: 'views/financeiro/visao-geral.html',
    page: 'financeiro',
    titulo: 'Visão Geral',
    modulo: 4
  },
  // '#/financeiro/novo-lancamento': {
  //   view: 'views/financeiro/novo-lancamento.html',
  //   page: 'financeiro',
  //   titulo: 'Novo Lançamento'
  // },
  '#/financeiro/registrar-lancamento': {
    view: 'views/financeiro/registrar-lancamento.html',
    page: 'financeiro',
    titulo: 'Registrar Lançamento',
    modulo: 4
  },
  '#/financeiro/relatorios': {
    view: 'views/financeiro/relatorios.html',
    page: 'financeiro',
    titulo: 'Relatórios',
    modulo: 9
  },
  '#/financeiro/contas-regentes': {
    view: 'views/financeiro/contas-regentes.html',
    page: 'financeiro',
    titulo: 'Contas Regentes',
    modulo: 4
  },
  '#/financeiro/contas-subordinadas': {
    view: 'views/financeiro/contas-subordinadas.html',
    page: 'financeiro',
    titulo: 'Contas Subordinadas',
    modulo: 4
  },
  '#/financeiro/estorno-liquidacao': {
    view: 'views/financeiro/estorno-liquidacao.html',
    page: 'financeiro',
    titulo: 'Estorno de Liquidações',
    modulo: 4
  },

  // ----- TABELAS -----
  '#/tabelas/ver': {
    view: 'views/tabelas/ver-tabelas.html',
    page: 'tabelas',
    titulo: 'Ver Tabelas',
    modulo: 8
  },

  // ----- CONFIGURAÇÕES -----
  '#/configuracoes/usuarios': {
    view: 'views/configuracoes/usuarios.html',
    page: 'usuarios',
    titulo: 'Gestão de Usuários',
    modulo: 7
  },
  '#/configuracoes/associacao': {
    view: 'views/configuracoes/associacao.html',
    page: 'configuracoes',
    titulo: 'Associação',
    modulo: 8
  },
  '#/configuracoes/relacionamentos': {
    view: 'views/configuracoes/relacionamentos.html',
    page: 'relacionamentos',
    titulo: 'Relacionamentos',
    modulo: 8
  },
  '#/configuracoes/config-gerais': {
    view: 'views/configuracoes/config-gerais.html',
    page: 'configuracoes',
    titulo: 'Configurações Gerais',
    modulo: 8
  },

  // ----- AJUDA -----
  '#/ajuda': {
    view: 'views/ajuda/ajuda.html',
    page: 'ajuda',
    titulo: 'Ajuda',
    modulo: null
  },

  // ----- SHOWCASE (vitrine de componentes) -----
  '#/showcase': {
    view: 'views/showcase.html',
    page: 'showcase',
    titulo: 'Showcase de Componentes',
    modulo: null
  },
};

/* ---------------------------------------------------------
   2. CONSTANTES INTERNAS
--------------------------------------------------------- */
const ROTA_PADRAO  = '#/dashboard';
const CONTAINER_ID = 'conteudo-principal';
const TITULO_BASE  = 'AMBC - Associação de Moradores do Bairro Califórnia';

// Guarda referencia da pagina atual para chamar destroy() ao sair
let paginaAtual = null;

/* ---------------------------------------------------------
   3. FUNCAO: renderiza HTML de loading
--------------------------------------------------------- */
function renderizarLoading(container) {
  container.innerHTML = `
    <div class="view view--loading">
      <p>Carregando...</p>
    </div>
  `;
}

/* ---------------------------------------------------------
   4. FUNCAO: renderiza HTML de erro
--------------------------------------------------------- */
function renderizarErro(container, mensagem) {
  container.innerHTML = `
    <div class="view view--erro">
      <h2>Ops! Algo deu errado.</h2>
      <p>${mensagem}</p>
      <a href="${ROTA_PADRAO}">Voltar ao Painel</a>
    </div>
  `;
}

/* ---------------------------------------------------------
   5. FUNCAO: carrega o HTML de uma view via fetch
--------------------------------------------------------- */
async function carregarView(caminho) {
  const resposta = await fetch(caminho);

  if (!resposta.ok) {
    throw new Error(`Falha ao carregar ${caminho} (HTTP ${resposta.status})`);
  }

  return await resposta.text();
}

/* ---------------------------------------------------------
   6. FUNCAO: injeta o HTML da view no container
   ---------------------------------------------------------
   Usa template element para garantir que elementos como
   <dialog> sejam preservados corretamente no DOM.
--------------------------------------------------------- */
function injetarHtml(container, html) {
  // Limpa o container
  container.innerHTML = '';

  // Usa <template> para parsear o HTML — preserva TODOS os elementos
  // incluindo <dialog>, <details>, <summary>, etc.
  const template = document.createElement('template');
  template.innerHTML = html;

  // Clona o conteúdo do template e injeta no container
  container.appendChild(template.content.cloneNode(true));
}


/* ---------------------------------------------------------
   7. FUNCAO: carrega o modulo JS da pagina dinamicamente
--------------------------------------------------------- */
async function carregarModuloPagina(nomePagina) {
  try {
    // ✅ Usa nomePagina dinamicamente + cache-busting via versão fixa
    const modulo = await import(`../paginas/${nomePagina}.js?v=10`);
    return modulo.default;
  } catch (erro) {
    console.warn(`[Router] Modulo js/paginas/${nomePagina}.js nao pode ser carregado:`, erro);
    return null;
  }
}


/* ---------------------------------------------------------
   8. FUNCAO PRINCIPAL: trata mudanca de rota
--------------------------------------------------------- */
async function tratarRota() {
  const hash      = window.location.hash || ROTA_PADRAO;
  const container = document.getElementById(CONTAINER_ID);

  // Valida se o container existe
  if (!container) {
    console.error(`[Router] Elemento #${CONTAINER_ID} nao encontrado no DOM!`);
    return;
  }

  // Se nao tem hash, redireciona pra rota padrao
  if (!window.location.hash) {
    window.location.hash = ROTA_PADRAO;
    return; // o proprio hashchange vai disparar tratarRota() de novo
  }

  // Permite query strings no hash, ex: #/cadastro/novo-associado?id=123
  const [rotaHash] = hash.split('?');

  // Busca a rota no mapa
  const rota = rotas[rotaHash];

  // Chama destroy() da pagina anterior (se existir)
  if (paginaAtual && typeof paginaAtual.destroy === 'function') {
    try {
      paginaAtual.destroy();
    } catch (erro) {
      console.warn('[Router] Erro ao destruir pagina anterior:', erro);
    }
    paginaAtual = null;
  }

  // Mostra estado de loading
  renderizarLoading(container);

  try {
    // --- ROTA NAO ENCONTRADA (404) ---
    if (!rota) {
      const html404 = await carregarView('views/404.html');
      injetarHtml(container, html404);
      document.title = `404 - Não encontrado | ${TITULO_BASE}`;
      console.warn(`[Router] Rota nao encontrada: ${hash}`);
      return;
    }

    // Verifica permissão de acesso ao módulo
    if (rota.modulo !== null && rota.modulo !== undefined) {
      if (!Sessao.temPermissao(rota.modulo)) {
        renderizarErro(container, 'Você não tem permissão para acessar este módulo.');
        document.title = `Acesso negado | ${TITULO_BASE}`;
        return;
      }
    }

    // --- ROTA VALIDA ---
    const html = await carregarView(rota.view);

    // ✅ Usa DOMParser para preservar elementos como <dialog>
    injetarHtml(container, html);

    document.title = `${rota.titulo} | ${TITULO_BASE}`;

    // Carrega e inicializa o modulo JS da pagina
    const modulo = await carregarModuloPagina(rota.page);
    if (modulo && typeof modulo.init === 'function') {
      await modulo.init();
      paginaAtual = modulo;
    }

    console.log(`[Router] Rota carregada: ${hash}`);

  } catch (erro) {
    console.error('[Router] Erro ao carregar rota:', erro);
    renderizarErro(container, erro.message);
  }
}

/* ---------------------------------------------------------
   9. FUNCAO PUBLICA: inicializa o router
--------------------------------------------------------- */
function iniciar() {
  // Escuta mudancas de hash
  window.addEventListener('hashchange', tratarRota);

  // Dispara a primeira rota ao carregar a pagina
  tratarRota();

  console.log('[Router] Inicializado com sucesso');
}

/* ---------------------------------------------------------
   10. EXPORT
--------------------------------------------------------- */
export default {
  iniciar,
  rotas // exportamos para debug/uso externo se necessario
};
