-- ============================================================
 
-- @UP
-- ============================================================
 
-- ----------------------------------------------------------
--  1. REMOVE fk_associado NOT NULL da tabela dependente
--  O vínculo passa a ser feito exclusivamente pela
--  tabela associado_dependente (migration 012)
-- ----------------------------------------------------------
ALTER TABLE dependente
    DROP CONSTRAINT IF EXISTS dependente_fk_associado_fkey,
    ALTER COLUMN fk_associado DROP NOT NULL;
 
 
-- ----------------------------------------------------------
--  2. SOFT DELETE — ativo/inativo no dependente
-- ----------------------------------------------------------
ALTER TABLE dependente
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;
 
 

ALTER TABLE dependente
    ADD CONSTRAINT chk_dependente_menor CHECK (
        data_nascimento > (CURRENT_DATE - INTERVAL '18 years')
    );
 
 
-- ----------------------------------------------------------
--  4. TRIGGER DEFERRED
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_validar_dependente_associado()
RETURNS TRIGGER AS $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*) INTO total
    FROM associado_dependente
    WHERE fk_dependente = NEW.id_dependente;
 
    IF total = 0 THEN
        RAISE EXCEPTION
            'Dependente (id: %) deve ter pelo menos um associado vinculado na tabela associado_dependente.',
            NEW.id_dependente;
    END IF;
 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
-- DEFERRABLE INITIALLY DEFERRED = só valida no COMMIT, não no INSERT
CREATE CONSTRAINT TRIGGER trg_dependente_tem_associado
    AFTER INSERT OR UPDATE ON dependente
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_validar_dependente_associado();
 
 
-- ----------------------------------------------------------
--  5. TRIGGER DE TIMESTAMP NO associado_dependente
-- ----------------------------------------------------------
ALTER TABLE associado_dependente
    ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMP DEFAULT NOW();
 
CREATE TRIGGER trg_ts_assoc_dep
    BEFORE UPDATE ON associado_dependente
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
 
 
-- ----------------------------------------------------------
--  6. ÍNDICES DE PERFORMANCE
-- ----------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_dependente_ativo
    ON dependente(ativo);
 
CREATE INDEX IF NOT EXISTS idx_dependente_nascimento
    ON dependente(data_nascimento);
 
 
-- @DOWN
-- ============================================================
 
DROP INDEX IF EXISTS idx_dependente_nascimento;
DROP INDEX IF EXISTS idx_dependente_ativo;
 
DROP TRIGGER IF EXISTS trg_ts_assoc_dep ON associado_dependente;
 
ALTER TABLE associado_dependente
    DROP COLUMN IF EXISTS atualizado_em;
 
DROP TRIGGER IF EXISTS trg_dependente_tem_associado ON dependente;
DROP FUNCTION IF EXISTS fn_validar_dependente_associado();
 
ALTER TABLE dependente
    DROP CONSTRAINT IF EXISTS chk_dependente_menor,
    DROP COLUMN IF EXISTS ativo;
 
ALTER TABLE dependente
    ALTER COLUMN fk_associado SET NOT NULL;
 