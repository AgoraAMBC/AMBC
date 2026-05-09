-- ============================================================
--  SEED DEV 008 — RESERVAS DE ESPAÇO
--  Roda DEPOIS dos seeds de espaços, horários,
--  associados e parceiros
--  Cobre: reserva por associado, parceiro, externo,
--  confirmada, cancelada, concluída e conflito impedido
-- ============================================================

INSERT INTO reserva_espaco (
    fk_espaco, fk_horario_espaco, fk_status_reserva,
    data_reserva,
    fk_associado, fk_parceiro, nome_externo, telefone_externo, email_externo,
    valor_cobrado, observacao
) VALUES

-- Salão (espaco 1, horario manhã segunda = id 1) — associado CONFIRMADA
(1, 1, 1, '2024-04-01',
 1, NULL, NULL, NULL, NULL,
 350.00, 'Festa de aniversário da Ana Paula'),

-- Salão (espaco 1, horario tarde segunda = id 2) — parceiro CONFIRMADA
(1, 2, 1, '2024-04-01',
 NULL, 1, NULL, NULL, NULL,
 500.00, 'Evento do Supermercado Bom Preço'),

-- Salão (espaco 1, horario manhã terça = id 3) — externo CONFIRMADA
(1, 3, 1, '2024-04-02',
 NULL, NULL, 'Empresa Externa ABC', '51988880010', 'abc@empresa.com',
 600.00, 'Treinamento corporativo'),

-- Sala reuniões (espaco 2, horario segunda = id 13) — associado CONFIRMADA
(2, 13, 1, '2024-04-01',
 2, NULL, NULL, NULL, NULL,
 100.00, 'Reunião de diretoria'),

-- Salão (espaco 1, horario manhã quarta = id 5) — CANCELADA
(1, 5, 2, '2024-04-03',
 3, NULL, NULL, NULL, NULL,
 350.00, 'Cancelado por motivo pessoal'),

-- Salão (espaco 1, horario tarde quarta = id 6) — CONCLUÍDA
(1, 6, 3, '2024-03-20',
 4, NULL, NULL, NULL, NULL,
 400.00, 'Confraternização realizada com sucesso'),

-- Área externa (espaco 3, horario sábado = id 19) — externo CONFIRMADA
(3, 19, 1, '2024-04-06',
 NULL, NULL, 'João da Silva Eventos', '51988880020', 'joao@eventos.com',
 800.00, 'Festa de casamento'),

-- Sala reuniões (espaco 2, horario terça = id 14) — parceiro CONFIRMADA
(2, 14, 1, '2024-04-02',
 NULL, 7, NULL, NULL, NULL,
 150.00, 'Reunião João Batista'),

-- Salão (espaco 1, horario manhã quinta = id 7) — sem cobrança
(1, 7, 1, '2024-04-04',
 1, NULL, NULL, NULL, NULL,
 NULL, 'Uso interno — sem cobrança');
