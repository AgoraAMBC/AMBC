-- ============================================================
--  MIGRATION 008 — INTEGRAÇÃO AGENDA ↔ DOCUMENTO
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE agenda_documento (
    id              SERIAL      PRIMARY KEY,
    fk_agenda       INT         NOT NULL REFERENCES agenda(id_agenda)       ON DELETE CASCADE,
    fk_documento    INT         NOT NULL REFERENCES documento(id_documento)  ON DELETE CASCADE,
    criado_em       TIMESTAMP   DEFAULT NOW(),
    UNIQUE (fk_agenda, fk_documento)
);


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS agenda_documento;
