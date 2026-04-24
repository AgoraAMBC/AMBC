-- ============================================================
--  MIGRATION 009 — USUÁRIOS E PERMISSÕES
-- ============================================================

-- @UP
-- ============================================================

CREATE TABLE usuario (
    id_usuario          SERIAL          PRIMARY KEY,
    nome                VARCHAR(150)    NOT NULL,
    email               VARCHAR(150)    NOT NULL UNIQUE,
    senha_hash          VARCHAR(255),
    fk_perfil           INT             NOT NULL REFERENCES perfil_usuario(id_perfil),
    fk_associado        INT             REFERENCES associado(id_associado) ON DELETE SET NULL,
    ativo               BOOLEAN         DEFAULT TRUE,
    primeiro_acesso     BOOLEAN         DEFAULT TRUE,
    ultimo_acesso       TIMESTAMP,
    token_reset         VARCHAR(255),
    token_expira_em     TIMESTAMP,
    criado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_em       TIMESTAMP       DEFAULT NOW()
);


CREATE TABLE permissao_usuario (
    id_permissao    SERIAL      PRIMARY KEY,
    fk_usuario      INT         NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    fk_modulo       INT         NOT NULL REFERENCES modulo_sistema(id_modulo),
    pode_acessar    BOOLEAN     DEFAULT FALSE,
    pode_editar     BOOLEAN     DEFAULT FALSE,
    UNIQUE (fk_usuario, fk_modulo)
);


CREATE TABLE log_acesso (
    id_log          SERIAL      PRIMARY KEY,
    fk_usuario      INT         NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    tipo            VARCHAR(10) NOT NULL,
    ip              VARCHAR(45),
    registrado_em   TIMESTAMP   DEFAULT NOW()
);


-- FKs de auditoria — vinculam criado_por/atualizado_por ao usuario
ALTER TABLE associado         ADD CONSTRAINT fk_assoc_criado_por      FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE associado         ADD CONSTRAINT fk_assoc_atualizado_por  FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE parceiro          ADD CONSTRAINT fk_parc_criado_por       FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE parceiro          ADD CONSTRAINT fk_parc_atualizado_por   FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_regente     ADD CONSTRAINT fk_cr_criado_por         FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_regente     ADD CONSTRAINT fk_cr_atualizado_por     FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_subordinada ADD CONSTRAINT fk_cs_criado_por         FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_subordinada ADD CONSTRAINT fk_cs_atualizado_por     FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta             ADD CONSTRAINT fk_conta_criado_por      FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta             ADD CONSTRAINT fk_conta_atualizado_por  FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE doacao            ADD CONSTRAINT fk_doac_criado_por       FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE doacao            ADD CONSTRAINT fk_doac_atualizado_por   FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE espaco            ADD CONSTRAINT fk_esp_criado_por        FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE espaco            ADD CONSTRAINT fk_esp_atualizado_por    FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE reserva_espaco    ADD CONSTRAINT fk_res_criado_por        FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE reserva_espaco    ADD CONSTRAINT fk_res_atualizado_por    FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE agenda            ADD CONSTRAINT fk_ag_criado_por         FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE agenda            ADD CONSTRAINT fk_ag_atualizado_por     FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE documento         ADD CONSTRAINT fk_doc_criado_por        FOREIGN KEY (criado_por)     REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE documento         ADD CONSTRAINT fk_doc_atualizado_por    FOREIGN KEY (atualizado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL;


-- @DOWN
-- ============================================================

-- Remove FKs de auditoria
ALTER TABLE associado         DROP CONSTRAINT IF EXISTS fk_assoc_criado_por;
ALTER TABLE associado         DROP CONSTRAINT IF EXISTS fk_assoc_atualizado_por;
ALTER TABLE parceiro          DROP CONSTRAINT IF EXISTS fk_parc_criado_por;
ALTER TABLE parceiro          DROP CONSTRAINT IF EXISTS fk_parc_atualizado_por;
ALTER TABLE conta_regente     DROP CONSTRAINT IF EXISTS fk_cr_criado_por;
ALTER TABLE conta_regente     DROP CONSTRAINT IF EXISTS fk_cr_atualizado_por;
ALTER TABLE conta_subordinada DROP CONSTRAINT IF EXISTS fk_cs_criado_por;
ALTER TABLE conta_subordinada DROP CONSTRAINT IF EXISTS fk_cs_atualizado_por;
ALTER TABLE conta             DROP CONSTRAINT IF EXISTS fk_conta_criado_por;
ALTER TABLE conta             DROP CONSTRAINT IF EXISTS fk_conta_atualizado_por;
ALTER TABLE doacao            DROP CONSTRAINT IF EXISTS fk_doac_criado_por;
ALTER TABLE doacao            DROP CONSTRAINT IF EXISTS fk_doac_atualizado_por;
ALTER TABLE espaco            DROP CONSTRAINT IF EXISTS fk_esp_criado_por;
ALTER TABLE espaco            DROP CONSTRAINT IF EXISTS fk_esp_atualizado_por;
ALTER TABLE reserva_espaco    DROP CONSTRAINT IF EXISTS fk_res_criado_por;
ALTER TABLE reserva_espaco    DROP CONSTRAINT IF EXISTS fk_res_atualizado_por;
ALTER TABLE agenda            DROP CONSTRAINT IF EXISTS fk_ag_criado_por;
ALTER TABLE agenda            DROP CONSTRAINT IF EXISTS fk_ag_atualizado_por;
ALTER TABLE documento         DROP CONSTRAINT IF EXISTS fk_doc_criado_por;
ALTER TABLE documento         DROP CONSTRAINT IF EXISTS fk_doc_atualizado_por;

DROP TABLE IF EXISTS log_acesso;
DROP TABLE IF EXISTS permissao_usuario;
DROP TABLE IF EXISTS usuario;
