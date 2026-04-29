--
-- PostgreSQL database dump
--


-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-04-27 22:02:27

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 304 (class 1255 OID 17208)
-- Name: fn_atualizar_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_atualizar_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_atualizar_timestamp() OWNER TO postgres;

--
-- TOC entry 303 (class 1255 OID 17206)
-- Name: fn_conflito_agenda(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_conflito_agenda() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflito INT;
BEGIN
    IF NEW.fk_espaco IS NULL THEN
        RETURN NEW;
    END IF;
 
    SELECT COUNT(*) INTO conflito
    FROM reserva_espaco r
    JOIN horario_espaco h ON h.id_horario_espaco = r.fk_horario_espaco
    WHERE r.fk_espaco           = NEW.fk_espaco
    AND   r.data_reserva        = NEW.data_inicio
    AND   r.fk_status_reserva   = 1
    AND   h.hora_inicio         < NEW.hora_fim
    AND   h.hora_fim            > NEW.hora_inicio;
 
    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Já existe uma reserva confirmada nesse horário.';
    END IF;
 
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_conflito_agenda() OWNER TO postgres;

--
-- TOC entry 302 (class 1255 OID 17204)
-- Name: fn_conflito_reserva(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_conflito_reserva() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflito    INT;
    hi_novo     TIME;
    hf_novo     TIME;
BEGIN
    SELECT hora_inicio, hora_fim INTO hi_novo, hf_novo
    FROM horario_espaco
    WHERE id_horario_espaco = NEW.fk_horario_espaco;
 
    -- Conflito com outras reservas confirmadas
    SELECT COUNT(*) INTO conflito
    FROM reserva_espaco r
    JOIN horario_espaco h ON h.id_horario_espaco = r.fk_horario_espaco
    WHERE r.fk_espaco           = NEW.fk_espaco
    AND   r.data_reserva        = NEW.data_reserva
    AND   r.fk_status_reserva   = 1
    AND   r.id_reserva          != COALESCE(NEW.id_reserva, 0)
    AND   h.hora_inicio         < hf_novo
    AND   h.hora_fim            > hi_novo;
 
    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Já existe uma reserva confirmada nesse horário.';
    END IF;
 
    -- Conflito com atividades da agenda
    SELECT COUNT(*) INTO conflito
    FROM agenda
    WHERE fk_espaco         = NEW.fk_espaco
    AND   data_inicio       = NEW.data_reserva
    AND   fk_status_agenda  != 2
    AND   hora_inicio       < hf_novo
    AND   hora_fim          > hi_novo;
 
    IF conflito > 0 THEN
        RAISE EXCEPTION 'Espaço indisponível. Existe uma atividade interna agendada nesse horário.';
    END IF;
 
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_conflito_reserva() OWNER TO postgres;

--
-- TOC entry 288 (class 1255 OID 17197)
-- Name: fn_validar_cpf_cnpj(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_cpf_cnpj() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tamanho INT;
BEGIN
    IF NEW.cpf_cnpj IS NOT NULL THEN
        -- Remove qualquer caractere não numérico antes de validar
        IF NEW.cpf_cnpj ~ '[^0-9]' THEN
            RAISE EXCEPTION 'CPF/CNPJ deve conter apenas números.';
        END IF;
 
        tamanho := LENGTH(NEW.cpf_cnpj);
 
        IF tamanho NOT IN (11, 14) THEN
            RAISE EXCEPTION
                'CPF/CNPJ inválido. Informe 11 dígitos para CPF ou 14 para CNPJ. Recebido: % dígitos.', tamanho;
        END IF;
    END IF;
 
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validar_cpf_cnpj() OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 17202)
-- Name: fn_validar_horario_espaco(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_horario_espaco() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    espaco_do_horario INT;
BEGIN
    SELECT fk_espaco INTO espaco_do_horario
    FROM horario_espaco
    WHERE id_horario_espaco = NEW.fk_horario_espaco;
 
    IF espaco_do_horario != NEW.fk_espaco THEN
        RAISE EXCEPTION 'O horário selecionado não pertence ao espaço informado.';
    END IF;
 
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validar_horario_espaco() OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 17200)
-- Name: fn_validar_parcelas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_parcelas() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    soma_atual  NUMERIC;
    valor_total NUMERIC;
BEGIN
    SELECT c.valor_total INTO valor_total
    FROM conta c WHERE c.id_conta = NEW.fk_conta;
 
    SELECT COALESCE(SUM(valor), 0) INTO soma_atual
    FROM parcela
    WHERE fk_conta   = NEW.fk_conta
    AND   id_parcela != COALESCE(NEW.id_parcela, 0);
 
    soma_atual := soma_atual + NEW.valor;
 
    IF soma_atual > valor_total THEN
        RAISE EXCEPTION
            'Soma das parcelas (R$ %) ultrapassa o valor total da conta (R$ %).',
            soma_atual, valor_total;
    END IF;
 
    RETURN NEW;
END;
$_$;


ALTER FUNCTION public.fn_validar_parcelas() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 277 (class 1259 OID 16939)
-- Name: agenda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agenda (
    id_agenda integer NOT NULL,
    titulo character varying(150) NOT NULL,
    descricao text,
    observacao text,
    data_inicio date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    data_fim date,
    hora_fim time without time zone NOT NULL,
    fk_espaco integer,
    fk_status_agenda integer DEFAULT 1 NOT NULL,
    fk_associado integer,
    fk_parceiro integer,
    responsavel_nome character varying(150),
    responsavel_telefone character varying(11),
    responsavel_email character varying(150),
    capacidade_maxima integer,
    total_participantes integer DEFAULT 0,
    valor_cobrado numeric(10,2),
    valor_aluguel numeric(10,2),
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_agenda_responsavel CHECK ((NOT ((fk_associado IS NOT NULL) AND (fk_parceiro IS NOT NULL))))
);


ALTER TABLE public.agenda OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 17006)
-- Name: agenda_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agenda_documento (
    id integer NOT NULL,
    fk_agenda integer NOT NULL,
    fk_documento integer NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.agenda_documento OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 17005)
-- Name: agenda_documento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agenda_documento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agenda_documento_id_seq OWNER TO postgres;

--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 280
-- Name: agenda_documento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agenda_documento_id_seq OWNED BY public.agenda_documento.id;


--
-- TOC entry 276 (class 1259 OID 16938)
-- Name: agenda_id_agenda_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agenda_id_agenda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agenda_id_agenda_seq OWNER TO postgres;

--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 276
-- Name: agenda_id_agenda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agenda_id_agenda_seq OWNED BY public.agenda.id_agenda;


--
-- TOC entry 249 (class 1259 OID 16555)
-- Name: associado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.associado (
    id_associado integer NOT NULL,
    nome character varying(150) NOT NULL,
    data_nascimento date NOT NULL,
    cpf_cnpj character varying(14),
    email character varying(150),
    observacao text,
    ativo boolean DEFAULT true,
    logradouro character varying(200),
    numero character varying(10),
    complemento character varying(100),
    cep character(8),
    bairro character varying(100),
    cidade character varying(100),
    uf character(2),
    fk_estadocivil integer,
    fk_profissao integer,
    fk_categoria integer,
    fk_status integer,
    fk_genero integer,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_associado_nome_composto CHECK ((TRIM(BOTH FROM nome) ~~ '% %'::text))
);


ALTER TABLE public.associado OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 16554)
-- Name: associado_id_associado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.associado_id_associado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.associado_id_associado_seq OWNER TO postgres;

--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 248
-- Name: associado_id_associado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.associado_id_associado_seq OWNED BY public.associado.id_associado;


--
-- TOC entry 224 (class 1259 OID 16412)
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16411)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_id_categoria_seq OWNER TO postgres;

--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 223
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_id_categoria_seq OWNED BY public.categoria.id_categoria;


--
-- TOC entry 263 (class 1259 OID 16731)
-- Name: conta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conta (
    id_conta integer NOT NULL,
    fk_associado integer NOT NULL,
    fk_conta_regente integer,
    fk_conta_subordinada integer,
    fk_status_conta integer NOT NULL,
    descricao character varying(200),
    valor_total numeric(10,2) NOT NULL,
    data_lancamento date DEFAULT CURRENT_DATE NOT NULL,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer
);


ALTER TABLE public.conta OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 16730)
-- Name: conta_id_conta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conta_id_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_id_conta_seq OWNER TO postgres;

--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 262
-- Name: conta_id_conta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conta_id_conta_seq OWNED BY public.conta.id_conta;


--
-- TOC entry 259 (class 1259 OID 16697)
-- Name: conta_regente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conta_regente (
    id_conta_regente integer NOT NULL,
    descricao character varying(100) NOT NULL,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer
);


ALTER TABLE public.conta_regente OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 16696)
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conta_regente_id_conta_regente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_regente_id_conta_regente_seq OWNER TO postgres;

--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 258
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conta_regente_id_conta_regente_seq OWNED BY public.conta_regente.id_conta_regente;


--
-- TOC entry 261 (class 1259 OID 16712)
-- Name: conta_subordinada; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conta_subordinada (
    id_conta_subordinada integer NOT NULL,
    fk_conta_regente integer NOT NULL,
    descricao character varying(100) NOT NULL,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer
);


ALTER TABLE public.conta_subordinada OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 16711)
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conta_subordinada_id_conta_subordinada_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_subordinada_id_conta_subordinada_seq OWNER TO postgres;

--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 260
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conta_subordinada_id_conta_subordinada_seq OWNED BY public.conta_subordinada.id_conta_subordinada;


--
-- TOC entry 253 (class 1259 OID 16623)
-- Name: dependente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dependente (
    id_dependente integer NOT NULL,
    fk_associado integer NOT NULL,
    nome character varying(150) NOT NULL,
    data_nascimento date NOT NULL,
    cpf character(11),
    observacao text,
    fk_parentesco integer,
    fk_genero integer,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT chk_dependente_nome_composto CHECK ((TRIM(BOTH FROM nome) ~~ '% %'::text))
);


ALTER TABLE public.dependente OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 16622)
-- Name: dependente_id_dependente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dependente_id_dependente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dependente_id_dependente_seq OWNER TO postgres;

--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 252
-- Name: dependente_id_dependente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dependente_id_dependente_seq OWNED BY public.dependente.id_dependente;


--
-- TOC entry 267 (class 1259 OID 16801)
-- Name: doacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doacao (
    id_doacao integer NOT NULL,
    fk_parceiro integer,
    fk_associado integer,
    nome_externo character varying(150),
    telefone_externo character varying(11),
    fk_tipo_doacao integer NOT NULL,
    fk_conta_regente integer,
    fk_conta_subordinada integer,
    descricao character varying(200),
    data_doacao date DEFAULT CURRENT_DATE NOT NULL,
    valor_dinheiro numeric(10,2),
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_doacao_doador CHECK (((fk_parceiro IS NOT NULL) OR (fk_associado IS NOT NULL) OR (nome_externo IS NOT NULL)))
);


ALTER TABLE public.doacao OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 16800)
-- Name: doacao_id_doacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doacao_id_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doacao_id_doacao_seq OWNER TO postgres;

--
-- TOC entry 5457 (class 0 OID 0)
-- Dependencies: 266
-- Name: doacao_id_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doacao_id_doacao_seq OWNED BY public.doacao.id_doacao;


--
-- TOC entry 279 (class 1259 OID 16979)
-- Name: documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documento (
    id_documento integer NOT NULL,
    numero integer NOT NULL,
    ano integer DEFAULT EXTRACT(year FROM CURRENT_DATE) NOT NULL,
    indice character varying(20) GENERATED ALWAYS AS (((lpad((numero)::text, 3, '0'::text) || '/'::text) || (ano)::text)) STORED,
    fk_tipo_documento integer,
    tipo_livre character varying(50),
    assunto character varying(200) NOT NULL,
    data_documento date DEFAULT CURRENT_DATE NOT NULL,
    conteudo text,
    arquivo_path character varying(500),
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_documento_tipo CHECK ((((fk_tipo_documento IS NOT NULL) AND (tipo_livre IS NULL)) OR ((fk_tipo_documento IS NULL) AND (tipo_livre IS NOT NULL))))
);


ALTER TABLE public.documento OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 16978)
-- Name: documento_id_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.documento_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documento_id_documento_seq OWNER TO postgres;

--
-- TOC entry 5458 (class 0 OID 0)
-- Dependencies: 278
-- Name: documento_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.documento_id_documento_seq OWNED BY public.documento.id_documento;


--
-- TOC entry 271 (class 1259 OID 16861)
-- Name: espaco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.espaco (
    id_espaco integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    capacidade integer,
    observacao text,
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer
);


ALTER TABLE public.espaco OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 16860)
-- Name: espaco_id_espaco_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.espaco_id_espaco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.espaco_id_espaco_seq OWNER TO postgres;

--
-- TOC entry 5459 (class 0 OID 0)
-- Dependencies: 270
-- Name: espaco_id_espaco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.espaco_id_espaco_seq OWNED BY public.espaco.id_espaco;


--
-- TOC entry 222 (class 1259 OID 16401)
-- Name: estado_civil; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estado_civil (
    id_estadocivil integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.estado_civil OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16400)
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estado_civil_id_estadocivil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estado_civil_id_estadocivil_seq OWNER TO postgres;

--
-- TOC entry 5460 (class 0 OID 0)
-- Dependencies: 221
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estado_civil_id_estadocivil_seq OWNED BY public.estado_civil.id_estadocivil;


--
-- TOC entry 233 (class 1259 OID 16465)
-- Name: forma_pagamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forma_pagamento (
    id_forma_pagamento integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.forma_pagamento OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16464)
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forma_pagamento_id_forma_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNER TO postgres;

--
-- TOC entry 5461 (class 0 OID 0)
-- Dependencies: 232
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNED BY public.forma_pagamento.id_forma_pagamento;


--
-- TOC entry 220 (class 1259 OID 16390)
-- Name: genero; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genero (
    id_genero integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.genero OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16389)
-- Name: genero_id_genero_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genero_id_genero_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genero_id_genero_seq OWNER TO postgres;

--
-- TOC entry 5462 (class 0 OID 0)
-- Dependencies: 219
-- Name: genero_id_genero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genero_id_genero_seq OWNED BY public.genero.id_genero;


--
-- TOC entry 273 (class 1259 OID 16877)
-- Name: horario_espaco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horario_espaco (
    id_horario_espaco integer NOT NULL,
    fk_espaco integer NOT NULL,
    dia_semana character varying(15) NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    observacao text
);


ALTER TABLE public.horario_espaco OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 16876)
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.horario_espaco_id_horario_espaco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horario_espaco_id_horario_espaco_seq OWNER TO postgres;

--
-- TOC entry 5463 (class 0 OID 0)
-- Dependencies: 272
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.horario_espaco_id_horario_espaco_seq OWNED BY public.horario_espaco.id_horario_espaco;


--
-- TOC entry 269 (class 1259 OID 16842)
-- Name: item_doacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_doacao (
    id_item_doacao integer NOT NULL,
    fk_doacao integer NOT NULL,
    descricao character varying(200) NOT NULL,
    quantidade numeric(10,2) NOT NULL,
    unidade character varying(20),
    observacao text,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.item_doacao OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 16841)
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_doacao_id_item_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_doacao_id_item_doacao_seq OWNER TO postgres;

--
-- TOC entry 5464 (class 0 OID 0)
-- Dependencies: 268
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_doacao_id_item_doacao_seq OWNED BY public.item_doacao.id_item_doacao;


--
-- TOC entry 287 (class 1259 OID 17182)
-- Name: log_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_acesso (
    id_log integer NOT NULL,
    fk_usuario integer NOT NULL,
    tipo character varying(10) NOT NULL,
    ip character varying(45),
    registrado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.log_acesso OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 17181)
-- Name: log_acesso_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_acesso_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_acesso_id_log_seq OWNER TO postgres;

--
-- TOC entry 5465 (class 0 OID 0)
-- Dependencies: 286
-- Name: log_acesso_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_acesso_id_log_seq OWNED BY public.log_acesso.id_log;


--
-- TOC entry 247 (class 1259 OID 16544)
-- Name: modulo_sistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modulo_sistema (
    id_modulo integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.modulo_sistema OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16543)
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modulo_sistema_id_modulo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modulo_sistema_id_modulo_seq OWNER TO postgres;

--
-- TOC entry 5466 (class 0 OID 0)
-- Dependencies: 246
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modulo_sistema_id_modulo_seq OWNED BY public.modulo_sistema.id_modulo;


--
-- TOC entry 255 (class 1259 OID 16654)
-- Name: parceiro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parceiro (
    id_parceiro integer NOT NULL,
    nome_razao_social character varying(200) NOT NULL,
    cpf_cnpj character varying(14) NOT NULL,
    email character varying(150),
    ativo boolean DEFAULT true,
    logradouro character varying(200),
    numero character varying(10),
    complemento character varying(100),
    cep character(8),
    bairro character varying(100),
    cidade character varying(100),
    uf character(2),
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_parceiro_nome_composto CHECK ((TRIM(BOTH FROM nome_razao_social) ~~ '% %'::text))
);


ALTER TABLE public.parceiro OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 16653)
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parceiro_id_parceiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parceiro_id_parceiro_seq OWNER TO postgres;

--
-- TOC entry 5467 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parceiro_id_parceiro_seq OWNED BY public.parceiro.id_parceiro;


--
-- TOC entry 265 (class 1259 OID 16768)
-- Name: parcela; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parcela (
    id_parcela integer NOT NULL,
    fk_conta integer NOT NULL,
    fk_status_conta integer NOT NULL,
    fk_forma_pagamento integer,
    numero_parcela integer NOT NULL,
    total_parcelas integer NOT NULL,
    valor numeric(10,2) NOT NULL,
    data_vencimento date NOT NULL,
    data_pagamento date,
    valor_pago numeric(10,2),
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.parcela OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 16767)
-- Name: parcela_id_parcela_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parcela_id_parcela_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parcela_id_parcela_seq OWNER TO postgres;

--
-- TOC entry 5468 (class 0 OID 0)
-- Dependencies: 264
-- Name: parcela_id_parcela_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parcela_id_parcela_seq OWNED BY public.parcela.id_parcela;


--
-- TOC entry 230 (class 1259 OID 16445)
-- Name: parentesco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parentesco (
    id_parentesco integer NOT NULL,
    descricao character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE public.parentesco OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16444)
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parentesco_id_parentesco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parentesco_id_parentesco_seq OWNER TO postgres;

--
-- TOC entry 5469 (class 0 OID 0)
-- Dependencies: 229
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parentesco_id_parentesco_seq OWNED BY public.parentesco.id_parentesco;


--
-- TOC entry 245 (class 1259 OID 16531)
-- Name: perfil_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.perfil_usuario (
    id_perfil integer NOT NULL,
    descricao character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE public.perfil_usuario OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16530)
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.perfil_usuario_id_perfil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.perfil_usuario_id_perfil_seq OWNER TO postgres;

--
-- TOC entry 5470 (class 0 OID 0)
-- Dependencies: 244
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.perfil_usuario_id_perfil_seq OWNED BY public.perfil_usuario.id_perfil;


--
-- TOC entry 285 (class 1259 OID 17158)
-- Name: permissao_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissao_usuario (
    id_permissao integer NOT NULL,
    fk_usuario integer NOT NULL,
    fk_modulo integer NOT NULL,
    pode_acessar boolean DEFAULT false,
    pode_editar boolean DEFAULT false
);


ALTER TABLE public.permissao_usuario OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 17157)
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissao_usuario_id_permissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissao_usuario_id_permissao_seq OWNER TO postgres;

--
-- TOC entry 5471 (class 0 OID 0)
-- Dependencies: 284
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissao_usuario_id_permissao_seq OWNED BY public.permissao_usuario.id_permissao;


--
-- TOC entry 228 (class 1259 OID 16434)
-- Name: profissao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissao (
    id_profissao integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.profissao OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16433)
-- Name: profissao_id_profissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissao_id_profissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissao_id_profissao_seq OWNER TO postgres;

--
-- TOC entry 5472 (class 0 OID 0)
-- Dependencies: 227
-- Name: profissao_id_profissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissao_id_profissao_seq OWNED BY public.profissao.id_profissao;


--
-- TOC entry 275 (class 1259 OID 16896)
-- Name: reserva_espaco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserva_espaco (
    id_reserva integer NOT NULL,
    fk_espaco integer NOT NULL,
    fk_horario_espaco integer NOT NULL,
    fk_status_reserva integer DEFAULT 1 NOT NULL,
    data_reserva date NOT NULL,
    fk_associado integer,
    fk_parceiro integer,
    nome_externo character varying(150),
    telefone_externo character varying(11),
    email_externo character varying(150),
    valor_cobrado numeric(10,2),
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT chk_reserva_responsavel CHECK ((((fk_associado IS NOT NULL) AND (fk_parceiro IS NULL) AND (nome_externo IS NULL)) OR ((fk_parceiro IS NOT NULL) AND (fk_associado IS NULL) AND (nome_externo IS NULL)) OR ((nome_externo IS NOT NULL) AND (fk_associado IS NULL) AND (fk_parceiro IS NULL))))
);


ALTER TABLE public.reserva_espaco OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 16895)
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reserva_espaco_id_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reserva_espaco_id_reserva_seq OWNER TO postgres;

--
-- TOC entry 5473 (class 0 OID 0)
-- Dependencies: 274
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reserva_espaco_id_reserva_seq OWNED BY public.reserva_espaco.id_reserva;


--
-- TOC entry 241 (class 1259 OID 16509)
-- Name: status_agenda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_agenda (
    id_status_agenda integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_agenda OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16508)
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_agenda_id_status_agenda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_agenda_id_status_agenda_seq OWNER TO postgres;

--
-- TOC entry 5474 (class 0 OID 0)
-- Dependencies: 240
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_agenda_id_status_agenda_seq OWNED BY public.status_agenda.id_status_agenda;


--
-- TOC entry 235 (class 1259 OID 16476)
-- Name: status_conta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_conta (
    id_status_conta integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_conta OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16475)
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_conta_id_status_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_conta_id_status_conta_seq OWNER TO postgres;

--
-- TOC entry 5475 (class 0 OID 0)
-- Dependencies: 234
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_conta_id_status_conta_seq OWNED BY public.status_conta.id_status_conta;


--
-- TOC entry 226 (class 1259 OID 16423)
-- Name: status_pessoa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_pessoa (
    id_status integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_pessoa OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16422)
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_pessoa_id_status_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_pessoa_id_status_seq OWNER TO postgres;

--
-- TOC entry 5476 (class 0 OID 0)
-- Dependencies: 225
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_pessoa_id_status_seq OWNED BY public.status_pessoa.id_status;


--
-- TOC entry 239 (class 1259 OID 16498)
-- Name: status_reserva; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_reserva (
    id_status_reserva integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_reserva OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16497)
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_reserva_id_status_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_reserva_id_status_reserva_seq OWNER TO postgres;

--
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 238
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_reserva_id_status_reserva_seq OWNED BY public.status_reserva.id_status_reserva;


--
-- TOC entry 251 (class 1259 OID 16603)
-- Name: telefone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telefone (
    id_telefone integer NOT NULL,
    fk_associado integer NOT NULL,
    ddd character(2) NOT NULL,
    numero character varying(9) NOT NULL,
    CONSTRAINT chk_telefone_ddd CHECK ((ddd ~ '^[0-9]+$'::text)),
    CONSTRAINT chk_telefone_numero CHECK (((numero)::text ~ '^[0-9]+$'::text))
);


ALTER TABLE public.telefone OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 16602)
-- Name: telefone_id_telefone_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telefone_id_telefone_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telefone_id_telefone_seq OWNER TO postgres;

--
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 250
-- Name: telefone_id_telefone_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telefone_id_telefone_seq OWNED BY public.telefone.id_telefone;


--
-- TOC entry 257 (class 1259 OID 16677)
-- Name: telefone_parceiro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telefone_parceiro (
    id_telefone_parceiro integer NOT NULL,
    fk_parceiro integer NOT NULL,
    ddd character(2) NOT NULL,
    numero character varying(9) NOT NULL,
    CONSTRAINT chk_tel_parceiro_ddd CHECK ((ddd ~ '^[0-9]+$'::text)),
    CONSTRAINT chk_tel_parceiro_numero CHECK (((numero)::text ~ '^[0-9]+$'::text))
);


ALTER TABLE public.telefone_parceiro OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 16676)
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq OWNER TO postgres;

--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 256
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq OWNED BY public.telefone_parceiro.id_telefone_parceiro;


--
-- TOC entry 237 (class 1259 OID 16487)
-- Name: tipo_doacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_doacao (
    id_tipo_doacao integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.tipo_doacao OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16486)
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_doacao_id_tipo_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_doacao_id_tipo_doacao_seq OWNER TO postgres;

--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 236
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_doacao_id_tipo_doacao_seq OWNED BY public.tipo_doacao.id_tipo_doacao;


--
-- TOC entry 243 (class 1259 OID 16520)
-- Name: tipo_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_documento (
    id_tipo_documento integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.tipo_documento OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16519)
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_documento_id_tipo_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNER TO postgres;

--
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 242
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNED BY public.tipo_documento.id_tipo_documento;


--
-- TOC entry 231 (class 1259 OID 16457)
-- Name: uf; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.uf (
    sigla character(2) NOT NULL,
    nome character varying(30) NOT NULL
);


ALTER TABLE public.uf OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 17029)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    senha_hash character varying(255),
    fk_perfil integer NOT NULL,
    fk_associado integer,
    ativo boolean DEFAULT true,
    primeiro_acesso boolean DEFAULT true,
    ultimo_acesso timestamp without time zone,
    token_reset character varying(255),
    token_expira_em timestamp without time zone,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 17028)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 282
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 4985 (class 2604 OID 16942)
-- Name: agenda id_agenda; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda ALTER COLUMN id_agenda SET DEFAULT nextval('public.agenda_id_agenda_seq'::regclass);


--
-- TOC entry 4996 (class 2604 OID 17009)
-- Name: agenda_documento id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda_documento ALTER COLUMN id SET DEFAULT nextval('public.agenda_documento_id_seq'::regclass);


--
-- TOC entry 4944 (class 2604 OID 16558)
-- Name: associado id_associado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado ALTER COLUMN id_associado SET DEFAULT nextval('public.associado_id_associado_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 16415)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 4963 (class 2604 OID 16734)
-- Name: conta id_conta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta ALTER COLUMN id_conta SET DEFAULT nextval('public.conta_id_conta_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 16700)
-- Name: conta_regente id_conta_regente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_regente ALTER COLUMN id_conta_regente SET DEFAULT nextval('public.conta_regente_id_conta_regente_seq'::regclass);


--
-- TOC entry 4960 (class 2604 OID 16715)
-- Name: conta_subordinada id_conta_subordinada; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_subordinada ALTER COLUMN id_conta_subordinada SET DEFAULT nextval('public.conta_subordinada_id_conta_subordinada_seq'::regclass);


--
-- TOC entry 4949 (class 2604 OID 16626)
-- Name: dependente id_dependente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependente ALTER COLUMN id_dependente SET DEFAULT nextval('public.dependente_id_dependente_seq'::regclass);


--
-- TOC entry 4970 (class 2604 OID 16804)
-- Name: doacao id_doacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao ALTER COLUMN id_doacao SET DEFAULT nextval('public.doacao_id_doacao_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 16982)
-- Name: documento id_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento ALTER COLUMN id_documento SET DEFAULT nextval('public.documento_id_documento_seq'::regclass);


--
-- TOC entry 4976 (class 2604 OID 16864)
-- Name: espaco id_espaco; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.espaco ALTER COLUMN id_espaco SET DEFAULT nextval('public.espaco_id_espaco_seq'::regclass);


--
-- TOC entry 4931 (class 2604 OID 16404)
-- Name: estado_civil id_estadocivil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado_civil ALTER COLUMN id_estadocivil SET DEFAULT nextval('public.estado_civil_id_estadocivil_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 16468)
-- Name: forma_pagamento id_forma_pagamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento ALTER COLUMN id_forma_pagamento SET DEFAULT nextval('public.forma_pagamento_id_forma_pagamento_seq'::regclass);


--
-- TOC entry 4930 (class 2604 OID 16393)
-- Name: genero id_genero; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genero ALTER COLUMN id_genero SET DEFAULT nextval('public.genero_id_genero_seq'::regclass);


--
-- TOC entry 4980 (class 2604 OID 16880)
-- Name: horario_espaco id_horario_espaco; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_espaco ALTER COLUMN id_horario_espaco SET DEFAULT nextval('public.horario_espaco_id_horario_espaco_seq'::regclass);


--
-- TOC entry 4974 (class 2604 OID 16845)
-- Name: item_doacao id_item_doacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_doacao ALTER COLUMN id_item_doacao SET DEFAULT nextval('public.item_doacao_id_item_doacao_seq'::regclass);


--
-- TOC entry 5006 (class 2604 OID 17185)
-- Name: log_acesso id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_acesso ALTER COLUMN id_log SET DEFAULT nextval('public.log_acesso_id_log_seq'::regclass);


--
-- TOC entry 4943 (class 2604 OID 16547)
-- Name: modulo_sistema id_modulo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modulo_sistema ALTER COLUMN id_modulo SET DEFAULT nextval('public.modulo_sistema_id_modulo_seq'::regclass);


--
-- TOC entry 4952 (class 2604 OID 16657)
-- Name: parceiro id_parceiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro ALTER COLUMN id_parceiro SET DEFAULT nextval('public.parceiro_id_parceiro_seq'::regclass);


--
-- TOC entry 4967 (class 2604 OID 16771)
-- Name: parcela id_parcela; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcela ALTER COLUMN id_parcela SET DEFAULT nextval('public.parcela_id_parcela_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 16448)
-- Name: parentesco id_parentesco; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco ALTER COLUMN id_parentesco SET DEFAULT nextval('public.parentesco_id_parentesco_seq'::regclass);


--
-- TOC entry 4942 (class 2604 OID 16534)
-- Name: perfil_usuario id_perfil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_usuario ALTER COLUMN id_perfil SET DEFAULT nextval('public.perfil_usuario_id_perfil_seq'::regclass);


--
-- TOC entry 5003 (class 2604 OID 17161)
-- Name: permissao_usuario id_permissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao_usuario ALTER COLUMN id_permissao SET DEFAULT nextval('public.permissao_usuario_id_permissao_seq'::regclass);


--
-- TOC entry 4934 (class 2604 OID 16437)
-- Name: profissao id_profissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissao ALTER COLUMN id_profissao SET DEFAULT nextval('public.profissao_id_profissao_seq'::regclass);


--
-- TOC entry 4981 (class 2604 OID 16899)
-- Name: reserva_espaco id_reserva; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_espaco_id_reserva_seq'::regclass);


--
-- TOC entry 4940 (class 2604 OID 16512)
-- Name: status_agenda id_status_agenda; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_agenda ALTER COLUMN id_status_agenda SET DEFAULT nextval('public.status_agenda_id_status_agenda_seq'::regclass);


--
-- TOC entry 4937 (class 2604 OID 16479)
-- Name: status_conta id_status_conta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_conta ALTER COLUMN id_status_conta SET DEFAULT nextval('public.status_conta_id_status_conta_seq'::regclass);


--
-- TOC entry 4933 (class 2604 OID 16426)
-- Name: status_pessoa id_status; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_pessoa ALTER COLUMN id_status SET DEFAULT nextval('public.status_pessoa_id_status_seq'::regclass);


--
-- TOC entry 4939 (class 2604 OID 16501)
-- Name: status_reserva id_status_reserva; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_reserva ALTER COLUMN id_status_reserva SET DEFAULT nextval('public.status_reserva_id_status_reserva_seq'::regclass);


--
-- TOC entry 4948 (class 2604 OID 16606)
-- Name: telefone id_telefone; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone ALTER COLUMN id_telefone SET DEFAULT nextval('public.telefone_id_telefone_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 16680)
-- Name: telefone_parceiro id_telefone_parceiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_parceiro ALTER COLUMN id_telefone_parceiro SET DEFAULT nextval('public.telefone_parceiro_id_telefone_parceiro_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 16490)
-- Name: tipo_doacao id_tipo_doacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_doacao ALTER COLUMN id_tipo_doacao SET DEFAULT nextval('public.tipo_doacao_id_tipo_doacao_seq'::regclass);


--
-- TOC entry 4941 (class 2604 OID 16523)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('public.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 4998 (class 2604 OID 17032)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 5433 (class 0 OID 16939)
-- Dependencies: 277
-- Data for Name: agenda; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agenda (id_agenda, titulo, descricao, observacao, data_inicio, hora_inicio, data_fim, hora_fim, fk_espaco, fk_status_agenda, fk_associado, fk_parceiro, responsavel_nome, responsavel_telefone, responsavel_email, capacidade_maxima, total_participantes, valor_cobrado, valor_aluguel, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5437 (class 0 OID 17006)
-- Dependencies: 281
-- Data for Name: agenda_documento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agenda_documento (id, fk_agenda, fk_documento, criado_em) FROM stdin;
\.


--
-- TOC entry 5405 (class 0 OID 16555)
-- Dependencies: 249
-- Data for Name: associado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.associado (id_associado, nome, data_nascimento, cpf_cnpj, email, observacao, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, fk_estadocivil, fk_profissao, fk_categoria, fk_status, fk_genero, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
3	Carlos Eduardo Souza	1985-03-12	11122233344	carlos.souza@email.com	\N	t	Rua das Acácias	123	Apto 201	91030010	Califórnia	Porto Alegre	RS	2	4	3	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N
4	Maria Aparecida Lima	1972-07-25	22233344455	maria.lima@email.com	\N	t	Av. Bento Gonçalves	456	\N	91500000	Califórnia	Porto Alegre	RS	1	8	1	1	1	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N
5	João Pedro Ferreira	1990-11-08	33344455566	joao.ferreira@email.com	\N	t	Rua Pinheiro Machado	789	Casa 2	91040000	Califórnia	Porto Alegre	RS	3	1	3	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N
6	Ana Paula Rodrigues	1998-05-30	44455566677	ana.rodrigues@email.com	\N	t	Rua Garibaldi	321	\N	91020000	Califórnia	Porto Alegre	RS	1	9	3	2	1	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N
7	Roberto Carlos Mendes	1965-01-19	55566677788	roberto.mendes@email.com	\N	t	Av. Sertório	654	Bloco B	91060000	Califórnia	Porto Alegre	RS	2	7	2	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N
\.


--
-- TOC entry 5380 (class 0 OID 16412)
-- Dependencies: 224
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id_categoria, descricao) FROM stdin;
1	Fundador
2	Honorário
3	Contribuinte
\.


--
-- TOC entry 5419 (class 0 OID 16731)
-- Dependencies: 263
-- Data for Name: conta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conta (id_conta, fk_associado, fk_conta_regente, fk_conta_subordinada, fk_status_conta, descricao, valor_total, data_lancamento, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5415 (class 0 OID 16697)
-- Dependencies: 259
-- Data for Name: conta_regente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conta_regente (id_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5417 (class 0 OID 16712)
-- Dependencies: 261
-- Data for Name: conta_subordinada; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conta_subordinada (id_conta_subordinada, fk_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5409 (class 0 OID 16623)
-- Dependencies: 253
-- Data for Name: dependente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dependente (id_dependente, fk_associado, nome, data_nascimento, cpf, observacao, fk_parentesco, fk_genero, criado_em, atualizado_em) FROM stdin;
\.


--
-- TOC entry 5423 (class 0 OID 16801)
-- Dependencies: 267
-- Data for Name: doacao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doacao (id_doacao, fk_parceiro, fk_associado, nome_externo, telefone_externo, fk_tipo_doacao, fk_conta_regente, fk_conta_subordinada, descricao, data_doacao, valor_dinheiro, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5435 (class 0 OID 16979)
-- Dependencies: 279
-- Data for Name: documento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documento (id_documento, numero, ano, fk_tipo_documento, tipo_livre, assunto, data_documento, conteudo, arquivo_path, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5427 (class 0 OID 16861)
-- Dependencies: 271
-- Data for Name: espaco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.espaco (id_espaco, nome, descricao, capacidade, observacao, ativo, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5378 (class 0 OID 16401)
-- Dependencies: 222
-- Data for Name: estado_civil; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estado_civil (id_estadocivil, descricao) FROM stdin;
1	Solteiro(a)
2	Casado(a)
3	Divorciado(a)
4	Viúvo(a)
5	Amasiado(a)
\.


--
-- TOC entry 5389 (class 0 OID 16465)
-- Dependencies: 233
-- Data for Name: forma_pagamento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.forma_pagamento (id_forma_pagamento, descricao) FROM stdin;
1	PIX
2	Boleto
3	Cartão de crédito
4	Cartão de débito
5	Dinheiro
6	Transferência bancária
\.


--
-- TOC entry 5376 (class 0 OID 16390)
-- Dependencies: 220
-- Data for Name: genero; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genero (id_genero, descricao) FROM stdin;
1	Feminino
2	Masculino
3	Não binário
\.


--
-- TOC entry 5429 (class 0 OID 16877)
-- Dependencies: 273
-- Data for Name: horario_espaco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horario_espaco (id_horario_espaco, fk_espaco, dia_semana, hora_inicio, hora_fim, observacao) FROM stdin;
\.


--
-- TOC entry 5425 (class 0 OID 16842)
-- Dependencies: 269
-- Data for Name: item_doacao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_doacao (id_item_doacao, fk_doacao, descricao, quantidade, unidade, observacao, criado_em) FROM stdin;
\.


--
-- TOC entry 5443 (class 0 OID 17182)
-- Dependencies: 287
-- Data for Name: log_acesso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log_acesso (id_log, fk_usuario, tipo, ip, registrado_em) FROM stdin;
\.


--
-- TOC entry 5403 (class 0 OID 16544)
-- Dependencies: 247
-- Data for Name: modulo_sistema; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modulo_sistema (id_modulo, descricao) FROM stdin;
1	Dashboard
2	Associados
3	Parceiros
4	Financeiro
5	Reserva de Espaço
6	Agenda
7	Documentação
8	Usuários e Permissões
\.


--
-- TOC entry 5411 (class 0 OID 16654)
-- Dependencies: 255
-- Data for Name: parceiro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parceiro (id_parceiro, nome_razao_social, cpf_cnpj, email, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5421 (class 0 OID 16768)
-- Dependencies: 265
-- Data for Name: parcela; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parcela (id_parcela, fk_conta, fk_status_conta, fk_forma_pagamento, numero_parcela, total_parcelas, valor, data_vencimento, data_pagamento, valor_pago, observacao, criado_em, atualizado_em) FROM stdin;
\.


--
-- TOC entry 5386 (class 0 OID 16445)
-- Dependencies: 230
-- Data for Name: parentesco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parentesco (id_parentesco, descricao, observacao) FROM stdin;
1	Filho(a)	\N
2	Enteado(a)	\N
3	Sobrinho(a)	\N
4	Neto(a)	\N
5	Outro	\N
\.


--
-- TOC entry 5401 (class 0 OID 16531)
-- Dependencies: 245
-- Data for Name: perfil_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.perfil_usuario (id_perfil, descricao, observacao) FROM stdin;
1	Administrador	Acesso total ao sistema. Gerencia usuários e permissões.
2	Gestor	Acesso operacional configurável pelo administrador.
3	Visualizador	Somente leitura. Módulos visíveis configuráveis pelo administrador.
\.


--
-- TOC entry 5441 (class 0 OID 17158)
-- Dependencies: 285
-- Data for Name: permissao_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissao_usuario (id_permissao, fk_usuario, fk_modulo, pode_acessar, pode_editar) FROM stdin;
1	3	1	t	f
2	3	2	t	f
3	3	3	t	f
4	3	4	t	f
5	3	5	t	f
6	3	6	t	f
7	3	7	t	f
8	3	8	t	f
9	4	1	t	f
10	4	2	t	f
11	4	3	t	f
12	4	4	t	f
13	4	5	t	f
14	4	6	t	f
15	4	7	t	f
16	4	8	t	f
17	5	1	f	f
18	5	2	f	f
19	5	3	f	f
20	5	4	f	f
21	5	5	f	f
22	5	6	t	f
23	5	7	f	f
24	5	8	f	f
25	6	1	t	t
26	6	2	t	t
27	6	3	t	f
28	6	4	t	f
29	6	5	t	f
30	6	6	t	f
31	6	7	t	f
32	6	8	t	f
33	2	1	f	f
34	2	2	f	f
35	2	3	f	f
36	2	4	f	f
37	2	5	f	f
38	2	6	f	f
39	2	7	f	f
40	2	8	f	f
\.


--
-- TOC entry 5384 (class 0 OID 16434)
-- Dependencies: 228
-- Data for Name: profissao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissao (id_profissao, descricao) FROM stdin;
1	Autônomo formal
2	Autônomo informal
3	Empregado informal
4	Empregado formal
5	Trabalhador doméstico
6	Trabalhador rural
7	Servidor público
8	Aposentado/Pensionista
9	Estudante
10	Estagiário
11	Não trabalha
12	Outro
\.


--
-- TOC entry 5431 (class 0 OID 16896)
-- Dependencies: 275
-- Data for Name: reserva_espaco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reserva_espaco (id_reserva, fk_espaco, fk_horario_espaco, fk_status_reserva, data_reserva, fk_associado, fk_parceiro, nome_externo, telefone_externo, email_externo, valor_cobrado, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 5397 (class 0 OID 16509)
-- Dependencies: 241
-- Data for Name: status_agenda; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_agenda (id_status_agenda, descricao) FROM stdin;
1	Agendado
2	Cancelado
3	Concluído
4	Suspenso
\.


--
-- TOC entry 5391 (class 0 OID 16476)
-- Dependencies: 235
-- Data for Name: status_conta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_conta (id_status_conta, descricao) FROM stdin;
1	Aberto
2	Liquidado
3	Cancelado
\.


--
-- TOC entry 5382 (class 0 OID 16423)
-- Dependencies: 226
-- Data for Name: status_pessoa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_pessoa (id_status, descricao) FROM stdin;
1	Ativo
2	Pendente
3	Inativo
\.


--
-- TOC entry 5395 (class 0 OID 16498)
-- Dependencies: 239
-- Data for Name: status_reserva; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_reserva (id_status_reserva, descricao) FROM stdin;
1	Confirmado
2	Cancelado
3	Concluído
\.


--
-- TOC entry 5407 (class 0 OID 16603)
-- Dependencies: 251
-- Data for Name: telefone; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telefone (id_telefone, fk_associado, ddd, numero) FROM stdin;
6	3	51	991234567
7	4	51	987654321
8	5	51	993456789
9	6	51	994567890
10	7	51	995678901
\.


--
-- TOC entry 5413 (class 0 OID 16677)
-- Dependencies: 257
-- Data for Name: telefone_parceiro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telefone_parceiro (id_telefone_parceiro, fk_parceiro, ddd, numero) FROM stdin;
\.


--
-- TOC entry 5393 (class 0 OID 16487)
-- Dependencies: 237
-- Data for Name: tipo_doacao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_doacao (id_tipo_doacao, descricao) FROM stdin;
1	Dinheiro
2	Alimentos e bebidas
3	Brinquedos
4	Outros itens
\.


--
-- TOC entry 5399 (class 0 OID 16520)
-- Dependencies: 243
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_documento (id_tipo_documento, descricao) FROM stdin;
1	Ata
2	Ofício
3	Mensagem
4	Circular
5	Requerimento
6	Declaração
7	Outro
\.


--
-- TOC entry 5387 (class 0 OID 16457)
-- Dependencies: 231
-- Data for Name: uf; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.uf (sigla, nome) FROM stdin;
AC	Acre
AL	Alagoas
AP	Amapá
AM	Amazonas
BA	Bahia
CE	Ceará
DF	Distrito Federal
ES	Espírito Santo
GO	Goiás
MA	Maranhão
MT	Mato Grosso
MS	Mato Grosso do Sul
MG	Minas Gerais
PA	Pará
PB	Paraíba
PR	Paraná
PE	Pernambuco
PI	Piauí
RJ	Rio de Janeiro
RN	Rio Grande do Norte
RS	Rio Grande do Sul
RO	Rondônia
RR	Roraima
SC	Santa Catarina
SP	São Paulo
SE	Sergipe
TO	Tocantins
\.


--
-- TOC entry 5439 (class 0 OID 17029)
-- Dependencies: 283
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id_usuario, nome, email, senha_hash, fk_perfil, fk_associado, ativo, primeiro_acesso, ultimo_acesso, token_reset, token_expira_em, criado_em, atualizado_em) FROM stdin;
3	abube	abube@abc.com	$2y$10$G0VjwG2.P9VRYHcFbAoEDOudd6OdzokTQQKLTlJgKgbCk9391r4aS	2	\N	t	f	\N	\N	\N	2026-04-24 02:04:12.30994	2026-04-24 02:04:12.30994
4	abube2	abube2@abube.com	$2y$10$170ryA7YsKgb3vEvfKOYIeHsBm5fNZV6Xl5jQySL5WX0R6mPm05.K	2	\N	t	f	\N	\N	\N	2026-04-24 10:01:53.25811	2026-04-24 10:01:53.25811
5	teste	tests@f.com	\N	2	\N	t	t	\N	\N	\N	2026-04-24 10:12:37.470684	2026-04-24 10:12:37.470684
6	mika	mika@mika.com	$2y$10$tJ5ldifNHTqdd98yF.H4wu4i7Ozmc4EqdYoZNnmNk3BXB.lHOI2sm	2	\N	t	f	\N	\N	\N	2026-04-24 21:17:03.591281	2026-04-24 21:17:03.591281
1	João da Silva	joao.silva@email.com	$2y$10$abcdefghijklmnopqrstuuVwXyZ1234567890abcdefghijklmnop	1	\N	f	t	\N	\N	\N	2026-04-24 01:41:34.576624	2026-04-24 21:19:40.742965
2	Leonardo Pereira Leote	leonardo.leote0909@gmail.com	$2y$10$V86AM1dX.kCjRA5oGCKiOOAwe1/j7Wr31kLIsjo2n8Plj45EkmtMm	2	\N	t	f	2026-04-24 22:17:39.198548	\N	\N	2026-04-24 01:43:17.079885	2026-04-24 22:17:39.198548
\.


--
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 280
-- Name: agenda_documento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.agenda_documento_id_seq', 1, false);


--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 276
-- Name: agenda_id_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.agenda_id_agenda_seq', 1, false);


--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 248
-- Name: associado_id_associado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.associado_id_associado_seq', 7, true);


--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 223
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 262
-- Name: conta_id_conta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conta_id_conta_seq', 1, false);


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 258
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conta_regente_id_conta_regente_seq', 1, false);


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 260
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conta_subordinada_id_conta_subordinada_seq', 1, false);


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 252
-- Name: dependente_id_dependente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dependente_id_dependente_seq', 1, false);


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 266
-- Name: doacao_id_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doacao_id_doacao_seq', 1, false);


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 278
-- Name: documento_id_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.documento_id_documento_seq', 1, false);


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 270
-- Name: espaco_id_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.espaco_id_espaco_seq', 1, false);


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 221
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estado_civil_id_estadocivil_seq', 1, false);


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 232
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.forma_pagamento_id_forma_pagamento_seq', 1, false);


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 219
-- Name: genero_id_genero_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genero_id_genero_seq', 1, false);


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 272
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.horario_espaco_id_horario_espaco_seq', 1, false);


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 268
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_doacao_id_item_doacao_seq', 1, false);


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 286
-- Name: log_acesso_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_acesso_id_log_seq', 1, false);


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 246
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modulo_sistema_id_modulo_seq', 1, false);


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parceiro_id_parceiro_seq', 1, false);


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 264
-- Name: parcela_id_parcela_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parcela_id_parcela_seq', 1, false);


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 229
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parentesco_id_parentesco_seq', 1, false);


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 244
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.perfil_usuario_id_perfil_seq', 1, false);


--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 284
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permissao_usuario_id_permissao_seq', 40, true);


--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 227
-- Name: profissao_id_profissao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissao_id_profissao_seq', 1, false);


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 274
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reserva_espaco_id_reserva_seq', 1, false);


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 240
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_agenda_id_status_agenda_seq', 1, false);


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 234
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_conta_id_status_conta_seq', 1, false);


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 225
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_pessoa_id_status_seq', 1, false);


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 238
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_reserva_id_status_reserva_seq', 1, false);


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 250
-- Name: telefone_id_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telefone_id_telefone_seq', 10, true);


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 256
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telefone_parceiro_id_telefone_parceiro_seq', 1, false);


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 236
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_doacao_id_tipo_doacao_seq', 1, false);


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 242
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_documento_id_tipo_documento_seq', 1, false);


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 282
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 6, true);


--
-- TOC entry 5131 (class 2606 OID 17017)
-- Name: agenda_documento agenda_documento_fk_agenda_fk_documento_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fk_documento_key UNIQUE (fk_agenda, fk_documento);


--
-- TOC entry 5133 (class 2606 OID 17015)
-- Name: agenda_documento agenda_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_pkey PRIMARY KEY (id);


--
-- TOC entry 5123 (class 2606 OID 16957)
-- Name: agenda agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_pkey PRIMARY KEY (id_agenda);


--
-- TOC entry 5078 (class 2606 OID 16571)
-- Name: associado associado_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 5080 (class 2606 OID 16569)
-- Name: associado associado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_pkey PRIMARY KEY (id_associado);


--
-- TOC entry 5028 (class 2606 OID 16421)
-- Name: categoria categoria_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_descricao_key UNIQUE (descricao);


--
-- TOC entry 5030 (class 2606 OID 16419)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 5104 (class 2606 OID 16746)
-- Name: conta conta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT conta_pkey PRIMARY KEY (id_conta);


--
-- TOC entry 5098 (class 2606 OID 16710)
-- Name: conta_regente conta_regente_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_descricao_key UNIQUE (descricao);


--
-- TOC entry 5100 (class 2606 OID 16708)
-- Name: conta_regente conta_regente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_pkey PRIMARY KEY (id_conta_regente);


--
-- TOC entry 5102 (class 2606 OID 16724)
-- Name: conta_subordinada conta_subordinada_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_pkey PRIMARY KEY (id_conta_subordinada);


--
-- TOC entry 5087 (class 2606 OID 16637)
-- Name: dependente dependente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_pkey PRIMARY KEY (id_dependente);


--
-- TOC entry 5109 (class 2606 OID 16815)
-- Name: doacao doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_pkey PRIMARY KEY (id_doacao);


--
-- TOC entry 5126 (class 2606 OID 16999)
-- Name: documento documento_numero_ano_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_numero_ano_key UNIQUE (numero, ano);


--
-- TOC entry 5128 (class 2606 OID 16997)
-- Name: documento documento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5114 (class 2606 OID 16875)
-- Name: espaco espaco_nome_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_nome_key UNIQUE (nome);


--
-- TOC entry 5116 (class 2606 OID 16873)
-- Name: espaco espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_pkey PRIMARY KEY (id_espaco);


--
-- TOC entry 5024 (class 2606 OID 16410)
-- Name: estado_civil estado_civil_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_descricao_key UNIQUE (descricao);


--
-- TOC entry 5026 (class 2606 OID 16408)
-- Name: estado_civil estado_civil_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_pkey PRIMARY KEY (id_estadocivil);


--
-- TOC entry 5046 (class 2606 OID 16474)
-- Name: forma_pagamento forma_pagamento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_descricao_key UNIQUE (descricao);


--
-- TOC entry 5048 (class 2606 OID 16472)
-- Name: forma_pagamento forma_pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_pkey PRIMARY KEY (id_forma_pagamento);


--
-- TOC entry 5020 (class 2606 OID 16399)
-- Name: genero genero_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_descricao_key UNIQUE (descricao);


--
-- TOC entry 5022 (class 2606 OID 16397)
-- Name: genero genero_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_pkey PRIMARY KEY (id_genero);


--
-- TOC entry 5118 (class 2606 OID 16889)
-- Name: horario_espaco horario_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_pkey PRIMARY KEY (id_horario_espaco);


--
-- TOC entry 5112 (class 2606 OID 16854)
-- Name: item_doacao item_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_pkey PRIMARY KEY (id_item_doacao);


--
-- TOC entry 5144 (class 2606 OID 17191)
-- Name: log_acesso log_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_pkey PRIMARY KEY (id_log);


--
-- TOC entry 5074 (class 2606 OID 16553)
-- Name: modulo_sistema modulo_sistema_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_descricao_key UNIQUE (descricao);


--
-- TOC entry 5076 (class 2606 OID 16551)
-- Name: modulo_sistema modulo_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_pkey PRIMARY KEY (id_modulo);


--
-- TOC entry 5090 (class 2606 OID 16670)
-- Name: parceiro parceiro_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 5092 (class 2606 OID 16668)
-- Name: parceiro parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_pkey PRIMARY KEY (id_parceiro);


--
-- TOC entry 5107 (class 2606 OID 16784)
-- Name: parcela parcela_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcela
    ADD CONSTRAINT parcela_pkey PRIMARY KEY (id_parcela);


--
-- TOC entry 5040 (class 2606 OID 16456)
-- Name: parentesco parentesco_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_descricao_key UNIQUE (descricao);


--
-- TOC entry 5042 (class 2606 OID 16454)
-- Name: parentesco parentesco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_pkey PRIMARY KEY (id_parentesco);


--
-- TOC entry 5070 (class 2606 OID 16542)
-- Name: perfil_usuario perfil_usuario_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_descricao_key UNIQUE (descricao);


--
-- TOC entry 5072 (class 2606 OID 16540)
-- Name: perfil_usuario perfil_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_pkey PRIMARY KEY (id_perfil);


--
-- TOC entry 5139 (class 2606 OID 17170)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fk_modulo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fk_modulo_key UNIQUE (fk_usuario, fk_modulo);


--
-- TOC entry 5141 (class 2606 OID 17168)
-- Name: permissao_usuario permissao_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_pkey PRIMARY KEY (id_permissao);


--
-- TOC entry 5036 (class 2606 OID 16443)
-- Name: profissao profissao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_descricao_key UNIQUE (descricao);


--
-- TOC entry 5038 (class 2606 OID 16441)
-- Name: profissao profissao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_pkey PRIMARY KEY (id_profissao);


--
-- TOC entry 5121 (class 2606 OID 16912)
-- Name: reserva_espaco reserva_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_pkey PRIMARY KEY (id_reserva);


--
-- TOC entry 5062 (class 2606 OID 16518)
-- Name: status_agenda status_agenda_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_descricao_key UNIQUE (descricao);


--
-- TOC entry 5064 (class 2606 OID 16516)
-- Name: status_agenda status_agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_pkey PRIMARY KEY (id_status_agenda);


--
-- TOC entry 5050 (class 2606 OID 16485)
-- Name: status_conta status_conta_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_descricao_key UNIQUE (descricao);


--
-- TOC entry 5052 (class 2606 OID 16483)
-- Name: status_conta status_conta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_pkey PRIMARY KEY (id_status_conta);


--
-- TOC entry 5032 (class 2606 OID 16432)
-- Name: status_pessoa status_pessoa_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_descricao_key UNIQUE (descricao);


--
-- TOC entry 5034 (class 2606 OID 16430)
-- Name: status_pessoa status_pessoa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_pkey PRIMARY KEY (id_status);


--
-- TOC entry 5058 (class 2606 OID 16507)
-- Name: status_reserva status_reserva_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_descricao_key UNIQUE (descricao);


--
-- TOC entry 5060 (class 2606 OID 16505)
-- Name: status_reserva status_reserva_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_pkey PRIMARY KEY (id_status_reserva);


--
-- TOC entry 5083 (class 2606 OID 16616)
-- Name: telefone telefone_fk_associado_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_ddd_numero_key UNIQUE (fk_associado, ddd, numero);


--
-- TOC entry 5094 (class 2606 OID 16690)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_ddd_numero_key UNIQUE (fk_parceiro, ddd, numero);


--
-- TOC entry 5096 (class 2606 OID 16688)
-- Name: telefone_parceiro telefone_parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_pkey PRIMARY KEY (id_telefone_parceiro);


--
-- TOC entry 5085 (class 2606 OID 16614)
-- Name: telefone telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_pkey PRIMARY KEY (id_telefone);


--
-- TOC entry 5054 (class 2606 OID 16496)
-- Name: tipo_doacao tipo_doacao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_descricao_key UNIQUE (descricao);


--
-- TOC entry 5056 (class 2606 OID 16494)
-- Name: tipo_doacao tipo_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_pkey PRIMARY KEY (id_tipo_doacao);


--
-- TOC entry 5066 (class 2606 OID 16529)
-- Name: tipo_documento tipo_documento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_descricao_key UNIQUE (descricao);


--
-- TOC entry 5068 (class 2606 OID 16527)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 5044 (class 2606 OID 16463)
-- Name: uf uf_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uf
    ADD CONSTRAINT uf_pkey PRIMARY KEY (sigla);


--
-- TOC entry 5135 (class 2606 OID 17046)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 5137 (class 2606 OID 17044)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5124 (class 1259 OID 17223)
-- Name: idx_agenda_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agenda_data ON public.agenda USING btree (data_inicio);


--
-- TOC entry 5081 (class 1259 OID 17226)
-- Name: idx_associado_nome; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_associado_nome ON public.associado USING btree (nome);


--
-- TOC entry 5110 (class 1259 OID 17225)
-- Name: idx_doacao_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doacao_data ON public.doacao USING btree (data_doacao);


--
-- TOC entry 5129 (class 1259 OID 17228)
-- Name: idx_documento_indice; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_documento_indice ON public.documento USING btree (ano, numero);


--
-- TOC entry 5142 (class 1259 OID 17229)
-- Name: idx_log_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_log_usuario ON public.log_acesso USING btree (fk_usuario);


--
-- TOC entry 5088 (class 1259 OID 17227)
-- Name: idx_parceiro_nome; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parceiro_nome ON public.parceiro USING btree (nome_razao_social);


--
-- TOC entry 5105 (class 1259 OID 17224)
-- Name: idx_parcela_conta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parcela_conta ON public.parcela USING btree (fk_conta);


--
-- TOC entry 5119 (class 1259 OID 17222)
-- Name: idx_reserva_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserva_data ON public.reserva_espaco USING btree (data_reserva);


--
-- TOC entry 5224 (class 2620 OID 17207)
-- Name: agenda trg_conflito_agenda; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_conflito_agenda BEFORE INSERT OR UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_agenda();


--
-- TOC entry 5221 (class 2620 OID 17205)
-- Name: reserva_espaco trg_conflito_reserva; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_conflito_reserva BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_reserva();


--
-- TOC entry 5209 (class 2620 OID 17198)
-- Name: associado trg_cpf_cnpj_associado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cpf_cnpj_associado BEFORE INSERT OR UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 5212 (class 2620 OID 17199)
-- Name: parceiro trg_cpf_cnpj_parceiro; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cpf_cnpj_parceiro BEFORE INSERT OR UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 5225 (class 2620 OID 17217)
-- Name: agenda trg_ts_agenda; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_agenda BEFORE UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5210 (class 2620 OID 17209)
-- Name: associado trg_ts_associado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_associado BEFORE UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5216 (class 2620 OID 17212)
-- Name: conta trg_ts_conta; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_conta BEFORE UPDATE ON public.conta FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5214 (class 2620 OID 17220)
-- Name: conta_regente trg_ts_conta_regente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_conta_regente BEFORE UPDATE ON public.conta_regente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5215 (class 2620 OID 17221)
-- Name: conta_subordinada trg_ts_conta_sub; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_conta_sub BEFORE UPDATE ON public.conta_subordinada FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5211 (class 2620 OID 17211)
-- Name: dependente trg_ts_dependente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_dependente BEFORE UPDATE ON public.dependente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5219 (class 2620 OID 17214)
-- Name: doacao trg_ts_doacao; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_doacao BEFORE UPDATE ON public.doacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5226 (class 2620 OID 17218)
-- Name: documento trg_ts_documento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_documento BEFORE UPDATE ON public.documento FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5220 (class 2620 OID 17215)
-- Name: espaco trg_ts_espaco; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_espaco BEFORE UPDATE ON public.espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5213 (class 2620 OID 17210)
-- Name: parceiro trg_ts_parceiro; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_parceiro BEFORE UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5217 (class 2620 OID 17213)
-- Name: parcela trg_ts_parcela; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_parcela BEFORE UPDATE ON public.parcela FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5222 (class 2620 OID 17216)
-- Name: reserva_espaco trg_ts_reserva; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_reserva BEFORE UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5227 (class 2620 OID 17219)
-- Name: usuario trg_ts_usuario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ts_usuario BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 5223 (class 2620 OID 17203)
-- Name: reserva_espaco trg_validar_horario_espaco; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_horario_espaco BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_validar_horario_espaco();


--
-- TOC entry 5218 (class 2620 OID 17201)
-- Name: parcela trg_validar_parcelas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_parcelas BEFORE INSERT OR UPDATE ON public.parcela FOR EACH ROW EXECUTE FUNCTION public.fn_validar_parcelas();


--
-- TOC entry 5202 (class 2606 OID 17018)
-- Name: agenda_documento agenda_documento_fk_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fkey FOREIGN KEY (fk_agenda) REFERENCES public.agenda(id_agenda) ON DELETE CASCADE;


--
-- TOC entry 5203 (class 2606 OID 17023)
-- Name: agenda_documento agenda_documento_fk_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_documento_fkey FOREIGN KEY (fk_documento) REFERENCES public.documento(id_documento) ON DELETE CASCADE;


--
-- TOC entry 5193 (class 2606 OID 16968)
-- Name: agenda agenda_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 5194 (class 2606 OID 16958)
-- Name: agenda agenda_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE SET NULL;


--
-- TOC entry 5195 (class 2606 OID 16973)
-- Name: agenda agenda_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE SET NULL;


--
-- TOC entry 5196 (class 2606 OID 16963)
-- Name: agenda agenda_fk_status_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_status_agenda_fkey FOREIGN KEY (fk_status_agenda) REFERENCES public.status_agenda(id_status_agenda);


--
-- TOC entry 5145 (class 2606 OID 16587)
-- Name: associado associado_fk_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_categoria_fkey FOREIGN KEY (fk_categoria) REFERENCES public.categoria(id_categoria);


--
-- TOC entry 5146 (class 2606 OID 16577)
-- Name: associado associado_fk_estadocivil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_estadocivil_fkey FOREIGN KEY (fk_estadocivil) REFERENCES public.estado_civil(id_estadocivil);


--
-- TOC entry 5147 (class 2606 OID 16597)
-- Name: associado associado_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 5148 (class 2606 OID 16582)
-- Name: associado associado_fk_profissao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_profissao_fkey FOREIGN KEY (fk_profissao) REFERENCES public.profissao(id_profissao);


--
-- TOC entry 5149 (class 2606 OID 16592)
-- Name: associado associado_fk_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_status_fkey FOREIGN KEY (fk_status) REFERENCES public.status_pessoa(id_status);


--
-- TOC entry 5150 (class 2606 OID 16572)
-- Name: associado associado_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 5166 (class 2606 OID 16747)
-- Name: conta conta_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT conta_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 5167 (class 2606 OID 16752)
-- Name: conta conta_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT conta_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 5168 (class 2606 OID 16757)
-- Name: conta conta_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT conta_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada) ON DELETE RESTRICT;


--
-- TOC entry 5169 (class 2606 OID 16762)
-- Name: conta conta_fk_status_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT conta_fk_status_conta_fkey FOREIGN KEY (fk_status_conta) REFERENCES public.status_conta(id_status_conta);


--
-- TOC entry 5163 (class 2606 OID 16725)
-- Name: conta_subordinada conta_subordinada_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 5154 (class 2606 OID 16638)
-- Name: dependente dependente_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 5155 (class 2606 OID 16648)
-- Name: dependente dependente_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 5156 (class 2606 OID 16643)
-- Name: dependente dependente_fk_parentesco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_parentesco_fkey FOREIGN KEY (fk_parentesco) REFERENCES public.parentesco(id_parentesco);


--
-- TOC entry 5175 (class 2606 OID 16821)
-- Name: doacao doacao_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 5176 (class 2606 OID 16831)
-- Name: doacao doacao_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente);


--
-- TOC entry 5177 (class 2606 OID 16836)
-- Name: doacao doacao_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada);


--
-- TOC entry 5178 (class 2606 OID 16816)
-- Name: doacao doacao_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 5179 (class 2606 OID 16826)
-- Name: doacao doacao_fk_tipo_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_tipo_doacao_fkey FOREIGN KEY (fk_tipo_doacao) REFERENCES public.tipo_doacao(id_tipo_doacao);


--
-- TOC entry 5199 (class 2606 OID 17000)
-- Name: documento documento_fk_tipo_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_fk_tipo_documento_fkey FOREIGN KEY (fk_tipo_documento) REFERENCES public.tipo_documento(id_tipo_documento);


--
-- TOC entry 5197 (class 2606 OID 17142)
-- Name: agenda fk_ag_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5198 (class 2606 OID 17137)
-- Name: agenda fk_ag_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5151 (class 2606 OID 17062)
-- Name: associado fk_assoc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5152 (class 2606 OID 17057)
-- Name: associado fk_assoc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5170 (class 2606 OID 17102)
-- Name: conta fk_conta_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT fk_conta_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5171 (class 2606 OID 17097)
-- Name: conta fk_conta_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT fk_conta_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5161 (class 2606 OID 17082)
-- Name: conta_regente fk_cr_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5162 (class 2606 OID 17077)
-- Name: conta_regente fk_cr_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5164 (class 2606 OID 17092)
-- Name: conta_subordinada fk_cs_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5165 (class 2606 OID 17087)
-- Name: conta_subordinada fk_cs_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5180 (class 2606 OID 17112)
-- Name: doacao fk_doac_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5181 (class 2606 OID 17107)
-- Name: doacao fk_doac_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5200 (class 2606 OID 17152)
-- Name: documento fk_doc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5201 (class 2606 OID 17147)
-- Name: documento fk_doc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5183 (class 2606 OID 17122)
-- Name: espaco fk_esp_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5184 (class 2606 OID 17117)
-- Name: espaco fk_esp_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5157 (class 2606 OID 17072)
-- Name: parceiro fk_parc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5158 (class 2606 OID 17067)
-- Name: parceiro fk_parc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5186 (class 2606 OID 17132)
-- Name: reserva_espaco fk_res_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5187 (class 2606 OID 17127)
-- Name: reserva_espaco fk_res_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5185 (class 2606 OID 16890)
-- Name: horario_espaco horario_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE CASCADE;


--
-- TOC entry 5182 (class 2606 OID 16855)
-- Name: item_doacao item_doacao_fk_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_fk_doacao_fkey FOREIGN KEY (fk_doacao) REFERENCES public.doacao(id_doacao) ON DELETE CASCADE;


--
-- TOC entry 5208 (class 2606 OID 17192)
-- Name: log_acesso log_acesso_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5159 (class 2606 OID 16671)
-- Name: parceiro parceiro_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 5172 (class 2606 OID 16785)
-- Name: parcela parcela_fk_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcela
    ADD CONSTRAINT parcela_fk_conta_fkey FOREIGN KEY (fk_conta) REFERENCES public.conta(id_conta) ON DELETE RESTRICT;


--
-- TOC entry 5173 (class 2606 OID 16795)
-- Name: parcela parcela_fk_forma_pagamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcela
    ADD CONSTRAINT parcela_fk_forma_pagamento_fkey FOREIGN KEY (fk_forma_pagamento) REFERENCES public.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 5174 (class 2606 OID 16790)
-- Name: parcela parcela_fk_status_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcela
    ADD CONSTRAINT parcela_fk_status_conta_fkey FOREIGN KEY (fk_status_conta) REFERENCES public.status_conta(id_status_conta);


--
-- TOC entry 5206 (class 2606 OID 17176)
-- Name: permissao_usuario permissao_usuario_fk_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_modulo_fkey FOREIGN KEY (fk_modulo) REFERENCES public.modulo_sistema(id_modulo);


--
-- TOC entry 5207 (class 2606 OID 17171)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5188 (class 2606 OID 16928)
-- Name: reserva_espaco reserva_espaco_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 5189 (class 2606 OID 16913)
-- Name: reserva_espaco reserva_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE RESTRICT;


--
-- TOC entry 5190 (class 2606 OID 16918)
-- Name: reserva_espaco reserva_espaco_fk_horario_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_horario_espaco_fkey FOREIGN KEY (fk_horario_espaco) REFERENCES public.horario_espaco(id_horario_espaco) ON DELETE RESTRICT;


--
-- TOC entry 5191 (class 2606 OID 16933)
-- Name: reserva_espaco reserva_espaco_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 5192 (class 2606 OID 16923)
-- Name: reserva_espaco reserva_espaco_fk_status_reserva_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_status_reserva_fkey FOREIGN KEY (fk_status_reserva) REFERENCES public.status_reserva(id_status_reserva);


--
-- TOC entry 5153 (class 2606 OID 16617)
-- Name: telefone telefone_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 5160 (class 2606 OID 16691)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE CASCADE;


--
-- TOC entry 5204 (class 2606 OID 17052)
-- Name: usuario usuario_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 5205 (class 2606 OID 17047)
-- Name: usuario usuario_fk_perfil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_perfil_fkey FOREIGN KEY (fk_perfil) REFERENCES public.perfil_usuario(id_perfil);


-- Completed on 2026-04-27 22:02:27

--
-- PostgreSQL database dump complete
--



