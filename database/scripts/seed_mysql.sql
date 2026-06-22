-- ============================================================
--  AMBC V2 — Seed MySQL
--  Gerado a partir do backup PostgreSQL de 29-05-2026
--  Execute: mysql -u root -p ambc < database/scripts/seed_mysql.sql
-- ============================================================
USE ambc;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Torna data_nascimento opcional (campo não obrigatório na criação)
ALTER TABLE `associado` MODIFY `data_nascimento` DATE NULL;

-- ─── UF ──────────────────────────────────────────────────────
INSERT IGNORE INTO `uf` (`sigla`, `nome`) VALUES
('AC','Acre'),('AL','Alagoas'),('AP','Amapá'),('AM','Amazonas'),
('BA','Bahia'),('CE','Ceará'),('DF','Distrito Federal'),
('ES','Espírito Santo'),('GO','Goiás'),('MA','Maranhão'),
('MT','Mato Grosso'),('MS','Mato Grosso do Sul'),('MG','Minas Gerais'),
('PA','Pará'),('PB','Paraíba'),('PR','Paraná'),('PE','Pernambuco'),
('PI','Piauí'),('RJ','Rio de Janeiro'),('RN','Rio Grande do Norte'),
('RS','Rio Grande do Sul'),('RO','Rondônia'),('RR','Roraima'),
('SC','Santa Catarina'),('SP','São Paulo'),('SE','Sergipe'),
('TO','Tocantins');

-- ─── GÊNERO ──────────────────────────────────────────────────
INSERT IGNORE INTO `genero` (`id_genero`, `descricao`) VALUES
(1,'Feminino'),(2,'Masculino'),(3,'Outro'),(7,'Prefiro não informar.');

-- ─── ESTADO CIVIL ────────────────────────────────────────────
INSERT IGNORE INTO `estado_civil` (`id_estadocivil`, `descricao`) VALUES
(1,'Solteiro(a)'),(2,'Casado(a)'),(3,'Divorciado(a)'),(4,'Viúvo(a)');

-- ─── STATUS PESSOA ───────────────────────────────────────────
INSERT IGNORE INTO `status_pessoa` (`id_status`, `descricao`) VALUES
(1,'Ativo'),(2,'Pendente'),(3,'Inativo');

-- ─── PROFISSÃO ───────────────────────────────────────────────
INSERT IGNORE INTO `profissao` (`id_profissao`, `descricao`) VALUES
(1,'Autônomo formal'),(2,'Autônomo informal'),(3,'Empregado informal'),
(4,'Empregado formal'),(5,'Trabalhador doméstico'),(6,'Trabalhador rural'),
(7,'Servidor público'),(8,'Aposentado/Pensionista'),(9,'Estudante'),
(10,'Estagiário'),(11,'Não trabalha'),(12,'Outro'),(13,'médico');

-- ─── PARENTESCO ──────────────────────────────────────────────
INSERT IGNORE INTO `parentesco` (`id_parentesco`, `descricao`, `observacao`) VALUES
(1,'Filho(a)',NULL),(2,'Enteado(a)',NULL),(3,'Sobrinho(a)',NULL),
(4,'Neto(a)',NULL),(5,'Outro',NULL);

-- ─── CATEGORIA ───────────────────────────────────────────────
INSERT IGNORE INTO `categoria` (`id_categoria`, `descricao`) VALUES
(1,'Fundador'),(2,'Honorário'),(3,'Contribuinte');

-- ─── TIPO TELEFONE ───────────────────────────────────────────
INSERT IGNORE INTO `tipo_telefone` (`id_tipo_telefone`, `descricao`) VALUES
(1,'Celular'),(2,'Residencial'),(3,'Comercial'),(4,'WhatsApp'),(5,'Outro');

-- ─── FORMA PAGAMENTO ─────────────────────────────────────────
INSERT IGNORE INTO `forma_pagamento` (`id_forma_pagamento`, `descricao`) VALUES
(1,'PIX'),(2,'Boleto'),(3,'Cartão de crédito'),
(4,'Cartão de débito'),(5,'Dinheiro'),(6,'Transferência bancária');

-- ─── STATUS CONTA ────────────────────────────────────────────
INSERT IGNORE INTO `status_conta` (`id_status_conta`, `descricao`) VALUES
(1,'Aberto'),(2,'Liquidado'),(3,'Cancelado');

-- ─── TIPO LANÇAMENTO ─────────────────────────────────────────
INSERT IGNORE INTO `tipo_lancamento` (`id_tipo_lancamento`, `descricao`, `observacao`) VALUES
(1,'Anuidade',NULL),(2,'Mensalidade',NULL),(3,'Doação',NULL),
(4,'Multa',NULL),(5,'Outro',NULL),(6,'Mensalidades',NULL),
(10,'Multa por Atraso','Multa por atraso no pagamento'),
(11,'Manutenção','Despesa de manutenção da associação'),
(12,'Conta de Energia Elétrica',NULL);

-- ─── PERFIL USUÁRIO ──────────────────────────────────────────
INSERT IGNORE INTO `perfil_usuario` (`id_perfil`, `descricao`, `observacao`) VALUES
(1,'Administrador','Presidente e Vice. Acesso total ao sistema, incluindo usuários e configurações.'),
(2,'Operacional','Secretários. Acesso ao cadastro de associados e gestão operacional.'),
(3,'Conselho Fiscal','Apenas leitura. Acesso para visualização e fiscalização das informações.'),
(4,'Financeiro','Tesoureiros. Acesso ao módulo financeiro e relatórios.');

-- ─── MÓDULO SISTEMA ──────────────────────────────────────────
INSERT IGNORE INTO `modulo_sistema` (`id_modulo`, `descricao`) VALUES
(1,'Dashboard'),(2,'Associados'),(3,'Parceiros'),(4,'Financeiro'),
(5,'Reserva de Espaço'),(6,'Agenda'),(7,'Documentação'),
(8,'Usuários e Permissões');

-- ─── USUÁRIOS ────────────────────────────────────────────────
INSERT IGNORE INTO `usuario`
  (`id_usuario`,`nome`,`email`,`senha_hash`,`fk_perfil`,`fk_associado`,
   `ativo`,`primeiro_acesso`,`ultimo_acesso`,`token_reset`,`token_expira_em`,
   `criado_em`,`atualizado_em`)
VALUES
(17,'fabiolopes','fabiomachado1212@gmail.com',
 '$2y$10$ngNB..SC6KHKMW81SY6w/eHHWVVZzLO1Ty6feVNLuv50Im0kpCpki',
 1,NULL,1,0,'2026-05-25 22:23:10',NULL,NULL,'2026-05-02 00:19:40','2026-05-25 22:23:10'),
(9,'Fabio','fabiomachadolopes@hotmail.com',
 '$2y$10$RtQS/0O3bqT7/xjH0XaAg.SXrcU9TCahTYFDmk5R.J2B5/md.Qof.',
 1,NULL,1,0,'2026-05-27 00:20:15',NULL,NULL,'2026-04-27 22:58:57','2026-05-27 00:20:15'),
(22,'Adriane Reis','adrianeb.reis22@gmail.com',
 '$2y$10$x0GsyKNUdWJ2qsWZGY3JEORusoj1Ne9.0PqeSJXt1NTwCm5VhenJu',
 1,NULL,1,0,'2026-05-27 23:24:51',NULL,NULL,'2026-05-14 22:16:45','2026-05-27 23:24:51'),
(18,'Mikaela Thais Silva Kichler','mikaelatsk@gmail.com',
 '$2y$10$XTMVRQL4jTAgEaeH9JjRg.bG.xoCMBPurZnrimV2HODKRBo0MwtFK',
 1,NULL,1,0,NULL,NULL,NULL,'2026-05-02 00:26:38','2026-05-02 00:26:38'),
(8,'Leonardo Pereira Leote','leonardo.leote0909@gmail.com',
 '$2y$10$7mFTe0VtaL8bXpuY8hjaSecyjN3zUQKGdPHlUMbpT2GUMuaeo6dn2',
 1,NULL,1,0,'2026-05-28 01:31:28',NULL,NULL,'2026-04-27 22:57:58','2026-05-28 01:31:28'),
(20,'adminAMBC','admin@ambc.com',
 '$2y$10$64WUVSRBW1V79YGdPcsozeVxu5.EO/4nB1D7cMm65F8s6fumtWilG',
 1,NULL,1,0,'2026-05-28 21:16:42',NULL,NULL,'2026-05-05 02:06:48','2026-05-28 21:16:42'),
(12,'admin','admin@admin.com',
 '$2y$10$WINMYpdKI7nvRaRvyMHra.g0HYRBgBrmewBRnEGvbNLKp/5BQyRi6',
 1,NULL,1,0,'2026-05-28 21:28:53',NULL,NULL,'2026-04-30 01:40:14','2026-05-28 21:28:53');

-- ─── ASSOCIADOS ──────────────────────────────────────────────
INSERT IGNORE INTO `associado`
  (`id_associado`,`nome`,`data_nascimento`,`cpf_cnpj`,`email`,`observacao`,
   `ativo`,`logradouro`,`numero`,`complemento`,`cep`,`bairro`,`cidade`,`uf`,
   `fk_estadocivil`,`fk_profissao`,`fk_categoria`,`fk_status`,`fk_genero`,
   `criado_em`,`atualizado_em`,`matricula`,`data_entrada`)
VALUES
(4,'Maria Aparecida Lima','1972-07-25','22233344455','maria.lima@email.com',NULL,
 1,'Av. Bento Gonçalves','456',NULL,'91500000','Califórnia','Porto Alegre','RS',
 1,8,1,1,1,'2026-04-23 22:04:24','2026-04-23 22:04:24',NULL,NULL),
(7,'Roberto Carlos Mendes','1965-01-19','55566677788','roberto.mendes@email.com',NULL,
 1,'Av. Sertório','654','Bloco B','91060000','Califórnia','Porto Alegre','RS',
 2,7,2,1,2,'2026-04-23 22:04:24','2026-04-23 22:04:24',NULL,NULL),
(9,'Teste Backend 2','1987-11-30','88888888888','teste@teste.com','teste',
 1,'Rua Teste','1',NULL,'92000000','Bairro','Canoas','RS',
 2,5,NULL,1,NULL,'2026-05-06 00:00:00','2026-05-07 02:06:20','0001',NULL),
(5,'João Pedro Ferreira','1990-11-08','33344455566','joao.ferreira@email.com',NULL,
 1,'Rua Pinheiro Machado','789','Casa 2','91040000','Califórnia','Porto Alegre','RS',
 3,1,3,1,2,'2026-04-23 22:04:24','2026-05-25 23:34:07',NULL,NULL),
(24,'Leonardo Leote','1992-09-09','35095512015','leonardo.leote0909@gmail.com',NULL,
 1,NULL,'381',NULL,'92480000',NULL,'Nova Santa Rita','RS',
 2,13,3,1,3,'2026-05-27 22:32:37','2026-05-27 22:32:37','0002','2026-05-27'),
(29,'Leonardo Leote','1990-09-09','01324852015','leonardo.leote0909@gmail.com',NULL,
 1,NULL,'381',NULL,'92480000',NULL,'Nova Santa Rita','RS',
 2,13,3,1,3,'2026-05-27 23:21:05','2026-05-27 23:21:05','0003','2026-05-27'),
(31,'Leonardo Leote','1992-09-09','02522182015','leonardo.leote0909@gmail.com',NULL,
 1,NULL,'381',NULL,'92480000',NULL,'Nova Santa Rita','RS',
 2,13,3,1,1,'2026-05-27 23:21:52','2026-05-27 23:21:52','0004','2026-05-27'),
(32,'Leonardo Leote','1993-09-09','26512345685','leonardo.leote0909@gmail.com',NULL,
 1,'Rua Barão do Rio Branco','381',NULL,'92480000','Califórnia','Nova Santa Rita','RS',
 3,12,3,1,1,'2026-05-27 23:22:34','2026-05-27 23:22:34','0005','2026-05-27'),
(34,'Maria da Silva','1950-05-22','12345678920','mariadasilva@gmail.com',NULL,
 1,'R. São João Batista','108','casa','92480000','Califórnia','Nova Santa Rita','RS',
 2,8,3,1,1,'2026-05-27 23:26:06','2026-05-27 23:26:06','0006','2026-05-27'),
(35,'rosa ribeiro','1990-12-20','12121212121','rosa@gmail.com',NULL,
 1,'Rua Garibaldi','321','casa','92480000','Califórnia','Nova Santa Rita','RS',
 2,1,3,1,1,'2026-05-27 23:36:38','2026-05-27 23:36:38','0007','2026-05-27');

-- ─── PARCEIROS ───────────────────────────────────────────────
INSERT IGNORE INTO `parceiro`
  (`id_parceiro`,`nome_razao_social`,`cpf_cnpj`,`email`,`ativo`,
   `logradouro`,`numero`,`complemento`,`cep`,`bairro`,`cidade`,`uf`,
   `criado_em`,`atualizado_em`,`tipo_servico`,`tipo_pessoa`)
VALUES
(8,'Supermercado Bom Preço Ltda','12345678000101','contato@bompreco.com.br',1,
 'Av. Assis Brasil','1000',NULL,'91000001','Sarandi','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(9,'Padaria São Jorge Ltda','23456789000112','padaria@saojorge.com.br',1,
 'Rua Coronel Aparício Borges','500',NULL,'91000002','Glória','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(10,'Farmácia Popular Saúde Ltda','34567890000123','farmacia@popular.com.br',1,
 'Av. Bento Gonçalves','2000','Loja 3','91000003','Partenon','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(11,'Distribuidora de Bebidas RS Ltda','45678901000134','bebidas@distribuidora.com.br',1,
 'Rua Industrial','300',NULL,'91000004','Navegantes','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(12,'Brinquedos Alegria Ltda','56789012000145','contato@alegria.com.br',1,
 'Shopping Bourbon','100','Loja 215','90000020','Três Figueiras','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(13,'Maria Aparecida Souza Lima','98765432100','maria.aparecida@email.com',1,
 'Rua Luciana de Abreu','450',NULL,'90000021','Moinhos de Vento','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(14,'João Batista Ferreira Neto','87654321099','joao.batista@email.com',1,
 'Av. Carlos Gomes','760','Sala 301','90000022','Auxiliadora','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(15,'Loja Encerrada Comércio Ltda','67890123000156',NULL,0,
 'Rua dos Andradas','900',NULL,'90000023','Centro','Porto Alegre','RS',
 '2026-05-13 00:54:30','2026-05-13 00:54:30',NULL,'PF'),
(16,'Grafica Mill','00000000000100','graficamill@graficamill.com',1,
 'Rua João Paulo','123','Sala 2','00000000','Gloria','Glorinha','RS',
 '2026-05-13 02:14:17','2026-05-13 04:17:48','Impressões','PJ'),
(17,'Pedro Petry','00000000000','pedropetry@pedropetry.com',1,
 'Rua Maria Afonso','456','torre 1, ap 1001','00000000','Graça','Alvorada','RS',
 '2026-05-14 01:12:03','2026-05-14 02:08:21','mecânico','PF'),
(18,'volfied store','01324782222','leo@leo@.com',1,
 'barao do rio branco 381','122',NULL,'92110410','niteroi','Canoas','RS',
 '2026-05-14 19:32:52','2026-05-14 19:32:52','loja','PF'),
(21,'padaria pao quentinho','11111111111',NULL,1,
 NULL,NULL,NULL,NULL,NULL,NULL,NULL,
 '2026-05-27 00:30:47','2026-05-27 00:30:47',NULL,'PF'),
(22,'loja central','12345678920','lojacentral@gmail.com',1,
 'R. São João Batista','88','102','92480000','Califórnia','Nova Santa Rita','RS',
 '2026-05-27 23:41:03','2026-05-27 23:41:03','vestuário','PF');

-- ─── TELEFONES ASSOCIADO ─────────────────────────────────────
INSERT IGNORE INTO `telefone` (`id_telefone`,`fk_associado`,`ddd`,`numero`,`fk_tipo_telefone`,`observacao`) VALUES
(7,4,'51','987654321',NULL,NULL),
(8,5,'51','993456789',NULL,NULL),
(10,7,'51','995678901',NULL,NULL),
(23,34,'51','99999999',NULL,NULL),
(24,35,'51','21215050',NULL,NULL);

-- ─── TELEFONES PARCEIRO ──────────────────────────────────────
INSERT IGNORE INTO `telefone_parceiro` (`id_telefone_parceiro`,`fk_parceiro`,`ddd`,`numero`,`fk_tipo_telefone`,`observacao`) VALUES
(11,8,'51','33331000',NULL,NULL),
(12,8,'51','988881000',NULL,NULL),
(13,9,'51','33332000',NULL,NULL),
(14,10,'51','33333000',NULL,NULL),
(15,11,'51','33334000',NULL,NULL),
(16,11,'51','988884000',NULL,NULL),
(17,12,'51','33335000',NULL,NULL),
(18,13,'51','988886000',NULL,NULL),
(19,14,'51','988887000',NULL,NULL),
(20,14,'51','33337000',NULL,NULL),
(22,16,'51','999999999',3,'Vendas'),
(23,17,'51','999999999',4,'horario comercial apenas'),
(24,18,'51','991726262',4,NULL),
(25,22,'51','89896320',1,NULL);

-- ─── PERMISSÕES USUÁRIO ──────────────────────────────────────
INSERT IGNORE INTO `permissao_usuario` (`id_permissao`,`fk_usuario`,`fk_modulo`,`pode_acessar`,`pode_editar`) VALUES
(41,8,1,1,1),(42,8,2,1,1),(43,8,3,1,1),(44,8,4,1,1),
(45,8,5,1,1),(46,8,6,1,1),(47,8,7,1,1),(48,8,8,1,1),
(49,9,1,1,1),(50,9,2,1,1),(51,9,3,1,1),(52,9,4,1,1),
(53,9,5,1,1),(54,9,6,1,1),(55,9,7,1,1),(56,9,8,1,1),
(73,12,1,1,1),(74,12,2,1,1),(75,12,3,1,1),(76,12,4,1,1),
(77,12,5,1,1),(78,12,6,1,1),(79,12,7,1,1),(80,12,8,1,1),
(121,17,1,1,1),(122,17,2,1,1),(123,17,3,1,1),(124,17,4,1,1),
(125,17,5,1,1),(126,17,6,1,1),(127,17,7,1,1),(128,17,8,1,1),
(129,18,1,1,1),(130,18,2,1,1),(131,18,3,1,1),(132,18,4,1,1),
(133,18,5,1,1),(134,18,6,1,1),(135,18,7,1,1),(136,18,8,1,1);

-- ─── CONTAS REGENTES ─────────────────────────────────────────
INSERT IGNORE INTO `conta_regente` (`id_conta_regente`,`descricao`,`observacao`,`criado_em`,`atualizado_em`,`tipo`,`ativo`) VALUES
(1,'Receitas Associação',NULL,'2026-05-05 01:09:58','2026-05-06 12:55:03','receita',1),
(2,'Contas Associação','Conta de Água e Luz','2026-05-05 01:11:11','2026-05-06 01:18:52','despesa',1),
(3,'padaria2','pao quentinho','2026-05-05 01:32:31','2026-05-28 17:06:56','despesa',1),
(4,'Alvará Associação','Pagamento do alvará de manutenção.','2026-05-06 01:17:34','2026-05-07 22:14:53','despesa',1),
(8,'MENSALIDADE','Receber taxa de mensalidade do associado.','2026-05-12 23:34:52','2026-05-12 23:34:52','receita',1);

-- ─── CONTAS SUBORDINADAS ─────────────────────────────────────
INSERT IGNORE INTO `conta_subordinada` (`id_conta_subordinada`,`fk_conta_regente`,`descricao`,`observacao`,`criado_em`,`atualizado_em`,`ativo`) VALUES
(1,2,'Luz',NULL,'2026-05-05 02:09:03','2026-05-28 21:06:08',1),
(2,8,'Mensalidade','Mensalidade Associado.','2026-05-12 23:35:29','2026-05-12 23:35:29',1),
(3,8,'anual',NULL,'2026-05-14 01:43:50','2026-05-14 01:43:50',1),
(4,2,'Eventos','Destinado para compra de insumos e realização de eventos.','2026-05-14 18:06:03','2026-05-14 18:06:03',1);

-- ─── LANÇAMENTOS ─────────────────────────────────────────────
INSERT IGNORE INTO `lancamento`
  (`id_lancamento`,`fk_associado`,`fk_conta_regente`,`fk_conta_subordinada`,
   `fk_tipo_lancamento`,`fk_forma_pagamento`,`fk_status_conta`,
   `descricao`,`valor`,`valor_pago`,`data_lancamento`,`data_vencimento`,
   `data_pagamento`,`observacao`,`criado_em`,`atualizado_em`,
   `fk_parceiro`,`fk_parcelamento`,`numero_parcela`,`total_parcelas`)
VALUES
(2,NULL,NULL,NULL,3,NULL,2,'Maio, 26',10.00,10.00,'2026-05-13',NULL,'2026-05-13',NULL,'2026-05-13 04:17:48','2026-05-13 04:17:48',16,NULL,NULL,NULL),
(3,NULL,NULL,NULL,3,NULL,2,'2026',10.00,10.00,'2026-05-14',NULL,'2026-05-13',NULL,'2026-05-14 02:08:21','2026-05-14 02:08:21',17,NULL,NULL,NULL),
(4,NULL,NULL,NULL,NULL,NULL,1,'Doação para Evento Beneficente',150.00,NULL,'2026-05-14',NULL,NULL,NULL,'2026-05-14 19:40:04','2026-05-14 19:40:04',NULL,NULL,NULL,NULL),
(5,NULL,1,1,1,1,2,'Conta de Energia elétrica',104.60,NULL,'2026-05-13','2026-05-13',NULL,NULL,'2026-05-14 20:06:09','2026-05-14 20:06:09',NULL,NULL,NULL,NULL),
(9,NULL,1,1,5,1,1,'Reforma da Sede',256.00,NULL,'2026-05-12','2026-05-18',NULL,NULL,'2026-05-18 21:33:51','2026-05-18 21:33:51',NULL,NULL,NULL,NULL),
(10,NULL,1,1,1,1,1,'Doação para Evento Beneficente',54.00,NULL,'2026-05-20','2026-05-19',NULL,NULL,'2026-05-19 21:37:27','2026-05-19 21:37:27',NULL,NULL,NULL,NULL),
(11,NULL,1,1,2,1,1,'mensalidade',60.00,NULL,'2026-05-19','2026-05-21',NULL,NULL,'2026-05-19 22:46:38','2026-05-19 22:46:38',NULL,NULL,NULL,NULL),
(12,NULL,NULL,NULL,NULL,NULL,1,'mensalidade - Parcela 1',100.00,NULL,'2026-05-19','2026-05-19',NULL,NULL,'2026-05-19 22:56:45','2026-05-19 22:56:45',NULL,2,NULL,NULL),
(13,NULL,NULL,NULL,NULL,NULL,1,'mensalidade - Parcela 2',100.00,NULL,'2026-05-19','2026-06-19',NULL,NULL,'2026-05-19 22:56:45','2026-05-19 22:56:45',NULL,2,NULL,NULL),
(14,NULL,NULL,NULL,NULL,NULL,1,'mensalidade - Parcela 3',100.00,NULL,'2026-05-19','2026-07-19',NULL,NULL,'2026-05-19 22:56:45','2026-05-19 22:56:45',NULL,2,NULL,NULL),
(15,NULL,NULL,NULL,NULL,NULL,1,'Doação - Parcela 1',100.00,NULL,'2026-05-19','2026-05-20',NULL,NULL,'2026-05-19 23:12:51','2026-05-19 23:12:51',NULL,3,1,12),
(51,NULL,1,1,2,1,1,'teste - Parcela 1',75.00,NULL,'2026-05-20','2026-05-19',NULL,NULL,'2026-05-20 00:03:56','2026-05-20 00:03:56',NULL,6,1,2),
(52,NULL,1,1,2,1,1,'teste - Parcela 2',75.00,NULL,'2026-05-20','2026-06-19',NULL,NULL,'2026-05-20 00:03:56','2026-05-20 00:03:56',NULL,6,2,2),
(53,NULL,3,3,12,1,1,'Conta de Energia elétrica',75.00,NULL,'2026-05-21','2026-05-22',NULL,NULL,'2026-05-23 00:30:12','2026-05-23 00:30:12',NULL,NULL,NULL,NULL),
(54,NULL,1,1,1,1,1,'LEONARDO PEREIRA LEOTE',50.00,NULL,'2026-05-27','2026-05-27',NULL,NULL,'2026-05-28 01:16:23','2026-05-28 01:16:23',NULL,NULL,NULL,NULL);


-- ─── CONFIGURAÇÕES ───────────────────────────────────────────
INSERT INTO `configuracoes` (`chave`, `valor`, `atualizado_em`) VALUES
('notif_vencimentos','false','2026-05-19 22:10:41'),
('notif_inadimplencia','false','2026-05-19 22:10:41'),
('notif_resumo_semanal','false','2026-05-19 22:10:41'),
('notif_novos_cadastros','false','2026-05-19 22:10:41'),
('seg_expirar_sessao','true','2026-05-19 22:10:41'),
('dias_alerta_vencimento','5','2026-05-19 22:10:41'),
('assoc_nome','Associação de Moradores do Bairro Califórnia','2026-05-19 22:10:41'),
('assoc_sigla','AMBC','2026-05-19 22:10:41'),
('assoc_cnpj','12.345.678/0001-90','2026-05-19 22:10:41'),
('assoc_email','contato@ambc.org.br','2026-05-19 22:10:41'),
('assoc_telefone','(51) 3333-0000','2026-05-19 22:10:41'),
('assoc_site','www.ambc.org.br','2026-05-19 22:10:41'),
('assoc_cep','90000-000','2026-05-19 22:10:41'),
('assoc_endereco','Rua das Flores, 100 – Bairro Califórnia','2026-05-19 22:10:41'),
('assoc_bairro','Bairro Califórnia','2026-05-19 22:10:41'),
('assoc_cidade','Porto Alegre','2026-05-19 22:10:41'),
('assoc_uf','RS','2026-05-19 22:10:41'),
('assoc_missao','Associação sem fins lucrativos que promove a melhoria da qualidade de vida dos moradores do Bairro Califórnia por meio de ações sociais, culturais e de infraestrutura.','2026-05-19 22:10:41'),
('tema','claro','2026-05-26 22:17:17')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `atualizado_em` = VALUES(`atualizado_em`);

-- Ajustar AUTO_INCREMENT para evitar conflito com IDs inseridos
ALTER TABLE `usuario`         AUTO_INCREMENT = 100;
ALTER TABLE `associado`       AUTO_INCREMENT = 100;
ALTER TABLE `parceiro`        AUTO_INCREMENT = 100;
ALTER TABLE `telefone`        AUTO_INCREMENT = 100;
ALTER TABLE `telefone_parceiro` AUTO_INCREMENT = 100;
ALTER TABLE `permissao_usuario` AUTO_INCREMENT = 200;
ALTER TABLE `conta_regente`   AUTO_INCREMENT = 20;
ALTER TABLE `conta_subordinada` AUTO_INCREMENT = 20;
ALTER TABLE `lancamento`      AUTO_INCREMENT = 100;

SET FOREIGN_KEY_CHECKS = 1;
