-- Salão Principal (id 1)
INSERT INTO horario_espaco (fk_espaco, dia_semana, hora_inicio, hora_fim) VALUES
    (1, 'Segunda', '08:00', '12:00'),
    (1, 'Segunda', '13:00', '18:00'),
    (1, 'Terça',   '08:00', '12:00'),
    (1, 'Terça',   '13:00', '18:00'),
    (1, 'Quarta',  '08:00', '12:00'),
    (1, 'Quarta',  '13:00', '18:00'),
    (1, 'Quinta',  '08:00', '12:00'),
    (1, 'Quinta',  '13:00', '18:00'),
    (1, 'Sexta',   '08:00', '12:00'),
    (1, 'Sexta',   '13:00', '18:00'),
    (1, 'Sábado',  '08:00', '12:00'),
    (1, 'Sábado',  '13:00', '18:00');
 
-- Sala de Reuniões (id 2)
INSERT INTO horario_espaco (fk_espaco, dia_semana, hora_inicio, hora_fim) VALUES
    (2, 'Segunda', '08:00', '18:00'),
    (2, 'Terça',   '08:00', '18:00'),
    (2, 'Quarta',  '08:00', '18:00'),
    (2, 'Quinta',  '08:00', '18:00'),
    (2, 'Sexta',   '08:00', '18:00');
 
-- Área Externa (id 3)
INSERT INTO horario_espaco (fk_espaco, dia_semana, hora_inicio, hora_fim) VALUES
    (3, 'Sábado',  '08:00', '18:00'),
    (3, 'Domingo', '08:00', '18:00');
 