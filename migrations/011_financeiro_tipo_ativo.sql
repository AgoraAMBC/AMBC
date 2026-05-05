-- ============================================================
--  MIGRATION 011 — FINANCEIRO: tipo e ativo em contas
-- ============================================================

-- @UP
-- ============================================================

ALTER TABLE conta_regente
    ADD COLUMN tipo  VARCHAR(10) NOT NULL DEFAULT 'receita'
        CHECK (tipo IN ('receita', 'despesa')),
    ADD COLUMN ativo BOOLEAN     NOT NULL DEFAULT TRUE;

ALTER TABLE conta_subordinada
    ADD COLUMN ativo BOOLEAN NOT NULL DEFAULT TRUE;


-- @DOWN
-- ============================================================

ALTER TABLE conta_regente      DROP COLUMN IF EXISTS tipo;
ALTER TABLE conta_regente      DROP COLUMN IF EXISTS ativo;
ALTER TABLE conta_subordinada  DROP COLUMN IF EXISTS ativo;
