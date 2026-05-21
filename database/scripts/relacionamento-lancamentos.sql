-- ============================================================
-- TABELAS PARA RELACIONAMENTOS DE LANÇAMENTOS
-- ============================================================

-- Tipos de Lançamento (Anuidade, Mensalidade, Doação, etc.)
CREATE TABLE IF NOT EXISTS tipo_lancamento (
    id_tipo_lancamento SERIAL PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL UNIQUE,
    observacao TEXT,
    criado_em TIMESTAMP DEFAULT NOW()
);

INSERT INTO tipo_lancamento (descricao, observacao) VALUES
    ('Anuidade', 'Taxa anual de associação'),
    ('Mensalidade', 'Taxa mensal de manutenção'),
    ('Doação', 'Doação voluntária'),
    ('Multa por Atraso', 'Multa por atraso no pagamento'),
    ('Manutenção', 'Despesa de manutenção da associação')
ON CONFLICT (descricao) DO NOTHING;

-- Relacionamento: Tipo de Lançamento ↔ Contas + Natureza + Modo
CREATE TABLE IF NOT EXISTS relacionamento_lancamento (
    id_relacionamento SERIAL PRIMARY KEY,

    fk_tipo_lancamento INT NOT NULL REFERENCES tipo_lancamento(id_tipo_lancamento)
        ON DELETE RESTRICT,
    fk_conta_regente INT NOT NULL REFERENCES conta_regente(id_conta_regente)
        ON DELETE RESTRICT,
    fk_conta_subordinada INT NOT NULL REFERENCES conta_subordinada(id_conta_subordinada)
        ON DELETE RESTRICT,

    natureza VARCHAR(20) NOT NULL CHECK (natureza IN ('RECEBER', 'PAGAR')),
    modo VARCHAR(20) NOT NULL CHECK (modo IN ('FIXO', 'SUGERIDO')),

    ativo BOOLEAN DEFAULT true,
    observacao TEXT,

    criado_em TIMESTAMP DEFAULT NOW(),
    criado_por INT,
    atualizado_em TIMESTAMP DEFAULT NOW(),
    atualizado_por INT
);

-- Índice para busca por tipo
CREATE INDEX IF NOT EXISTS idx_relacionamento_tipo ON relacionamento_lancamento(fk_tipo_lancamento);
CREATE INDEX IF NOT EXISTS idx_relacionamento_ativo ON relacionamento_lancamento(ativo);
