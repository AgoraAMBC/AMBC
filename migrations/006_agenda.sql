-- ============================================================
--  MIGRATION 006 — AGENDA DE ATIVIDADES
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE agenda (
    id_agenda               SERIAL          PRIMARY KEY,
    titulo                  VARCHAR(150)    NOT NULL,
    descricao               TEXT,
    observacao              TEXT,

    data_inicio             DATE            NOT NULL,
    hora_inicio             TIME            NOT NULL,
    data_fim                DATE,
    hora_fim                TIME            NOT NULL,

    fk_espaco               INT             REFERENCES espaco(id_espaco) ON DELETE SET NULL,
    fk_status_agenda        INT             NOT NULL REFERENCES status_agenda(id_status_agenda)
                                            DEFAULT 1,

    fk_associado            INT             REFERENCES associado(id_associado) ON DELETE SET NULL,
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro)   ON DELETE SET NULL,
    responsavel_nome        VARCHAR(150),
    responsavel_telefone    VARCHAR(11),
    responsavel_email       VARCHAR(150),

    CONSTRAINT chk_agenda_responsavel CHECK (
        NOT (fk_associado IS NOT NULL AND fk_parceiro IS NOT NULL)
    ),

    capacidade_maxima       INT,
    total_participantes     INT             DEFAULT 0,
    valor_cobrado           NUMERIC(10,2),
    valor_aluguel           NUMERIC(10,2),

    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS agenda;
