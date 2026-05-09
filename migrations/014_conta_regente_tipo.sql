-- ============================================================
 
-- @UP
-- ============================================================
 
ALTER TABLE conta_regente
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(10) DEFAULT 'RECEITA',
    ADD CONSTRAINT chk_conta_regente_tipo
        CHECK (tipo IN ('RECEITA', 'DESPESA'));
 
-- Atualiza o seed de plano de contas para refletir os tipos
-- conforme o que aparece nas telas do sistema
UPDATE conta_regente SET tipo = 'RECEITA'  WHERE descricao = 'Mensalidades';
UPDATE conta_regente SET tipo = 'RECEITA'  WHERE descricao = 'Eventos';
UPDATE conta_regente SET tipo = 'RECEITA'  WHERE descricao = 'Doações';
UPDATE conta_regente SET tipo = 'DESPESA'  WHERE descricao = 'Despesas Administrativas';
UPDATE conta_regente SET tipo = 'DESPESA'  WHERE descricao = 'Outros';
 
 
-- @DOWN
-- ============================================================
 
ALTER TABLE conta_regente
    DROP CONSTRAINT IF EXISTS chk_conta_regente_tipo,
    DROP COLUMN IF EXISTS tipo;
 