# /analisar-pagina

Analisa uma página do sistema AMBC comparando todos os arquivos frontend com o schema do banco de dados, identificando divergências e gerando um relatório salvo em `docs/`.

## Como usar

```
/analisar-pagina <nome-da-funcionalidade>
```

**Exemplos:**
```
/analisar-pagina cadastro-associado
/analisar-pagina listar-associados
/analisar-pagina usuarios
/analisar-pagina contas-regentes
```

---

## Instruções para o Claude

Ao receber este comando com um argumento `$ARGUMENTS`, execute os seguintes passos **sem alterar nenhum arquivo do projeto**:

### Passo 1 — Localizar os arquivos relevantes

Com base no argumento fornecido, procure os arquivos relacionados à funcionalidade nas seguintes localizações (não todos precisam existir):

**Frontend:**
- `views/**/*<argumento>*.html` — template HTML da página
- `js/paginas/*<argumento>*.js` — lógica da página
- `js/services/*<argumento>*-service.js` — serviço de chamadas HTTP

**Backend:**
- `backend/<entidade>/` — pasta de endpoints PHP (cadastrar.php, listar.php, obter.php, etc.)
- `backend/<entidade>.php` — arquivo PHP monolítico (se existir)

**Banco de dados:**
- `migrations/*.sql` — leia as migrations relevantes para identificar tabelas e colunas
- `database/*.sql` — dump completo se as migrations não forem suficientes

Use Glob e Grep para encontrar os arquivos. Informe ao usuário quais arquivos foram encontrados antes de prosseguir.

### Passo 2 — Ler todos os arquivos encontrados

Leia o conteúdo completo de cada arquivo identificado no Passo 1.

### Passo 3 — Executar a análise comparativa

Compare os arquivos lidos e identifique os seguintes pontos:

1. **Campos do formulário HTML vs colunas do banco**
   - Campos no HTML que não existem no banco
   - Colunas no banco que não estão no formulário
   - Campos obrigatórios no banco (`NOT NULL`) que podem estar faltando no HTML

2. **IDs do HTML vs referências no JS** (`getElementById`, `querySelector`)
   - IDs presentes no HTML que o JS não encontra
   - IDs que o JS procura mas não existem no HTML

3. **Tipos de dados — HTML vs banco**
   - Selects com valores hardcoded em texto quando o banco usa FK (INT)
   - Inputs de texto onde o banco espera um tipo específico (DATE, INT, BOOLEAN)

4. **Nomes de campos — JS (payload) vs banco (colunas)**
   - Chaves enviadas pelo JS que não batem com nomes de colunas
   - Ex: JS envia `fkGenero` mas banco espera `fk_genero`

5. **Nomes de campos — PHP vs banco**
   - Colunas referenciadas no PHP que divergem do schema real
   - Ex: PHP usa `fk_estado_civil` mas banco tem `fk_estadocivil`

6. **Endpoints esperados pelo frontend vs endpoints que existem**
   - Liste todas as URLs chamadas no service JS
   - Verifique se os arquivos PHP correspondentes existem em `backend/`

7. **Tabelas auxiliares e dados de domínio**
   - Selects que deveriam carregar de API mas têm opções hardcoded
   - Tabelas de domínio referenciadas por FK que precisam de endpoint `/listar.php`

8. **Funcionalidades presentes no HTML sem suporte no banco**
   - Seções/campos sem tabela ou coluna correspondente

### Passo 4 — Gerar o relatório

Crie o arquivo `docs/analise-<argumento>.md` com a seguinte estrutura:

```markdown
# Análise: <Nome da Funcionalidade>

**Data da análise:** <data atual>

---

## Arquivos analisados

| Arquivo | Descrição |
|---|---|
| ... | ... |

---

## Divergências encontradas

### 1. Campos HTML vs banco de dados
...

### 2. IDs HTML vs referências JS
...

### 3. Tipos de dados
...

### 4. Nomes de campos (JS payload vs banco)
...

### 5. Nomes de campos (PHP vs banco)
...

### 6. Endpoints — esperados vs existentes
...

### 7. Selects e dados de domínio
...

### 8. Funcionalidades sem suporte no banco
...

---

## Resumo executivo

<Parágrafo curto resumindo o estado geral e o que precisaria ser feito para implementar o backend>

---

## Checklist de implementação

- [ ] Item 1
- [ ] Item 2
- [ ] ...
```

### Passo 5 — Apresentar resultado ao usuário

Após salvar o arquivo, apresente na conversa:
1. Quais arquivos foram analisados
2. Um resumo das principais divergências encontradas (não repita tudo — destaque o que é mais crítico)
3. Informe o caminho do arquivo salvo
