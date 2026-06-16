-- Adiciona status "Isento" para parcelas dispensadas (ex: meses anteriores ao ingresso do associado)
-- Parcelas isentas não são contabilizadas como receita no dashboard
INSERT IGNORE INTO status_conta (id_status_conta, descricao) VALUES (4, 'Isento');
