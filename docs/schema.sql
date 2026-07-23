-- ============================================================
-- AMBC — Schema do Banco de Dados
-- Versão: 2.0  |  Gerado em: 23/07/2026
--
-- Conteúdo:
--   - Estrutura completa de todas as tabelas
--   - Dados de referência (categorias, status, tipos, UFs, etc.)
--   - Perfis de acesso e módulos do sistema
--   - 1 usuário administrador genérico
--   - Nenhum dado pessoal ou de teste
--
-- Usuário padrão:
--   Login: admin@ambc.com
--   Senha: admin123   ← altere após o primeiro acesso
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

DROP TABLE IF EXISTS `associado`;

CREATE TABLE `associado` (
  `id_associado` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_nascimento` date DEFAULT NULL,
  `cpf_cnpj` varchar(14) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `ativo` tinyint(1) DEFAULT '1',
  `logradouro` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `complemento` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cep` char(8) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bairro` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cidade` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uf` char(2) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fk_estadocivil` int DEFAULT NULL,
  `fk_profissao` int DEFAULT NULL,
  `fk_categoria` int DEFAULT NULL,
  `fk_status` int DEFAULT NULL,
  `fk_genero` int DEFAULT NULL,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `matricula` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_entrada` date DEFAULT NULL,
  PRIMARY KEY (`id_associado`),
  UNIQUE KEY `associado_cpf_cnpj_key` (`cpf_cnpj`),
  UNIQUE KEY `associado_matricula_key` (`matricula`),
  KEY `associado_fk_categoria_fkey` (`fk_categoria`),
  KEY `associado_fk_estadocivil_fkey` (`fk_estadocivil`),
  KEY `associado_fk_genero_fkey` (`fk_genero`),
  KEY `associado_fk_profissao_fkey` (`fk_profissao`),
  KEY `associado_fk_status_fkey` (`fk_status`),
  KEY `associado_uf_fkey` (`uf`),
  KEY `fk_assoc_atualizado_por` (`atualizado_por`),
  KEY `fk_assoc_criado_por` (`criado_por`),
  KEY `idx_associado_nome` (`nome`),
  CONSTRAINT `associado_fk_categoria_fkey` FOREIGN KEY (`fk_categoria`) REFERENCES `categoria` (`id_categoria`),
  CONSTRAINT `associado_fk_estadocivil_fkey` FOREIGN KEY (`fk_estadocivil`) REFERENCES `estado_civil` (`id_estadocivil`),
  CONSTRAINT `associado_fk_genero_fkey` FOREIGN KEY (`fk_genero`) REFERENCES `genero` (`id_genero`),
  CONSTRAINT `associado_fk_profissao_fkey` FOREIGN KEY (`fk_profissao`) REFERENCES `profissao` (`id_profissao`),
  CONSTRAINT `associado_fk_status_fkey` FOREIGN KEY (`fk_status`) REFERENCES `status_pessoa` (`id_status`),
  CONSTRAINT `associado_uf_fkey` FOREIGN KEY (`uf`) REFERENCES `uf` (`sigla`),
  CONSTRAINT `fk_assoc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_assoc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `chk_associado_nome_composto` CHECK ((trim(`nome`) like _utf8mb4'% %'))
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `categoria`;

CREATE TABLE `categoria` (
  `id_categoria` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_categoria`),
  UNIQUE KEY `categoria_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `categoria` VALUES (3,'Contribuinte'),(1,'Fundador'),(2,'Honorário');
DROP TABLE IF EXISTS `configuracao_sistema`;

CREATE TABLE `configuracao_sistema` (
  `chave` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`chave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `configuracoes`;

CREATE TABLE `configuracoes` (
  `chave` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` longtext COLLATE utf8mb4_unicode_ci,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`chave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `conta_regente`;

CREATE TABLE `conta_regente` (
  `id_conta_regente` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `tipo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'receita',
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_conta_regente`),
  UNIQUE KEY `conta_regente_descricao_key` (`descricao`),
  KEY `fk_cr_atualizado_por` (`atualizado_por`),
  KEY `fk_cr_criado_por` (`criado_por`),
  CONSTRAINT `fk_cr_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_cr_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `conta_regente_tipo_check` CHECK ((`tipo` in (_utf8mb4'receita',_utf8mb4'despesa')))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `conta_subordinada`;

CREATE TABLE `conta_subordinada` (
  `id_conta_subordinada` int NOT NULL AUTO_INCREMENT,
  `fk_conta_regente` int NOT NULL,
  `descricao` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_conta_subordinada`),
  KEY `conta_subordinada_fk_conta_regente_fkey` (`fk_conta_regente`),
  KEY `fk_cs_atualizado_por` (`atualizado_por`),
  KEY `fk_cs_criado_por` (`criado_por`),
  CONSTRAINT `conta_subordinada_fk_conta_regente_fkey` FOREIGN KEY (`fk_conta_regente`) REFERENCES `conta_regente` (`id_conta_regente`) ON DELETE RESTRICT,
  CONSTRAINT `fk_cs_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_cs_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `dependente`;

CREATE TABLE `dependente` (
  `id_dependente` int NOT NULL AUTO_INCREMENT,
  `fk_associado` int DEFAULT NULL,
  `nome` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_nascimento` date NOT NULL,
  `cpf` char(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `fk_parentesco` int DEFAULT NULL,
  `fk_genero` int DEFAULT NULL,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `ativo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_dependente`),
  KEY `dependente_fk_associado_fkey` (`fk_associado`),
  KEY `dependente_fk_genero_fkey` (`fk_genero`),
  KEY `dependente_fk_parentesco_fkey` (`fk_parentesco`),
  KEY `idx_dependente_ativo` (`ativo`),
  KEY `idx_dependente_nascimento` (`data_nascimento`),
  CONSTRAINT `dependente_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado` (`id_associado`) ON DELETE CASCADE,
  CONSTRAINT `dependente_fk_genero_fkey` FOREIGN KEY (`fk_genero`) REFERENCES `genero` (`id_genero`),
  CONSTRAINT `dependente_fk_parentesco_fkey` FOREIGN KEY (`fk_parentesco`) REFERENCES `parentesco` (`id_parentesco`),
  CONSTRAINT `chk_dependente_nome_composto` CHECK ((trim(`nome`) like _utf8mb4'% %'))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `documento`;

CREATE TABLE `documento` (
  `id_documento` int NOT NULL AUTO_INCREMENT,
  `numero` int DEFAULT NULL,
  `ano` int NOT NULL DEFAULT (year(curdate())),
  `indice` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fk_tipo_documento` int DEFAULT NULL,
  `tipo_livre` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assunto` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_documento` date NOT NULL DEFAULT (curdate()),
  `conteudo` text COLLATE utf8mb4_unicode_ci,
  `arquivo_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `categoria` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'operacional',
  `versao` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_documento`),
  UNIQUE KEY `documento_numero_ano_key` (`numero`,`ano`),
  KEY `documento_fk_tipo_documento_fkey` (`fk_tipo_documento`),
  KEY `fk_doc_atualizado_por` (`atualizado_por`),
  KEY `fk_doc_criado_por` (`criado_por`),
  KEY `idx_documento_indice` (`ano`,`numero`),
  CONSTRAINT `documento_fk_tipo_documento_fkey` FOREIGN KEY (`fk_tipo_documento`) REFERENCES `tipo_documento` (`id_tipo_documento`),
  CONSTRAINT `fk_doc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_doc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `chk_documento_tipo` CHECK ((((`fk_tipo_documento` is not null) and (`tipo_livre` is null)) or ((`fk_tipo_documento` is null) and (`tipo_livre` is not null)))),
  CONSTRAINT `documento_categoria_check` CHECK ((`categoria` in (_utf8mb4'operacional',_utf8mb4'institucional')))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `estado_civil`;

CREATE TABLE `estado_civil` (
  `id_estadocivil` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_estadocivil`),
  UNIQUE KEY `estado_civil_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `estado_civil` VALUES (2,'Casado(a)'),(3,'Divorciado(a)'),(1,'Solteiro(a)'),(4,'Viúvo(a)');
DROP TABLE IF EXISTS `forma_pagamento`;

CREATE TABLE `forma_pagamento` (
  `id_forma_pagamento` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_forma_pagamento`),
  UNIQUE KEY `forma_pagamento_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `forma_pagamento` VALUES (2,'Boleto'),(3,'Cartão de crédito'),(4,'Cartão de débito'),(5,'Dinheiro'),(1,'PIX'),(6,'Transferência bancária');
DROP TABLE IF EXISTS `genero`;

CREATE TABLE `genero` (
  `id_genero` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_genero`),
  UNIQUE KEY `genero_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `genero` VALUES (1,'Feminino'),(2,'Masculino'),(3,'Outro'),(7,'Prefiro não informar.');
DROP TABLE IF EXISTS `lancamento`;

CREATE TABLE `lancamento` (
  `id_lancamento` int NOT NULL AUTO_INCREMENT,
  `fk_associado` int DEFAULT NULL,
  `fk_conta_regente` int DEFAULT NULL,
  `fk_conta_subordinada` int DEFAULT NULL,
  `fk_tipo_lancamento` int DEFAULT NULL,
  `fk_forma_pagamento` int DEFAULT NULL,
  `fk_status_conta` int NOT NULL DEFAULT '1',
  `descricao` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `valor_pago` decimal(10,2) DEFAULT NULL,
  `data_lancamento` date NOT NULL DEFAULT (curdate()),
  `data_vencimento` date DEFAULT NULL,
  `data_pagamento` date DEFAULT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `fk_parceiro` int DEFAULT NULL,
  `fk_parcelamento` int DEFAULT NULL,
  `numero_parcela` int DEFAULT NULL,
  `total_parcelas` int DEFAULT NULL,
  PRIMARY KEY (`id_lancamento`),
  KEY `lancamento_atualizado_por_fkey` (`atualizado_por`),
  KEY `lancamento_criado_por_fkey` (`criado_por`),
  KEY `lancamento_fk_forma_pagamento_fkey` (`fk_forma_pagamento`),
  KEY `idx_lancamento_associado` (`fk_associado`),
  KEY `idx_lancamento_conta_regente` (`fk_conta_regente`),
  KEY `idx_lancamento_conta_subordinada` (`fk_conta_subordinada`),
  KEY `idx_lancamento_data_lancamento` (`data_lancamento`),
  KEY `idx_lancamento_fk_parceiro` (`fk_parceiro`),
  KEY `idx_lancamento_status` (`fk_status_conta`),
  KEY `idx_lancamento_tipo` (`fk_tipo_lancamento`),
  KEY `idx_lancamento_vencimento` (`data_vencimento`),
  CONSTRAINT `lancamento_atualizado_por_fkey` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `lancamento_criado_por_fkey` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `lancamento_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado` (`id_associado`) ON DELETE RESTRICT,
  CONSTRAINT `lancamento_fk_conta_regente_fkey` FOREIGN KEY (`fk_conta_regente`) REFERENCES `conta_regente` (`id_conta_regente`) ON DELETE RESTRICT,
  CONSTRAINT `lancamento_fk_conta_subordinada_fkey` FOREIGN KEY (`fk_conta_subordinada`) REFERENCES `conta_subordinada` (`id_conta_subordinada`) ON DELETE RESTRICT,
  CONSTRAINT `lancamento_fk_forma_pagamento_fkey` FOREIGN KEY (`fk_forma_pagamento`) REFERENCES `forma_pagamento` (`id_forma_pagamento`),
  CONSTRAINT `lancamento_fk_parceiro_fkey` FOREIGN KEY (`fk_parceiro`) REFERENCES `parceiro` (`id_parceiro`) ON DELETE SET NULL,
  CONSTRAINT `lancamento_fk_status_conta_fkey` FOREIGN KEY (`fk_status_conta`) REFERENCES `status_conta` (`id_status_conta`),
  CONSTRAINT `lancamento_fk_tipo_lancamento_fkey` FOREIGN KEY (`fk_tipo_lancamento`) REFERENCES `tipo_lancamento` (`id_tipo_lancamento`),
  CONSTRAINT `chk_lancamento_pagamento` CHECK ((((`data_pagamento` is null) and (`valor_pago` is null)) or ((`data_pagamento` is not null) and (`valor_pago` is not null)))),
  CONSTRAINT `chk_lancamento_valor` CHECK ((`valor` > 0)),
  CONSTRAINT `chk_lancamento_valor_pago` CHECK (((`valor_pago` is null) or (`valor_pago` >= 0)))
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `modulo_sistema`;

CREATE TABLE `modulo_sistema` (
  `id_modulo` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_modulo`),
  UNIQUE KEY `modulo_sistema_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `modulo_sistema` VALUES (2,'Associados'),(8,'Configuracoes'),(1,'Dashboard'),(3,'Dependentes'),(6,'Documentos'),(4,'Financeiro'),(5,'Parceiros'),(7,'Usuarios');
DROP TABLE IF EXISTS `parceiro`;

CREATE TABLE `parceiro` (
  `id_parceiro` int NOT NULL AUTO_INCREMENT,
  `nome_razao_social` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cpf_cnpj` varchar(14) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT '1',
  `logradouro` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `complemento` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cep` char(8) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bairro` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cidade` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uf` char(2) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  `tipo_servico` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_pessoa` char(2) COLLATE utf8mb4_unicode_ci DEFAULT 'PF',
  PRIMARY KEY (`id_parceiro`),
  UNIQUE KEY `parceiro_cpf_cnpj_key` (`cpf_cnpj`),
  KEY `fk_parc_atualizado_por` (`atualizado_por`),
  KEY `fk_parc_criado_por` (`criado_por`),
  KEY `parceiro_uf_fkey` (`uf`),
  KEY `idx_parceiro_nome` (`nome_razao_social`),
  KEY `idx_parceiro_tipo_pessoa` (`tipo_pessoa`),
  CONSTRAINT `fk_parc_atualizado_por` FOREIGN KEY (`atualizado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_parc_criado_por` FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `parceiro_uf_fkey` FOREIGN KEY (`uf`) REFERENCES `uf` (`sigla`),
  CONSTRAINT `chk_parceiro_nome_composto` CHECK ((trim(`nome_razao_social`) like _utf8mb4'% %')),
  CONSTRAINT `chk_parceiro_tipo_pessoa` CHECK ((`tipo_pessoa` in (_utf8mb4'PF',_utf8mb4'PJ')))
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `parentesco`;

CREATE TABLE `parentesco` (
  `id_parentesco` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id_parentesco`),
  UNIQUE KEY `parentesco_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `parentesco` VALUES (1,'Filho(a)',NULL),(2,'Enteado(a)',NULL),(3,'Sobrinho(a)',NULL),(4,'Neto(a)',NULL),(5,'Outro',NULL);
DROP TABLE IF EXISTS `perfil_usuario`;

CREATE TABLE `perfil_usuario` (
  `id_perfil` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id_perfil`),
  UNIQUE KEY `perfil_usuario_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `permissao_usuario`;

CREATE TABLE `permissao_usuario` (
  `id_permissao` int NOT NULL AUTO_INCREMENT,
  `fk_usuario` int NOT NULL,
  `fk_modulo` int NOT NULL,
  `pode_acessar` tinyint(1) DEFAULT '0',
  `pode_editar` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id_permissao`),
  UNIQUE KEY `permissao_usuario_fk_usuario_fk_modulo_key` (`fk_usuario`,`fk_modulo`),
  KEY `permissao_usuario_fk_modulo_fkey` (`fk_modulo`),
  CONSTRAINT `permissao_usuario_fk_modulo_fkey` FOREIGN KEY (`fk_modulo`) REFERENCES `modulo_sistema` (`id_modulo`),
  CONSTRAINT `permissao_usuario_fk_usuario_fkey` FOREIGN KEY (`fk_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=137 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `plano_associacao`;

CREATE TABLE `plano_associacao` (
  `id_plano` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `preco` decimal(10,2) NOT NULL DEFAULT '0.00',
  `periodo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'anuidade',
  `beneficios` json NOT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  `ordem` int NOT NULL DEFAULT '0',
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_plano`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `profissao`;

CREATE TABLE `profissao` (
  `id_profissao` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_profissao`),
  UNIQUE KEY `profissao_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `profissao` VALUES (8,'Aposentado/Pensionista'),(1,'Autônomo formal'),(2,'Autônomo informal'),(4,'Empregado formal'),(3,'Empregado informal'),(10,'Estagiário'),(9,'Estudante'),(13,'médico'),(11,'Não trabalha'),(12,'Outro'),(7,'Servidor público'),(5,'Trabalhador doméstico');
DROP TABLE IF EXISTS `relacionamento_lancamento`;

CREATE TABLE `relacionamento_lancamento` (
  `id_relacionamento` int NOT NULL AUTO_INCREMENT,
  `fk_tipo_lancamento` int NOT NULL,
  `fk_conta_regente` int NOT NULL,
  `fk_conta_subordinada` int NOT NULL,
  `natureza` enum('RECEBER','PAGAR') COLLATE utf8mb4_unicode_ci NOT NULL,
  `modo` enum('FIXO','SUGERIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'FIXO',
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  `observacao` text COLLATE utf8mb4_unicode_ci,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `criado_por` int DEFAULT NULL,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `atualizado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_relacionamento`),
  KEY `rel_lanc_fk_tipo` (`fk_tipo_lancamento`),
  KEY `rel_lanc_fk_regente` (`fk_conta_regente`),
  KEY `rel_lanc_fk_subordinada` (`fk_conta_subordinada`),
  CONSTRAINT `rel_lanc_fk_regente` FOREIGN KEY (`fk_conta_regente`) REFERENCES `conta_regente` (`id_conta_regente`),
  CONSTRAINT `rel_lanc_fk_subordinada` FOREIGN KEY (`fk_conta_subordinada`) REFERENCES `conta_subordinada` (`id_conta_subordinada`),
  CONSTRAINT `rel_lanc_fk_tipo` FOREIGN KEY (`fk_tipo_lancamento`) REFERENCES `tipo_lancamento` (`id_tipo_lancamento`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `status_conta`;

CREATE TABLE `status_conta` (
  `id_status_conta` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_status_conta`),
  UNIQUE KEY `status_conta_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `status_conta` VALUES (1,'Aberto'),(3,'Cancelado'),(2,'Liquidado');
DROP TABLE IF EXISTS `status_pessoa`;

CREATE TABLE `status_pessoa` (
  `id_status` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_status`),
  UNIQUE KEY `status_pessoa_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `status_pessoa` VALUES (1,'Ativo'),(3,'Inativo'),(2,'Pendente');
DROP TABLE IF EXISTS `telefone`;

CREATE TABLE `telefone` (
  `id_telefone` int NOT NULL AUTO_INCREMENT,
  `fk_associado` int NOT NULL,
  `ddd` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fk_tipo_telefone` int DEFAULT NULL,
  `observacao` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_telefone`),
  UNIQUE KEY `telefone_fk_associado_ddd_numero_key` (`fk_associado`,`ddd`,`numero`),
  KEY `idx_telefone_tipo` (`fk_tipo_telefone`),
  CONSTRAINT `telefone_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado` (`id_associado`) ON DELETE CASCADE,
  CONSTRAINT `telefone_fk_tipo_telefone_fkey` FOREIGN KEY (`fk_tipo_telefone`) REFERENCES `tipo_telefone` (`id_tipo_telefone`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `telefone_parceiro`;

CREATE TABLE `telefone_parceiro` (
  `id_telefone_parceiro` int NOT NULL AUTO_INCREMENT,
  `fk_parceiro` int NOT NULL,
  `ddd` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fk_tipo_telefone` int DEFAULT NULL,
  `observacao` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_telefone_parceiro`),
  UNIQUE KEY `telefone_parceiro_fk_parceiro_ddd_numero_key` (`fk_parceiro`,`ddd`,`numero`),
  KEY `idx_telefone_parceiro_tipo` (`fk_tipo_telefone`),
  CONSTRAINT `telefone_parceiro_fk_parceiro_fkey` FOREIGN KEY (`fk_parceiro`) REFERENCES `parceiro` (`id_parceiro`) ON DELETE CASCADE,
  CONSTRAINT `telefone_parceiro_fk_tipo_telefone_fkey` FOREIGN KEY (`fk_tipo_telefone`) REFERENCES `tipo_telefone` (`id_tipo_telefone`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS `tipo_documento`;

CREATE TABLE `tipo_documento` (
  `id_tipo_documento` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_tipo_documento`),
  UNIQUE KEY `tipo_documento_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `tipo_documento` VALUES (1,'Ata'),(4,'Circular'),(6,'Declaração'),(8,'Estatuto'),(3,'Mensagem'),(2,'Ofício'),(7,'Outro'),(9,'Regimento Interno'),(5,'Requerimento');
DROP TABLE IF EXISTS `tipo_lancamento`;

CREATE TABLE `tipo_lancamento` (
  `id_tipo_lancamento` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observacao` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id_tipo_lancamento`),
  UNIQUE KEY `tipo_lancamento_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `tipo_lancamento` VALUES (1,'Anuidade',NULL),(2,'Mensalidade',NULL),(3,'Doação',NULL),(4,'Multa',NULL),(5,'Outro',NULL),(6,'Mensalidades',NULL),(10,'Multa por Atraso','Multa por atraso no pagamento'),(11,'Manutenção','Despesa de manutenção da associação'),(12,'Conta de Energia Elétrica',NULL);
DROP TABLE IF EXISTS `tipo_telefone`;

CREATE TABLE `tipo_telefone` (
  `id_tipo_telefone` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_tipo_telefone`),
  UNIQUE KEY `tipo_telefone_descricao_key` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `tipo_telefone` VALUES (1,'Celular'),(3,'Comercial'),(5,'Outro'),(2,'Residencial'),(4,'WhatsApp');
DROP TABLE IF EXISTS `uf`;

CREATE TABLE `uf` (
  `sigla` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nome` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`sigla`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `uf` VALUES ('AC','Acre'),('AL','Alagoas'),('AM','Amazonas'),('AP','Amapá'),('BA','Bahia'),('CE','Ceará'),('DF','Distrito Federal'),('ES','Espírito Santo'),('GO','Goiás'),('MA','Maranhão'),('MG','Minas Gerais'),('MS','Mato Grosso do Sul'),('MT','Mato Grosso'),('PA','Pará'),('PB','Paraíba'),('PE','Pernambuco'),('PI','Piauí'),('PR','Paraná'),('RJ','Rio de Janeiro'),('RN','Rio Grande do Norte'),('RO','Rondônia'),('RR','Roraima'),('RS','Rio Grande do Sul'),('SC','Santa Catarina'),('SE','Sergipe'),('SP','São Paulo'),('TO','Tocantins');
DROP TABLE IF EXISTS `usuario`;

CREATE TABLE `usuario` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `senha_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fk_perfil` int NOT NULL,
  `fk_associado` int DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT '1',
  `primeiro_acesso` tinyint(1) DEFAULT '1',
  `ultimo_acesso` datetime DEFAULT NULL,
  `token_reset` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token_expira_em` datetime DEFAULT NULL,
  `criado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `usuario_email_key` (`email`),
  KEY `usuario_fk_associado_fkey` (`fk_associado`),
  KEY `usuario_fk_perfil_fkey` (`fk_perfil`),
  CONSTRAINT `usuario_fk_associado_fkey` FOREIGN KEY (`fk_associado`) REFERENCES `associado` (`id_associado`) ON DELETE SET NULL,
  CONSTRAINT `usuario_fk_perfil_fkey` FOREIGN KEY (`fk_perfil`) REFERENCES `perfil_usuario` (`id_perfil`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- PERFIS DE ACESSO
-- ============================================================
INSERT INTO `perfil_usuario` (`id_perfil`, `descricao`, `observacao`) VALUES
  (1, 'Administrador', NULL),
  (2, 'Gestor', 'Acesso operacional configurável pelo administrador.'),
  (3, 'Visualizador', 'Somente leitura. Módulos visíveis configuráveis pelo administrador.')
  ON DUPLICATE KEY UPDATE `descricao` = VALUES(`descricao`);

-- ============================================================
-- MÓDULOS DO SISTEMA
-- ============================================================
INSERT INTO `modulo_sistema` (`id_modulo`, `descricao`) VALUES
  (1, 'Dashboard'),
  (2, 'Associados'),
  (3, 'Dependentes'),
  (4, 'Financeiro'),
  (5, 'Parceiros'),
  (6, 'Documentos'),
  (7, 'Usuarios'),
  (8, 'Configuracoes')
  ON DUPLICATE KEY UPDATE `descricao` = VALUES(`descricao`);

-- ============================================================
-- CONTAS FINANCEIRAS BASE
-- ============================================================
INSERT INTO `conta_regente` (`id_conta_regente`, `descricao`, `tipo`, `ativo`) VALUES
  (1, 'Receitas Associação', 'receita', 1),
  (2, 'Despesas Associação', 'despesa', 1)
  ON DUPLICATE KEY UPDATE `descricao` = VALUES(`descricao`);

INSERT INTO `conta_subordinada` (`id_conta_subordinada`, `fk_conta_regente`, `descricao`, `ativo`) VALUES
  (1, 1, 'Mensalidade', 1),
  (2, 2, 'Manutenção', 1)
  ON DUPLICATE KEY UPDATE `descricao` = VALUES(`descricao`);

-- ============================================================
-- TIPOS DE LANÇAMENTO E RELACIONAMENTOS
-- ============================================================
INSERT INTO `tipo_lancamento` (`id_tipo_lancamento`, `descricao`) VALUES
  (1, 'Anuidade'),
  (2, 'Mensalidade'),
  (3, 'Doação'),
  (4, 'Multa'),
  (5, 'Outro'),
  (6, 'Mensalidades'),
  (10, 'Multa por Atraso'),
  (11, 'Manutenção'),
  (12, 'Conta de Energia Elétrica')
  ON DUPLICATE KEY UPDATE `descricao` = VALUES(`descricao`);

INSERT INTO `relacionamento_lancamento` (`fk_tipo_lancamento`, `fk_conta_regente`, `fk_conta_subordinada`, `natureza`, `modo`, `ativo`) VALUES
  (6, 1, 1, 'RECEBER', 'FIXO', 1),
  (2, 1, 1, 'RECEBER', 'FIXO', 1)
  ON DUPLICATE KEY UPDATE `ativo` = VALUES(`ativo`);

-- ============================================================
-- USUÁRIO ADMINISTRADOR GENÉRICO
-- Senha: admin123  —  altere após o primeiro acesso
-- ============================================================
INSERT INTO `usuario` (`id_usuario`, `nome`, `email`, `senha_hash`, `fk_perfil`, `ativo`, `primeiro_acesso`) VALUES
  (1, 'Administrador', 'admin@ambc.com',
   '$2y$12$GvOErlYEQnO7gdXQEOvxj.CEXnZOfxpHEnQ4aW2gmBZ8ihzdgHr1m',
   1, 1, 1)
  ON DUPLICATE KEY UPDATE `nome` = VALUES(`nome`);

-- Permissões: libera todos os módulos para o administrador
INSERT INTO `permissao_usuario` (`fk_usuario`, `fk_modulo`, `pode_acessar`, `pode_editar`)
SELECT 1, id_modulo, 1, 1 FROM `modulo_sistema`
ON DUPLICATE KEY UPDATE `pode_acessar` = 1, `pode_editar` = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- FIM DO SCHEMA
