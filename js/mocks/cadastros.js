/* =========================================================
   cadastros.js
   Projeto: AMBC-V2
   Descricao: Mock de dados de cadastros (associados,
              dependentes e parceiros) para desenvolvimento
              do frontend antes da integracao com backend.
   Total: 30 registros ficticios.
========================================================= */

const cadastros = [
  // ===== ASSOCIADOS =====
  { id: 1,  nome: 'Ricardo Mendonça',     email: 'ricardo.mendonca@email.com',  cpf: '123.456.789-01', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2024-01-12' },
  { id: 2,  nome: 'Júlio Pereira',         email: 'julio.pereira@email.com',     cpf: '234.567.890-12', tipo: 'associado',  status: 'inativo', cadastradoEm: '2023-03-03' },
  { id: 3,  nome: 'Beatriz Oliveira',      email: 'beatriz.oliveira@email.com',  cpf: '345.678.901-23', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2024-05-20' },
  { id: 4,  nome: 'Carlos Almeida',        email: 'carlos.almeida@email.com',    cpf: '456.789.012-34', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2022-11-08' },
  { id: 5,  nome: 'Fernanda Souza',        email: 'fernanda.souza@email.com',    cpf: '567.890.123-45', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2023-07-15' },
  { id: 6,  nome: 'Roberto Lima',          email: 'roberto.lima@email.com',      cpf: '678.901.234-56', tipo: 'associado',  status: 'inativo', cadastradoEm: '2021-02-28' },
  { id: 7,  nome: 'Patrícia Rocha',        email: 'patricia.rocha@email.com',    cpf: '789.012.345-67', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2024-09-10' },
  { id: 8,  nome: 'Eduardo Martins',       email: 'eduardo.martins@email.com',   cpf: '890.123.456-78', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2023-12-05' },
  { id: 9,  nome: 'Luciana Cardoso',       email: 'luciana.cardoso@email.com',   cpf: '901.234.567-89', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2024-02-18' },
  { id: 10, nome: 'Marcelo Nunes',         email: 'marcelo.nunes@email.com',     cpf: '012.345.678-90', tipo: 'associado',  status: 'inativo', cadastradoEm: '2022-06-22' },
  { id: 11, nome: 'Camila Ribeiro',        email: 'camila.ribeiro@email.com',    cpf: '111.222.333-44', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2024-03-30' },
  { id: 12, nome: 'André Castro',          email: 'andre.castro@email.com',      cpf: '222.333.444-55', tipo: 'associado',  status: 'ativo',   cadastradoEm: '2023-08-14' },

  // ===== DEPENDENTES =====
  { id: 13, nome: 'Alice Mendonça',        email: 'alice.mendonca@email.com',    cpf: '333.444.555-66', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2024-01-12' },
  { id: 14, nome: 'Pedro Mendonça',        email: 'pedro.mendonca@email.com',    cpf: '444.555.666-77', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2024-01-12' },
  { id: 15, nome: 'Sofia Almeida',         email: 'sofia.almeida@email.com',     cpf: '555.666.777-88', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2022-11-08' },
  { id: 16, nome: 'Lucas Souza',           email: 'lucas.souza@email.com',       cpf: '666.777.888-99', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2023-07-15' },
  { id: 17, nome: 'Helena Lima',           email: 'helena.lima@email.com',       cpf: '777.888.999-00', tipo: 'dependente', status: 'inativo', cadastradoEm: '2021-02-28' },
  { id: 18, nome: 'Gabriel Rocha',         email: 'gabriel.rocha@email.com',     cpf: '888.999.000-11', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2024-09-10' },
  { id: 19, nome: 'Isabela Martins',       email: 'isabela.martins@email.com',   cpf: '999.000.111-22', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2023-12-05' },
  { id: 20, nome: 'Theo Cardoso',          email: 'theo.cardoso@email.com',      cpf: '101.202.303-44', tipo: 'dependente', status: 'ativo',   cadastradoEm: '2024-02-18' },

  // ===== PARCEIROS =====
  { id: 21, nome: 'Mariana Costa',         email: 'contato@padariamariana.com',  cpf: '12.345.678/0001-90', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2023-09-18' },
  { id: 22, nome: 'Farmácia Saúde Total',  email: 'atendimento@saudetotal.com',  cpf: '23.456.789/0001-01', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2024-04-22' },
  { id: 23, nome: 'Mercado Bom Preço',     email: 'gerencia@bompreco.com',       cpf: '34.567.890/0001-12', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2023-11-30' },
  { id: 24, nome: 'Pet Shop Amigo Fiel',   email: 'contato@amigofiel.com',       cpf: '45.678.901/0001-23', tipo: 'parceiro', status: 'inativo', cadastradoEm: '2022-08-12' },
  { id: 25, nome: 'Academia Movimento',    email: 'contato@movimento.com',       cpf: '56.789.012/0001-34', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2024-06-05' },
  { id: 26, nome: 'Lava-Jato Express',     email: 'lavajato@express.com',        cpf: '67.890.123/0001-45', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2023-05-17' },
  { id: 27, nome: 'Salão Beleza Pura',     email: 'contato@belezapura.com',      cpf: '78.901.234/0001-56', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2024-08-09' },
  { id: 28, nome: 'Restaurante Sabor',     email: 'reservas@sabor.com',          cpf: '89.012.345/0001-67', tipo: 'parceiro', status: 'inativo', cadastradoEm: '2022-12-01' },
  { id: 29, nome: 'Ótica Visão Clara',     email: 'atendimento@visaoclara.com',  cpf: '90.123.456/0001-78', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2024-10-25' },
  { id: 30, nome: 'Auto Escola Direção',   email: 'contato@direcao.com',         cpf: '01.234.567/0001-89', tipo: 'parceiro', status: 'ativo',   cadastradoEm: '2023-04-14' },
];

export default cadastros;
