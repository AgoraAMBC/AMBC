-- ============================================================
--  SEED DEV 001 — ASSOCIADOS FICTÍCIOS
--  Dados para desenvolvimento e testes
--  Cobre os cenários: ativo, pendente, inativo,
--  todas as categorias, todos os gêneros
-- ============================================================

INSERT INTO associado (
    nome, data_nascimento, cpf_cnpj, email,
    logradouro, numero, complemento, cep, bairro, cidade, uf,
    fk_estadocivil, fk_profissao, fk_categoria, fk_status, fk_genero,
    observacao, ativo
) VALUES

-- Associados ATIVOS
('Ana Paula Silva Santos',      '1985-03-15', '12345678901', 'ana.paula@email.com',
 'Rua das Flores', '123', 'Apto 201', '90000001', 'Centro', 'Porto Alegre', 'RS',
 2, 4, 1, 1, 1, 'Sócia fundadora', TRUE),

('Carlos Eduardo Oliveira',     '1978-07-22', '23456789012', 'carlos.eduardo@email.com',
 'Av. Ipiranga', '456', NULL, '90000002', 'Azenha', 'Porto Alegre', 'RS',
 1, 7, 2, 1, 2, NULL, TRUE),

('Fernanda Costa Rodrigues',    '1992-11-08', '34567890123', 'fernanda.costa@email.com',
 'Rua Sete de Setembro', '789', 'Casa', '90000003', 'Floresta', 'Porto Alegre', 'RS',
 3, 4, 3, 1, 1, NULL, TRUE),

('Roberto Souza Mendes',        '1965-05-30', '45678901234', 'roberto.souza@email.com',
 'Rua da República', '321', NULL, '90000004', 'Cidade Baixa', 'Porto Alegre', 'RS',
 2, 8, 1, 1, 2, 'Aposentado, contribui regularmente', TRUE),

('Patricia Lima Ferreira',      '1990-09-14', '56789012345', 'patricia.lima@email.com',
 'Av. Osvaldo Aranha', '654', 'Apto 302', '90000005', 'Bom Fim', 'Porto Alegre', 'RS',
 1, 9, 3, 1, 1, NULL, TRUE),

('Marcos Antonio Pereira',      '1982-01-25', '67890123456', 'marcos.antonio@email.com',
 'Rua Voluntários da Pátria', '987', NULL, '90000006', 'Navegantes', 'Porto Alegre', 'RS',
 4, 4, 2, 1, 2, NULL, TRUE),

('Juliana Martins Carvalho',    '1995-06-18', '78901234567', 'juliana.martins@email.com',
 'Rua General Lima e Silva', '147', 'Apto 101', '90000007', 'Cidade Baixa', 'Porto Alegre', 'RS',
 1, 10, 3, 1, 1, NULL, TRUE),

('Diego Alves Nascimento',      '1988-12-03', '89012345678', 'diego.alves@email.com',
 'Rua João Alfredo', '258', NULL, '90000008', 'Cidade Baixa', 'Porto Alegre', 'RS',
 1, 3, 3, 1, 2, NULL, TRUE),

('Camila Rodrigues Teixeira',   '1993-04-27', '90123456789', 'camila.rodrigues@email.com',
 'Av. Protásio Alves', '369', 'Apto 404', '90000009', 'Petrópolis', 'Porto Alegre', 'RS',
 1, 4, 1, 1, 1, NULL, TRUE),

('José Carlos Barbosa',         '1970-08-11', '01234567890', 'jose.carlos@email.com',
 'Rua Ramiro Barcelos', '741', NULL, '90000010', 'Floresta', 'Porto Alegre', 'RS',
 2, 6, 2, 1, 2, NULL, TRUE),

-- Associados PENDENTES (entre 1 e 90 dias de inadimplência)
('Luciana Ferreira Gomes',      '1987-02-19', '11223344556', 'luciana.ferreira@email.com',
 'Rua Cristóvão Colombo', '852', NULL, '90000011', 'Floresta', 'Porto Alegre', 'RS',
 3, 4, 3, 2, 1, 'Pendente desde janeiro', TRUE),

('Rafael Santos Costa',         '1991-10-07', '22334455667', 'rafael.santos@email.com',
 'Av. Nilo Peçanha', '963', 'Apto 502', '90000012', 'Boa Vista', 'Porto Alegre', 'RS',
 1, 2, 3, 2, 2, NULL, TRUE),

-- Associados INATIVOS (mais de 90 dias de inadimplência)
('Mariana Oliveira Dias',       '1983-06-14', '33445566778', 'mariana.oliveira@email.com',
 'Rua Garibaldi', '174', NULL, '90000013', 'Independência', 'Porto Alegre', 'RS',
 2, 11, 2, 3, 1, 'Inativa por inadimplência', FALSE),

('Thiago Mendes Ribeiro',       '1979-03-28', '44556677889', 'thiago.mendes@email.com',
 'Rua Santo Antônio', '285', NULL, '90000014', 'Cidade Baixa', 'Porto Alegre', 'RS',
 1, 12, 3, 3, 2, NULL, FALSE),

-- Associado sem email (testa campo opcional)
('Sandra Regina Pinto Alves',   '1975-11-22', NULL, NULL,
 'Rua Felipe Neri', '396', NULL, '90000015', 'Auxiliadora', 'Porto Alegre', 'RS',
 2, 5, 1, 1, 1, 'Sem email cadastrado', TRUE),

-- Associado não binário
('Alex Souza Cardoso',          '1998-07-04', '55667788990', 'alex.souza@email.com',
 'Av. João Pessoa', '507', 'Apto 201', '90000016', 'Farroupilha', 'Porto Alegre', 'RS',
 1, 9, 3, 1, 3, NULL, TRUE),

-- Associado de outra cidade
('Beatriz Almeida Correia',     '1986-09-16', '66778899001', 'beatriz.almeida@email.com',
 'Rua XV de Novembro', '618', NULL, '88000001', 'Centro', 'Florianópolis', 'SC',
 1, 4, 2, 1, 1, NULL, TRUE),

-- Associado viúvo aposentado
('Antônio Carlos Machado',      '1950-04-05', '77889900112', 'antonio.machado@email.com',
 'Rua dos Andradas', '729', NULL, '90000018', 'Centro Histórico', 'Porto Alegre', 'RS',
 4, 8, 1, 1, 2, 'Sócio desde a fundação', TRUE);
