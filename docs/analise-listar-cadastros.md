# Análise: Listar Todos os Cadastros

**Data da análise:** 2026-05-05

---

## Arquivos analisados

| Arquivo | Descrição |
|---|---|
| `views/cadastro/listar.html` | Template HTML da listagem |
| `js/paginas/cadastro-listar.js` | Lógica da página |
| `js/mocks/cadastros.js` | Mock de dados atual |
| `js/services/associados-service.js` | Serviço de chamadas HTTP |
| `migrations/001_dominio.sql` | Tabelas de domínio |
| `migrations/002_associados.sql` | Tabelas `associado`, `telefone`, `dependente` |
| `migrations/003_parceiros.sql` | Tabela `parceiro` |

---

## Estado atual

A página **funciona completamente com dados mock** — importa `js/mocks/cadastros.js` e nunca chama a API. O `AssociadosService.listar()` existe mas não é usado.

---

## O que o mock retorna (o que o JS espera receber da API)

Cada registro tem: `id`, `nome`, `email`, `cpf`, `tipo`, `status`, `cadastradoEm`

---

## Divergência principal: a listagem mistura 3 tabelas

O filtro de tipo tem: `associado`, `dependente`, `parceiro` — cada um em uma tabela diferente no banco. O backend precisaria fazer uma query unificada das 3. Mas cada tabela tem estrutura diferente:

| Campo esperado | `associado` | `dependente` | `parceiro` |
|---|---|---|---|
| `id` | `id_associado` | `id_dependente` | `id_parceiro` |
| `nome` | `nome` | `nome` | **`nome_razao_social`** ← diferente |
| `email` | `email` | **não existe** ← falta | `email` |
| `cpf` | `cpf_cnpj` | `cpf` (CHAR 11) | `cpf_cnpj` |
| `tipo` | não existe | não existe | não existe |
| `status` | `ativo` (BOOLEAN) | **não tem `ativo`** ← falta | `ativo` (BOOLEAN) |
| `cadastradoEm` | `criado_em` | `criado_em` | `criado_em` |

---

## Problemas específicos por tabela

**Dependente:**
- Não tem coluna `email` — ficaria vazio na listagem
- Não tem coluna `ativo` — impossível filtrar por status sem herdar do associado pai

**Parceiro:**
- O campo nome é `nome_razao_social`, não `nome` — o JS precisaria saber disso ou o backend normaliza

---

## Problema das ações (Editar / Excluir)

O JS usa `data-id="${c.id}"` para editar e excluir, mas IDs podem colidir entre tabelas (associado `id=1` + dependente `id=1` + parceiro `id=1` todos existem). As ações precisam saber o **tipo + id** para chamar o endpoint correto.

A ação "Editar" hoje navega para `#/cadastro/novo-associado` — mas parceiros e dependentes têm telas diferentes (ou ainda não têm).

---

## O que não tem divergência

- Todos os IDs do HTML batem com o que o JS procura ✓
- Paginação, filtros, busca, contador — toda a lógica de UI está correta ✓
- A estrutura do serviço `AssociadosService.listar()` já existe e só precisa ser chamada ✓

---

## Decisão tomada

**Opção B — Só associados por agora:** simplifica a implementação. Os filtros "dependente" e "parceiro" ficam desabilitados até os módulos respectivos ficarem prontos.

---

## Checklist de implementação (Opção B)

- [x] Criar `backend/associados/listar.php` com filtros: `busca`, `status`, `pagina`, `por_pagina`
- [x] Desabilitar opções "Dependente" e "Parceiro" no select de tipo no HTML
- [x] Atualizar `cadastro-listar.js` para usar `AssociadosService.listar()` em vez do mock
- [x] Mapear campos do retorno da API: `id_associado→id`, `cpf_cnpj→cpf`, `criado_em→cadastradoEm`, `ativo→status`
- [x] Implementar ação "Editar": navegar para `#/cadastro/novo-associado?id=<id>`
- [x] Implementar ação "Excluir": chamar `AssociadosService.deletar(id)` com confirmação modal
- [ ] Ação "Visualizar": decidir se abre modal de detalhes ou rota nova (pendente)
