-- ============================================================
 
-- @UP
-- ============================================================
 
-- ----------------------------------------------------------
--  1. MATRÍCULA DO ASSOCIADO
--  Formato: ASS-ANO-SEQUENCIAL ex: ASS-2024-0104
--  Gerada automaticamente pelo sistema PHP
-- ----------------------------------------------------------
ALTER TABLE associado
    ADD COLUMN IF NOT EXISTS matricula VARCHAR(20) UNIQUE;
 
 
-- ----------------------------------------------------------
--  2. TIPO E OBSERVAÇÃO NO TELEFONE DO ASSOCIADO
-- ----------------------------------------------------------
CREATE TABLE tipo_telefone (
    id_tipo_telefone    SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO tipo_telefone (id_tipo_telefone, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Celular'),
    (2, 'Residencial'),
    (3, 'Comercial'),
    (4, 'WhatsApp'),
    (5, 'Outro');
 
ALTER TABLE telefone
    ADD COLUMN IF NOT EXISTS fk_tipo_telefone   INT         REFERENCES tipo_telefone(id_tipo_telefone),
    ADD COLUMN IF NOT EXISTS observacao         VARCHAR(100);
 
ALTER TABLE telefone_parceiro
    ADD COLUMN IF NOT EXISTS fk_tipo_telefone   INT         REFERENCES tipo_telefone(id_tipo_telefone),
    ADD COLUMN IF NOT EXISTS observacao         VARCHAR(100);
 
 
-- ----------------------------------------------------------
--  3. TIPO DE LANÇAMENTO FINANCEIRO
--  Diferencia Anuidade, Mensalidade, Multa, Doação na conta
-- ----------------------------------------------------------
CREATE TABLE tipo_lancamento (
    id_tipo_lancamento  SERIAL      PRIMARY KEY,
    descricao           VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO tipo_lancamento (id_tipo_lancamento, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Anuidade'),
    (2, 'Mensalidade'),
    (3, 'Doação'),
    (4, 'Multa'),
    (5, 'Outro');
 
ALTER TABLE conta
    ADD COLUMN IF NOT EXISTS fk_tipo_lancamento INT REFERENCES tipo_lancamento(id_tipo_lancamento);
 
 
-- ----------------------------------------------------------
--  4. TIPO DE SERVIÇO/PRODUTO DO PARCEIRO
--  Ex: Alimentação, Consultoria, Brinquedos
-- ----------------------------------------------------------
ALTER TABLE parceiro
    ADD COLUMN IF NOT EXISTS tipo_servico VARCHAR(100);
 
 
-- ----------------------------------------------------------
--  5. TIPO DE PESSOA DO PARCEIRO
--  PF = Pessoa Física, PJ = Pessoa Jurídica
-- ----------------------------------------------------------
ALTER TABLE parceiro
    ADD COLUMN IF NOT EXISTS tipo_pessoa CHAR(2) DEFAULT 'PF'
    CONSTRAINT chk_tipo_pessoa CHECK (tipo_pessoa IN ('PF', 'PJ'));
 
 
-- @DOWN
-- ============================================================
 
ALTER TABLE parceiro
    DROP COLUMN IF EXISTS tipo_pessoa,
    DROP COLUMN IF EXISTS tipo_servico;
 
ALTER TABLE conta
    DROP COLUMN IF EXISTS fk_tipo_lancamento;
 
DROP TABLE IF EXISTS tipo_lancamento;
 
ALTER TABLE telefone_parceiro
    DROP COLUMN IF EXISTS fk_tipo_telefone,
    DROP COLUMN IF EXISTS observacao;
 
ALTER TABLE telefone
    DROP COLUMN IF EXISTS fk_tipo_telefone,
    DROP COLUMN IF EXISTS observacao;
 
DROP TABLE IF EXISTS tipo_telefone;
 
ALTER TABLE associado
    DROP COLUMN IF EXISTS matricula;
 