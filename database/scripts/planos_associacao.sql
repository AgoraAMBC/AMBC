-- ============================================================
--  MIGRATION — Planos de Associação
--  Execute uma única vez no banco de dados AMBC
-- ============================================================

CREATE TABLE IF NOT EXISTS plano_associacao (
    id_plano   SERIAL       PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL,
    preco      NUMERIC(10,2) NOT NULL DEFAULT 0,
    periodo    VARCHAR(20)  NOT NULL DEFAULT 'anuidade',
    beneficios JSONB        NOT NULL DEFAULT '[]',
    ativo      BOOLEAN      NOT NULL DEFAULT TRUE,
    ordem      INTEGER      NOT NULL DEFAULT 0,
    criado_em  TIMESTAMP    DEFAULT NOW()
);

-- Plano padrão inicial
INSERT INTO plano_associacao (nome, preco, periodo, beneficios, ativo, ordem) VALUES (
    'Associado Padrão',
    60.00,
    'anuidade',
    '[
        {"descricao": "Acesso à sede social",    "incluido": true},
        {"descricao": "Até 3 dependentes",        "incluido": true},
        {"descricao": "Participação em eventos",  "incluido": true},
        {"descricao": "Sala de reuniões",         "incluido": false}
    ]',
    TRUE,
    1
) ON CONFLICT DO NOTHING;
