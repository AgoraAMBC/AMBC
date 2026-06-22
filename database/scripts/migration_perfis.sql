-- ============================================================
-- MIGRATION: Renomeia perfis de usuário para estrutura AMBC
-- ============================================================
-- Executar UMA ÚNICA VEZ no banco de produção (Hostinger)
--
-- Mapeamento:
--   id=1  Administrador  → Administrador  (Presidente e Vice)
--   id=2  Gestor         → Operacional    (Secretários)
--   id=3  Visualizador   → Conselho Fiscal (Apenas leitura)
--   id=4  [novo]         → Financeiro     (Tesoureiros)
-- ============================================================

UPDATE `perfil_usuario`
SET `descricao`  = 'Administrador',
    `observacao` = 'Presidente e Vice. Acesso total ao sistema, incluindo usuários e configurações.'
WHERE `id_perfil` = 1;

UPDATE `perfil_usuario`
SET `descricao`  = 'Operacional',
    `observacao` = 'Secretários. Acesso ao cadastro de associados e gestão operacional.'
WHERE `id_perfil` = 2;

UPDATE `perfil_usuario`
SET `descricao`  = 'Conselho Fiscal',
    `observacao` = 'Apenas leitura. Acesso para visualização e fiscalização das informações.'
WHERE `id_perfil` = 3;

INSERT IGNORE INTO `perfil_usuario` (`id_perfil`, `descricao`, `observacao`) VALUES
(4, 'Financeiro', 'Tesoureiros. Acesso ao módulo financeiro e relatórios.');
