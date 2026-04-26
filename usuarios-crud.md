# TAREFA — Módulo de Cadastro de Usuários (CRUD)
# Sistema de Gestão AMBC — Associação de Moradores do Bairro Califórnia

## ANTES DE COMEÇAR

Leia todos os arquivos já existentes no projeto antes de criar qualquer coisa.
Entenda a estrutura de pastas, padrão de código e estilo visual já adotado.
Me mostre um resumo do que encontrou e o plano de implementação antes de codar.

---

## CONTEXTO DO PROJETO

Sistema de gestão interno da AMBC. O front-end já foi iniciado neste repositório.
Repositório front-end: https://github.com/AgoraAMBC/AMBC_Testes

O banco de dados é PostgreSQL e já está populado com as tabelas abaixo.
Não recriar tabelas — apenas conectar e usar.

---

## ESTRUTURA DO BANCO DE DADOS (tabelas já existentes)

```sql
-- Perfis disponíveis (já populados: Administrador, Gestor, Visualizador)
CREATE TABLE perfil_usuario (
    id_perfil   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE,
    observacao  TEXT
);

-- Módulos do sistema (já populados: Dashboard, Associados, Parceiros, Financeiro...)
CREATE TABLE modulo_sistema (
    id_modulo   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(50) NOT NULL UNIQUE
);

-- Tabela principal de usuários
CREATE TABLE usuario (
    id_usuario      SERIAL          PRIMARY KEY,
    nome            VARCHAR(150)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    senha_hash      VARCHAR(255),   -- NULL até primeiro acesso
    fk_perfil       INT             NOT NULL REFERENCES perfil_usuario(id_perfil),
    fk_associado    INT             REFERENCES associado(id_associado) ON DELETE SET NULL,
    ativo           BOOLEAN         DEFAULT TRUE,
    primeiro_acesso BOOLEAN         DEFAULT TRUE,
    ultimo_acesso   TIMESTAMP,
    token_reset     VARCHAR(255),
    token_expira_em TIMESTAMP,
    criado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_em   TIMESTAMP       DEFAULT NOW()
);

-- Permissões por módulo para cada usuário
CREATE TABLE permissao_usuario (
    id_permissao    SERIAL  PRIMARY KEY,
    fk_usuario      INT     NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    fk_modulo       INT     NOT NULL REFERENCES modulo_sistema(id_modulo),
    pode_acessar    BOOLEAN DEFAULT FALSE,
    pode_editar     BOOLEAN DEFAULT FALSE,
    UNIQUE (fk_usuario, fk_modulo)
);
```

---

## PARTE 1 — Conexão com o banco de dados

Crie um arquivo de configuração de conexão com PostgreSQL seguindo
o padrão de pastas já existente no projeto.

O arquivo deve:
- Usar variáveis de ambiente via arquivo `.env`:
  ```
  DB_HOST=localhost
  DB_PORT=5432
  DB_NAME=ambc
  DB_USER=seu_usuario
  DB_PASS=sua_senha
  ```
- Exportar uma função ou instância de conexão reutilizável para os demais módulos
- Tratar erros de conexão com mensagem clara no console
- Criar também `.env.example` com as variáveis sem valores preenchidos
- Garantir que `.env` está no `.gitignore`

---

## PARTE 2 — Página de Gestão de Usuários (seção Configurações)

Criar a página seguindo o padrão visual já existente no projeto.
A página deve aparecer no menu lateral dentro de "Configurações".

**Layout:**
- Título: "Gestão de Usuários"
- Botão "Novo Usuário" no canto superior direito
- Tabela com as colunas:
  - Nome
  - E-mail
  - Perfil (Administrador / Gestor / Visualizador)
  - Status — badge verde = Ativo / badge vermelho = Inativo
  - Primeiro acesso — badge (Sim / Não)
  - Último acesso — data formatada em pt-BR
  - Ações — botões Editar e Desativar/Ativar

---

## PARTE 3 — CRUD completo

### CREATE — Cadastrar novo usuário
Modal ou página com formulário contendo:
- **Nome** (obrigatório)
- **E-mail** (obrigatório, único — validar antes de salvar)
- **Perfil** — select carregado da tabela `perfil_usuario`
- **Vincular a associado** — select opcional carregado da tabela `associado`
  (exibir nome + CPF para facilitar identificação)
- **Senha temporária** — campo opcional:
  - Se preenchida: gerar hash com bcrypt (custo mínimo 10) antes de salvar
  - Se vazia: salvar NULL em `senha_hash` e manter `primeiro_acesso = TRUE`
- **Permissões por módulo** — checkboxes gerados dinamicamente
  a partir da tabela `modulo_sistema`:
  - Para cada módulo: "Pode acessar" e "Pode editar"
  - Pré-marcar todos como FALSE por padrão
- Ao salvar: INSERT em `usuario` + INSERT em `permissao_usuario` para cada módulo

### READ — Listar usuários
- Buscar todos com JOIN em `perfil_usuario`
- Paginação de 10 por página
- Campo de busca por nome ou e-mail
- Filtro por perfil e por status (ativo/inativo)
- Nunca retornar `senha_hash` ou `token_reset` nas queries

### UPDATE — Editar usuário
Mesmo formulário do cadastro com as diferenças:
- E-mail: somente leitura (não permitir edição)
- Senha: campo "Redefinir senha" separado e opcional
  - Se preenchido: gerar novo hash e salvar
  - Se vazio: manter senha atual sem alteração
- Sempre atualizar `atualizado_em = NOW()` ao salvar
- Atualizar permissões: DELETE das existentes + INSERT das novas

### DELETE LÓGICO — Desativar/Ativar
- Não apagar o registro — apenas alternar `ativo = TRUE / FALSE`
- Botão na tabela alterna entre "Desativar" e "Ativar" conforme estado atual
- Exibir modal de confirmação antes de executar
- Usuário inativo não pode fazer login no sistema

---

## PARTE 4 — Validações e segurança

- Validar e-mail único antes de cadastrar (query antes do INSERT)
- Senha nunca salva em texto puro — sempre bcrypt, custo mínimo 10
- Nunca expor `senha_hash` ou `token_reset` em nenhuma resposta do back-end
- Validar campos obrigatórios no front-end E no back-end
- Retornar mensagens de erro claras (ex: "E-mail já cadastrado")
- Retornar mensagens de sucesso após cada operação concluída

---

## FLUXO DE TRABALHO

Implemente nesta ordem, aguardando aprovação a cada etapa:

1. Leia o projeto e me mostre o plano antes de codar
2. Conexão com o banco (Parte 1)
3. Listagem de usuários com tabela e filtros (READ)
4. Formulário de cadastro (CREATE)
5. Formulário de edição (UPDATE)
6. Desativar/Ativar (DELETE lógico)
7. Teste as 4 operações e me confirme os resultados

**Comece lendo o projeto e me apresentando o plano.**
