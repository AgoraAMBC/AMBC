-- ============================================================
--  AMBC V2 — Migration 01
--  Execute após o seed_mysql.sql
--  Corrige: logo (TEXT→LONGTEXT), cria plano_associacao,
--           popula tipo_documento, cria relacionamento_lancamento
-- ============================================================
USE ambc;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ─── FIX: logo não salva (TEXT tem limite de 64 KB) ──────────
ALTER TABLE `configuracoes`
    MODIFY `valor` LONGTEXT;

-- ─── CRIA tabela plano_associacao ────────────────────────────
CREATE TABLE IF NOT EXISTS `plano_associacao` (
    `id_plano`   INT          NOT NULL AUTO_INCREMENT,
    `nome`       VARCHAR(100) NOT NULL,
    `preco`      DECIMAL(10,2) NOT NULL DEFAULT 0,
    `periodo`    VARCHAR(20)  NOT NULL DEFAULT 'anuidade',
    `beneficios` JSON         NOT NULL,
    `ativo`      TINYINT(1)   NOT NULL DEFAULT 1,
    `ordem`      INT          NOT NULL DEFAULT 0,
    `criado_em`  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `plano_associacao_pkey` PRIMARY KEY (`id_plano`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Plano padrão
INSERT IGNORE INTO `plano_associacao` (`id_plano`, `nome`, `preco`, `periodo`, `beneficios`, `ativo`, `ordem`, `criado_em`) VALUES
(1, 'Associado Padrão', 60.00, 'anuidade',
 '[{"descricao":"Acesso à sede social","incluido":true},{"descricao":"Até 3 dependentes","incluido":true},{"descricao":"Participação em eventos","incluido":true}]',
 1, 0, '2026-05-18 13:02:41'),
(3, 'teste', 12.00, 'anuidade', '[]', 1, 0, '2026-05-18 13:07:08');

ALTER TABLE `plano_associacao` AUTO_INCREMENT = 10;

-- ─── SEED: tipo_documento ────────────────────────────────────
INSERT IGNORE INTO `tipo_documento` (`id_tipo_documento`, `descricao`) VALUES
(1,'Ata'),(2,'Ofício'),(3,'Mensagem'),(4,'Circular'),
(5,'Requerimento'),(6,'Declaração'),(7,'Outro'),
(8,'Estatuto'),(9,'Regimento Interno');

-- ─── CRIA tabela relacionamento_lancamento ───────────────────
CREATE TABLE IF NOT EXISTS `relacionamento_lancamento` (
    `id_relacionamento`    INT          NOT NULL AUTO_INCREMENT,
    `fk_tipo_lancamento`   INT          NOT NULL,
    `fk_conta_regente`     INT          NOT NULL,
    `fk_conta_subordinada` INT          NOT NULL,
    `natureza`             ENUM('RECEBER','PAGAR') NOT NULL,
    `modo`                 ENUM('FIXO','SUGERIDO') NOT NULL DEFAULT 'FIXO',
    `ativo`                TINYINT(1)   NOT NULL DEFAULT 1,
    `observacao`           TEXT,
    `criado_em`            DATETIME     DEFAULT CURRENT_TIMESTAMP,
    `criado_por`           INT,
    `atualizado_em`        DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `atualizado_por`       INT,
    CONSTRAINT `relacionamento_lancamento_pkey` PRIMARY KEY (`id_relacionamento`),
    CONSTRAINT `rel_lanc_fk_tipo`       FOREIGN KEY (`fk_tipo_lancamento`)   REFERENCES `tipo_lancamento`(`id_tipo_lancamento`),
    CONSTRAINT `rel_lanc_fk_regente`    FOREIGN KEY (`fk_conta_regente`)     REFERENCES `conta_regente`(`id_conta_regente`),
    CONSTRAINT `rel_lanc_fk_subordinada` FOREIGN KEY (`fk_conta_subordinada`) REFERENCES `conta_subordinada`(`id_conta_subordinada`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dados do backup PostgreSQL (29-05-2026)
INSERT IGNORE INTO `relacionamento_lancamento`
  (`id_relacionamento`,`fk_tipo_lancamento`,`fk_conta_regente`,`fk_conta_subordinada`,
   `natureza`,`modo`,`ativo`,`observacao`,`criado_em`,`atualizado_em`)
VALUES
(1, 6,  8, 2, 'RECEBER', 'FIXO', 1, NULL, '2026-05-21 00:35:37', '2026-05-21 00:35:37'),
(3, 1,  8, 3, 'RECEBER', 'FIXO', 1, NULL, '2026-05-21 21:22:54', '2026-05-21 21:22:54'),
(4, 12, 2, 1, 'PAGAR',   'FIXO', 1, NULL, '2026-05-21 22:16:47', '2026-05-21 22:16:47');

ALTER TABLE `relacionamento_lancamento` AUTO_INCREMENT = 10;

SET FOREIGN_KEY_CHECKS = 1;
