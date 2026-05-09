-- ============================================================
--  SEED DEV 006 — MENSALIDADES E PARCELAS
--  Roda DEPOIS dos seeds de associados e plano de contas
--  Cobre: pagamento à vista, parcelado, pago, em aberto,
--  atrasado, cancelado
-- ============================================================

-- ----------------------------------------------------------
--  CONTAS (lançamentos de mensalidade)
-- ----------------------------------------------------------

INSERT INTO conta (
    fk_associado, fk_conta_regente, fk_conta_subordinada,
    fk_status_conta, descricao, valor_total, data_lancamento
) VALUES

-- Ana Paula (id 1) — paga, à vista
(1, 1, 1, 2, 'Mensalidade Janeiro 2024', 150.00, '2024-01-05'),

-- Ana Paula (id 1) — paga, parcelada
(1, 1, 1, 2, 'Mensalidade Fevereiro/Março 2024', 300.00, '2024-02-05'),

-- Carlos (id 2) — em aberto
(2, 1, 2, 1, 'Mensalidade Janeiro 2024', 100.00, '2024-01-05'),

-- Fernanda (id 3) — parcelada em aberto
(3, 1, 3, 1, 'Mensalidade Janeiro/Fevereiro 2024', 200.00, '2024-01-05'),

-- Roberto (id 4) — cancelado
(4, 1, 1, 3, 'Mensalidade Janeiro 2024', 150.00, '2024-01-05'),

-- Patricia (id 5) — paga
(5, 1, 3, 2, 'Mensalidade Janeiro 2024', 80.00, '2024-01-05'),

-- Luciana pendente (id 11) — atrasada
(11, 1, 3, 1, 'Mensalidade Novembro 2023', 80.00, '2023-11-05'),

-- Rafael pendente (id 12) — atrasada
(12, 1, 3, 1, 'Mensalidade Dezembro 2023', 80.00, '2023-12-05'),

-- Marcos (id 6) — paga parcelada em 3x
(6, 1, 2, 2, 'Mensalidade Trimestre Q1 2024', 300.00, '2024-01-05'),

-- Juliana (id 7) — em aberto
(7, 1, 3, 1, 'Mensalidade Janeiro 2024', 80.00, '2024-01-05');


-- ----------------------------------------------------------
--  PARCELAS
-- ----------------------------------------------------------

INSERT INTO parcela (
    fk_conta, fk_status_conta, fk_forma_pagamento,
    numero_parcela, total_parcelas, valor,
    data_vencimento, data_pagamento, valor_pago
) VALUES

-- Conta 1 — Ana Paula à vista PAGA (PIX)
(1, 2, 1, 1, 1, 150.00, '2024-01-10', '2024-01-08', 150.00),

-- Conta 2 — Ana Paula parcelada 2x PAGA
(2, 2, 4, 1, 2, 150.00, '2024-02-10', '2024-02-09', 150.00),
(2, 2, 4, 2, 2, 150.00, '2024-03-10', '2024-03-08', 150.00),

-- Conta 3 — Carlos em aberto
(3, 1, NULL, 1, 1, 100.00, '2024-01-10', NULL, NULL),

-- Conta 4 — Fernanda parcelada 2x em aberto
(4, 1, NULL, 1, 2, 100.00, '2024-01-10', NULL, NULL),
(4, 1, NULL, 2, 2, 100.00, '2024-02-10', NULL, NULL),

-- Conta 5 — Roberto cancelado
(5, 3, NULL, 1, 1, 150.00, '2024-01-10', NULL, NULL),

-- Conta 6 — Patricia paga (boleto)
(6, 2, 2, 1, 1, 80.00, '2024-01-10', '2024-01-07', 80.00),

-- Conta 7 — Luciana ATRASADA (vencida há mais de 30 dias)
(7, 1, NULL, 1, 1, 80.00, '2023-11-10', NULL, NULL),

-- Conta 8 — Rafael ATRASADA
(8, 1, NULL, 1, 1, 80.00, '2023-12-10', NULL, NULL),

-- Conta 9 — Marcos 3x parcelado PAGO
(9, 2, 1, 1, 3, 100.00, '2024-01-10', '2024-01-09', 100.00),
(9, 2, 1, 2, 3, 100.00, '2024-02-10', '2024-02-08', 100.00),
(9, 2, 1, 3, 3, 100.00, '2024-03-10', '2024-03-07', 100.00),

-- Conta 10 — Juliana em aberto
(10, 1, NULL, 1, 1, 80.00, '2024-01-10', NULL, NULL);
