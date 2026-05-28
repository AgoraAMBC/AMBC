# Relatório de Compatibilidade: PostgreSQL → MySQL

**Arquivo analisado:** `database/scripts/20-05.sql`
**Versão PostgreSQL:** 18.3
**Data:** 20/05/2026
**Escopo:** Excluídas tabelas `agenda`, `reserva_espaco`, `horario_espaco`

---

## 1. Functions Encontradas

### `fn_atualizar_timestamp()`

Atualiza automaticamente o campo `atualizado_em = NOW()` em toda operação de UPDATE nas tabelas monitoradas.

**Recursos PL/pgSQL utilizados:** `NOW()`, atribuição em `NEW`

| | |
|---|---|
| **Classificação** | ✅ COMPATÍVEL |
| **Ação** | Substituir `NOW()` por `CURRENT_TIMESTAMP` |

---

### `fn_validar_cpf_cnpj()`

Valida que o CPF (11 dígitos) ou CNPJ (14 dígitos) contém apenas números e tem o comprimento correto. Aborta a operação com exceção em caso de formato inválido.

**Recursos PL/pgSQL utilizados:** `DECLARE`, `LENGTH()`, operador regex `~`, `RAISE EXCEPTION`, `IF/END IF`

| | |
|---|---|
| **Classificação** | 🔴 REESCRITA NECESSÁRIA |
| **Motivo** | `RAISE EXCEPTION` não existe no MySQL; operador `~` não existe no MySQL |
| **Ação** | Converter `RAISE EXCEPTION` para `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '...'`; converter `~` para `REGEXP` |

---

### `fn_validar_parcelas()`

Valida que a soma das parcelas de um parcelamento não ultrapassa o valor total da conta associada. Aborta com exceção se o limite for excedido.

**Recursos PL/pgSQL utilizados:** `DECLARE`, `SELECT INTO`, `SUM()`, `COALESCE()`, `RAISE EXCEPTION`, delimitador `$_$`

| | |
|---|---|
| **Classificação** | 🔴 REESCRITA NECESSÁRIA |
| **Motivo** | Sintaxe PL/pgSQL completa (`DECLARE`, `SELECT INTO`, `IF/END IF`) é incompatível com MySQL |
| **Ação** | Reescrever como MySQL Stored Procedure; converter `RAISE EXCEPTION` para `SIGNAL SQLSTATE` |

---

### `fn_conflito_agenda()` / `fn_conflito_reserva()` / `fn_validar_horario_espaco()`

Validações de conflito de horários em agenda e reserva de espaços.

| | |
|---|---|
| **Classificação** | ⚫ IGNORADAS |
| **Motivo** | Funcionalidades removidas do escopo do projeto |

---

## 2. Triggers Encontrados

> ⚠️ **Atenção:** MySQL não suporta `INSERT OR UPDATE` em um único trigger. Cada trigger com esse evento precisa ser dividido em dois triggers separados (um para INSERT e um para UPDATE).

### Triggers de Timestamp (UPDATE)

| Trigger | Tabela | Evento | Classificação |
|---|---|---|---|
| `trg_ts_associado` | associado | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_assoc_dep` | associado_dependente | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_conta_regente` | conta_regente | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_conta_sub` | conta_subordinada | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_dependente` | dependente | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_doacao` | doacao | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_documento` | documento | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_lancamento` | lancamento | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_parceiro` | parceiro | UPDATE | ✅ COMPATÍVEL |
| `trg_ts_usuario` | usuario | UPDATE | ✅ COMPATÍVEL |

### Triggers de Validação

| Trigger | Tabela | Evento | Classificação |
|---|---|---|---|
| `trg_cpf_cnpj_associado` | associado | INSERT OR UPDATE | 🔴 REESCRITA NECESSÁRIA |
| `trg_cpf_cnpj_parceiro` | parceiro | INSERT OR UPDATE | 🔴 REESCRITA NECESSÁRIA |

---

## 3. Recursos PostgreSQL Sem Equivalente Direto no MySQL

| Recurso PostgreSQL | Onde Aparece | Equivalente MySQL | Impacto |
|---|---|---|---|
| `RAISE EXCEPTION 'msg'` | `fn_validar_cpf_cnpj`, `fn_validar_parcelas` | `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'msg'` | Médio |
| `~` (operador regex) | CHECKs de telefone, CPF/CNPJ | `REGEXP` | Baixo |
| `~~` (operador LIKE interno) | CHECKs de nome composto | `LIKE` | Baixo |
| `= ANY (ARRAY[...])` | CHECKs em 3 tabelas | `IN (...)` | Baixo |
| `SERIAL` / sequences (47 instâncias) | PKs de todas as tabelas | `INT AUTO_INCREMENT` | Médio |
| `JSONB` | `plano_associacao.beneficios` | `JSON` (MySQL 5.7+) | Baixo |
| `GENERATED ALWAYS AS ... STORED` | `documento.indice` | Trigger ou cálculo no PHP | **Alto** |
| `now()` | 12+ defaults de timestamp | `CURRENT_TIMESTAMP` | Baixo |
| `EXTRACT(year FROM CURRENT_DATE)` | `documento.ano` DEFAULT | `YEAR(CURDATE())` | Baixo |
| `(valor)::text` (cast explícito) | Múltiplos CHECKs | `CAST(valor AS CHAR)` ou remover | Baixo |
| Sintaxe PL/pgSQL (`DECLARE`, `SELECT INTO`) | Todas as functions | MySQL Stored Procedure syntax | Médio |
| `INSERT OR UPDATE` em trigger | 2 triggers ativos | Dois triggers separados | Médio |

---

## 4. Tabelas e Incompatibilidades

**Total de 34 tabelas no escopo.** A maioria é totalmente compatível com MySQL.

### Tabelas com Incompatibilidades

| Tabela | Incompatibilidade | Severidade |
|---|---|---|
| `documento` | Coluna `indice` com `GENERATED ALWAYS AS (lpad(numero::text,3,'0') \|\| '/' \|\| ano::text) STORED` | 🔴 Alta |
| `documento` | CHECK com `= ANY (ARRAY['operacional','institucional'])` | 🟡 Baixa |
| `plano_associacao` | Coluna `beneficios JSONB` | 🟡 Baixa |
| `conta_regente` | CHECK com `= ANY (ARRAY['receita','despesa'])` | 🟡 Baixa |
| `parceiro` | CHECK com `= ANY (ARRAY['PF','PJ'])` + operador `~~` | 🟡 Baixa |
| `associado` | CHECK com `~~` para validação de nome composto | 🟡 Baixa |
| `dependente` | CHECK com `~~` para validação de nome composto | 🟡 Baixa |
| `telefone` | CHECK com `~` (regex) em DDD e número | 🟡 Baixa |
| `telefone_parceiro` | CHECK com `~` (regex) em DDD e número | 🟡 Baixa |
| **Demais 25 tabelas** | Nenhuma incompatibilidade | ✅ — |

> **Nota sobre `documento.indice`:** Este é o problema mais crítico da migração. MySQL não suporta expressões com concatenação de strings em colunas geradas. A solução seria criar um trigger `AFTER INSERT / AFTER UPDATE` no MySQL, ou calcular o valor de `indice` no código PHP antes de salvar.

### Itens 100% Compatíveis

- **23 índices BTREE** — compatibilidade total, migração direta
- **56 Foreign Keys** (CASCADE, RESTRICT, SET NULL) — compatibilidade total
- Tipos `DATE`, `TIME`, `BOOLEAN`, `VARCHAR`, `TEXT`, `DECIMAL`, `INT`, `BIGINT` — compatibilidade direta

---

## 5. Conclusão

### A migração é viável?

**Tecnicamente sim. Estrategicamente não recomendada.**

### Esforço Estimado

| Etapa | Horas Estimadas |
|---|---|
| Converter DDL (34 tabelas + índices + FKs) | 6–10h |
| Reescrever functions e triggers ativos | 8–12h |
| Resolver coluna `documento.indice` (trigger ou PHP) | 4–6h |
| Migrar dados (export PostgreSQL → import MySQL) | 2–4h |
| Testes e correções | 10–16h |
| **Total** | **30–48 horas** |

### Por Que Não Vale a Pena

1. A coluna `documento.indice` sozinha já exige reescrita de lógica no banco e possivelmente no PHP
2. As validações de CPF/CNPJ e parcelas em trigger precisam ser reescritas do zero em dialeto MySQL
3. 47 sequences SERIAL → AUTO_INCREMENT: conversão mecânica mas trabalhosa e sujeita a erros
4. Risco real de introduzir bugs nas regras de negócio durante a conversão
5. Esforço de 30–48h sem nenhum ganho funcional para o sistema

### Alternativas Recomendadas

| Opção | Custo Estimado | Esforço de Migração |
|---|---|---|
| VPS Hostinger / DigitalOcean | R$ 40–80/mês | Zero — sistema roda como está |
| Supabase (PostgreSQL gerenciado, free tier) | Grátis até 500 MB | Zero |
| Railway / Render (PostgreSQL gerenciado) | ~US$ 5/mês | Zero |
| **Migrar para MySQL** | Custo do dev | **30–48 horas** |

### Recomendação Final

Hospedar em VPS ou usar um serviço de PostgreSQL gerenciado (Supabase, Railway, Render) é mais rápido, mais barato e sem risco de bugs introduzidos pela migração. A migração para MySQL só faria sentido se houvesse uma restrição absoluta de usar hospedagem compartilhada sem suporte a VPS — o que hoje é raro e cada vez mais caro em relação às alternativas de cloud.
