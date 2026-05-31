-- ============================================================
--  AMBC V2 — Seed relacionamento_lancamento
--  Execute no Workbench: File > Open SQL Script > Execute
-- ============================================================
USE ambc;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Cria a tabela se ainda não existir
CREATE TABLE IF NOT EXISTS `relacionamento_lancamento` (
    `id_relacionamento`    INT     NOT NULL AUTO_INCREMENT,
    `fk_tipo_lancamento`   INT     NOT NULL,
    `fk_conta_regente`     INT     NOT NULL,
    `fk_conta_subordinada` INT     NOT NULL,
    `natureza`             ENUM('RECEBER','PAGAR') NOT NULL,
    `modo`                 ENUM('FIXO','SUGERIDO') NOT NULL DEFAULT 'FIXO',
    `ativo`                TINYINT(1) NOT NULL DEFAULT 1,
    `observacao`           TEXT,
    `criado_em`            DATETIME DEFAULT CURRENT_TIMESTAMP,
    `criado_por`           INT,
    `atualizado_em`        DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `atualizado_por`       INT,
    CONSTRAINT `relacionamento_lancamento_pkey` PRIMARY KEY (`id_relacionamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Regras do backup (29-05-2026)
INSERT INTO `relacionamento_lancamento`
    (`id_relacionamento`, `fk_tipo_lancamento`, `fk_conta_regente`, `fk_conta_subordinada`,
     `natureza`, `modo`, `ativo`, `observacao`, `criado_em`, `atualizado_em`)
VALUES
    (1,  6,  8, 2, 'RECEBER', 'FIXO', 1, NULL, '2026-05-21 00:35:37', '2026-05-21 00:35:37'),
    (3,  1,  8, 3, 'RECEBER', 'FIXO', 1, NULL, '2026-05-21 21:22:54', '2026-05-21 21:22:54'),
    (4, 12,  2, 1, 'PAGAR',   'FIXO', 1, NULL, '2026-05-21 22:16:47', '2026-05-21 22:16:47')
ON DUPLICATE KEY UPDATE
    `fk_tipo_lancamento`   = VALUES(`fk_tipo_lancamento`),
    `fk_conta_regente`     = VALUES(`fk_conta_regente`),
    `fk_conta_subordinada` = VALUES(`fk_conta_subordinada`),
    `natureza`             = VALUES(`natureza`),
    `modo`                 = VALUES(`modo`),
    `ativo`                = VALUES(`ativo`);

ALTER TABLE `relacionamento_lancamento` AUTO_INCREMENT = 10;

SET FOREIGN_KEY_CHECKS = 1;

SELECT
    rl.id_relacionamento,
    tl.descricao  AS tipo_lancamento,
    cr.descricao  AS conta_regente,
    cs.descricao  AS conta_subordinada,
    rl.natureza,
    rl.modo,
    rl.ativo
FROM relacionamento_lancamento rl
LEFT JOIN tipo_lancamento  tl ON tl.id_tipo_lancamento   = rl.fk_tipo_lancamento
LEFT JOIN conta_regente    cr ON cr.id_conta_regente     = rl.fk_conta_regente
LEFT JOIN conta_subordinada cs ON cs.id_conta_subordinada = rl.fk_conta_subordinada;
