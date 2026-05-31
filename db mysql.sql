CREATE DATABASE IF NOT EXISTS ambc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ambc;

-- SQL usado pelo projeto AMBC convertido de PostgreSQL para MySQL
-- Origem: C:\Users\ResTIC55\Desktop\sql-banco-online-usado.md
-- Extraido do banco PostgreSQL online em 2026-05-28 15:48:04 (America/Sao_Paulo).
-- Conversao: schema sem dados, pensado para MySQL 8.0+ / InnoDB.
--
-- Observacoes:
-- - PostgreSQL sequences foram convertidas para AUTO_INCREMENT.
-- - PostgreSQL boolean foi convertido para TINYINT(1).
-- - PostgreSQL timestamp without time zone foi convertido para DATETIME.
-- - Triggers PL/pgSQL foram reescritas em sintaxe MySQL.
-- - A FK fk_lancamento_parcelamento foi mantida comentada porque a tabela
--   parcelamento nao esta incluida no SQL original.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

START TRANSACTION;

CREATE TABLE IF NOT EXISTS `associado` (
    `id_associado` INT NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(150) NOT NULL,
    `data_nascimento` DATE NOT NULL,
    `cpf_cnpj` VARCHAR(14),
    `email` VARCHAR(150),
    `observacao` TEXT,
    `ativo` TINYINT(1) DEFAULT 1,
    `logradouro` VARCHAR(200),
    `numero` VARCHAR(10),
    `complemento` VARCHAR(100),
    `cep` CHAR(8),
    `bairro` VARCHAR(100),
    `cidade` VARCHAR(100),
    `uf` CHAR(2),
    `fk_estadocivil` INT,
    `fk_profissao` INT,
    `fk_categoria` INT,
    `fk_status` INT,
    `fk_genero` INT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `matricula` VARCHAR(20),
    `data_entrada` DATE,
    CONSTRAINT `associado_pkey` PRIMARY KEY (`id_associado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `telefone` (
    `id_telefone` INT NOT NULL AUTO_INCREMENT,
    `fk_associado` INT NOT NULL,
    `ddd` CHAR(2) NOT NULL,
    `numero` VARCHAR(9) NOT NULL,
    `fk_tipo_telefone` INT,
    `observacao` VARCHAR(100),
    CONSTRAINT `telefone_pkey` PRIMARY KEY (`id_telefone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dependente` (
    `id_dependente` INT NOT NULL AUTO_INCREMENT,
    `fk_associado` INT,
    `nome` VARCHAR(150) NOT NULL,
    `data_nascimento` DATE NOT NULL,
    `cpf` CHAR(11),
    `observacao` TEXT,
    `fk_parentesco` INT,
    `fk_genero` INT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `ativo` TINYINT(1) DEFAULT 1,
    CONSTRAINT `dependente_pkey` PRIMARY KEY (`id_dependente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `parceiro` (
    `id_parceiro` INT NOT NULL AUTO_INCREMENT,
    `nome_razao_social` VARCHAR(200) NOT NULL,
    `cpf_cnpj` VARCHAR(14) NOT NULL,
    `email` VARCHAR(150),
    `ativo` TINYINT(1) DEFAULT 1,
    `logradouro` VARCHAR(200),
    `numero` VARCHAR(10),
    `complemento` VARCHAR(100),
    `cep` CHAR(8),
    `bairro` VARCHAR(100),
    `cidade` VARCHAR(100),
    `uf` CHAR(2),
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `tipo_servico` VARCHAR(100),
    `tipo_pessoa` CHAR(2) DEFAULT 'PF',
    CONSTRAINT `parceiro_pkey` PRIMARY KEY (`id_parceiro`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `telefone_parceiro` (
    `id_telefone_parceiro` INT NOT NULL AUTO_INCREMENT,
    `fk_parceiro` INT NOT NULL,
    `ddd` CHAR(2) NOT NULL,
    `numero` VARCHAR(9) NOT NULL,
    `fk_tipo_telefone` INT,
    `observacao` VARCHAR(100),
    CONSTRAINT `telefone_parceiro_pkey` PRIMARY KEY (`id_telefone_parceiro`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lancamento` (
    `id_lancamento` INT NOT NULL AUTO_INCREMENT,
    `fk_associado` INT,
    `fk_conta_regente` INT,
    `fk_conta_subordinada` INT,
    `fk_tipo_lancamento` INT,
    `fk_forma_pagamento` INT,
    `fk_status_conta` INT NOT NULL DEFAULT 1,
    `descricao` VARCHAR(200) NOT NULL,
    `valor` DECIMAL(10,2) NOT NULL,
    `valor_pago` DECIMAL(10,2),
    `data_lancamento` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `data_vencimento` DATE,
    `data_pagamento` DATE,
    `observacao` TEXT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `fk_parceiro` INT,
    `fk_parcelamento` INT,
    `numero_parcela` INT,
    `total_parcelas` INT,
    CONSTRAINT `lancamento_pkey` PRIMARY KEY (`id_lancamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `conta_regente` (
    `id_conta_regente` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(100) NOT NULL,
    `observacao` TEXT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `tipo` VARCHAR(10) NOT NULL DEFAULT 'receita',
    `ativo` TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT `conta_regente_pkey` PRIMARY KEY (`id_conta_regente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `conta_subordinada` (
    `id_conta_subordinada` INT NOT NULL AUTO_INCREMENT,
    `fk_conta_regente` INT NOT NULL,
    `descricao` VARCHAR(100) NOT NULL,
    `observacao` TEXT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `ativo` TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT `conta_subordinada_pkey` PRIMARY KEY (`id_conta_subordinada`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `categoria` (
    `id_categoria` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    CONSTRAINT `categoria_pkey` PRIMARY KEY (`id_categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `estado_civil` (
    `id_estadocivil` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    CONSTRAINT `estado_civil_pkey` PRIMARY KEY (`id_estadocivil`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `status_pessoa` (
    `id_status` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(20) NOT NULL,
    CONSTRAINT `status_pessoa_pkey` PRIMARY KEY (`id_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `genero` (
    `id_genero` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    CONSTRAINT `genero_pkey` PRIMARY KEY (`id_genero`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `profissao` (
    `id_profissao` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(50) NOT NULL,
    CONSTRAINT `profissao_pkey` PRIMARY KEY (`id_profissao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `parentesco` (
    `id_parentesco` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    `observacao` TEXT,
    CONSTRAINT `parentesco_pkey` PRIMARY KEY (`id_parentesco`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `uf` (
    `sigla` CHAR(2) NOT NULL,
    `nome` VARCHAR(30) NOT NULL,
    CONSTRAINT `uf_pkey` PRIMARY KEY (`sigla`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tipo_telefone` (
    `id_tipo_telefone` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(20) NOT NULL,
    CONSTRAINT `tipo_telefone_pkey` PRIMARY KEY (`id_tipo_telefone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `usuario` (
    `id_usuario` INT NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `senha_hash` VARCHAR(255),
    `fk_perfil` INT NOT NULL,
    `fk_associado` INT,
    `ativo` TINYINT(1) DEFAULT 1,
    `primeiro_acesso` TINYINT(1) DEFAULT 1,
    `ultimo_acesso` DATETIME,
    `token_reset` VARCHAR(255),
    `token_expira_em` DATETIME,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `usuario_pkey` PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `perfil_usuario` (
    `id_perfil` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    `observacao` TEXT,
    CONSTRAINT `perfil_usuario_pkey` PRIMARY KEY (`id_perfil`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permissao_usuario` (
    `id_permissao` INT NOT NULL AUTO_INCREMENT,
    `fk_usuario` INT NOT NULL,
    `fk_modulo` INT NOT NULL,
    `pode_acessar` TINYINT(1) DEFAULT 0,
    `pode_editar` TINYINT(1) DEFAULT 0,
    CONSTRAINT `permissao_usuario_pkey` PRIMARY KEY (`id_permissao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `modulo_sistema` (
    `id_modulo` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(50) NOT NULL,
    CONSTRAINT `modulo_sistema_pkey` PRIMARY KEY (`id_modulo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `documento` (
    `id_documento` INT NOT NULL AUTO_INCREMENT,
    `numero` INT,
    `ano` INT NOT NULL DEFAULT (YEAR(CURRENT_DATE)),
    `indice` VARCHAR(20),
    `fk_tipo_documento` INT,
    `tipo_livre` VARCHAR(50),
    `assunto` VARCHAR(200) NOT NULL,
    `data_documento` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `conteudo` TEXT,
    `arquivo_path` VARCHAR(500),
    `observacao` TEXT,
    `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por` INT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `atualizado_por` INT,
    `categoria` VARCHAR(20) NOT NULL DEFAULT 'operacional',
    `versao` VARCHAR(20),
    CONSTRAINT `documento_pkey` PRIMARY KEY (`id_documento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tipo_documento` (
    `id_tipo_documento` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(50) NOT NULL,
    CONSTRAINT `tipo_documento_pkey` PRIMARY KEY (`id_tipo_documento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `configuracoes` (
    `chave` VARCHAR(100) NOT NULL,
    `valor` TEXT,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `configuracoes_pkey` PRIMARY KEY (`chave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `configuracao_sistema` (
    `chave` VARCHAR(60) NOT NULL,
    `valor` TEXT NOT NULL,
    `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `configuracao_sistema_pkey` PRIMARY KEY (`chave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `forma_pagamento` (
    `id_forma_pagamento` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    CONSTRAINT `forma_pagamento_pkey` PRIMARY KEY (`id_forma_pagamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `status_conta` (
    `id_status_conta` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(20) NOT NULL,
    CONSTRAINT `status_conta_pkey` PRIMARY KEY (`id_status_conta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tipo_lancamento` (
    `id_tipo_lancamento` INT NOT NULL AUTO_INCREMENT,
    `descricao` VARCHAR(30) NOT NULL,
    `observacao` TEXT,
    CONSTRAINT `tipo_lancamento_pkey` PRIMARY KEY (`id_tipo_lancamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `associado` ADD CONSTRAINT `associado_cpf_cnpj_key` UNIQUE (`cpf_cnpj`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_matricula_key` UNIQUE (`matricula`);
ALTER TABLE `telefone` ADD CONSTRAINT `telefone_fk_associado_ddd_numero_key` UNIQUE (`fk_associado`, `ddd`, `numero`);
ALTER TABLE `parceiro` ADD CONSTRAINT `parceiro_cpf_cnpj_key` UNIQUE (`cpf_cnpj`);
ALTER TABLE `telefone_parceiro` ADD CONSTRAINT `telefone_parceiro_fk_parceiro_ddd_numero_key` UNIQUE (`fk_parceiro`, `ddd`, `numero`);
ALTER TABLE `conta_regente` ADD CONSTRAINT `conta_regente_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `categoria` ADD CONSTRAINT `categoria_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `estado_civil` ADD CONSTRAINT `estado_civil_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `status_pessoa` ADD CONSTRAINT `status_pessoa_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `genero` ADD CONSTRAINT `genero_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `profissao` ADD CONSTRAINT `profissao_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `parentesco` ADD CONSTRAINT `parentesco_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `tipo_telefone` ADD CONSTRAINT `tipo_telefone_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `usuario` ADD CONSTRAINT `usuario_email_key` UNIQUE (`email`);
ALTER TABLE `perfil_usuario` ADD CONSTRAINT `perfil_usuario_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `permissao_usuario` ADD CONSTRAINT `permissao_usuario_fk_usuario_fk_modulo_key` UNIQUE (`fk_usuario`, `fk_modulo`);
ALTER TABLE `modulo_sistema` ADD CONSTRAINT `modulo_sistema_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `documento` ADD CONSTRAINT `documento_numero_ano_key` UNIQUE (`numero`, `ano`);
ALTER TABLE `tipo_documento` ADD CONSTRAINT `tipo_documento_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `forma_pagamento` ADD CONSTRAINT `forma_pagamento_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `status_conta` ADD CONSTRAINT `status_conta_descricao_key` UNIQUE (`descricao`);
ALTER TABLE `tipo_lancamento` ADD CONSTRAINT `tipo_lancamento_descricao_key` UNIQUE (`descricao`);

ALTER TABLE `associado` ADD CONSTRAINT `chk_associado_nome_composto` CHECK (TRIM(`nome`) LIKE '% %');
ALTER TABLE `telefone` ADD CONSTRAINT `chk_telefone_ddd` CHECK (`ddd` REGEXP '^[0-9]+$');
ALTER TABLE `telefone` ADD CONSTRAINT `chk_telefone_numero` CHECK (`numero` REGEXP '^[0-9]+$');
ALTER TABLE `dependente` ADD CONSTRAINT `chk_dependente_nome_composto` CHECK (TRIM(`nome`) LIKE '% %');
ALTER TABLE `parceiro` ADD CONSTRAINT `chk_parceiro_nome_composto` CHECK (TRIM(`nome_razao_social`) LIKE '% %');
ALTER TABLE `parceiro` ADD CONSTRAINT `chk_parceiro_tipo_pessoa` CHECK (`tipo_pessoa` IN ('PF', 'PJ'));
ALTER TABLE `telefone_parceiro` ADD CONSTRAINT `chk_tel_parceiro_ddd` CHECK (`ddd` REGEXP '^[0-9]+$');
ALTER TABLE `telefone_parceiro` ADD CONSTRAINT `chk_tel_parceiro_numero` CHECK (`numero` REGEXP '^[0-9]+$');
ALTER TABLE `lancamento` ADD CONSTRAINT `chk_lancamento_pagamento` CHECK ((`data_pagamento` IS NULL AND `valor_pago` IS NULL) OR (`data_pagamento` IS NOT NULL AND `valor_pago` IS NOT NULL));
ALTER TABLE `lancamento` ADD CONSTRAINT `chk_lancamento_valor` CHECK (`valor` > 0);
ALTER TABLE `lancamento` ADD CONSTRAINT `chk_lancamento_valor_pago` CHECK (`valor_pago` IS NULL OR `valor_pago` >= 0);
ALTER TABLE `conta_regente` ADD CONSTRAINT `conta_regente_tipo_check` CHECK (`tipo` IN ('receita', 'despesa'));
ALTER TABLE `documento` ADD CONSTRAINT `chk_documento_tipo` CHECK ((`fk_tipo_documento` IS NOT NULL AND `tipo_livre` IS NULL) OR (`fk_tipo_documento` IS NULL AND `tipo_livre` IS NOT NULL));
ALTER TABLE `documento` ADD CONSTRAINT `documento_categoria_check` CHECK (`categoria` IN ('operacional', 'institucional'));

ALTER TABLE `associado` ADD CONSTRAINT `associado_fk_categoria_fkey` FOREIGN KEY (`fk_categoria`) REFERENCES `categoria`(`id_categoria`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_fk_estadocivil_fkey` FOREIGN KEY (`fk_estadocivil`) REFERENCES `estado_civil`(`id_estadocivil`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_fk_genero_fkey` FOREIGN KEY (`fk_genero`) REFERENCES `genero`(`id_genero`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_fk_profissao_fkey` FOREIGN KEY (`fk_profissao`) REFERENCES `profissao`(`id_profissao`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_fk_status_fkey` FOREIGN KEY (`fk_status`) REFERENCES `status_pessoa`(`id_status`);
ALTER TABLE `associado` ADD CONSTRAINT `associado_uf_fkey` FOREIGN KEY (`uf`) REFERENCES `uf`(`sigla`);
ALTER TABLE `associado` ADD CONSTRAINT `fk_assoc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `associado` ADD CONSTRAINT `fk_assoc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `telefone` ADD CONSTRAINT `telefone_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado`(`id_associado`) ON DELETE CASCADE;
ALTER TABLE `telefone` ADD CONSTRAINT `telefone_fk_tipo_telefone_fkey` FOREIGN KEY (`fk_tipo_telefone`) REFERENCES `tipo_telefone`(`id_tipo_telefone`);
ALTER TABLE `dependente` ADD CONSTRAINT `dependente_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado`(`id_associado`) ON DELETE CASCADE;
ALTER TABLE `dependente` ADD CONSTRAINT `dependente_fk_genero_fkey` FOREIGN KEY (`fk_genero`) REFERENCES `genero`(`id_genero`);
ALTER TABLE `dependente` ADD CONSTRAINT `dependente_fk_parentesco_fkey` FOREIGN KEY (`fk_parentesco`) REFERENCES `parentesco`(`id_parentesco`);
ALTER TABLE `parceiro` ADD CONSTRAINT `fk_parc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `parceiro` ADD CONSTRAINT `fk_parc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `parceiro` ADD CONSTRAINT `parceiro_uf_fkey` FOREIGN KEY (`uf`) REFERENCES `uf`(`sigla`);
ALTER TABLE `telefone_parceiro` ADD CONSTRAINT `telefone_parceiro_fk_parceiro_fkey` FOREIGN KEY (`fk_parceiro`) REFERENCES `parceiro`(`id_parceiro`) ON DELETE CASCADE;
ALTER TABLE `telefone_parceiro` ADD CONSTRAINT `telefone_parceiro_fk_tipo_telefone_fkey` FOREIGN KEY (`fk_tipo_telefone`) REFERENCES `tipo_telefone`(`id_tipo_telefone`);
-- ALTER TABLE `lancamento` ADD CONSTRAINT `fk_lancamento_parcelamento` FOREIGN KEY (`fk_parcelamento`) REFERENCES `parcelamento`(`id_parcelamento`);
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_atualizado_por_fkey` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_criado_por_fkey` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado`(`id_associado`) ON DELETE RESTRICT;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_conta_regente_fkey` FOREIGN KEY (`fk_conta_regente`) REFERENCES `conta_regente`(`id_conta_regente`) ON DELETE RESTRICT;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_conta_subordinada_fkey` FOREIGN KEY (`fk_conta_subordinada`) REFERENCES `conta_subordinada`(`id_conta_subordinada`) ON DELETE RESTRICT;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_forma_pagamento_fkey` FOREIGN KEY (`fk_forma_pagamento`) REFERENCES `forma_pagamento`(`id_forma_pagamento`);
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_parceiro_fkey` FOREIGN KEY (`fk_parceiro`) REFERENCES `parceiro`(`id_parceiro`) ON DELETE SET NULL;
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_status_conta_fkey` FOREIGN KEY (`fk_status_conta`) REFERENCES `status_conta`(`id_status_conta`);
ALTER TABLE `lancamento` ADD CONSTRAINT `lancamento_fk_tipo_lancamento_fkey` FOREIGN KEY (`fk_tipo_lancamento`) REFERENCES `tipo_lancamento`(`id_tipo_lancamento`);
ALTER TABLE `conta_regente` ADD CONSTRAINT `fk_cr_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `conta_regente` ADD CONSTRAINT `fk_cr_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `conta_subordinada` ADD CONSTRAINT `conta_subordinada_fk_conta_regente_fkey` FOREIGN KEY (`fk_conta_regente`) REFERENCES `conta_regente`(`id_conta_regente`) ON DELETE RESTRICT;
ALTER TABLE `conta_subordinada` ADD CONSTRAINT `fk_cs_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `conta_subordinada` ADD CONSTRAINT `fk_cs_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `usuario` ADD CONSTRAINT `usuario_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado`(`id_associado`) ON DELETE SET NULL;
ALTER TABLE `usuario` ADD CONSTRAINT `usuario_fk_perfil_fkey` FOREIGN KEY (`fk_perfil`) REFERENCES `perfil_usuario`(`id_perfil`);
ALTER TABLE `permissao_usuario` ADD CONSTRAINT `permissao_usuario_fk_modulo_fkey` FOREIGN KEY (`fk_modulo`) REFERENCES `modulo_sistema`(`id_modulo`);
ALTER TABLE `permissao_usuario` ADD CONSTRAINT `permissao_usuario_fk_usuario_fkey` FOREIGN KEY (`fk_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE;
ALTER TABLE `documento` ADD CONSTRAINT `documento_fk_tipo_documento_fkey` FOREIGN KEY (`fk_tipo_documento`) REFERENCES `tipo_documento`(`id_tipo_documento`);
ALTER TABLE `documento` ADD CONSTRAINT `fk_doc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;
ALTER TABLE `documento` ADD CONSTRAINT `fk_doc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL;

CREATE INDEX `idx_associado_nome` ON `associado` (`nome`);
CREATE INDEX `idx_telefone_tipo` ON `telefone` (`fk_tipo_telefone`);
CREATE INDEX `idx_dependente_ativo` ON `dependente` (`ativo`);
CREATE INDEX `idx_dependente_nascimento` ON `dependente` (`data_nascimento`);
CREATE INDEX `idx_parceiro_nome` ON `parceiro` (`nome_razao_social`);
CREATE INDEX `idx_parceiro_tipo_pessoa` ON `parceiro` (`tipo_pessoa`);
CREATE INDEX `idx_telefone_parceiro_tipo` ON `telefone_parceiro` (`fk_tipo_telefone`);
CREATE INDEX `idx_lancamento_associado` ON `lancamento` (`fk_associado`);
CREATE INDEX `idx_lancamento_conta_regente` ON `lancamento` (`fk_conta_regente`);
CREATE INDEX `idx_lancamento_conta_subordinada` ON `lancamento` (`fk_conta_subordinada`);
CREATE INDEX `idx_lancamento_data_lancamento` ON `lancamento` (`data_lancamento`);
CREATE INDEX `idx_lancamento_fk_parceiro` ON `lancamento` (`fk_parceiro`);
CREATE INDEX `idx_lancamento_status` ON `lancamento` (`fk_status_conta`);
CREATE INDEX `idx_lancamento_tipo` ON `lancamento` (`fk_tipo_lancamento`);
CREATE INDEX `idx_lancamento_vencimento` ON `lancamento` (`data_vencimento`);
CREATE INDEX `idx_documento_indice` ON `documento` (`ano`, `numero`);

DELIMITER $$

CREATE TRIGGER `trg_cpf_cnpj_associado_insert`
BEFORE INSERT ON `associado`
FOR EACH ROW
BEGIN
    IF NEW.`cpf_cnpj` IS NOT NULL THEN
        IF NEW.`cpf_cnpj` REGEXP '[^0-9]' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ deve conter apenas numeros.';
        END IF;

        IF CHAR_LENGTH(NEW.`cpf_cnpj`) NOT IN (11, 14) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ invalido. Informe 11 digitos para CPF ou 14 para CNPJ.';
        END IF;
    END IF;
END$$

CREATE TRIGGER `trg_cpf_cnpj_associado_update`
BEFORE UPDATE ON `associado`
FOR EACH ROW
BEGIN
    IF NEW.`cpf_cnpj` IS NOT NULL THEN
        IF NEW.`cpf_cnpj` REGEXP '[^0-9]' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ deve conter apenas numeros.';
        END IF;

        IF CHAR_LENGTH(NEW.`cpf_cnpj`) NOT IN (11, 14) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ invalido. Informe 11 digitos para CPF ou 14 para CNPJ.';
        END IF;
    END IF;
END$$

CREATE TRIGGER `trg_cpf_cnpj_parceiro_insert`
BEFORE INSERT ON `parceiro`
FOR EACH ROW
BEGIN
    IF NEW.`cpf_cnpj` IS NOT NULL THEN
        IF NEW.`cpf_cnpj` REGEXP '[^0-9]' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ deve conter apenas numeros.';
        END IF;

        IF CHAR_LENGTH(NEW.`cpf_cnpj`) NOT IN (11, 14) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ invalido. Informe 11 digitos para CPF ou 14 para CNPJ.';
        END IF;
    END IF;
END$$

CREATE TRIGGER `trg_cpf_cnpj_parceiro_update`
BEFORE UPDATE ON `parceiro`
FOR EACH ROW
BEGIN
    IF NEW.`cpf_cnpj` IS NOT NULL THEN
        IF NEW.`cpf_cnpj` REGEXP '[^0-9]' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ deve conter apenas numeros.';
        END IF;

        IF CHAR_LENGTH(NEW.`cpf_cnpj`) NOT IN (11, 14) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF/CNPJ invalido. Informe 11 digitos para CPF ou 14 para CNPJ.';
        END IF;
    END IF;
END$$

CREATE TRIGGER `trg_ts_associado`
BEFORE UPDATE ON `associado`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_dependente`
BEFORE UPDATE ON `dependente`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_parceiro`
BEFORE UPDATE ON `parceiro`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_lancamento`
BEFORE UPDATE ON `lancamento`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_conta_regente`
BEFORE UPDATE ON `conta_regente`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_conta_sub`
BEFORE UPDATE ON `conta_subordinada`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_usuario`
BEFORE UPDATE ON `usuario`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER `trg_ts_documento`
BEFORE UPDATE ON `documento`
FOR EACH ROW
BEGIN
    SET NEW.`atualizado_em` = CURRENT_TIMESTAMP;
END$$

DELIMITER ;

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;

