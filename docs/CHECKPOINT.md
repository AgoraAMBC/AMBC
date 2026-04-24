# 📍 Checkpoint — AMBC V2

> **Última sessão:** 22/04/2026 (quarta-feira)  
> **Próxima sessão:** Fase 3 — Biblioteca de Componentes UI

---

## 🎯 Onde paramos

Concluímos **100% da Fase 2** — toda a navegação SPA está funcionando:
roteamento por hash, sidebar com accordion, menu mobile com overlay,
e 15 views placeholder carregando via fetch.

### 🏆 Conquistas desta sessão
- ✅ Router SPA (`js/core/router.js`) com cache de views
- ✅ Sidebar interativa (`js/layout/sidebar.js`) com accordion
- ✅ Topbar com hambúrguer + overlay + ESC (`js/layout/topbar.js`)
- ✅ Orquestrador central (`js/core/app.js`)
- ✅ 15 views HTML placeholder (todas as rotas do sistema)
- ✅ Integração router ↔ sidebar ↔ topbar
- ✅ Menu mobile 100% funcional
- ✅ Console F12 limpo

---

## 🚀 Por onde começar na próxima sessão

### Próxima tarefa: **Fase 3 — Biblioteca de Componentes UI**

Antes de entrar nos módulos funcionais (dashboard real, cadastro, financeiro),
vamos construir uma biblioteca de componentes reutilizáveis.

### ⚙️ Antes de codar, decidir:
1. Ordem dos componentes (sugestão: botões → inputs → cards → tabelas → modais)
2. Se criamos um arquivo CSS por componente em `css/components/`
3. Se haverá JS para componentes interativos (modal, toast, dropdown)
4. Se manteremos uma "página showcase" pra visualizar os componentes

### 🔄 Pendências da Fase 2 (revisitar se fizer sentido)
- [ ] Ciclo de vida formal das páginas (montar/desmontar)
- [ ] Persistência de submenus abertos (localStorage)
- [ ] Transições suaves entre páginas

---

## 📐 Padrões do projeto (lembrete)

- 📝 **Nomes de arquivos:** sempre em português
- 🎨 **Sempre usar variáveis CSS** (nunca hardcoded)
- 📱 **Sempre pensar em responsivo**
- ♻️ **Sempre reutilizável** (componente antes de página)
- 🚫 **Sem frameworks** (JS Vanilla puro)
- 🏷️ **BEM em português** para classes CSS

---

## 📂 Arquivos criados até agora

### HTML
- `index.html`
- 15 views em `views/**/*.html`

### CSS — Base
- `css/base/reset.css`
- `css/base/variaveis.css`
- `css/base/tipografia.css`
- `css/base/global.css`

### CSS — Layout
- `css/layout/app-shell.css`
- `css/layout/sidebar.css`
- `css/layout/topbar.css`
- `css/layout/main.css`

### JavaScript — Core
- `js/core/app.js`
- `js/core/router.js`

### JavaScript — Layout
- `js/layout/sidebar.js`
- `js/layout/topbar.js`

### JavaScript — Páginas (stubs)
- `js/pages/dashboard.js`
- `js/pages/cadastro.js`
- `js/pages/dependentes.js`
- `js/pages/financeiro.js`
- `js/pages/tabelas.js`
- `js/pages/configuracoes.js`

### Documentação
- `docs/ROADMAP.md`
- `docs/CHECKPOINT.md`
- `docs/specificacao.md`
- `docs/specificacao.pdf`

---

## 💬 Como retomar na próxima sessão

Abra o chat e mande algo como:

> "Oi! Vamos continuar o AMBC V2. Parei na Fase 3 — Biblioteca de Componentes UI.
> Fase 2 (Navegação SPA) está 100% concluída. Lê o CHECKPOINT.md e o ROADMAP.md."

Ou simplesmente:

> "Vamos continuar de onde paramos no AMBC V2."
