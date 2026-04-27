# 📘 Padrões de Desenvolvimento — AMBC-V2

> **Versão:** 1.0  
> **Última atualização:** 26/04/2026  
> **Aplicabilidade:** OBRIGATÓRIA para todo código novo do projeto.  
> **Responsável:** Fabio (frontend)

---

## 🎯 Objetivo

Este documento define as convenções, padrões e práticas que **todo o time** deve seguir ao desenvolver no projeto **AMBC-V2** (Plataforma de Gestão da Associação dos Moradores do Bairro Califórnia).

O objetivo é garantir:
- ✅ Consistência visual e estrutural
- ✅ Facilidade de manutenção e onboarding
- ✅ Compatibilidade entre frontend, backend e banco de dados
- ✅ Redução de conflitos de merge

---

## 🗂️ 1. Estrutura de Pastas
ambc-v2/ ├── index.html # SPA shell (único HTML carregado pelo navegador) ├── css/ │ ├── base/ # Reset, variáveis, tipografia │ ├── componentes/ # Botões, cards, modais, badges, etc. │ ├── paginas/ # CSS específico de cada página │ └── app.css # Importa tudo (entry point) ├── js/ │ ├── core/ # App, router, sessão, config │ ├── componentes/ # Modal, Toast, etc. (componentes reutilizáveis) │ ├── layout/ # Sidebar, topbar │ ├── services/ # Comunicação com API (um por módulo) │ ├── paginas/ # Lógica de cada página (init/destroy) │ └── utils/ # Funções utilitárias (formatadores, validadores) ├── views/ # HTML de cada página (carregado via fetch pelo router) │ ├── cadastro/ │ ├── financeiro/ │ ├── configuracoes/ │ └── dashboard/ ├── assets/ # Imagens, ícones, fontes └── docs/ # Documentação (este arquivo, README, etc.)




---

## 🌐 2. Idioma e Convenções de Nomenclatura

### 2.1. Idioma

| Contexto | Idioma | Exemplo |
|---|---|---|
| **Variáveis e funções JS** | 🇧🇷 Português | `carregarTabela()`, `usuariosAtivos` |
| **Classes CSS** | 🇧🇷 Português | `.usuarios-pagina__titulo` |
| **IDs HTML** | 🇧🇷 Português | `#btn-novo-usuario` |
| **Lifecycle JS (`init`/`destroy`)** | 🇺🇸 Inglês | Convenção universal — exceção permitida |
| **Comentários** | 🇧🇷 Português com acento | `// Carrega lista de usuários` |
| **Mensagens ao usuário** | 🇧🇷 Português com acento | `"Usuário cadastrado com sucesso!"` |

### 2.2. Case (estilo de escrita)

| Contexto | Estilo | Exemplo |
|---|---|---|
| Variáveis e funções JS | `camelCase` | `usuarioAtivo`, `carregarDados()` |
| Constantes JS | `SCREAMING_SNAKE_CASE` | `API_BASE`, `BREAKPOINT_MOBILE` |
| Objetos exportados (módulos) | `PascalCase` | `Sessao`, `Modal`, `UsuariosService` |
| Classes CSS | `kebab-case` (BEM) | `gu-tabela__linha--ativa` |
| IDs HTML | `kebab-case` | `btn-novo-usuario` |
| Arquivos JS/CSS | `kebab-case` | `usuarios.js`, `cadastro-listar.css` |
| Pastas | `kebab-case` | `views/configuracoes/` |

---

## 🎨 3. Padrões CSS

### 3.1. Metodologia: BEM (Block Element Modifier)

> **Obrigatório para todo CSS novo.**
bloco__elemento--modificador




#### ✅ Correto

```css
.usuarios-pagina { }                        /* bloco */
.usuarios-pagina__titulo { }                /* elemento */
.usuarios-pagina__titulo--destaque { }      /* modificador */
.gu-btn { }
.gu-btn--primario { }
.gu-btn--icone-perigo { }
❌ Errado
css


.usuarios .titulo { }              /* sem BEM */
.btn.primario { }                  /* modificador como classe separada */
.btn-primario { }                  /* falta o `--` */
.UsuariosPagina { }                /* PascalCase */
3.2. Estrutura de view (página)
Toda nova página deve usar namespace próprio (Estilo C).

html


<section class="usuarios-pagina">
  <header class="usuarios-pagina__cabecalho">
    <h2 class="usuarios-pagina__titulo">Título</h2>
    <p class="usuarios-pagina__subtitulo">Subtítulo</p>
  </header>

  <div class="usuarios-pagina__filtros">...</div>
  <div class="usuarios-pagina__tabela">...</div>
</section>
Regras:

O bloco principal segue o nome da página: usuarios-pagina, dashboard-pagina, cadastro-listar
Todos os elementos internos são modificadores desse bloco
Componentes globais (btn, card, modal, badge) podem ser usados normalmente
3.3. Variáveis CSS (Design Tokens)
Sempre usar variáveis do design system. Nunca hardcode de valores.

css


/* ✅ Correto */
.minha-classe {
  color: var(--texto-principal);
  background: var(--cor-primaria);
  padding: var(--esp-md);
  border-radius: var(--raio-sm);
  font-size: var(--fs-sm);
}

/* ❌ Errado */
.minha-classe {
  color: #1f2937;
  background: #1E5BA8;
  padding: 16px;
}
Variáveis disponíveis (consultar css/base/variaveis.css):

Cores: --cor-primaria, --cor-sucesso, --cor-erro, --cor-alerta, --cor-info...
Espaçamentos: --esp-xs (4px), --esp-sm (8px), --esp-md (16px), --esp-lg (24px), --esp-xl (32px)
Raios: --raio-sm, --raio-md, --raio-lg
Fontes: --fs-xs, --fs-sm, --fs-md, --fs-lg, --fs-xl, --fs-2xl
Sombras: --sombra-sm, --sombra-md, --sombra-lg
3.4. Material Icons
Usar somente a classe oficial:

html


<!-- ✅ Correto -->
<span class="material-icons">edit</span>

<!-- ❌ Errado -->
<span class="mi">edit</span>
<i class="material-icons">edit</i>
A classe .mi é legada e está sendo removida.

3.5. Tipografia
Fonte oficial: Inter (importada via Google Fonts no index.html)
Fallback: system-ui, -apple-system, sans-serif
❌ NÃO usar Plus Jakarta Sans, Roboto ou outras
🧩 4. Padrões JavaScript
4.1. Módulos ES6
Todo arquivo JS é um módulo ES6:

javascript


// ✅ Importação
import Sessao from '../core/sessao.js';
import { api } from '../services/api.js';

// ✅ Exportação default (para módulos com objeto principal)
export default UsuariosPage;

// ✅ Exportação nomeada (para utilitários e constantes)
export const API_BASE = 'http://localhost:8080/backend';
export function formatarMoeda(valor) { ... }
4.2. Padrão de página (lifecycle obrigatório)
Toda página em js/paginas/ DEVE seguir este padrão.

javascript


/* =========================================================
   Pagina: Nome da Página
   Projeto: AMBC-V2
   Descricao: ...
========================================================= */

import { UsuariosService } from '../services/usuarios.js';

/* ---------------------------------------------------------
   Estado local
--------------------------------------------------------- */
let estado = { /* ... */ };
let debounce = null;

/* ---------------------------------------------------------
   Funções privadas
--------------------------------------------------------- */
async function carregarTabela() { /* ... */ }
function registrarEventos() { /* ... */ }

/* ---------------------------------------------------------
   Módulo exportado
--------------------------------------------------------- */
const NomePagina = {
  async init() {
    console.log('[NomePagina] Inicializando...');
    estado = { /* reset */ };
    await carregarTabela();
    registrarEventos();
  },

  destroy() {
    console.log('[NomePagina] Destruindo...');
    clearTimeout(debounce);
    debounce = null;
    estado = {};
  }
};

export default NomePagina;
Regras do init():

Resetar estado local sempre
Carregar dados iniciais (try/catch obrigatório)
Registrar event listeners
Logar [NomePagina] Inicializado
Regras do destroy():

Limpar timers (clearTimeout, clearInterval)
Limpar listeners globais (window, document)
Resetar variáveis de estado
❌ Não precisa remover listeners de elementos da view (são removidos com o DOM)
4.3. Comentários
javascript


/* =========================================================
   Cabeçalho do arquivo (obrigatório)
========================================================= */

/* ---------------------------------------------------------
   Seção do arquivo (obrigatório)
--------------------------------------------------------- */

// Comentário de linha (use com moderação)

/**
 * JSDoc para funções públicas e exports
 * @param {string} nome - Descrição
 * @returns {boolean}
 */
4.4. Logs (console)
Sempre prefixar com o nome do módulo entre colchetes:

javascript


console.log('[Sidebar] Inicializada com sucesso');
console.warn('[Router] Rota não encontrada:', hash);
console.error('[UsuariosService] Falha ao listar:', erro);
4.5. Tratamento de erros
javascript


try {
  const dados = await UsuariosService.listar();
  renderTabela(dados);
} catch (erro) {
  console.error('[Usuarios] Erro:', erro);
  Toast.erro(erro.message || 'Erro ao carregar dados');
}
🌐 5. Comunicação com Backend
5.1. URL base oficial
javascript


// js/core/config.js
export const API_BASE = 'http://localhost:8080/backend';
❌ Não usar localhost:3000 (json-server) — removido do projeto.

5.2. Camada de service (obrigatório)
Páginas NUNCA fazem fetch direto. Sempre via service.

Estrutura de um service
javascript


// js/services/usuarios.js
import { api } from './api.js';

const ENDPOINT = '/usuarios';

export const UsuariosService = {
  listar(params) {
    const qs = new URLSearchParams(params);
    return api.get(`${ENDPOINT}/listar.php?${qs}`);
  },

  buscarPorId(id) {
    return api.get(`${ENDPOINT}/buscar.php?id=${id}`);
  },

  cadastrar(dados) {
    return api.post(`${ENDPOINT}/cadastrar.php`, dados);
  },

  editar(id, dados) {
    return api.put(`${ENDPOINT}/editar.php`, { id, ...dados });
  },

  alternarStatus(id) {
    return api.patch(`${ENDPOINT}/alternar-status.php`, { id });
  }
};
Uso na página
javascript


import { UsuariosService } from '../services/usuarios.js';

const usuarios = await UsuariosService.listar({ pagina: 1 });
5.3. Padrão de resposta esperado do backend
json


// Sucesso
{
  "sucesso": true,
  "dados": [...],
  "pagina": 1,
  "paginas": 10
}

// Erro
{
  "sucesso": false,
  "erro": "Mensagem amigável ao usuário",
  "detalhes": "Detalhes técnicos (apenas em dev)"
}
🧱 6. Componentes Globais
6.1. Componentes disponíveis



Componente	Importação	Uso
Modal	import Modal from '../componentes/modal.js'*	Modal.abrir('id'), Modal.confirmar({...})
Toast	import Toast from '../componentes/toast.js'	Toast.sucesso(msg), Toast.erro(msg)
Sessao	import Sessao from '../core/sessao.js'	Sessao.obter(), Sessao.encerrar()
6.2. Atributos data-* oficiais



Atributo	Uso
data-modal-abrir="id"	Botão que abre modal estático
data-modal-fechar	Botão que fecha o modal pai
data-acao="editar"	Identifica ação em event delegation
data-id="123"*	Carrega ID do registro
data-toggle-submenu="financeiro"*	Toggle de submenu (sidebar)
data-action="logout"	Ação de logout
data-view="Painel"*	Identifica a view atual
🛡️ 7. Segurança e Boas Práticas
7.1. Escape de HTML
Sempre escapar conteúdo dinâmico inserido via innerHTML:

javascript


// utils/seguranca.js
export function esc(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Uso:
elemento.innerHTML = `<p>${esc(dadosUsuario.nome)}</p>`;
7.2. Validação
✅ Validar sempre no frontend (UX) e no backend (segurança)
❌ Nunca confiar apenas no frontend
7.3. Sessão e autenticação
Token/dados de sessão ficam em Sessao (localStorage)
Páginas protegidas verificam sessão via Sessao.estaLogado() no router
Nunca enviar senhas em log/console
🔀 8. Git Workflow
8.1. Branches


main                    # Produção (estável)
desenvolvimento         # Integração do time
feature/nome-da-feature # Sua branch de trabalho
fix/nome-do-bug         # Branch de correção
8.2. Commits
Padrão Conventional Commits em português:



feat: adiciona página de usuários
fix: corrige conflito de merge em usuarios.js
refactor: padroniza CSS de cadastro-listar
docs: atualiza PADROES.md
style: ajusta espaçamento do modal
8.3. Antes de fazer push
bash


# Sempre puxe o que tem de novo
git pull origin desenvolvimento

# Resolva conflitos LOCALMENTE — nunca commite com `<<<<<<<` no código
# (aconteceu em usuarios.js — não pode acontecer de novo!)

# Teste a aplicação rodando antes de subir
📋 9. Checklist para Pull Request
Antes de abrir PR, confirmar:

 Código segue convenção de nomenclatura (PT-BR + camelCase/kebab-case)
 CSS usa BEM completo (__/--)
 CSS usa variáveis (sem valores hardcoded)
 HTML usa namespace próprio da página
 JS de página implementa init() e destroy()
 Sem console.log esquecidos (apenas logs prefixados úteis)
 Sem marcadores de merge (<<<<<<<, =======, >>>>>>>)
 Comunicação com backend via services/
 Conteúdo dinâmico escapado (esc())
 Testado em desktop e mobile (responsivo)
 Sem warnings no console do navegador
🚧 10. | Duplo `app.js` (`js/` e `js/core/`) | ✅ RESOLVIDO | Removido em refactor/fase-1 |
| `services/api.js` apontando pra `:3000` | ✅ RESOLVIDO | Migrado para API_BASE em config.js (Fase 2) |
| `view-loader.js` | ✅ RESOLVIDO | Removido na Fase 3 — código morto, substituído por router.js |





Item	Status	Plano
Classe .mi no showcase	🟡 Aliasing temporário*	Migrar para .material-icons
Componentes .btn, .card (sem prefix)	🟡 Mantidos	Manter (são globais), só reforçar BEM
view-loader.js IIFE	🔴 Remover	Não é usado pelo router atual
services/api.js apontando pra :3000	🔴 Corrigir	Trocar para API_BASE do config.js
Função api() interna em usuarios.js*	🟡 Refatorar	Migrar para UsuariosService
Duplo app.js (js/ e js/core/)	🔴 Remover duplicata	Manter apenas js/core/app.js
📞 11. Dúvidas e Atualizações
Este documento é vivo — sugestões de melhoria são bem-vindas
Mudanças devem ser discutidas no grupo antes de serem aplicadas
Versionamento: cada alteração significativa incrementa a versão no topo