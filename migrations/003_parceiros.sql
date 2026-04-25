-- ============================================================
--  MIGRATION 003 — PARCEIROS
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE parceiro (
    id_parceiro         SERIAL          PRIMARY KEY,
    nome_razao_social   VARCHAR(200)    NOT NULL,
    cpf_cnpj            VARCHAR(14)     NOT NULL UNIQUE,

    CONSTRAINT chk_parceiro_nome_composto CHECK (TRIM(nome_razao_social) LIKE '% %'),

    email               VARCHAR(150),
    ativo               BOOLEAN         DEFAULT TRUE,

    logradouro          VARCHAR(200),
    numero              VARCHAR(10),
    complemento         VARCHAR(100),
    cep                 CHAR(8),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    uf                  CHAR(2)         REFERENCES uf(sigla),

    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT
);


CREATE TABLE telefone_parceiro (
    id_telefone_parceiro    SERIAL      PRIMARY KEY,
    fk_parceiro             INT         NOT NULL REFERENCES parceiro(id_parceiro) ON DELETE CASCADE,
    ddd                     CHAR(2)     NOT NULL,
    numero                  VARCHAR(9)  NOT NULL,
    CONSTRAINT chk_tel_parceiro_numero CHECK (numero ~ '^[0-9]+$'),
    CONSTRAINT chk_tel_parceiro_ddd    CHECK (ddd    ~ '^[0-9]+$'),
    UNIQUE (fk_parceiro, ddd, numero)
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS telefone_parceiro;
DROP TABLE IF EXISTS parceiro;
