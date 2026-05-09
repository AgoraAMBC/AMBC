-- ============================================================
--  SEED DEV 009 — AGENDA DE ATIVIDADES
--  Cobre: atividade com espaço, sem espaço,
--  com responsável cadastrado, externo, com e sem participantes,
--  agendada, cancelada, concluída, suspensa
-- ============================================================

INSERT INTO agenda (
    titulo, descricao, observacao,
    data_inicio, hora_inicio, data_fim, hora_fim,
    fk_espaco, fk_status_agenda,
    fk_associado, fk_parceiro,
    responsavel_nome, responsavel_telefone, responsavel_email,
    capacidade_maxima, total_participantes,
    valor_cobrado, valor_aluguel
) VALUES

-- Assembleia geral — com espaço, responsável externo, AGENDADA
('Assembleia Geral Ordinária',
 'Assembleia anual para prestação de contas e eleição de diretoria',
 'Confirmar presença com antecedência',
 '2024-04-10', '19:00', '2024-04-10', '22:00',
 1, 1,
 NULL, NULL, 'Presidente da Associação', '51988880030', 'presidente@ambc.com.br',
 100, 0, NULL, NULL),

-- Ginástica funcional — recorrente, responsável externo, AGENDADA
('Ginástica Funcional — Grupo Idosos',
 'Aula de ginástica funcional para o grupo de idosos da associação',
 'Toda quarta-feira pela manhã',
 '2024-04-03', '08:00', '2024-04-03', '10:00',
 1, 1,
 NULL, NULL, 'Prof. João Saúde', '51988880031', 'prof.saude@email.com',
 30, 18, 20.00, 50.00),

-- Aula de violino — parceiro responsável, AGENDADA
('Aula de Violino',
 'Aulas de violino em parceria com a professora',
 'Toda sexta-feira',
 '2024-04-05', '09:00', '2024-04-05', '11:00',
 2, 1,
 NULL, 6, NULL, NULL, NULL,
 15, 10, 50.00, 100.00),

-- Festa junina — com espaço, AGENDADA
('Festa Junina 2024',
 'Festa junina anual da associação com barracas, quadrilha e comidas típicas',
 'Confirmar parceiros doadores',
 '2024-06-15', '16:00', '2024-06-15', '22:00',
 3, 1,
 1, NULL, NULL, NULL, NULL,
 200, 0, 30.00, NULL),

-- Natal solidário — AGENDADA sem espaço ainda
('Natal Solidário 2024',
 'Arrecadação de brinquedos e distribuição para crianças carentes',
 'Definir local posteriormente',
 '2024-12-20', '14:00', '2024-12-20', '18:00',
 NULL, 1,
 NULL, NULL, 'Comissão Organizadora', '51988880032', NULL,
 NULL, 0, NULL, NULL),

-- Reunião de diretoria — sem espaço, associado responsável, CONCLUÍDA
('Reunião de Diretoria — Março',
 'Reunião mensal da diretoria para deliberações',
 NULL,
 '2024-03-15', '18:00', '2024-03-15', '20:00',
 2, 3,
 4, NULL, NULL, NULL, NULL,
 10, 8, NULL, NULL),

-- Atividade CANCELADA
('Workshop de Artesanato',
 'Workshop cancelado por falta de participantes',
 'Reagendar para data futura',
 '2024-03-25', '14:00', '2024-03-25', '17:00',
 1, 2,
 NULL, NULL, 'Artesã Maria', '51988880033', NULL,
 20, 0, 40.00, 80.00),

-- Atividade SUSPENSA
('Aula de Yoga',
 'Aulas de yoga suspensas temporariamente',
 'Instrutora de licença médica',
 '2024-04-08', '07:00', '2024-04-08', '08:30',
 1, 4,
 NULL, NULL, 'Instrutora Carla', '51988880034', 'carla.yoga@email.com',
 25, 0, 35.00, 70.00),

-- Atividade sem espaço e sem participantes — só registro
('Visita ao Hospital',
 'Visita solidária ao Hospital de Clínicas',
 'Levar brinquedos arrecadados',
 '2024-04-12', '10:00', '2024-04-12', '12:00',
 NULL, 1,
 1, NULL, NULL, NULL, NULL,
 NULL, 0, NULL, NULL),

-- Atividade com lotação máxima
('Curso de Primeiros Socorros',
 'Curso básico de primeiros socorros para associados',
 'Vagas limitadas — lista de espera disponível',
 '2024-04-20', '08:00', '2024-04-20', '17:00',
 2, 1,
 NULL, NULL, 'Cruz Vermelha RS', '51988880035', 'crvrs@email.com',
 20, 20, 50.00, NULL);
