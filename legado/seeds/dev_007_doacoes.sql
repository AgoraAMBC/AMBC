-- ============================================================
--  SEED DEV 007 — DOAÇÕES
--  Roda DEPOIS dos seeds de parceiros e associados
--  Cobre: doação em dinheiro, itens, de parceiro,
--  de associado e de externo
-- ============================================================

-- ----------------------------------------------------------
--  DOAÇÕES
-- ----------------------------------------------------------

INSERT INTO doacao (
    fk_parceiro, fk_associado, nome_externo, telefone_externo,
    fk_tipo_doacao, fk_conta_regente, fk_conta_subordinada,
    descricao, data_doacao, valor_dinheiro
) VALUES

-- Supermercado (parceiro id 1) — alimentos
(1, NULL, NULL, NULL,
 2, 3, 8, 'Doação de alimentos para festa junina',
 '2024-01-15', NULL),

-- Padaria (parceiro id 2) — alimentos
(2, NULL, NULL, NULL,
 2, 3, 8, 'Doação de pães e bolos',
 '2024-01-20', NULL),

-- Distribuidora (parceiro id 4) — bebidas
(4, NULL, NULL, NULL,
 2, 3, 8, 'Doação de bebidas para evento',
 '2024-02-01', NULL),

-- Brinquedos (parceiro id 5) — brinquedos
(5, NULL, NULL, NULL,
 3, 3, 9, 'Doação de brinquedos para natal solidário',
 '2024-02-10', NULL),

-- Maria Aparecida (parceiro id 6) — dinheiro
(6, NULL, NULL, NULL,
 1, 3, 7, 'Doação em dinheiro',
 '2024-02-15', 500.00),

-- João Batista (parceiro id 7) — dinheiro
(7, NULL, NULL, NULL,
 1, 3, 7, 'Contribuição para eventos',
 '2024-03-01', 250.00),

-- Ana Paula (associado id 1) — dinheiro
(NULL, 1, NULL, NULL,
 1, 3, 7, 'Doação voluntária da associada',
 '2024-03-05', 100.00),

-- Roberto (associado id 4) — outros itens
(NULL, 4, NULL, NULL,
 4, 3, 8, 'Doação de cadeiras e mesas',
 '2024-03-10', NULL),

-- Doador externo — dinheiro
(NULL, NULL, 'Pedro Henrique Azevedo', '51988880001',
 1, 3, 7, 'Doação anônima em dinheiro',
 '2024-03-15', 200.00),

-- Doador externo — brinquedos
(NULL, NULL, 'Empresa Solidária XPTO', '51988880002',
 3, 3, 9, 'Doação de brinquedos para crianças',
 '2024-03-20', NULL);


-- ----------------------------------------------------------
--  ITENS DAS DOAÇÕES
-- ----------------------------------------------------------

INSERT INTO item_doacao (fk_doacao, descricao, quantidade, unidade) VALUES

-- Doação 1 — Supermercado alimentos
(1, 'Arroz 5kg',            20, 'pacote'),
(1, 'Feijão 1kg',           20, 'pacote'),
(1, 'Óleo de soja 900ml',   10, 'garrafa'),
(1, 'Macarrão 500g',        30, 'pacote'),

-- Doação 2 — Padaria
(2, 'Pão francês',         100, 'unidade'),
(2, 'Bolo de chocolate',     5, 'unidade'),

-- Doação 3 — Distribuidora bebidas
(3, 'Refrigerante 2L',      24, 'garrafa'),
(3, 'Suco de uva 1L',       12, 'caixa'),
(3, 'Água mineral 500ml',   48, 'garrafa'),

-- Doação 4 — Brinquedos
(4, 'Boneca',               10, 'unidade'),
(4, 'Carrinho de brinquedo',10, 'unidade'),
(4, 'Jogo de tabuleiro',     5, 'unidade'),

-- Doação 8 — Roberto cadeiras e mesas
(8, 'Cadeira plástica',     20, 'unidade'),
(8, 'Mesa plástica',         5, 'unidade'),

-- Doação 10 — Empresa XPTO brinquedos
(10, 'Kit escolar',         15, 'unidade'),
(10, 'Massinha de modelar', 20, 'unidade');
