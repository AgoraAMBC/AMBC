-- ============================================================
--  MIGRATION 012 - DEPENDENTES COM MULTIPLOS ASSOCIADOS
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE IF NOT EXISTS associado_dependente (
    fk_associado    INT NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
    fk_dependente   INT NOT NULL REFERENCES dependente(id_dependente) ON DELETE CASCADE,
    principal       BOOLEAN DEFAULT FALSE,
    criado_em       TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (fk_associado, fk_dependente)
);

INSERT INTO associado_dependente (fk_associado, fk_dependente, principal)
SELECT fk_associado, id_dependente, TRUE
FROM dependente
WHERE fk_associado IS NOT NULL
ON CONFLICT (fk_associado, fk_dependente) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_assoc_dep_associado
    ON associado_dependente(fk_associado);

CREATE INDEX IF NOT EXISTS idx_assoc_dep_dependente
    ON associado_dependente(fk_dependente);

-- @DOWN
-- ============================================================

DROP INDEX IF EXISTS idx_assoc_dep_dependente;
DROP INDEX IF EXISTS idx_assoc_dep_associado;
DROP TABLE IF EXISTS associado_dependente;
