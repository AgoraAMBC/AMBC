-- ============================================================
--  MIGRATION 002 — ASSOCIADOS
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE associado (
    id_associado        SERIAL          PRIMARY KEY,
    nome                VARCHAR(150)    NOT NULL,
    data_nascimento     DATE            NOT NULL,

    CONSTRAINT chk_associado_nome_composto CHECK (TRIM(nome) LIKE '% %'),

    cpf_cnpj            VARCHAR(14)     UNIQUE,
    email               VARCHAR(150),
    observacao          TEXT,
    ativo               BOOLEAN         DEFAULT TRUE,

    logradouro          VARCHAR(200),
    numero              VARCHAR(10),
    complemento         VARCHAR(100),
    cep                 CHAR(8),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    uf                  CHAR(2)         REFERENCES uf(sigla),

    fk_estadocivil      INT             REFERENCES estado_civil(id_estadocivil),
    fk_profissao        INT             REFERENCES profissao(id_profissao),
    fk_categoria        INT             REFERENCES categoria(id_categoria),
    fk_status           INT             REFERENCES status_pessoa(id_status),
    fk_genero           INT             REFERENCES genero(id_genero),

    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT
);


CREATE TABLE telefone (
    id_telefone     SERIAL      PRIMARY KEY,
    fk_associado    INT         NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
    ddd             CHAR(2)     NOT NULL,
    numero          VARCHAR(9)  NOT NULL,
    CONSTRAINT chk_telefone_numero CHECK (numero ~ '^[0-9]+$'),
    CONSTRAINT chk_telefone_ddd    CHECK (ddd    ~ '^[0-9]+$'),
    UNIQUE (fk_associado, ddd, numero)
);


CREATE TABLE dependente (
    id_dependente       SERIAL          PRIMARY KEY,
    fk_associado        INT             NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
    nome                VARCHAR(150)    NOT NULL,
    data_nascimento     DATE            NOT NULL,

    CONSTRAINT chk_dependente_nome_composto CHECK (TRIM(nome) LIKE '% %'),

    cpf                 CHAR(11),
    observacao          TEXT,
    fk_parentesco       INT             REFERENCES parentesco(id_parentesco),
    fk_genero           INT             REFERENCES genero(id_genero),

    criado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_em       TIMESTAMP       DEFAULT NOW()
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS dependente;
DROP TABLE IF EXISTS telefone;
DROP TABLE IF EXISTS associado;
