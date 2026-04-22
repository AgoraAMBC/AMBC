# 🗺️ ROADMAP — AMBC V2

> Documento-mestre do projeto frontend.
> **Última atualização:** 21/04/2026

---

## 📌 Sobre
Plataforma de gestão da Associação de Moradores do Bairro Califórnia (AMBC).
Responsabilidade atual: **Frontend** (Fabio).
Backend (PHP + PostgreSQL) será integrado por outro time.

## 🛠️ Stack
- HTML5 + CSS3 + JavaScript Vanilla
- Arquitetura SPA (Single Page Application)
- Material Icons (CDN)

---

## ✅ FASE 1 — Fundação CSS [COMPLETA]
- [x] `css/base/variables.css` — tokens de design (cores, espaços, fontes)
- [x] `css/base/reset.css` — reset de estilos do navegador
- [x] `css/base/typography.css` — tipografia global
- [x] `css/base/global.css` — estilos base

## ✅ FASE 2 — Layout do sistema [COMPLETA]
- [x] `css/layout/app-shell.css` — estrutura geral da aplicação
- [x] `css/layout/sidebar.css` — menu lateral
- [x] `css/layout/topbar.css` — barra superior

## ✅ FASE 4 — HTML principal [COMPLETA]
- [x] `index.html` — shell SPA com sidebar + topbar + área de conteúdo

## 🔨 FASE 5 — JavaScript core [EM ANDAMENTO]
- [ ] `js/core/app.js` — inicialização da aplicação
- [ ] `js/components/sidebar.js` — toggle mobile + abrir/fechar submenus
- [ ] `js/core/router.js` — roteador SPA (hash-based)
- [ ] `js/mock/dados.js` — dados falsos para desenvolvimento

## ⬜ FASE 3 — Componentes CSS [sob demanda]
- [ ] `css/components/buttons.css`
- [ ] `css/components/forms.css`
- [ ] `css/components/cards.css`
- [ ] `css/components/tables.css`
- [ ] `css/components/modals.css`
- [ ] `css/components/alerts.css`
- [ ] `css/components/badges.css`

## ⬜ FASE 6 — Views
- [ ] `views/dashboard/` — painel principal
- [ ] `views/cadastro/` — associados e parceiros
- [ ] `views/financeiro/` — lançamentos e relatórios
- [ ] `views/tabelas/` — tabelas auxiliares
- [ ] `views/configuracoes/` — associação e relacionamentos

---

## 📝 Decisões tomadas
- **Metodologia CSS:** BEM (`bloco__elemento--modificador`)
- **Prefixo de estado:** `is-` (ex: `is-ativo`, `is-aberto`)
- **Idioma das classes:** Português
- **Variáveis CSS:** Português (ex: `--cor-primaria`, `--esp-md`)
- **Ícones:** Material Icons via CDN
- **Sem frameworks pesados** (sem Bootstrap, sem React/Vue)

---

## 🔄 Protocolo de trabalho com a IA
1. A cada resposta, a IA lê este ROADMAP antes de seguir.
2. A cada arquivo entregue, a IA marca `[x]` e indica o próximo passo.
3. Em caso de dúvida sobre o que foi feito, a IA pergunta — não chuta.
4. O ROADMAP é a **única fonte de verdade** do progresso.
