# 📍 Checkpoint — AMBC V2

> **Última sessão:** 21/04/2026 (terça-feira)  
> **Próxima sessão:** retomar na Fase 2 — Navegação SPA

---

## 🎯 Onde paramos

Concluímos **100% da Fase 1** — toda a fundação visual do sistema está pronta
e funcionando sem erros. O "esqueleto" da aplicação está de pé.

### 🏆 Conquistas da última sessão
- ✅ Layout completo (sidebar + topbar + main + footer)
- ✅ Scroll interno no `<main>` funcionando
- ✅ Sidebar com seções PRINCIPAL e SISTEMA
- ✅ Topbar com título dinâmico e perfil do usuário
- ✅ Design tokens centralizados em `variaveis.css`
- ✅ Console F12 limpo, sem erros
- ✅ Todos os CSS carregando corretamente

---

## 🚀 Por onde começar amanhã

### Próxima tarefa: **Fase 2.1 — Roteamento SPA**

Vamos criar o arquivo `js/core/router.js`, responsável por:
1. Detectar mudanças na URL (hash `#painel`, `#cadastro/listar`, etc.)
2. Carregar a página correspondente
3. Atualizar o título na topbar
4. Marcar o item ativo na sidebar

### ⚙️ Antes de codar, vamos decidir:
1. Estrutura de pastas do JS (`js/core/`, `js/layout/`, `js/paginas/`)
2. Formato do mapa de rotas (objeto JS central)
3. Se cada página será um arquivo `.html` separado (carregado via fetch)
   **OU** uma função JS que monta o HTML dinamicamente
4. Estratégia de transição entre páginas (fade, slide, nenhuma)

---

## 📝 Lembretes importantes

- 🔤 **Padrão de nomenclatura:** BEM em português (`bloco__elemento--modificador`)
- 📁 **Nomes de arquivos:** sempre em português (ex: `cadastro.js`, não `registration.js`)
- 🎨 **Sempre usar variáveis CSS** (nunca hardcoded colors/spacings)
- 📱 **Sempre pensar em responsivo** (mobile first quando fizer sentido)
- ♻️ **Sempre reutilizável** (componente antes de página)
- 🚫 **Sem frameworks** (decisão do projeto — JS Vanilla puro)

---

## 📂 Arquivos criados até agora

### HTML
- `index.html`

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

### Documentação
- `ROADMAP.md`
- `CHECKPOINT.md`

---

## 💬 Como retomar amanhã

Abra o chat e mande algo como:

> "Oi! Vamos continuar o projeto AMBC V2. Parei na Fase 2 — Navegação SPA.
> Já temos toda a Fase 1 concluída. Me ajude a começar o roteamento."

Ou simplesmente:

> "Vamos continuar de onde paramos no AMBC V2."

Eu vou ler o `CHECKPOINT.md` e o `ROADMAP.md` e já sei exatamente por onde seguir. 🚀
