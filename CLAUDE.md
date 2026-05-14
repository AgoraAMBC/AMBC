# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AMBC V2 is a web-based management platform for a residential neighborhood association (Associação dos Moradores do Bairro Califórnia). It is built with pure vanilla HTML5 + CSS3 + JavaScript ES6+ — no frameworks, no build tools, no npm.

**Current status:** Phase 1 (Foundation) complete. Phase 2 (SPA Navigation/Router) is next.

## Running Locally

There is no build step. Open `index.html` with VS Code Live Server (right-click → "Open with Live Server") and access at `http://localhost:5500`. No compilation or install required.

## Code Architecture

### Layers

```
index.html               ← Single entry point / app shell
css/base/                ← Design foundation (load order matters — see below)
css/layout/              ← App shell grid (sidebar, topbar, main)
js/core/                 ← Router, state, services (not yet implemented)
js/components/           ← Reusable UI components (not yet implemented)
js/pages/                ← Page logic modules (not yet implemented)
js/mock/                 ← Mock data for development (not yet implemented)
views/                   ← HTML templates for each route (not yet implemented)
```

### CSS Load Order (critical — must not be changed)

1. `variaveis.css` — CSS custom properties (must come first)
2. `reset.css`
3. `tipografia.css`
4. `global.css`
5. `app-shell.css`
6. `sidebar.css`
7. `topbar.css`
8. `main.css`

### Design Tokens

All colors, font sizes, spacing, shadows, and border radii are CSS custom properties in `css/base/variaveis.css`. Never hard-code values that have a token equivalent.

### Planned JS Architecture (Phase 2+)

- **Router:** Hash-based (`#painel`, `#cadastro/listar`, etc.) implemented in `js/core/router.js`
- **Pages:** Loaded by the router — either fetched from `views/` or generated dynamically
- **State:** Centralized state management in `js/core/`

## Conventions

### Language

All code, comments, variable names, CSS class names, and file names are in **Portuguese (Brazil)**. Examples: `variaveis.css` (not `variables.css`), `cadastro` (not `register`), `painel` (not `dashboard`).

### CSS Naming

Strict BEM in Portuguese: `.bloco__elemento--modificador`  
Examples: `.sidebar__link`, `.topbar__titulo`, `.app-shell__sidebar--collapsed`

### Git

Conventional Commits: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `chore:`  
Branch flow: feature branches → `develop` → `main`

### Editor

UTF-8, LF line endings, 2-space indentation (4 spaces for PHP and SQL files) — enforced via `.editorconfig`.

## Postura de Colaboração

Seja um parceiro de debate. Seja crítico, ache pontos fracos e pontos cegos. Pare de concordar automaticamente — busque sempre o que é melhor para o projeto, não o que o usuário quer ouvir. Seja direto e duro: se precisar contrariar, contrarie. Se não tiver certeza de algo técnico, diga explicitamente que não tem certeza; recorra à internet apenas nesses casos, não como regra.

## Roadmap Reference

See `docs/ROADMAP.md` for the 6-phase plan and `docs/CHECKPOINT.md` for the latest session notes and what's next. Full functional specification is in `docs/specificacao.md`.
