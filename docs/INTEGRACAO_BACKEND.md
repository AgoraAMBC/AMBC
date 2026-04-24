# 🔗 Guia de Integração Backend — AMBC V2

> **Documento destinado aos desenvolvedores backend do projeto.**
> Este documento define o contrato de API entre o frontend (já em desenvolvimento) e o backend (PHP + PostgreSQL).

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Stack Esperada](#-stack-esperada)
3. [Estrutura do Banco](#-estrutura-do-banco)
4. [Endpoints da API](#-endpoints-da-api)
5. [Padrões de Resposta](#-padrões-de-resposta)
6. [CORS](#-cors)
7. [Checklist de Entrega](#-checklist-de-entrega)

---

## 🎯 Visão Geral

O frontend consome a API via `fetch()` (JavaScript). Todas as respostas devem ser em **JSON**.

**URL base esperada:** `http://localhost/ambc/api/` (ajustável)

---

## 🛠️ Stack Esperada

- **Linguagem:** PHP 8+
- **Banco:** PostgreSQL 14+
- **Formato:** REST + JSON
- **Autenticação:** não obrigatória nesta fase inicial (será adicionada depois)

---

## 🗄️ Estrutura do Banco

### Tabela: `associados`

```sql
CREATE TABLE associados (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    email VARCHAR(150),
    telefone VARCHAR(20),
    endereco VARCHAR(255),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- Dados de exemplo para testes
INSERT INTO associados (nome, cpf, email, telefone, endereco) VALUES
('João Silva', '123.456.789-00', 'joao@email.com', '(51) 98888-1111', 'Rua A, 100'),
('Maria Santos', '987.654.321-00', 'maria@email.com', '(51) 98888-2222', 'Rua B, 200'),
('Carlos Oliveira', '456.789.123-00', 'carlos@email.com', '(51) 98888-3333', 'Rua C, 300');
