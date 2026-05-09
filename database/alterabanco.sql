-- ============================================================
--  BLOCO 1 — MATRÍCULA DO ASSOCIADO
-- ============================================================
 
ALTER TABLE associado
    ADD COLUMN IF NOT EXISTS matricula VARCHAR(20) UNIQUE;
 
 
-- ============================================================
--  BLOCO 2 — TIPO DE TELEFONE
-- ============================================================
 
CREATE TABLE IF NOT EXISTS tipo_telefone (
    id_tipo_telefone    SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
 
INSERT INTO tipo_telefone (id_tipo_telefone, descricao)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'Celular'),
    (2, 'Residencial'),
    (3, 'Comercial'),
    (4, 'WhatsApp'),
    (5, 'Recado'),
    (6, 'Outro')
ON CONFLICT DO NOTHING;
 
ALTER TABLE telefone
    ADD COLUMN IF NOT EXISTS fk_tipo_telefone   INT REFERENCES tipo_telefone(id_tipo_telefone),
    ADD COLUMN IF NOT EXISTS observacao         VARCHAR(100);
 
ALTER TABLE telefone_parceiro
    ADD COLUMN IF NOT EXISTS fk_tipo_telefone   INT REFERENCES tipo_telefone(id_tipo_telefone),
    ADD COLUMN IF NOT EXISTS observacao         VARCHAR(100);
 
 
-- ============================================================
--  BLOCO 3 — TIPO DE LANÇAMENTO FINANCEIRO
-- ============================================================
 
CREATE TABLE IF NOT EXISTS tipo_lancamento (
    id_tipo_lancamento  SERIAL      PRIMARY KEY,
    descricao           VARCHAR(30) NOT NULL UNIQUE
);
 
INSERT INTO tipo_lancamento (id_tipo_lancamento, descricao)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'Anuidade'),
    (2, 'Mensalidade'),
    (3, 'Doação'),
    (4, 'Multa'),
    (5, 'Outro')
ON CONFLICT DO NOTHING;
 
ALTER TABLE conta
    ADD COLUMN IF NOT EXISTS fk_tipo_lancamento INT REFERENCES tipo_lancamento(id_tipo_lancamento);
 
 
-- ============================================================
--  BLOCO 4 — TIPO DE PESSOA E SERVIÇO NO PARCEIRO
-- ============================================================
 
ALTER TABLE parceiro
    ADD COLUMN IF NOT EXISTS tipo_servico VARCHAR(100);
 
ALTER TABLE parceiro
    ADD COLUMN IF NOT EXISTS tipo_pessoa CHAR(2) DEFAULT 'PF';
 
ALTER TABLE parceiro
    ADD CONSTRAINT IF NOT EXISTS chk_tipo_pessoa
    CHECK (tipo_pessoa IN ('PF', 'PJ'));
 
 
-- ============================================================
--  BLOCO 5 — DEPENDENTES COM MÚLTIPLOS ASSOCIADOS
-- ============================================================
 
CREATE TABLE IF NOT EXISTS associado_dependente (
    fk_associado    INT NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
    fk_dependente   INT NOT NULL REFERENCES dependente(id_dependente) ON DELETE CASCADE,
    principal       BOOLEAN DEFAULT FALSE,
    criado_em       TIMESTAMP DEFAULT NOW(),
    atualizado_em   TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (fk_associado, fk_dependente)
);
 
-- Migra vínculos existentes para a nova tabela
INSERT INTO associado_dependente (fk_associado, fk_dependente, principal)
SELECT fk_associado, id_dependente, TRUE
FROM dependente
WHERE fk_associado IS NOT NULL
ON CONFLICT (fk_associado, fk_dependente) DO NOTHING;
 
CREATE INDEX IF NOT EXISTS idx_assoc_dep_associado
    ON associado_dependente(fk_associado);
 
CREATE INDEX IF NOT EXISTS idx_assoc_dep_dependente
    ON associado_dependente(fk_dependente);
 
CREATE TRIGGER trg_ts_assoc_dep
    BEFORE UPDATE ON associado_dependente
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
 
 
-- ============================================================
--  BLOCO 6 — AJUSTES NA TABELA DEPENDENTE
-- ============================================================
 
ALTER TABLE dependente
    DROP CONSTRAINT IF EXISTS dependente_fk_associado_fkey;
 
ALTER TABLE dependente
    ALTER COLUMN fk_associado DROP NOT NULL;
 
ALTER TABLE dependente
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;
 
ALTER TABLE dependente
    ADD CONSTRAINT chk_dependente_menor CHECK (
        data_nascimento > (CURRENT_DATE - INTERVAL '18 years')
    );
 
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
            'Dependente (id: %) deve ter pelo menos um associado vinculado.',
            NEW.id_dependente;
    END IF;
 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE CONSTRAINT TRIGGER trg_dependente_tem_associado
    AFTER INSERT OR UPDATE ON dependente
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_validar_dependente_associado();
 
-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_dependente_ativo
    ON dependente(ativo);
 
CREATE INDEX IF NOT EXISTS idx_dependente_nascimento
    ON dependente(data_nascimento);
 
 