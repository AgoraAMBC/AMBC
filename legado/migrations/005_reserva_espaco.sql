-- ============================================================
--  MIGRATION 005 — RESERVA DE ESPAÇO
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE espaco (
    id_espaco       SERIAL          PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL UNIQUE,
    descricao       TEXT,
    capacidade      INT,
    observacao      TEXT,
    ativo           BOOLEAN         DEFAULT TRUE,
    criado_em       TIMESTAMP       DEFAULT NOW(),
    criado_por      INT,
    atualizado_em   TIMESTAMP       DEFAULT NOW(),
    atualizado_por  INT
);


CREATE TABLE horario_espaco (
    id_horario_espaco   SERIAL          PRIMARY KEY,
    fk_espaco           INT             NOT NULL REFERENCES espaco(id_espaco) ON DELETE CASCADE,
    dia_semana          VARCHAR(15)     NOT NULL,
    hora_inicio         TIME            NOT NULL,
    hora_fim            TIME            NOT NULL,
    observacao          TEXT
);


CREATE TABLE reserva_espaco (
    id_reserva              SERIAL          PRIMARY KEY,
    fk_espaco               INT             NOT NULL REFERENCES espaco(id_espaco)
                                            ON DELETE RESTRICT,
    fk_horario_espaco       INT             NOT NULL REFERENCES horario_espaco(id_horario_espaco)
                                            ON DELETE RESTRICT,
    fk_status_reserva       INT             NOT NULL REFERENCES status_reserva(id_status_reserva)
                                            DEFAULT 1,
    data_reserva            DATE            NOT NULL,

    fk_associado            INT             REFERENCES associado(id_associado)  ON DELETE RESTRICT,
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro)    ON DELETE RESTRICT,
    nome_externo            VARCHAR(150),
    telefone_externo        VARCHAR(11),
    email_externo           VARCHAR(150),

    CONSTRAINT chk_reserva_responsavel CHECK (
        (fk_associado IS NOT NULL AND fk_parceiro IS NULL     AND nome_externo IS NULL) OR
        (fk_parceiro  IS NOT NULL AND fk_associado IS NULL    AND nome_externo IS NULL) OR
        (nome_externo IS NOT NULL AND fk_associado IS NULL    AND fk_parceiro  IS NULL)
    ),

    valor_cobrado           NUMERIC(10,2),
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS reserva_espaco;
DROP TABLE IF EXISTS horario_espaco;
DROP TABLE IF EXISTS espaco;
