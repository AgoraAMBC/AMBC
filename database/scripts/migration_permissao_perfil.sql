-- ============================================================
-- MIGRATION: Sistema de permissões por perfil
-- Executar UMA ÚNICA VEZ no banco de produção
-- ============================================================

-- Adiciona módulos que faltam
INSERT IGNORE INTO `modulo_sistema` (`id_modulo`, `descricao`) VALUES
(9,  'Relatórios'),
(10, 'Configurações');

-- Cria tabela de permissões por perfil
CREATE TABLE IF NOT EXISTS `permissao_perfil` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `fk_perfil`   INT         NOT NULL,
    `fk_modulo`   INT         NOT NULL,
    `pode_acessar` TINYINT(1) NOT NULL DEFAULT 0,
    `pode_editar`  TINYINT(1) NOT NULL DEFAULT 0,
    UNIQUE KEY `uk_perfil_modulo` (`fk_perfil`, `fk_modulo`),
    CONSTRAINT `fk_pp_perfil` FOREIGN KEY (`fk_perfil`) REFERENCES `perfil_usuario`(`id_perfil`),
    CONSTRAINT `fk_pp_modulo` FOREIGN KEY (`fk_modulo`) REFERENCES `modulo_sistema`(`id_modulo`)
);

-- Seed: permissões padrão por perfil
-- Colunas: fk_perfil, fk_modulo, pode_acessar, pode_editar
INSERT IGNORE INTO `permissao_perfil` (`fk_perfil`, `fk_modulo`, `pode_acessar`, `pode_editar`) VALUES
-- Administrador (1) — acesso total
(1,1,1,1),(1,2,1,1),(1,3,1,1),(1,4,1,1),(1,9,1,1),(1,10,1,1),
-- Operacional (2) — cadastros + leitura financeiro, sem configurações
(2,1,1,1),(2,2,1,1),(2,3,1,1),(2,4,1,0),(2,9,1,0),(2,10,0,0),
-- Conselho Fiscal (3) — apenas leitura, sem configurações
(3,1,1,0),(3,2,1,0),(3,3,1,0),(3,4,1,0),(3,9,1,0),(3,10,0,0),
-- Financeiro (4) — financeiro pleno + leitura cadastros, sem configurações
(4,1,1,1),(4,2,1,0),(4,3,1,0),(4,4,1,1),(4,9,1,1),(4,10,0,0);
