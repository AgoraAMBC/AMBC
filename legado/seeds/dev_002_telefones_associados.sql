-- ============================================================
--  SEED DEV 002 — TELEFONES DOS ASSOCIADOS
--  Roda DEPOIS do dev_001_associados.sql
--  Cobre: associado com um telefone, com vários,
--  e associado sem telefone (Sandra, id 15)
-- ============================================================

INSERT INTO telefone (fk_associado, ddd, numero) VALUES
-- Ana Paula (id 1) — dois telefones
(1, '51', '999991111'),
(1, '51', '33331111'),

-- Carlos Eduardo (id 2) — um telefone
(2, '51', '999992222'),

-- Fernanda (id 3) — um telefone
(3, '51', '999993333'),

-- Roberto (id 4) — dois telefones
(4, '51', '999994444'),
(4, '51', '33334444'),

-- Patricia (id 5)
(5, '51', '999995555'),

-- Marcos (id 6)
(6, '51', '999996666'),

-- Juliana (id 7)
(7, '51', '999997777'),

-- Diego (id 8)
(8, '51', '999998888'),

-- Camila (id 9)
(9, '51', '999999999'),

-- José Carlos (id 10) — três telefones
(10, '51', '999990000'),
(10, '51', '33330000'),
(10, '51', '988880000'),

-- Luciana pendente (id 11)
(11, '51', '988881111'),

-- Rafael pendente (id 12)
(12, '51', '988882222'),

-- Mariana inativa (id 13)
(13, '51', '988883333'),

-- Thiago inativo (id 14)
(14, '51', '988884444'),

-- Sandra sem email (id 15) — só telefone
(15, '51', '988885555'),

-- Alex (id 16)
(16, '51', '988886666'),

-- Beatriz de Floripa (id 17)
(17, '48', '988887777'),

-- Antônio Carlos (id 18)
(18, '51', '988888888');
