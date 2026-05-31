-- ============================================================
--  SEED DEV 003 — DEPENDENTES
--  Roda DEPOIS do dev_001_associados.sql
--  Cobre: associado sem dependente, com um,
--  com vários e dependentes de gêneros diferentes
-- ============================================================

INSERT INTO dependente (fk_associado, nome, data_nascimento, cpf, fk_parentesco, fk_genero) VALUES

-- Ana Paula (id 1) — dois filhos
(1, 'Lucas Silva Santos',       '2010-05-12', '11122233344', 1, 2),
(1, 'Isabela Silva Santos',     '2013-08-20', '22233344455', 1, 1),

-- Carlos Eduardo (id 2) — um filho
(2, 'Gabriel Oliveira Costa',   '2008-03-15', '33344455566', 1, 2),

-- Roberto (id 4) — neto
(4, 'Pedro Mendes Souza',       '2015-11-30', '44455566677', 4, 2),

-- Marcos (id 6) — dois filhos
(6, 'Sofia Pereira Lima',       '2012-07-04', '55566677788', 1, 1),
(6, 'Matheus Pereira Lima',     '2014-02-18', '66677788899', 1, 2),

-- José Carlos (id 10) — enteado e sobrinho
(10, 'Henrique Barbosa Silva',  '2005-09-22', '77788899900', 2, 2),
(10, 'Clara Barbosa Santos',    '2018-04-10', '88899900011', 3, 1),

-- Antônio Carlos (id 18) — neto não binário
(18, 'João Machado Alves',      '2016-12-05', '99900011122', 4, 2),

-- Luciana pendente (id 11) — filha
(11, 'Marina Gomes Ferreira',   '2011-06-28', '00011122233', 1, 1),

-- Beatriz (id 17) — filho com parentesco "outro"
(17, 'Davi Correia Almeida',    '2019-01-15', '11122233345', 5, 2);
