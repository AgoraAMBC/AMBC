# 🗺️ Roadmap — AMBC V2

> Plataforma de gestão da Associação de Moradores do Bairro Califórnia

**Última atualização:** 22/04/2026
**Branch ativa:** `develop`

---

## 📌 Visão Geral

Sistema web SPA (Single-Page Application) para gestão de associados,
parceiros e finanças da AMBC. Frontend desacoplado, preparado para
integração futura com backend PHP + PostgreSQL.

---

## 🛠️ Stack Técnica

### Frontend (em desenvolvimento)
- **HTML5** semântico
- **CSS3** puro (metodologia BEM + variáveis CSS + Grid/Flexbox)
- **JavaScript Vanilla** (ES6 Modules, sem frameworks)
- **Material Icons** (ícones)
- **Arquitetura SPA** com hash-based routing

### Backend (planejado)
- **PHP** (a ser implementado por outro membro do grupo)
- **PostgreSQL** (banco de dados)
- **API REST** (contratos a definir)

### Ferramentas
- **VS Code** (IDE)
- **Git + GitHub** (controle de versão)
- **Live Server** ou servidor local PHP (desenvolvimento)

---

## 📁 Estrutura de Pastas

AMBC-V2/ ├── css/ │ ├── base/ → reset, variáveis, tipografia │ ├── components/ → botões, cards, formulários... │ ├── layout/ → app-shell, sidebar, topbar │ └── pages/ → estilos específicos de páginas ├── js/ │ ├── core/ → app.js, router.js │ ├── layout/ → sidebar.js, topbar.js │ ├── pages/ → dashboard.js, cadastro.js, financeiro.js... │ └── utils/ → helpers futuros ├── views/ → templates HTML das páginas (carregados pelo router) │ ├── dashboard/ │ ├── cadastro/ │ ├── financeiro/ │ ├── tabelas/ │ └── configuracoes/ ├── assets/ → imagens, ícones, fontes ├── index.html → shell principal da SPA ├── ROADMAP.md → este arquivo └── README.md

---

## ✅ Fases Concluídas

### ✅ Fase 1 — Fundação Visual (concluída)
- [x] Estrutura de pastas
- [x] `index.html` base
- [x] CSS base (reset, variáveis, tipografia)
- [x] Design System (cores, espaçamentos, sombras)

### ✅ Fase 2 — Layout, Roteamento e Navegação (concluída em 22/04/2026)
- [x] **2.1** App-shell responsivo (Grid Layout)
- [x] **2.2** Sidebar com accordion (submenus)
- [x] **2.3** Router SPA (hash-based) + integração com sidebar
- [x] **2.4** Menu mobile (hambúrguer + overlay + ESC + título dinâmico)

**Entregas:**
- `js/core/router.js` — roteador SPA com cache de views
- `js/layout/sidebar.js` — accordion + fechamento automático no mobile
- `js/layout/topbar.js` — hambúrguer + overlay + título dinâmico
- `js/core/app.js` — orquestrador da aplicação
- 13 views HTML placeholder (dashboard, cadastro, financeiro, tabelas, configurações, 404)

---

## 🔄 Fase Atual

**Nenhuma** — pronto para iniciar Fase 3.

---

## 🔜 Próximas Fases

### 🎯 Fase 3 — Dashboard (Painel) Real
- [ ] Cards de KPIs (total associados, inadimplentes, receita do mês)
- [ ] Gráfico de receita mensal (Chart.js ou Canvas puro — a decidir)
- [ ] Gráfico de evolução de associados
- [ ] Lista de atividades recentes
- [ ] Atalhos rápidos (novo associado, novo lançamento)
- [ ] Responsividade completa

### 🎯 Fase 4 — Módulo Cadastro
- [ ] Listagem de associados (tabela com busca, filtro, paginação)
- [ ] Formulário de novo associado (validação client-side)
- [ ] Formulário de novo parceiro
- [ ] Gestão de dependentes
- [ ] Edição e exclusão de cadastros
- [ ] Upload de foto/documentos (preparar UI para backend)

### 🎯 Fase 5 — Módulo Financeiro
- [ ] Visão geral (resumo mensal)
- [ ] Novo lançamento (receita/despesa)
- [ ] Relatórios (com filtros por período)
- [ ] Contas regentes (plano de contas principal)
- [ ] Contas subordinadas (hierarquia)
- [ ] Export CSV/PDF (planejar)

### 🎯 Fase 6 — Tabelas Auxiliares
- [ ] CRUD de tabelas de apoio (tipos de cadastro, status, categorias)
- [ ] Interface unificada para gerenciar múltiplas tabelas

### 🎯 Fase 7 — Configurações
- [ ] Dados da Associação (CNPJ, endereço, logo)
- [ ] Relacionamentos (parentesco, vínculos)
- [ ] Configurações Gerais (preferências do sistema)

### 🎯 Fase 8 — Autenticação (UI)
- [ ] Tela de login
- [ ] Tela de recuperação de senha
- [ ] Guard de rotas (proteger páginas autenticadas)
- [ ] Logout funcional

### 🎯 Fase 9 — Integração Backend
- [ ] Definir contratos de API com o time backend
- [ ] Camada de serviços (`js/services/api.js`)
- [ ] Tratamento de erros e loading states
- [ ] Autenticação via token/sessão
- [ ] Substituir dados mock por chamadas reais

### 🎯 Fase 10 — Polimento e Deploy
- [ ] Otimizações (lazy loading de views)
- [ ] Testes manuais completos
- [ ] Acessibilidade (WCAG AA)
- [ ] Documentação final (README completo)
- [ ] Deploy em ambiente de homologação

---

## 🎨 Convenções do Projeto

### CSS
- **Metodologia BEM** (`bloco__elemento--modificador`)
- **Variáveis CSS** para todos os valores reutilizáveis (`--cor-*`, `--esp-*`, `--z-*`)
- **Mobile-first** quando possível, com media queries `max-width` para tablet/mobile

### JavaScript
- **ES6 Modules** (`import` / `export`)
- **Nomenclatura em português** (funções, variáveis, comentários)
- **Estado local em cada módulo** (sem variáveis globais)
- **Eventos via `addEventListener`** (sem `onclick` inline)

### Git
- **Branch principal:** `main` (produção)
- **Branch de desenvolvimento:** `develop`
- **Conventional Commits**: `feat`, `fix`, `docs`, `refactor`, `style`, `chore`
- **Commits em português**

---

## 👥 Equipe

- **Frontend:** Fabio
- **Backend:** (a definir)
- **Banco de Dados:** (a definir)

---

## 📝 Notas

- O arquivo HTML original com a plataforma completa serve como **referência visual e de dados** para cada módulo
- Todos os textos, labels e dados devem seguir o que está no HTML de referência
- Código preparado para receber backend sem refatorações grandes
