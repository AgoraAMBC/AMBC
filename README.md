# AMBC — Sistema de Gestão da Associação

Plataforma web para gestão da **Associação dos Moradores do Bairro Califórnia (AMBC)** — associados, dependentes, parceiros, financeiro e configurações administrativas.

---

## Histórico de repositórios

| Versão | Repositório | Situação |
|--------|------------|----------|
| Protótipo / testes | [AgoraAMBC/AMBC\_Testes](https://github.com/AgoraAMBC/AMBC_Testes) | Arquivado |
| V2 (desenvolvimento) | [fabiomachado1212-lgtm/ambc-v2](https://github.com/fabiomachado1212-lgtm/ambc-v2) | Arquivado |
| **V2 — versão final** | **[AgoraAMBC/AMBC](https://github.com/AgoraAMBC/AMBC)** | ✅ Ativo |

---

## Stack

**Frontend**
- HTML5 + CSS3 + JavaScript Vanilla ES6+
- Arquitetura SPA com hash routing (`#/rota`)
- Material Icons (Google CDN)

**Backend**
- PHP 8.x — API REST (JSON)
- MySQL 8.x
- Servidor embutido PHP para desenvolvimento

---

## Estrutura do projeto

```
AMBC/
├── index.html              # Entrada da SPA / app shell
├── login.html              # Tela de login
├── router.php              # Roteador PHP para o servidor de desenvolvimento
├── .env                    # Variáveis de ambiente (não versionado)
├── .env.example            # Modelo do .env
│
├── css/
│   ├── base/               # Variáveis, reset, tipografia, global
│   ├── layout/             # App shell, sidebar, topbar, main
│   ├── componentes/        # Botões, cards, modais, toasts, etc.
│   └── paginas/            # Estilos específicos por tela
│
├── js/
│   ├── core/               # Router, sessão, estado global
│   ├── layout/             # Sidebar, topbar
│   ├── componentes/        # Toast, modal, etc.
│   ├── paginas/            # Lógica de cada tela
│   └── services/           # Comunicação com a API
│
├── views/                  # Fragmentos HTML por módulo
│   ├── cadastro/
│   ├── financeiro/
│   └── configuracoes/
│
├── backend/                # API PHP
│   ├── config/             # Conexão com banco, helpers
│   ├── auth/               # Login, logout, sessão
│   ├── associados/
│   ├── financeiro/
│   └── ...
│
├── docs/                   # Documentação técnica e diagramas
└── local/                  # Scripts utilitários para desenvolvimento local
```

---

## Como executar localmente

### Pré-requisitos

- [PHP 8.1+](https://www.php.net/downloads) — para o backend
- [MySQL 8.0+](https://dev.mysql.com/downloads/) — banco de dados
- [VS Code](https://code.visualstudio.com/) + extensão [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) — para o frontend

### 1. Clone o repositório

```bash
git clone https://github.com/AgoraAMBC/AMBC.git
cd AMBC
```

### 2. Configure o banco de dados

Crie um banco MySQL e importe o schema (estrutura + dados de referência, sem dados pessoais):

```bash
mysql -u root -p -e "CREATE DATABASE ambc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p ambc < docs/schema.sql
```

Ou pelo **phpMyAdmin**: crie o banco `ambc` → aba **SQL** → cole o conteúdo de `docs/schema.sql` → Execute.

O script cria automaticamente um usuário administrador inicial:

| Campo | Valor |
|-------|-------|
| Login | `admin@ambc.com` |
| Senha | `admin123` |

> **Altere a senha após o primeiro acesso.**

### 3. Configure as variáveis de ambiente

Copie o arquivo de exemplo e preencha com seus dados:

```bash
cp .env.example .env
```

Edite o `.env`:

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=ambc
DB_USER=root
DB_PASS=sua_senha
DB_CHARSET=utf8mb4

SESSION_NAME=ambc_session
SESSION_LIFETIME=28800
```

### 4. Inicie o backend PHP

No terminal, na raiz do projeto:

```bash
php -S localhost:8081 router.php
```

Ou no Windows, execute o atalho:

```
local/iniciar-backend.bat
```

O backend ficará disponível em `http://localhost:8081`.

### 5. Inicie o frontend

No VS Code, clique com o botão direito em `index.html` → **Open with Live Server**.

O frontend abrirá em `http://localhost:5500`.

> **Por que portas diferentes?**
> O Live Server (`:5500`) serve os arquivos estáticos e o PHP (`:8081`) responde as chamadas de API. As requisições do frontend já apontam para `:8081` automaticamente.

### 6. Acesse o sistema

Abra `http://localhost:5500/login.html` e entre com as credenciais configuradas no banco.

---

## Fluxo de trabalho (Git)

- `main` — versão estável, espelha a produção
- Commits seguem o padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

| Prefixo | Quando usar |
|---------|-------------|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `style:` | CSS, formatação visual |
| `refactor:` | Refatoração sem mudar comportamento |
| `docs:` | Documentação |
| `chore:` | Configurações, scripts auxiliares |

---

## Documentação

Os arquivos na pasta `docs/` incluem:

- `diagrama-casos-de-uso.pdf` — Diagrama UML de casos de uso
- `modelo-conceitual.pdf` — Modelo conceitual do banco de dados (ER)
- `ROADMAP.md` — Plano de desenvolvimento em fases
- `specificacao.md` — Especificação funcional completa

---

## Licença

Uso interno — Associação dos Moradores do Bairro Califórnia.
