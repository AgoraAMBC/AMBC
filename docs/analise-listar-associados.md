# Análise: Listar Associados

**Data da análise:** 2026-05-05

---

## Arquivos analisados

| Arquivo | Descrição |
|---|---|
| `views/cadastro/listar.html` | Template HTML da listagem |
| `js/paginas/cadastro-listar.js` | Lógica da página |
| `js/services/associados-service.js` | Serviço de chamadas HTTP (referência) |
| `migrations/001_dominio.sql` | Tabelas de domínio (status_pessoa, genero, etc.) |
| `migrations/002_associados.sql` | Tabelas `associado`, `telefone`, `dependente` |

---

## Divergências encontradas

### 1. Página usa dados MOCK — nenhuma chamada real à API

O JS importa `'../mocks/cadastros.js'` e usa esse array estático diretamente.
O `AssociadosService.listar()` existe mas **não é chamado em nenhum momento** pela página.

---

### 2. Campos do mock vs colunas reais do banco

| Campo usado no mock/JS | Coluna real no banco | Situação |
|---|---|---|
| `c.id` | `id_associado` | Nome divergente |
| `c.tipo` | **não existe** na tabela `associado` | Veja tópico 3 abaixo |
| `c.status` | `fk_status` (INT, FK) + `ativo` (BOOLEAN) | Divergência de tipo e nome |
| `c.nome` | `nome` | ✓ |
| `c.email` | `email` | ✓ |
| `c.cpf` | `cpf_cnpj` | Nome divergente |
| `c.cadastradoEm` | `criado_em` | Nome divergente (camelCase vs snake_case) |

---

### 3. Filtro por "Tipo" — dados de tabelas diferentes

O HTML tem filtro com as opções: `associado`, `dependente`, `parceiro`.
Cada um vem de uma tabela diferente no banco:

| Tipo | Tabela no banco |
|---|---|
| `associado` | `associado` |
| `dependente` | `dependente` (filho de `associado`) |
| `parceiro` | `parceiro` (migration 003) |

A tabela `associado` **não tem coluna `tipo`** — esse campo precisaria ser gerado pelo backend ao unificar os resultados das três tabelas em uma única listagem.

**Decisão necessária:** o backend vai fazer uma query `UNION` das três tabelas, ou a página vai fazer chamadas separadas e mesclar no frontend?

---

### 4. Campo "Status" — texto vs FK no banco

O HTML filtra por `"ativo"` / `"inativo"` (texto), mas o banco tem dois campos:
- `ativo` BOOLEAN — indica se o registro está ativo
- `fk_status` INT — FK para `status_pessoa` (1=Ativo, 2=Pendente, 3=Inativo)

O backend precisará mapear o filtro de texto para a coluna correta.
Sugestão: usar `ativo = TRUE/FALSE` para o filtro da listagem (mais simples).

---

### 5. Ações de linha — todas em construção

| Ação | Situação atual |
|---|---|
| Visualizar | Exibe toast "em construção" |
| Editar | Exibe toast "em construção" |
| Excluir | Remove do mock (memória apenas) — não chama API |

Nenhuma ação está conectada ao backend real.

---

### 6. Endpoint esperado pelo service vs o que existe

O `AssociadosService.listar()` chama `GET /associados/listar.php`.
O arquivo `backend/associados/listar.php` **não existe** — o backend do Fabio está em `backend/associados.php` (monolítico) e não é chamado pela página.

---

### 7. IDs HTML vs referências JS

Todos os IDs estão corretos — nenhuma divergência neste ponto.

| JS referencia | HTML tem | Situação |
|---|---|---|
| `input-busca` | `id="input-busca"` | ✓ |
| `filtro-tipo` | `id="filtro-tipo"` | ✓ |
| `filtro-status` | `id="filtro-status"` | ✓ |
| `tbody-cadastros` | `id="tbody-cadastros"` | ✓ |
| `contador-registros` | `id="contador-registros"` | ✓ |
| `paginacao` | `id="paginacao"` | ✓ |
| `estado-vazio` | `id="estado-vazio"` | ✓ |
| `btn-novo-cadastro` | `id="btn-novo-cadastro"` | ✓ |

---

## Resumo executivo

A página de listagem está funcionando visualmente com dados mock mas **completamente desconectada do banco**. A estrutura HTML e o JS estão bem organizados — os IDs batem, a paginação e os filtros funcionam. O principal trabalho para conectar ao backend real é:

1. Decidir se a listagem vai unificar `associado + dependente + parceiro` ou mostrar só associados por enquanto
2. Criar o endpoint `backend/associados/listar.php` com suporte a filtros (`busca`, `tipo`, `status`, `pagina`)
3. Substituir o import do mock por chamada real ao `AssociadosService.listar()`
4. Implementar as ações de editar e excluir (hoje são stubs)

---

## Checklist de implementação

- [ ] Decidir escopo da listagem: apenas associados ou unificada (associado + dependente + parceiro)
- [ ] Criar `backend/associados/listar.php` com filtros: `busca`, `status`, `pagina`, `por_pagina`
- [ ] Se unificada: criar query com UNION das tabelas `associado`, `dependente`, `parceiro` adicionando coluna `tipo`
- [ ] Atualizar `cadastro-listar.js` para usar `AssociadosService.listar()` em vez do mock
- [ ] Mapear campos do retorno da API (`id_associado`, `cpf_cnpj`, `criado_em`) para o que o JS espera — ou ajustar o JS
- [ ] Implementar ação "Editar": navegar para `#/cadastro/novo-associado?id=<id>`
- [ ] Implementar ação "Excluir": chamar `AssociadosService.deletar(id)` com confirmação
- [ ] Implementar ação "Visualizar": decidir se abre modal de detalhes ou rota nova
- [ ] Ajustar filtro de status para usar `ativo=1/0` ao consultar o banco
