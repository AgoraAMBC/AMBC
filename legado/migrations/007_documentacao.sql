-- ============================================================
--  MIGRATION 007 — DOCUMENTAÇÃO
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE documento (
    id_documento        SERIAL          PRIMARY KEY,

    numero              INT             NOT NULL,
    ano                 INT             NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    indice              VARCHAR(20)     GENERATED ALWAYS AS
                        (LPAD(numero::TEXT, 3, '0') || '/' || ano::TEXT) STORED,

    fk_tipo_documento   INT             REFERENCES tipo_documento(id_tipo_documento),
    tipo_livre          VARCHAR(50),

    CONSTRAINT chk_documento_tipo CHECK (
        (fk_tipo_documento IS NOT NULL AND tipo_livre IS NULL) OR
        (fk_tipo_documento IS NULL     AND tipo_livre IS NOT NULL)
    ),

    assunto             VARCHAR(200)    NOT NULL,
    data_documento      DATE            NOT NULL DEFAULT CURRENT_DATE,
    conteudo            TEXT,
    arquivo_path        VARCHAR(500),
    observacao          TEXT,

    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT,

    UNIQUE (numero, ano)
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS documento;
