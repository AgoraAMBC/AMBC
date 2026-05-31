-- CONTAS REGENTES (categorias maiores)
INSERT INTO conta_regente (descricao) VALUES
    ('Mensalidades'),
    ('Eventos'),
    ('Doações'),
    ('Despesas Administrativas'),
    ('Outros');
 
-- CONTAS SUBORDINADAS (subcategorias)
 
-- Mensalidades (id 1)
INSERT INTO conta_subordinada (fk_conta_regente, descricao) VALUES
    (1, 'Mensalidade Fundador'),
    (1, 'Mensalidade Honorário'),
    (1, 'Mensalidade Contribuinte');
 
-- Eventos (id 2)
INSERT INTO conta_subordinada (fk_conta_regente, descricao) VALUES
    (2, 'Festa Junina'),
    (2, 'Natal Solidário'),
    (2, 'Assembleia Geral');
 
-- Doações (id 3)
INSERT INTO conta_subordinada (fk_conta_regente, descricao) VALUES
    (3, 'Doação em Dinheiro'),
    (3, 'Doação de Alimentos'),
    (3, 'Doação de Brinquedos');
 
-- Despesas Administrativas (id 4)
INSERT INTO conta_subordinada (fk_conta_regente, descricao) VALUES
    (4, 'Material de Escritório'),
    (4, 'Contas e Serviços'),
    (4, 'Manutenção');
 
-- Outros (id 5)
INSERT INTO conta_subordinada (fk_conta_regente, descricao) VALUES
    (5, 'Outros Recebimentos'),
    (5, 'Outros Pagamentos');