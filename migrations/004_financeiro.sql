-- ============================================================
--  MIGRATION 004 — FINANCEIRO
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE conta_regente (
    id_conta_regente    SERIAL          PRIMARY KEY,
    descricao           VARCHAR(100)    NOT NULL UNIQUE,
    observacao          TEXT,
    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT
);


CREATE TABLE conta_subordinada (
    id_conta_subordinada    SERIAL          PRIMARY KEY,
    fk_conta_regente        INT             NOT NULL REFERENCES conta_regente(id_conta_regente)
                                            ON DELETE RESTRICT,
    descricao               VARCHAR(100)    NOT NULL,
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);


CREATE TABLE conta (
    id_conta                SERIAL          PRIMARY KEY,
    fk_associado            INT             NOT NULL REFERENCES associado(id_associado)
                                            ON DELETE RESTRICT,
    fk_conta_regente        INT             REFERENCES conta_regente(id_conta_regente)
                                            ON DELETE RESTRICT,
    fk_conta_subordinada    INT             REFERENCES conta_subordinada(id_conta_subordinada)
                                            ON DELETE RESTRICT,
    fk_status_conta         INT             NOT NULL REFERENCES status_conta(id_status_conta),
    descricao               VARCHAR(200),
    valor_total             NUMERIC(10,2)   NOT NULL,
    data_lancamento         DATE            NOT NULL DEFAULT CURRENT_DATE,
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);


CREATE TABLE parcela (
    id_parcela              SERIAL          PRIMARY KEY,
    fk_conta                INT             NOT NULL REFERENCES conta(id_conta)
                                            ON DELETE RESTRICT,
    fk_status_conta         INT             NOT NULL REFERENCES status_conta(id_status_conta),
    fk_forma_pagamento      INT             REFERENCES forma_pagamento(id_forma_pagamento),
    numero_parcela          INT             NOT NULL,
    total_parcelas          INT             NOT NULL,
    valor                   NUMERIC(10,2)   NOT NULL,
    data_vencimento         DATE            NOT NULL,
    data_pagamento          DATE,
    valor_pago              NUMERIC(10,2),
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    atualizado_em           TIMESTAMP       DEFAULT NOW()
);


CREATE TABLE doacao (
    id_doacao               SERIAL          PRIMARY KEY,
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro)    ON DELETE RESTRICT,
    fk_associado            INT             REFERENCES associado(id_associado)  ON DELETE RESTRICT,
    nome_externo            VARCHAR(150),
    telefone_externo        VARCHAR(11),

    CONSTRAINT chk_doacao_doador CHECK (
        fk_parceiro  IS NOT NULL OR
        fk_associado IS NOT NULL OR
        nome_externo IS NOT NULL
    ),

    fk_tipo_doacao          INT             NOT NULL REFERENCES tipo_doacao(id_tipo_doacao),
    fk_conta_regente        INT             REFERENCES conta_regente(id_conta_regente),
    fk_conta_subordinada    INT             REFERENCES conta_subordinada(id_conta_subordinada),
    descricao               VARCHAR(200),
    data_doacao             DATE            NOT NULL DEFAULT CURRENT_DATE,
    valor_dinheiro          NUMERIC(10,2),
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);


CREATE TABLE item_doacao (
    id_item_doacao  SERIAL          PRIMARY KEY,
    fk_doacao       INT             NOT NULL REFERENCES doacao(id_doacao) ON DELETE CASCADE,
    descricao       VARCHAR(200)    NOT NULL,
    quantidade      NUMERIC(10,2)   NOT NULL,
    unidade         VARCHAR(20),
    observacao      TEXT,
    criado_em       TIMESTAMP       DEFAULT NOW()
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS item_doacao;
DROP TABLE IF EXISTS doacao;
DROP TABLE IF EXISTS parcela;
DROP TABLE IF EXISTS conta;
DROP TABLE IF EXISTS conta_subordinada;
DROP TABLE IF EXISTS conta_regente;
