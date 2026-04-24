-- ============================================================
--  MIGRATION 001 — TABELAS DE DOMÍNIO
-- ============================================================

-- UP
-- ============================================================
-- @UP

CREATE TABLE genero (
    id_genero   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO genero (id_genero, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Feminino'),(2, 'Masculino'),(3, 'Não binário');


CREATE TABLE estado_civil (
    id_estadocivil  SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO estado_civil (id_estadocivil, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Solteiro(a)'),(2,'Casado(a)'),(3,'Divorciado(a)'),(4,'Viúvo(a)'),(5,'Amasiado(a)');


CREATE TABLE categoria (
    id_categoria    SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO categoria (id_categoria, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Fundador'),(2,'Honorário'),(3,'Contribuinte');


CREATE TABLE status_pessoa (
    id_status   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_pessoa (id_status, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Ativo'),(2,'Pendente'),(3,'Inativo');


CREATE TABLE profissao (
    id_profissao    SERIAL      PRIMARY KEY,
    descricao       VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO profissao (id_profissao, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Autônomo formal'),(2,'Autônomo informal'),(3,'Empregado informal'),
    (4,'Empregado formal'),(5,'Trabalhador doméstico'),(6,'Trabalhador rural'),
    (7,'Servidor público'),(8,'Aposentado/Pensionista'),(9,'Estudante'),
    (10,'Estagiário'),(11,'Não trabalha'),(12,'Outro');


CREATE TABLE parentesco (
    id_parentesco   SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE,
    observacao      TEXT
);
INSERT INTO parentesco (id_parentesco, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Filho(a)'),(2,'Enteado(a)'),(3,'Sobrinho(a)'),(4,'Neto(a)'),(5,'Outro');


CREATE TABLE uf (
    sigla   CHAR(2)     PRIMARY KEY,
    nome    VARCHAR(30) NOT NULL
);
INSERT INTO uf (sigla, nome) VALUES
    ('AC','Acre'),('AL','Alagoas'),('AP','Amapá'),('AM','Amazonas'),
    ('BA','Bahia'),('CE','Ceará'),('DF','Distrito Federal'),('ES','Espírito Santo'),
    ('GO','Goiás'),('MA','Maranhão'),('MT','Mato Grosso'),('MS','Mato Grosso do Sul'),
    ('MG','Minas Gerais'),('PA','Pará'),('PB','Paraíba'),('PR','Paraná'),
    ('PE','Pernambuco'),('PI','Piauí'),('RJ','Rio de Janeiro'),('RN','Rio Grande do Norte'),
    ('RS','Rio Grande do Sul'),('RO','Rondônia'),('RR','Roraima'),('SC','Santa Catarina'),
    ('SP','São Paulo'),('SE','Sergipe'),('TO','Tocantins');


CREATE TABLE forma_pagamento (
    id_forma_pagamento  SERIAL      PRIMARY KEY,
    descricao           VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO forma_pagamento (id_forma_pagamento, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'PIX'),(2,'Boleto'),(3,'Cartão de crédito'),
    (4,'Cartão de débito'),(5,'Dinheiro'),(6,'Transferência bancária');


CREATE TABLE status_conta (
    id_status_conta SERIAL      PRIMARY KEY,
    descricao       VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_conta (id_status_conta, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Aberto'),(2,'Liquidado'),(3,'Cancelado');


CREATE TABLE tipo_doacao (
    id_tipo_doacao  SERIAL      PRIMARY KEY,
    descricao       VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO tipo_doacao (id_tipo_doacao, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Dinheiro'),(2,'Alimentos e bebidas'),(3,'Brinquedos'),(4,'Outros itens');


CREATE TABLE status_reserva (
    id_status_reserva   SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_reserva (id_status_reserva, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Confirmado'),(2,'Cancelado'),(3,'Concluído');


CREATE TABLE status_agenda (
    id_status_agenda    SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_agenda (id_status_agenda, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Agendado'),(2,'Cancelado'),(3,'Concluído'),(4,'Suspenso');


CREATE TABLE tipo_documento (
    id_tipo_documento   SERIAL      PRIMARY KEY,
    descricao           VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO tipo_documento (id_tipo_documento, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Ata'),(2,'Ofício'),(3,'Mensagem'),(4,'Circular'),
    (5,'Requerimento'),(6,'Declaração'),(7,'Outro');


CREATE TABLE perfil_usuario (
    id_perfil   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE,
    observacao  TEXT
);
INSERT INTO perfil_usuario (id_perfil, descricao, observacao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Administrador','Acesso total ao sistema. Gerencia usuários e permissões.'),
    (2,'Gestor','Acesso operacional configurável pelo administrador.'),
    (3,'Visualizador','Somente leitura. Módulos visíveis configuráveis pelo administrador.');


CREATE TABLE modulo_sistema (
    id_modulo   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO modulo_sistema (id_modulo, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,'Dashboard'),(2,'Associados'),(3,'Parceiros'),(4,'Financeiro'),
    (5,'Reserva de Espaço'),(6,'Agenda'),(7,'Documentação'),(8,'Usuários e Permissões');


-- @DOWN
-- ============================================================

DROP TABLE IF EXISTS modulo_sistema;
DROP TABLE IF EXISTS perfil_usuario;
DROP TABLE IF EXISTS tipo_documento;
DROP TABLE IF EXISTS status_agenda;
DROP TABLE IF EXISTS status_reserva;
DROP TABLE IF EXISTS tipo_doacao;
DROP TABLE IF EXISTS status_conta;
DROP TABLE IF EXISTS forma_pagamento;
DROP TABLE IF EXISTS uf;
DROP TABLE IF EXISTS parentesco;
DROP TABLE IF EXISTS profissao;
DROP TABLE IF EXISTS status_pessoa;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS estado_civil;
DROP TABLE IF EXISTS genero;
