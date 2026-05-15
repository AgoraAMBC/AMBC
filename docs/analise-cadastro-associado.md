# Análise: Tela de Cadastro de Associado

**Data da análise:** 2026-05-05

---

## Pergunta original

> "Poderia analisar para mim a página de cadastrar associado e o banco de dados para ver se tem alguma divergência e se seria possível implementarmos já o back end de cadastro de associados?"

---

## Arquivos analisados

| Arquivo | Descrição |
|---|---|
| `views/cadastro/novo-associado.html` | Formulário de cadastro (HTML) |
| `js/paginas/cadastro-novo-associado.js` | Lógica da página |
| `js/services/associados-service.js` | Camada de serviço (chamadas HTTP) |
| `js/services/associados-auxiliares-service.js` | Serviço para dados auxiliares (selects) |
| `backend/associados.php` | Backend monolítico do Fabio |
| `migrations/001_dominio.sql` | Tabelas de domínio (genero, estado_civil, etc.) |
| `migrations/002_associados.sql` | Tabela `associado`, `telefone`, `dependente` |

---

## Análise 1 — Divergências encontradas

### 1. Colunas que existem no banco mas não estão na página HTML

| Campo no banco | Situação no HTML |
|---|---|
| `fk_status` | Ausente — JS espera `id="fk_status"` mas HTML não tem esse campo |
| `data_entrada` | Ausente — JS espera `id="data_entrada"` mas HTML não tem |
| `criado_por` / `atualizado_por` | OK — gerados no backend |

---

### 2. Colunas que a página/JS esperam mas não existem no banco (migration 002)

| Campo esperado | Situação |
|---|---|
| `matricula` | **Não está na tabela** `associado` — JS e PHP do Fabio assumem que existe |
| `data_entrada` | **Não está na tabela** |
| `data_cadastro` | `associados.php` do Fabio insere `data_cadastro` mas o banco tem `criado_em` |
| `rg` | HTML tem campo RG mas **não existe** no banco |

---

### 3. Divergências de nomes de colunas (PHP do Fabio vs banco real)

| PHP do Fabio usa | Banco tem |
|---|---|
| `cpf` | `cpf_cnpj` |
| `fk_estado_civil` | `fk_estadocivil` |

---

### 4. HTML usa valores texto, banco usa chaves estrangeiras (FK inteiros)

| Campo HTML | HTML envia | Banco espera |
|---|---|---|
| `categoria` | `"fundador"`, `"honorario"` | `fk_categoria` = 1, 2, 3 (INT) |
| `Genero` | `"masculino"`, `"feminino"` | `fk_genero` = 1, 2, 3 (INT) |
| `estadoCivil` | `"solteiro"`, `"casado"` | `fk_estadocivil` = 1, 2 (INT) |
| `profissao` | texto livre | `fk_profissao` (INT, FK) |
| `statusFinanceiro` | `"ativo"`, `"pendente"` | `fk_status` (INT, FK) |

---

### 5. IDs do HTML não batem com os que o JS procura (mapearRefs)

| JS procura `getElementById(...)` | HTML tem `id=` |
|---|---|
| `"form-associado"` | `"form-novo-associado"` ← **CRÍTICO**, form não recebe eventos |
| `"cpf_cnpj"` | `"cpf"` |
| `"fk_genero"` | `"Genero"` |
| `"fk_estadocivil"` | `"estado-civil"` |
| `"fk_profissao"` | `"profissao"` (input text, não select) |
| `"fk_categoria"` | `"categoria"` |
| `"fk_status"` | não existe no HTML |
| `"data_entrada"` | não existe no HTML |
| `"observacao"` | `"observacoes-gerais"` |

---

### 6. Seção de Telefones — tabela `telefone` no banco

| HTML mostra colunas | Banco tem colunas |
|---|---|
| Tipo, Número, Observação | `ddd`, `numero` — **sem tipo e sem observação** |

---

### 7. Seção "Informações Financeiras" — sem tabela correspondente

Os campos `categoria-financeira`, `valor-mensalidade`, `vencimento`, `status-financeiro`, `observacoes-financeiras` aparecem no HTML mas não existem na tabela `associado` nem há relação clara com a tabela de lançamentos. Provavelmente pertencem ao módulo financeiro e não deveriam estar nesta tela de cadastro.

---

### 8. Endpoints esperados pelo frontend vs backend do Fabio

O frontend chama endpoints separados por arquivo:

- `GET /associados/proxima-matricula.php`
- `POST /associados/cadastrar.php`
- `GET /associados/listar.php`
- `GET /associados/obter.php?id=`
- `GET /generos/listar.php`
- `GET /estados-civis/listar.php`
- `GET /profissoes/listar.php`
- `GET /status-pessoa/listar.php`
- `GET /situacoes-imovel/listar.php`

O Fabio implementou um único `backend/associados.php` com roteamento interno — **nenhum dos endpoints esperados existe**.

---

## Análise 2 — Escopo decidido para implementação futura

**Decisão do usuário:** Implementar apenas as 2 primeiras seções do formulário por enquanto.

### Seções a implementar
- Dados Pessoais
- Endereço

### Seções removidas por ora
- Telefones (divergências no banco, complexidade extra)
- Dependentes
- Informações Financeiras (não pertence à tabela `associado`)

### Regras de negócio definidas
- **Status**: ao cadastrar, sempre "Ativo" (`fk_status = 1`) — sem campo para o usuário
- **Data de entrada**: preenchida automaticamente com a data do cadastro — sem campo para o usuário

---

## O que será necessário quando implementar

1. **Nova migration** adicionando `matricula` e `data_entrada` à tabela `associado`
2. **Remover campo RG** do HTML (não existe no banco — mais limpo que criar migration)
3. **Corrigir HTML** — alinhar todos os `id=` com o que o JS espera em `mapearRefs()`
4. **Converter selects** de valores hardcoded para carregar via API (genero, estado_civil, categoria, profissao)
5. **Criar endpoints separados** no padrão do projeto:
   - `backend/associados/cadastrar.php`
   - `backend/associados/obter.php`
   - `backend/associados/listar.php`
   - `backend/associados/proxima-matricula.php`
   - `backend/generos/listar.php`
   - `backend/estados-civis/listar.php`
   - `backend/profissoes/listar.php`
   - `backend/status-pessoa/listar.php`
6. **Corrigir PHP** do Fabio: `cpf` → `cpf_cnpj`, `fk_estado_civil` → `fk_estadocivil`, `data_cadastro` → `criado_em`
7. **Reescrever JS** alinhado ao HTML corrigido
