-- ============================================================
--  SEED DEV 004 — PARCEIROS FICTÍCIOS
--  Cobre: pessoa física (CPF), pessoa jurídica (CNPJ),
--  parceiro ativo e inativo
-- ============================================================

INSERT INTO parceiro (
    nome_razao_social, cpf_cnpj, email,
    logradouro, numero, complemento, cep, bairro, cidade, uf,
    ativo
) VALUES

-- Pessoa jurídica (CNPJ)
('Supermercado Bom Preço Ltda',     '12345678000101', 'contato@bompreco.com.br',
 'Av. Assis Brasil', '1000', NULL, '91000001', 'Sarandi', 'Porto Alegre', 'RS', TRUE),

('Padaria São Jorge Ltda',          '23456789000112', 'padaria@saojorge.com.br',
 'Rua Coronel Aparício Borges', '500', NULL, '91000002', 'Glória', 'Porto Alegre', 'RS', TRUE),

('Farmácia Popular Saúde Ltda',     '34567890000123', 'farmacia@popular.com.br',
 'Av. Bento Gonçalves', '2000', 'Loja 3', '91000003', 'Partenon', 'Porto Alegre', 'RS', TRUE),

('Distribuidora de Bebidas RS Ltda','45678901000134', 'bebidas@distribuidora.com.br',
 'Rua Industrial', '300', NULL, '91000004', 'Navegantes', 'Porto Alegre', 'RS', TRUE),

('Brinquedos Alegria Ltda',         '56789012000145', 'contato@alegria.com.br',
 'Shopping Bourbon', '100', 'Loja 215', '90000020', 'Três Figueiras', 'Porto Alegre', 'RS', TRUE),

-- Pessoa física (CPF)
('Maria Aparecida Souza Lima',      '98765432100', 'maria.aparecida@email.com',
 'Rua Luciana de Abreu', '450', NULL, '90000021', 'Moinhos de Vento', 'Porto Alegre', 'RS', TRUE),

('João Batista Ferreira Neto',      '87654321099', 'joao.batista@email.com',
 'Av. Carlos Gomes', '760', 'Sala 301', '90000022', 'Auxiliadora', 'Porto Alegre', 'RS', TRUE),

-- Parceiro inativo
('Loja Encerrada Comércio Ltda',    '67890123000156', NULL,
 'Rua dos Andradas', '900', NULL, '90000023', 'Centro', 'Porto Alegre', 'RS', FALSE);
