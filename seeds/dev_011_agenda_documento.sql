-- ============================================================
--  SEED DEV 011 — INTEGRAÇÃO AGENDA ↔ DOCUMENTO
--  Roda DEPOIS dos seeds de agenda e documentos
--  Cobre: documento vinculado a atividade e vice-versa
-- ============================================================

INSERT INTO agenda_documento (fk_agenda, fk_documento) VALUES

-- Assembleia (agenda id 1) vinculada à Ata (documento id 1)
(1, 1),

-- Assembleia (agenda id 1) vinculada à Circular de convocação (documento id 4)
(1, 4),

-- Festa Junina (agenda id 4) vinculada ao Convite (documento id 7)
(4, 7),

-- Natal Solidário (agenda id 5) vinculada ao Registro Fotográfico (documento id 9)
(5, 9),

-- Reunião de diretoria (agenda id 6) vinculada à Ata (documento id 1)
(6, 1);
