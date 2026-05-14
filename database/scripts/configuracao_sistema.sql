-- ============================================================
--  MIGRATION — Configurações do sistema
--  Execute uma única vez no banco de dados AMBC
-- ============================================================

CREATE TABLE IF NOT EXISTS configuracao_sistema (
    chave       VARCHAR(60)  PRIMARY KEY,
    valor       TEXT         NOT NULL,
    atualizado_em TIMESTAMP  DEFAULT NOW()
);

INSERT INTO configuracao_sistema (chave, valor) VALUES
    ('idioma',                  'pt-BR'),
    ('fuso_horario',            'America/Sao_Paulo'),
    ('formato_data',            'DD/MM/YYYY'),
    ('moeda',                   'BRL'),
    ('notif_vencimentos',       'true'),
    ('notif_inadimplencia',     'true'),
    ('notif_resumo_semanal',    'false'),
    ('notif_novos_cadastros',   'true'),
    ('seg_2fa',                 'false'),
    ('seg_expirar_sessao',      'true'),
    ('dias_alerta_vencimento',  '5')
ON CONFLICT (chave) DO NOTHING;
