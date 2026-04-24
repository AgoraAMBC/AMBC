# 🗺️ Roadmap — AMBC V2

> Plataforma de Gestão — Associação dos Moradores do Bairro Califórnia  
> Última atualização: 22/04/2026

---

## 🎯 Visão geral

Sistema SPA (Single Page Application) em HTML5 + CSS3 + JavaScript Vanilla,
preparado para futura integração com backend PHP + PostgreSQL.

---

## ✅ FASE 1 — Fundação do Frontend (CONCLUÍDA)

### 1.1 Estrutura do projeto
- [x] Criação da estrutura de pastas
- [x] Definição da stack (HTML5, CSS3, JS Vanilla, Material Icons)
- [x] Padrão de nomenclatura BEM em português
- [x] Padrão de arquivos em português (tipografia.css, variaveis.css, etc.)

### 1.2 Camada Base (CSS)
- [x] `css/base/reset.css` — Reset moderno
- [x] `css/base/variaveis.css` — Design tokens (cores, espaçamentos, tipografia, raios, sombras)
- [x] `css/base/tipografia.css` — Hierarquia tipográfica
- [x] `css/base/global.css` — Estilos globais e utilitários

### 1.3 Camada de Layout (CSS)
- [x] `css/layout/app-shell.css` — Grid principal (sidebar + topbar + main + footer)
- [x] `css/layout/sidebar.css` — Menu lateral com seções e submenus
- [x] `css/layout/topbar.css` — Barra superior com título + perfil
- [x] `css/layout/main.css` — Área de conteúdo com scroll interno

### 1.4 HTML
- [x] `index.html` — Estrutura completa do app-shell
- [x] Sidebar com menus PRINCIPAL e SISTEMA
- [x] Topbar com título dinâmico e perfil do usuário
- [x] Rodapé com copyright e versão

### 1.5 Validações
- [x] Console sem erros (F12 limpo)
- [x] Todos os CSS carregando (200 OK)
- [x] Layout responsivo funcionando
- [x] Scroll interno no `<main>` com sidebar/topbar fixas

---

## ✅ FASE 2 — Navegação SPA (CONCLUÍDA em 22/04/2026)

### 2.1 Roteamento ✅
- [x] `js/core/router.js` — Roteador baseado em hash (#painel, #cadastro/listar, etc.)
- [x] Mapa de rotas centralizado
- [x] Atualização automática do título na topbar
- [x] Marcação do item ativo na sidebar
- [x] Rota padrão (fallback) e 404
- [x] Cache de views carregadas via fetch

### 2.2 Comportamento da Sidebar ✅
- [x] `js/layout/sidebar.js` — Expandir/colapsar submenus (accordion)
- [x] Destacar item ativo conforme rota
- [x] Fechamento automático no mobile ao navegar
- [x] Integração com o router

### 2.3 Menu Mobile ✅
- [x] `js/layout/topbar.js` — Botão hambúrguer funcional
- [x] Overlay escuro ao abrir sidebar no mobile
- [x] Fechamento via overlay, ESC ou seleção de item
- [x] Título dinâmico na topbar conforme rota

### 2.4 Views (páginas HTML) ✅
- [x] `views/dashboard/dashboard.html`
- [x] `views/cadastro/listar.html`
- [x] `views/cadastro/novo-associado.html`
- [x] `views/cadastro/novo-parceiro.html`
- [x] `views/cadastro/dependentes.html`
- [x] `views/financeiro/visao-geral.html`
- [x] `views/financeiro/novo-lancamento.html`
- [x] `views/financeiro/relatorios.html`
- [x] `views/financeiro/contas-regentes.html`
- [x] `views/financeiro/contas-subordinadas.html`
- [x] `views/tabelas/ver-tabelas.html`
- [x] `views/configuracoes/associacao.html`
- [x] `views/configuracoes/relacionamentos.html`
- [x] `views/configuracoes/config-gerais.html`
- [x] `views/404.html`

### 2.5 Pendências (revisitar na próxima fase)
- [ ] Ciclo de vida formal das páginas (montar / desmontar)
- [ ] Persistência do estado dos submenus (localStorage)
- [ ] Transições suaves entre páginas

---

## 📦 FASE 3 — Biblioteca de Componentes UI

- [ ] Botões (primário, secundário, perigo, ícone, loading)
- [ ] Cards (básico, com cabeçalho, com ações)
- [ ] Badges e tags
- [ ] Inputs (texto, senha, email, número, data, select, textarea)
- [ ] Formulários (validação, mensagens de erro)
- [ ] Tabelas (paginação, ordenação, busca)
- [ ] Modais e confirmações
- [ ] Notificações/Toasts
- [ ] Breadcrumbs
- [ ] Abas (tabs)
- [ ] Paginação
- [ ] Skeleton loaders

---

## 📊 FASE 4 — Módulos Funcionais

### 4.1 Painel (Dashboard)
- [ ] Cards de estatísticas
- [ ] Gráficos (Chart.js ou similar)
- [ ] Atividades recentes
- [ ] Atalhos rápidos

### 4.2 Cadastro
- [ ] Listar Associados
- [ ] Novo Associado (formulário completo)
- [ ] Novo Parceiro
- [ ] Edição e exclusão
- [ ] Filtros e busca

### 4.3 Financeiro
- [ ] Visão Geral
- [ ] Novo Lançamento
- [ ] Relatórios
- [ ] Contas Regentes
- [ ] Contas Subordinadas

### 4.4 Tabelas Auxiliares
- [ ] Ver Tabelas (CRUD genérico)

### 4.5 Configurações
- [ ] Dados da Associação
- [ ] Relacionamentos
- [ ] Configurações Gerais

---

## 🔌 FASE 5 — Integração Backend (futura)

- [ ] Definir contratos de API (endpoints, payloads)
- [ ] Camada de serviços (`js/servicos/*.js`)
- [ ] Tratamento de erros HTTP
- [ ] Autenticação e sessão
- [ ] Loading states globais
- [ ] Integração com PHP + PostgreSQL

---

## 🎨 FASE 6 — Polimento Final

- [ ] Tema escuro (dark mode)
- [ ] Acessibilidade (ARIA, navegação por teclado)
- [ ] Performance (lazy load, minificação)
- [ ] Testes de responsividade em dispositivos reais
- [ ] Documentação de componentes
