-- ============================================================
--  MIGRATION 010 — TRIGGERS E ÍNDICES
-- ============================================================

-- @UP
-- ============================================================

-- ----------------------------------------------------------
--  TRIGGER 1 — Valida CPF/CNPJ (11 ou 14 dígitos)
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_cpf_cnpj()
RETURNS TRIGGER AS $$
DECLARE tamanho INT;
BEGIN
    IF NEW.cpf_cnpj IS NOT NULL THEN
        IF NEW.cpf_cnpj ~ '[^0-9]' THEN
            RAISE EXCEPTION 'CPF/CNPJ deve conter apenas números.';
        END IF;
        tamanho := LENGTH(NEW.cpf_cnpj);
        IF tamanho NOT IN (11, 14) THEN
            RAISE EXCEPTION 'CPF/CNPJ inválido. Informe 11 dígitos (CPF) ou 14 (CNPJ). Recebido: % dígitos.', tamanho;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cpf_cnpj_associado
    BEFORE INSERT OR UPDATE ON associado
    FOR EACH ROW EXECUTE FUNCTION fn_validar_cpf_cnpj();

CREATE TRIGGER trg_cpf_cnpj_parceiro
    BEFORE INSERT OR UPDATE ON parceiro
    FOR EACH ROW EXECUTE FUNCTION fn_validar_cpf_cnpj();


-- ----------------------------------------------------------
--  TRIGGER 2 — Valida soma das parcelas
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_parcelas()
RETURNS TRIGGER AS $$
DECLARE
    soma_atual  NUMERIC;
    valor_total NUMERIC;
BEGIN
    SELECT c.valor_total INTO valor_total FROM conta c WHERE c.id_conta = NEW.fk_conta;
    SELECT COALESCE(SUM(valor), 0) INTO soma_atual
    FROM parcela
    WHERE fk_conta = NEW.fk_conta AND id_parcela != COALESCE(NEW.id_parcela, 0);
    soma_atual := soma_atual + NEW.valor;
    IF soma_atual > valor_total THEN
        RAISE EXCEPTION 'Soma das parcelas (R$ %) ultrapassa o valor total da conta (R$ %).', soma_atual, valor_total;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_parcelas
    BEFORE INSERT OR UPDATE ON parcela
    FOR EACH ROW EXECUTE FUNCTION fn_validar_parcelas();


-- ----------------------------------------------------------
--  TRIGGER 3 — Valida que horário pertence ao espaço reservado
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_horario_espaco()
RETURNS TRIGGER AS $$
DECLARE espaco_do_horario INT;
BEGIN
    SELECT fk_espaco INTO espaco_do_horario
    FROM horario_espaco WHERE id_horario_espaco = NEW.fk_horario_espaco;
    IF espaco_do_horario != NEW.fk_espaco THEN
        RAISE EXCEPTION 'O horário selecionado não pertence ao espaço informado.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_horario_espaco
    BEFORE INSERT OR UPDATE ON reserva_espaco
    FOR EACH ROW EXECUTE FUNCTION fn_validar_horario_espaco();


-- ----------------------------------------------------------
--  TRIGGER 4 — Impede conflito de reserva de espaço
--  Considera sobreposição de horário
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_conflito_reserva()
RETURNS TRIGGER AS $$
DECLARE
    conflito    INT;
    hi_novo     TIME;
    hf_novo     TIME;
BEGIN
    SELECT hora_inicio, hora_fim INTO hi_novo, hf_novo
    FROM horario_espaco WHERE id_horario_espaco = NEW.fk_horario_espaco;

    SELECT COUNT(*) INTO conflito
    FROM reserva_espaco r
    JOIN horario_espaco h ON h.id_horario_espaco = r.fk_horario_espaco
    WHERE r.fk_espaco         = NEW.fk_espaco
    AND   r.data_reserva      = NEW.data_reserva
    AND   r.fk_status_reserva = 1
    AND   r.id_reserva        != COALESCE(NEW.id_reserva, 0)
    AND   h.hora_inicio       < hf_novo
    AND   h.hora_fim          > hi_novo;

    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Já existe uma reserva confirmada nesse horário.';
    END IF;

    SELECT COUNT(*) INTO conflito
    FROM agenda
    WHERE fk_espaco        = NEW.fk_espaco
    AND   data_inicio      = NEW.data_reserva
    AND   fk_status_agenda != 2
    AND   hora_inicio      < hf_novo
    AND   hora_fim         > hi_novo;

    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Existe uma atividade interna agendada nesse horário.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_conflito_reserva
    BEFORE INSERT OR UPDATE ON reserva_espaco
    FOR EACH ROW EXECUTE FUNCTION fn_conflito_reserva();


-- ----------------------------------------------------------
--  TRIGGER 5 — Impede conflito de agenda com reserva de espaço
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_conflito_agenda()
RETURNS TRIGGER AS $$
DECLARE conflito INT;
BEGIN
    IF NEW.fk_espaco IS NULL THEN RETURN NEW; END IF;

    SELECT COUNT(*) INTO conflito
    FROM reserva_espaco r
    JOIN horario_espaco h ON h.id_horario_espaco = r.fk_horario_espaco
    WHERE r.fk_espaco         = NEW.fk_espaco
    AND   r.data_reserva      = NEW.data_inicio
    AND   r.fk_status_reserva = 1
    AND   h.hora_inicio       < NEW.hora_fim
    AND   h.hora_fim          > NEW.hora_inicio;

    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Já existe uma reserva confirmada nesse horário.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_conflito_agenda
    BEFORE INSERT OR UPDATE ON agenda
    FOR EACH ROW EXECUTE FUNCTION fn_conflito_agenda();


-- ----------------------------------------------------------
--  TRIGGER 6 — Atualiza atualizado_em automaticamente
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ts_associado     BEFORE UPDATE ON associado         FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_parceiro      BEFORE UPDATE ON parceiro          FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_dependente    BEFORE UPDATE ON dependente        FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta         BEFORE UPDATE ON conta             FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_parcela       BEFORE UPDATE ON parcela           FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_doacao        BEFORE UPDATE ON doacao            FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_espaco        BEFORE UPDATE ON espaco            FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_reserva       BEFORE UPDATE ON reserva_espaco    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_agenda        BEFORE UPDATE ON agenda            FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_documento     BEFORE UPDATE ON documento         FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_usuario       BEFORE UPDATE ON usuario           FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta_reg     BEFORE UPDATE ON conta_regente     FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta_sub     BEFORE UPDATE ON conta_subordinada FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ----------------------------------------------------------
--  ÍNDICES DE PERFORMANCE
-- ----------------------------------------------------------

CREATE INDEX idx_reserva_data     ON reserva_espaco(data_reserva);
CREATE INDEX idx_agenda_data      ON agenda(data_inicio);
CREATE INDEX idx_parcela_conta    ON parcela(fk_conta);
CREATE INDEX idx_doacao_data      ON doacao(data_doacao);
CREATE INDEX idx_associado_nome   ON associado(nome);
CREATE INDEX idx_parceiro_nome    ON parceiro(nome_razao_social);
CREATE INDEX idx_documento_indice ON documento(ano, numero);
CREATE INDEX idx_log_usuario      ON log_acesso(fk_usuario);


-- @DOWN
-- ============================================================

DROP INDEX IF EXISTS idx_log_usuario;
DROP INDEX IF EXISTS idx_documento_indice;
DROP INDEX IF EXISTS idx_parceiro_nome;
DROP INDEX IF EXISTS idx_associado_nome;
DROP INDEX IF EXISTS idx_doacao_data;
DROP INDEX IF EXISTS idx_parcela_conta;
DROP INDEX IF EXISTS idx_agenda_data;
DROP INDEX IF EXISTS idx_reserva_data;

DROP TRIGGER IF EXISTS trg_ts_conta_sub     ON conta_subordinada;
DROP TRIGGER IF EXISTS trg_ts_conta_reg     ON conta_regente;
DROP TRIGGER IF EXISTS trg_ts_usuario       ON usuario;
DROP TRIGGER IF EXISTS trg_ts_documento     ON documento;
DROP TRIGGER IF EXISTS trg_ts_agenda        ON agenda;
DROP TRIGGER IF EXISTS trg_ts_reserva       ON reserva_espaco;
DROP TRIGGER IF EXISTS trg_ts_espaco        ON espaco;
DROP TRIGGER IF EXISTS trg_ts_doacao        ON doacao;
DROP TRIGGER IF EXISTS trg_ts_parcela       ON parcela;
DROP TRIGGER IF EXISTS trg_ts_conta         ON conta;
DROP TRIGGER IF EXISTS trg_ts_dependente    ON dependente;
DROP TRIGGER IF EXISTS trg_ts_parceiro      ON parceiro;
DROP TRIGGER IF EXISTS trg_ts_associado     ON associado;
DROP TRIGGER IF EXISTS trg_conflito_agenda  ON agenda;
DROP TRIGGER IF EXISTS trg_conflito_reserva ON reserva_espaco;
DROP TRIGGER IF EXISTS trg_validar_horario_espaco ON reserva_espaco;
DROP TRIGGER IF EXISTS trg_validar_parcelas ON parcela;
DROP TRIGGER IF EXISTS trg_cpf_cnpj_parceiro  ON parceiro;
DROP TRIGGER IF EXISTS trg_cpf_cnpj_associado ON associado;

DROP FUNCTION IF EXISTS fn_atualizar_timestamp();
DROP FUNCTION IF EXISTS fn_conflito_agenda();
DROP FUNCTION IF EXISTS fn_conflito_reserva();
DROP FUNCTION IF EXISTS fn_validar_horario_espaco();
DROP FUNCTION IF EXISTS fn_validar_parcelas();
DROP FUNCTION IF EXISTS fn_validar_cpf_cnpj();
