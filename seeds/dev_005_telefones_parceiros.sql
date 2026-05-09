-- ============================================================
--  SEED DEV 005 — TELEFONES DOS PARCEIROS
--  Roda DEPOIS do dev_004_parceiros.sql
-- ============================================================

INSERT INTO telefone_parceiro (fk_parceiro, ddd, numero) VALUES
-- Supermercado (id 1) — dois telefones
(1, '51', '33331000'),
(1, '51', '988881000'),

-- Padaria (id 2)
(2, '51', '33332000'),

-- Farmácia (id 3)
(3, '51', '33333000'),

-- Distribuidora (id 4) — dois telefones
(4, '51', '33334000'),
(4, '51', '988884000'),

-- Brinquedos (id 5)
(5, '51', '33335000'),

-- Maria Aparecida (id 6)
(6, '51', '988886000'),

-- João Batista (id 7) — dois telefones
(7, '51', '988887000'),
(7, '51', '33337000');

-- Loja encerrada (id 8) — sem telefone propositalmente
