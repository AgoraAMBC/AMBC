--
-- PostgreSQL database dump
--

\restrict kCiDgdrMFyd27WfF6B7G8wZw1wu6jGxfEuU6QfjcdUBdBcQ2vsmf68Agc2dLzRh

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg12+1)
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-29 10:03:41

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
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: ambc_db_user
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO ambc_db_user;

--
-- TOC entry 311 (class 1255 OID 16398)
-- Name: fn_atualizar_timestamp(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
--

CREATE FUNCTION public.fn_atualizar_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_atualizar_timestamp() OWNER TO ambc_db_user;

--
-- TOC entry 312 (class 1255 OID 16399)
-- Name: fn_conflito_agenda(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
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


ALTER FUNCTION public.fn_conflito_agenda() OWNER TO ambc_db_user;

--
-- TOC entry 313 (class 1255 OID 16400)
-- Name: fn_conflito_reserva(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
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


ALTER FUNCTION public.fn_conflito_reserva() OWNER TO ambc_db_user;

--
-- TOC entry 314 (class 1255 OID 16401)
-- Name: fn_validar_cpf_cnpj(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
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


ALTER FUNCTION public.fn_validar_cpf_cnpj() OWNER TO ambc_db_user;

--
-- TOC entry 315 (class 1255 OID 16402)
-- Name: fn_validar_horario_espaco(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
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


ALTER FUNCTION public.fn_validar_horario_espaco() OWNER TO ambc_db_user;

--
-- TOC entry 316 (class 1255 OID 16403)
-- Name: fn_validar_parcelas(); Type: FUNCTION; Schema: public; Owner: ambc_db_user
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


ALTER FUNCTION public.fn_validar_parcelas() OWNER TO ambc_db_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16404)
-- Name: agenda; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.agenda OWNER TO ambc_db_user;

--
-- TOC entry 220 (class 1259 OID 16420)
-- Name: agenda_documento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.agenda_documento (
    id integer NOT NULL,
    fk_agenda integer NOT NULL,
    fk_documento integer NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.agenda_documento OWNER TO ambc_db_user;

--
-- TOC entry 221 (class 1259 OID 16427)
-- Name: agenda_documento_id_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.agenda_documento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agenda_documento_id_seq OWNER TO ambc_db_user;

--
-- TOC entry 4049 (class 0 OID 0)
-- Dependencies: 221
-- Name: agenda_documento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.agenda_documento_id_seq OWNED BY public.agenda_documento.id;


--
-- TOC entry 222 (class 1259 OID 16428)
-- Name: agenda_id_agenda_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.agenda_id_agenda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agenda_id_agenda_seq OWNER TO ambc_db_user;

--
-- TOC entry 4050 (class 0 OID 0)
-- Dependencies: 222
-- Name: agenda_id_agenda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.agenda_id_agenda_seq OWNED BY public.agenda.id_agenda;


--
-- TOC entry 223 (class 1259 OID 16429)
-- Name: associado; Type: TABLE; Schema: public; Owner: ambc_db_user
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
    matricula character varying(20),
    data_entrada date,
    CONSTRAINT chk_associado_nome_composto CHECK ((TRIM(BOTH FROM nome) ~~ '% %'::text))
);


ALTER TABLE public.associado OWNER TO ambc_db_user;

--
-- TOC entry 291 (class 1259 OID 17658)
-- Name: associado_dependente; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.associado_dependente (
    fk_associado integer NOT NULL,
    fk_dependente integer NOT NULL,
    principal boolean DEFAULT false,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.associado_dependente OWNER TO ambc_db_user;

--
-- TOC entry 224 (class 1259 OID 16441)
-- Name: associado_id_associado_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.associado_id_associado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.associado_id_associado_seq OWNER TO ambc_db_user;

--
-- TOC entry 4051 (class 0 OID 0)
-- Dependencies: 224
-- Name: associado_id_associado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.associado_id_associado_seq OWNED BY public.associado.id_associado;


--
-- TOC entry 225 (class 1259 OID 16442)
-- Name: categoria; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.categoria OWNER TO ambc_db_user;

--
-- TOC entry 226 (class 1259 OID 16447)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_id_categoria_seq OWNER TO ambc_db_user;

--
-- TOC entry 4052 (class 0 OID 0)
-- Dependencies: 226
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.categoria_id_categoria_seq OWNED BY public.categoria.id_categoria;


--
-- TOC entry 292 (class 1259 OID 17687)
-- Name: configuracao_sistema; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.configuracao_sistema (
    chave character varying(60) NOT NULL,
    valor text NOT NULL,
    atualizado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.configuracao_sistema OWNER TO ambc_db_user;

--
-- TOC entry 293 (class 1259 OID 17706)
-- Name: configuracoes; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.configuracoes (
    chave character varying(100) NOT NULL,
    valor text,
    atualizado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.configuracoes OWNER TO ambc_db_user;

--
-- TOC entry 227 (class 1259 OID 16462)
-- Name: conta_regente; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.conta_regente (
    id_conta_regente integer NOT NULL,
    descricao character varying(100) NOT NULL,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    tipo character varying(10) DEFAULT 'receita'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT conta_regente_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['receita'::character varying, 'despesa'::character varying])::text[])))
);


ALTER TABLE public.conta_regente OWNER TO ambc_db_user;

--
-- TOC entry 228 (class 1259 OID 16471)
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.conta_regente_id_conta_regente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_regente_id_conta_regente_seq OWNER TO ambc_db_user;

--
-- TOC entry 4053 (class 0 OID 0)
-- Dependencies: 228
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.conta_regente_id_conta_regente_seq OWNED BY public.conta_regente.id_conta_regente;


--
-- TOC entry 229 (class 1259 OID 16472)
-- Name: conta_subordinada; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.conta_subordinada (
    id_conta_subordinada integer NOT NULL,
    fk_conta_regente integer NOT NULL,
    descricao character varying(100) NOT NULL,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    ativo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.conta_subordinada OWNER TO ambc_db_user;

--
-- TOC entry 230 (class 1259 OID 16482)
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.conta_subordinada_id_conta_subordinada_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_subordinada_id_conta_subordinada_seq OWNER TO ambc_db_user;

--
-- TOC entry 4054 (class 0 OID 0)
-- Dependencies: 230
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.conta_subordinada_id_conta_subordinada_seq OWNED BY public.conta_subordinada.id_conta_subordinada;


--
-- TOC entry 231 (class 1259 OID 16483)
-- Name: dependente; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.dependente (
    id_dependente integer NOT NULL,
    fk_associado integer,
    nome character varying(150) NOT NULL,
    data_nascimento date NOT NULL,
    cpf character(11),
    observacao text,
    fk_parentesco integer,
    fk_genero integer,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now(),
    ativo boolean DEFAULT true,
    CONSTRAINT chk_dependente_nome_composto CHECK ((TRIM(BOTH FROM nome) ~~ '% %'::text))
);


ALTER TABLE public.dependente OWNER TO ambc_db_user;

--
-- TOC entry 232 (class 1259 OID 16495)
-- Name: dependente_id_dependente_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.dependente_id_dependente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dependente_id_dependente_seq OWNER TO ambc_db_user;

--
-- TOC entry 4055 (class 0 OID 0)
-- Dependencies: 232
-- Name: dependente_id_dependente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.dependente_id_dependente_seq OWNED BY public.dependente.id_dependente;


--
-- TOC entry 233 (class 1259 OID 16496)
-- Name: doacao; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.doacao OWNER TO ambc_db_user;

--
-- TOC entry 234 (class 1259 OID 16508)
-- Name: doacao_id_doacao_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.doacao_id_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doacao_id_doacao_seq OWNER TO ambc_db_user;

--
-- TOC entry 4056 (class 0 OID 0)
-- Dependencies: 234
-- Name: doacao_id_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.doacao_id_doacao_seq OWNED BY public.doacao.id_doacao;


--
-- TOC entry 235 (class 1259 OID 16509)
-- Name: documento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.documento (
    id_documento integer NOT NULL,
    numero integer,
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
    categoria character varying(20) DEFAULT 'operacional'::character varying NOT NULL,
    versao character varying(20),
    CONSTRAINT chk_documento_tipo CHECK ((((fk_tipo_documento IS NOT NULL) AND (tipo_livre IS NULL)) OR ((fk_tipo_documento IS NULL) AND (tipo_livre IS NOT NULL)))),
    CONSTRAINT documento_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['operacional'::character varying, 'institucional'::character varying])::text[])))
);


ALTER TABLE public.documento OWNER TO ambc_db_user;

--
-- TOC entry 236 (class 1259 OID 16525)
-- Name: documento_id_documento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.documento_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documento_id_documento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4057 (class 0 OID 0)
-- Dependencies: 236
-- Name: documento_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.documento_id_documento_seq OWNED BY public.documento.id_documento;


--
-- TOC entry 237 (class 1259 OID 16526)
-- Name: espaco; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.espaco OWNER TO ambc_db_user;

--
-- TOC entry 238 (class 1259 OID 16536)
-- Name: espaco_id_espaco_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.espaco_id_espaco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.espaco_id_espaco_seq OWNER TO ambc_db_user;

--
-- TOC entry 4058 (class 0 OID 0)
-- Dependencies: 238
-- Name: espaco_id_espaco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.espaco_id_espaco_seq OWNED BY public.espaco.id_espaco;


--
-- TOC entry 239 (class 1259 OID 16537)
-- Name: estado_civil; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.estado_civil (
    id_estadocivil integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.estado_civil OWNER TO ambc_db_user;

--
-- TOC entry 240 (class 1259 OID 16542)
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.estado_civil_id_estadocivil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estado_civil_id_estadocivil_seq OWNER TO ambc_db_user;

--
-- TOC entry 4059 (class 0 OID 0)
-- Dependencies: 240
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.estado_civil_id_estadocivil_seq OWNED BY public.estado_civil.id_estadocivil;


--
-- TOC entry 241 (class 1259 OID 16543)
-- Name: forma_pagamento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.forma_pagamento (
    id_forma_pagamento integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.forma_pagamento OWNER TO ambc_db_user;

--
-- TOC entry 242 (class 1259 OID 16548)
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.forma_pagamento_id_forma_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4060 (class 0 OID 0)
-- Dependencies: 242
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNED BY public.forma_pagamento.id_forma_pagamento;


--
-- TOC entry 243 (class 1259 OID 16549)
-- Name: genero; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.genero (
    id_genero integer NOT NULL,
    descricao character varying(30) NOT NULL
);


ALTER TABLE public.genero OWNER TO ambc_db_user;

--
-- TOC entry 244 (class 1259 OID 16554)
-- Name: genero_id_genero_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.genero_id_genero_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genero_id_genero_seq OWNER TO ambc_db_user;

--
-- TOC entry 4061 (class 0 OID 0)
-- Dependencies: 244
-- Name: genero_id_genero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.genero_id_genero_seq OWNED BY public.genero.id_genero;


--
-- TOC entry 245 (class 1259 OID 16555)
-- Name: horario_espaco; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.horario_espaco (
    id_horario_espaco integer NOT NULL,
    fk_espaco integer NOT NULL,
    dia_semana character varying(15) NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    observacao text
);


ALTER TABLE public.horario_espaco OWNER TO ambc_db_user;

--
-- TOC entry 246 (class 1259 OID 16565)
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.horario_espaco_id_horario_espaco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horario_espaco_id_horario_espaco_seq OWNER TO ambc_db_user;

--
-- TOC entry 4062 (class 0 OID 0)
-- Dependencies: 246
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.horario_espaco_id_horario_espaco_seq OWNED BY public.horario_espaco.id_horario_espaco;


--
-- TOC entry 247 (class 1259 OID 16566)
-- Name: item_doacao; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.item_doacao OWNER TO ambc_db_user;

--
-- TOC entry 248 (class 1259 OID 16576)
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.item_doacao_id_item_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_doacao_id_item_doacao_seq OWNER TO ambc_db_user;

--
-- TOC entry 4063 (class 0 OID 0)
-- Dependencies: 248
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.item_doacao_id_item_doacao_seq OWNED BY public.item_doacao.id_item_doacao;


--
-- TOC entry 290 (class 1259 OID 17590)
-- Name: lancamento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.lancamento (
    id_lancamento integer NOT NULL,
    fk_associado integer,
    fk_conta_regente integer,
    fk_conta_subordinada integer,
    fk_tipo_lancamento integer,
    fk_forma_pagamento integer,
    fk_status_conta integer DEFAULT 1 NOT NULL,
    descricao character varying(200) NOT NULL,
    valor numeric(10,2) NOT NULL,
    valor_pago numeric(10,2),
    data_lancamento date DEFAULT CURRENT_DATE NOT NULL,
    data_vencimento date,
    data_pagamento date,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    fk_parceiro integer,
    fk_parcelamento integer,
    numero_parcela integer,
    total_parcelas integer,
    CONSTRAINT chk_lancamento_pagamento CHECK ((((data_pagamento IS NULL) AND (valor_pago IS NULL)) OR ((data_pagamento IS NOT NULL) AND (valor_pago IS NOT NULL)))),
    CONSTRAINT chk_lancamento_valor CHECK ((valor > (0)::numeric)),
    CONSTRAINT chk_lancamento_valor_pago CHECK (((valor_pago IS NULL) OR (valor_pago >= (0)::numeric)))
);


ALTER TABLE public.lancamento OWNER TO ambc_db_user;

--
-- TOC entry 289 (class 1259 OID 17589)
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.lancamento_id_lancamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lancamento_id_lancamento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4064 (class 0 OID 0)
-- Dependencies: 289
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.lancamento_id_lancamento_seq OWNED BY public.lancamento.id_lancamento;


--
-- TOC entry 249 (class 1259 OID 16577)
-- Name: log_acesso; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.log_acesso (
    id_log integer NOT NULL,
    fk_usuario integer NOT NULL,
    tipo character varying(10) NOT NULL,
    ip character varying(45),
    registrado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.log_acesso OWNER TO ambc_db_user;

--
-- TOC entry 250 (class 1259 OID 16584)
-- Name: log_acesso_id_log_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.log_acesso_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_acesso_id_log_seq OWNER TO ambc_db_user;

--
-- TOC entry 4065 (class 0 OID 0)
-- Dependencies: 250
-- Name: log_acesso_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.log_acesso_id_log_seq OWNED BY public.log_acesso.id_log;


--
-- TOC entry 251 (class 1259 OID 16585)
-- Name: modulo_sistema; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.modulo_sistema (
    id_modulo integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.modulo_sistema OWNER TO ambc_db_user;

--
-- TOC entry 252 (class 1259 OID 16590)
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.modulo_sistema_id_modulo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modulo_sistema_id_modulo_seq OWNER TO ambc_db_user;

--
-- TOC entry 4066 (class 0 OID 0)
-- Dependencies: 252
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.modulo_sistema_id_modulo_seq OWNED BY public.modulo_sistema.id_modulo;


--
-- TOC entry 253 (class 1259 OID 16591)
-- Name: parceiro; Type: TABLE; Schema: public; Owner: ambc_db_user
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
    tipo_servico character varying(100),
    tipo_pessoa character(2) DEFAULT 'PF'::bpchar,
    CONSTRAINT chk_parceiro_nome_composto CHECK ((TRIM(BOTH FROM nome_razao_social) ~~ '% %'::text)),
    CONSTRAINT chk_parceiro_tipo_pessoa CHECK ((tipo_pessoa = ANY (ARRAY['PF'::bpchar, 'PJ'::bpchar])))
);


ALTER TABLE public.parceiro OWNER TO ambc_db_user;

--
-- TOC entry 254 (class 1259 OID 16603)
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.parceiro_id_parceiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parceiro_id_parceiro_seq OWNER TO ambc_db_user;

--
-- TOC entry 4067 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.parceiro_id_parceiro_seq OWNED BY public.parceiro.id_parceiro;


--
-- TOC entry 297 (class 1259 OID 17759)
-- Name: parcelamento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.parcelamento (
    id_parcelamento integer NOT NULL,
    fk_associado integer,
    descricao character varying(255) NOT NULL,
    quantidade_parcelas integer NOT NULL,
    valor_total numeric(10,2) NOT NULL,
    valor_parcela numeric(10,2) NOT NULL,
    data_primeiro_vencimento date NOT NULL,
    criado_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.parcelamento OWNER TO ambc_db_user;

--
-- TOC entry 296 (class 1259 OID 17758)
-- Name: parcelamento_id_parcelamento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.parcelamento_id_parcelamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parcelamento_id_parcelamento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4068 (class 0 OID 0)
-- Dependencies: 296
-- Name: parcelamento_id_parcelamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.parcelamento_id_parcelamento_seq OWNED BY public.parcelamento.id_parcelamento;


--
-- TOC entry 255 (class 1259 OID 16619)
-- Name: parentesco; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.parentesco (
    id_parentesco integer NOT NULL,
    descricao character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE public.parentesco OWNER TO ambc_db_user;

--
-- TOC entry 256 (class 1259 OID 16626)
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.parentesco_id_parentesco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parentesco_id_parentesco_seq OWNER TO ambc_db_user;

--
-- TOC entry 4069 (class 0 OID 0)
-- Dependencies: 256
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.parentesco_id_parentesco_seq OWNED BY public.parentesco.id_parentesco;


--
-- TOC entry 257 (class 1259 OID 16627)
-- Name: perfil_usuario; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.perfil_usuario (
    id_perfil integer NOT NULL,
    descricao character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE public.perfil_usuario OWNER TO ambc_db_user;

--
-- TOC entry 258 (class 1259 OID 16634)
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.perfil_usuario_id_perfil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.perfil_usuario_id_perfil_seq OWNER TO ambc_db_user;

--
-- TOC entry 4070 (class 0 OID 0)
-- Dependencies: 258
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.perfil_usuario_id_perfil_seq OWNED BY public.perfil_usuario.id_perfil;


--
-- TOC entry 259 (class 1259 OID 16635)
-- Name: permissao_usuario; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.permissao_usuario (
    id_permissao integer NOT NULL,
    fk_usuario integer NOT NULL,
    fk_modulo integer NOT NULL,
    pode_acessar boolean DEFAULT false,
    pode_editar boolean DEFAULT false
);


ALTER TABLE public.permissao_usuario OWNER TO ambc_db_user;

--
-- TOC entry 260 (class 1259 OID 16643)
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.permissao_usuario_id_permissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissao_usuario_id_permissao_seq OWNER TO ambc_db_user;

--
-- TOC entry 4071 (class 0 OID 0)
-- Dependencies: 260
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.permissao_usuario_id_permissao_seq OWNED BY public.permissao_usuario.id_permissao;


--
-- TOC entry 295 (class 1259 OID 17737)
-- Name: plano_associacao; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.plano_associacao (
    id_plano integer NOT NULL,
    nome character varying(100) NOT NULL,
    preco numeric(10,2) DEFAULT 0 NOT NULL,
    periodo character varying(20) DEFAULT 'anuidade'::character varying NOT NULL,
    beneficios jsonb DEFAULT '[]'::jsonb NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.plano_associacao OWNER TO ambc_db_user;

--
-- TOC entry 294 (class 1259 OID 17736)
-- Name: plano_associacao_id_plano_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.plano_associacao_id_plano_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.plano_associacao_id_plano_seq OWNER TO ambc_db_user;

--
-- TOC entry 4072 (class 0 OID 0)
-- Dependencies: 294
-- Name: plano_associacao_id_plano_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.plano_associacao_id_plano_seq OWNED BY public.plano_associacao.id_plano;


--
-- TOC entry 261 (class 1259 OID 16644)
-- Name: profissao; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.profissao (
    id_profissao integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.profissao OWNER TO ambc_db_user;

--
-- TOC entry 262 (class 1259 OID 16649)
-- Name: profissao_id_profissao_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.profissao_id_profissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissao_id_profissao_seq OWNER TO ambc_db_user;

--
-- TOC entry 4073 (class 0 OID 0)
-- Dependencies: 262
-- Name: profissao_id_profissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.profissao_id_profissao_seq OWNED BY public.profissao.id_profissao;


--
-- TOC entry 299 (class 1259 OID 17787)
-- Name: relacionamento_lancamento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.relacionamento_lancamento (
    id_relacionamento integer NOT NULL,
    fk_tipo_lancamento integer NOT NULL,
    fk_conta_regente integer NOT NULL,
    fk_conta_subordinada integer NOT NULL,
    natureza character varying(20) NOT NULL,
    modo character varying(20) NOT NULL,
    ativo boolean DEFAULT true,
    observacao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por integer,
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por integer,
    CONSTRAINT relacionamento_lancamento_modo_check CHECK (((modo)::text = ANY ((ARRAY['FIXO'::character varying, 'SUGERIDO'::character varying])::text[]))),
    CONSTRAINT relacionamento_lancamento_natureza_check CHECK (((natureza)::text = ANY ((ARRAY['RECEBER'::character varying, 'PAGAR'::character varying])::text[])))
);


ALTER TABLE public.relacionamento_lancamento OWNER TO ambc_db_user;

--
-- TOC entry 298 (class 1259 OID 17786)
-- Name: relacionamento_lancamento_id_relacionamento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.relacionamento_lancamento_id_relacionamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.relacionamento_lancamento_id_relacionamento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4074 (class 0 OID 0)
-- Dependencies: 298
-- Name: relacionamento_lancamento_id_relacionamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.relacionamento_lancamento_id_relacionamento_seq OWNED BY public.relacionamento_lancamento.id_relacionamento;


--
-- TOC entry 263 (class 1259 OID 16650)
-- Name: reserva_espaco; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.reserva_espaco OWNER TO ambc_db_user;

--
-- TOC entry 264 (class 1259 OID 16664)
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.reserva_espaco_id_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reserva_espaco_id_reserva_seq OWNER TO ambc_db_user;

--
-- TOC entry 4075 (class 0 OID 0)
-- Dependencies: 264
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.reserva_espaco_id_reserva_seq OWNED BY public.reserva_espaco.id_reserva;


--
-- TOC entry 284 (class 1259 OID 17544)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.schema_migrations (
    versao character varying(80) NOT NULL,
    aplicada_em timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO ambc_db_user;

--
-- TOC entry 265 (class 1259 OID 16665)
-- Name: status_agenda; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.status_agenda (
    id_status_agenda integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_agenda OWNER TO ambc_db_user;

--
-- TOC entry 266 (class 1259 OID 16670)
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.status_agenda_id_status_agenda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_agenda_id_status_agenda_seq OWNER TO ambc_db_user;

--
-- TOC entry 4076 (class 0 OID 0)
-- Dependencies: 266
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.status_agenda_id_status_agenda_seq OWNED BY public.status_agenda.id_status_agenda;


--
-- TOC entry 267 (class 1259 OID 16671)
-- Name: status_conta; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.status_conta (
    id_status_conta integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_conta OWNER TO ambc_db_user;

--
-- TOC entry 268 (class 1259 OID 16676)
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.status_conta_id_status_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_conta_id_status_conta_seq OWNER TO ambc_db_user;

--
-- TOC entry 4077 (class 0 OID 0)
-- Dependencies: 268
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.status_conta_id_status_conta_seq OWNED BY public.status_conta.id_status_conta;


--
-- TOC entry 269 (class 1259 OID 16677)
-- Name: status_pessoa; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.status_pessoa (
    id_status integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_pessoa OWNER TO ambc_db_user;

--
-- TOC entry 270 (class 1259 OID 16682)
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.status_pessoa_id_status_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_pessoa_id_status_seq OWNER TO ambc_db_user;

--
-- TOC entry 4078 (class 0 OID 0)
-- Dependencies: 270
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.status_pessoa_id_status_seq OWNED BY public.status_pessoa.id_status;


--
-- TOC entry 271 (class 1259 OID 16683)
-- Name: status_reserva; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.status_reserva (
    id_status_reserva integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.status_reserva OWNER TO ambc_db_user;

--
-- TOC entry 272 (class 1259 OID 16688)
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.status_reserva_id_status_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_reserva_id_status_reserva_seq OWNER TO ambc_db_user;

--
-- TOC entry 4079 (class 0 OID 0)
-- Dependencies: 272
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.status_reserva_id_status_reserva_seq OWNED BY public.status_reserva.id_status_reserva;


--
-- TOC entry 273 (class 1259 OID 16689)
-- Name: telefone; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.telefone (
    id_telefone integer NOT NULL,
    fk_associado integer NOT NULL,
    ddd character(2) NOT NULL,
    numero character varying(9) NOT NULL,
    fk_tipo_telefone integer,
    observacao character varying(100),
    CONSTRAINT chk_telefone_ddd CHECK ((ddd ~ '^[0-9]+$'::text)),
    CONSTRAINT chk_telefone_numero CHECK (((numero)::text ~ '^[0-9]+$'::text))
);


ALTER TABLE public.telefone OWNER TO ambc_db_user;

--
-- TOC entry 274 (class 1259 OID 16698)
-- Name: telefone_id_telefone_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.telefone_id_telefone_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telefone_id_telefone_seq OWNER TO ambc_db_user;

--
-- TOC entry 4080 (class 0 OID 0)
-- Dependencies: 274
-- Name: telefone_id_telefone_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.telefone_id_telefone_seq OWNED BY public.telefone.id_telefone;


--
-- TOC entry 275 (class 1259 OID 16699)
-- Name: telefone_parceiro; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.telefone_parceiro (
    id_telefone_parceiro integer NOT NULL,
    fk_parceiro integer NOT NULL,
    ddd character(2) NOT NULL,
    numero character varying(9) NOT NULL,
    fk_tipo_telefone integer,
    observacao character varying(100),
    CONSTRAINT chk_tel_parceiro_ddd CHECK ((ddd ~ '^[0-9]+$'::text)),
    CONSTRAINT chk_tel_parceiro_numero CHECK (((numero)::text ~ '^[0-9]+$'::text))
);


ALTER TABLE public.telefone_parceiro OWNER TO ambc_db_user;

--
-- TOC entry 276 (class 1259 OID 16708)
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq OWNER TO ambc_db_user;

--
-- TOC entry 4081 (class 0 OID 0)
-- Dependencies: 276
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.telefone_parceiro_id_telefone_parceiro_seq OWNED BY public.telefone_parceiro.id_telefone_parceiro;


--
-- TOC entry 277 (class 1259 OID 16709)
-- Name: tipo_doacao; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.tipo_doacao (
    id_tipo_doacao integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.tipo_doacao OWNER TO ambc_db_user;

--
-- TOC entry 278 (class 1259 OID 16714)
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.tipo_doacao_id_tipo_doacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_doacao_id_tipo_doacao_seq OWNER TO ambc_db_user;

--
-- TOC entry 4082 (class 0 OID 0)
-- Dependencies: 278
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.tipo_doacao_id_tipo_doacao_seq OWNED BY public.tipo_doacao.id_tipo_doacao;


--
-- TOC entry 279 (class 1259 OID 16715)
-- Name: tipo_documento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.tipo_documento (
    id_tipo_documento integer NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.tipo_documento OWNER TO ambc_db_user;

--
-- TOC entry 280 (class 1259 OID 16720)
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.tipo_documento_id_tipo_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4083 (class 0 OID 0)
-- Dependencies: 280
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNED BY public.tipo_documento.id_tipo_documento;


--
-- TOC entry 288 (class 1259 OID 17576)
-- Name: tipo_lancamento; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.tipo_lancamento (
    id_tipo_lancamento integer NOT NULL,
    descricao character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE public.tipo_lancamento OWNER TO ambc_db_user;

--
-- TOC entry 287 (class 1259 OID 17575)
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.tipo_lancamento_id_tipo_lancamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_lancamento_id_tipo_lancamento_seq OWNER TO ambc_db_user;

--
-- TOC entry 4084 (class 0 OID 0)
-- Dependencies: 287
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.tipo_lancamento_id_tipo_lancamento_seq OWNED BY public.tipo_lancamento.id_tipo_lancamento;


--
-- TOC entry 286 (class 1259 OID 17553)
-- Name: tipo_telefone; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.tipo_telefone (
    id_tipo_telefone integer NOT NULL,
    descricao character varying(20) NOT NULL
);


ALTER TABLE public.tipo_telefone OWNER TO ambc_db_user;

--
-- TOC entry 285 (class 1259 OID 17552)
-- Name: tipo_telefone_id_tipo_telefone_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.tipo_telefone_id_tipo_telefone_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_telefone_id_tipo_telefone_seq OWNER TO ambc_db_user;

--
-- TOC entry 4085 (class 0 OID 0)
-- Dependencies: 285
-- Name: tipo_telefone_id_tipo_telefone_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.tipo_telefone_id_tipo_telefone_seq OWNED BY public.tipo_telefone.id_tipo_telefone;


--
-- TOC entry 281 (class 1259 OID 16721)
-- Name: uf; Type: TABLE; Schema: public; Owner: ambc_db_user
--

CREATE TABLE public.uf (
    sigla character(2) NOT NULL,
    nome character varying(30) NOT NULL
);


ALTER TABLE public.uf OWNER TO ambc_db_user;

--
-- TOC entry 282 (class 1259 OID 16726)
-- Name: usuario; Type: TABLE; Schema: public; Owner: ambc_db_user
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


ALTER TABLE public.usuario OWNER TO ambc_db_user;

--
-- TOC entry 283 (class 1259 OID 16739)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: ambc_db_user
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO ambc_db_user;

--
-- TOC entry 4086 (class 0 OID 0)
-- Dependencies: 283
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 3440 (class 2604 OID 16740)
-- Name: agenda id_agenda; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda ALTER COLUMN id_agenda SET DEFAULT nextval('public.agenda_id_agenda_seq'::regclass);


--
-- TOC entry 3445 (class 2604 OID 16741)
-- Name: agenda_documento id; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento ALTER COLUMN id SET DEFAULT nextval('public.agenda_documento_id_seq'::regclass);


--
-- TOC entry 3447 (class 2604 OID 16742)
-- Name: associado id_associado; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado ALTER COLUMN id_associado SET DEFAULT nextval('public.associado_id_associado_seq'::regclass);


--
-- TOC entry 3451 (class 2604 OID 16743)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 3452 (class 2604 OID 16745)
-- Name: conta_regente id_conta_regente; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente ALTER COLUMN id_conta_regente SET DEFAULT nextval('public.conta_regente_id_conta_regente_seq'::regclass);


--
-- TOC entry 3457 (class 2604 OID 16746)
-- Name: conta_subordinada id_conta_subordinada; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada ALTER COLUMN id_conta_subordinada SET DEFAULT nextval('public.conta_subordinada_id_conta_subordinada_seq'::regclass);


--
-- TOC entry 3461 (class 2604 OID 16747)
-- Name: dependente id_dependente; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente ALTER COLUMN id_dependente SET DEFAULT nextval('public.dependente_id_dependente_seq'::regclass);


--
-- TOC entry 3465 (class 2604 OID 16748)
-- Name: doacao id_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao ALTER COLUMN id_doacao SET DEFAULT nextval('public.doacao_id_doacao_seq'::regclass);


--
-- TOC entry 3469 (class 2604 OID 16749)
-- Name: documento id_documento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento ALTER COLUMN id_documento SET DEFAULT nextval('public.documento_id_documento_seq'::regclass);


--
-- TOC entry 3476 (class 2604 OID 16750)
-- Name: espaco id_espaco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco ALTER COLUMN id_espaco SET DEFAULT nextval('public.espaco_id_espaco_seq'::regclass);


--
-- TOC entry 3480 (class 2604 OID 16751)
-- Name: estado_civil id_estadocivil; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil ALTER COLUMN id_estadocivil SET DEFAULT nextval('public.estado_civil_id_estadocivil_seq'::regclass);


--
-- TOC entry 3481 (class 2604 OID 16752)
-- Name: forma_pagamento id_forma_pagamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento ALTER COLUMN id_forma_pagamento SET DEFAULT nextval('public.forma_pagamento_id_forma_pagamento_seq'::regclass);


--
-- TOC entry 3482 (class 2604 OID 16753)
-- Name: genero id_genero; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero ALTER COLUMN id_genero SET DEFAULT nextval('public.genero_id_genero_seq'::regclass);


--
-- TOC entry 3483 (class 2604 OID 16754)
-- Name: horario_espaco id_horario_espaco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco ALTER COLUMN id_horario_espaco SET DEFAULT nextval('public.horario_espaco_id_horario_espaco_seq'::regclass);


--
-- TOC entry 3484 (class 2604 OID 16755)
-- Name: item_doacao id_item_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao ALTER COLUMN id_item_doacao SET DEFAULT nextval('public.item_doacao_id_item_doacao_seq'::regclass);


--
-- TOC entry 3520 (class 2604 OID 17593)
-- Name: lancamento id_lancamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento ALTER COLUMN id_lancamento SET DEFAULT nextval('public.lancamento_id_lancamento_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 16756)
-- Name: log_acesso id_log; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso ALTER COLUMN id_log SET DEFAULT nextval('public.log_acesso_id_log_seq'::regclass);


--
-- TOC entry 3488 (class 2604 OID 16757)
-- Name: modulo_sistema id_modulo; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema ALTER COLUMN id_modulo SET DEFAULT nextval('public.modulo_sistema_id_modulo_seq'::regclass);


--
-- TOC entry 3489 (class 2604 OID 16758)
-- Name: parceiro id_parceiro; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro ALTER COLUMN id_parceiro SET DEFAULT nextval('public.parceiro_id_parceiro_seq'::regclass);


--
-- TOC entry 3537 (class 2604 OID 17762)
-- Name: parcelamento id_parcelamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parcelamento ALTER COLUMN id_parcelamento SET DEFAULT nextval('public.parcelamento_id_parcelamento_seq'::regclass);


--
-- TOC entry 3494 (class 2604 OID 16760)
-- Name: parentesco id_parentesco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco ALTER COLUMN id_parentesco SET DEFAULT nextval('public.parentesco_id_parentesco_seq'::regclass);


--
-- TOC entry 3495 (class 2604 OID 16761)
-- Name: perfil_usuario id_perfil; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario ALTER COLUMN id_perfil SET DEFAULT nextval('public.perfil_usuario_id_perfil_seq'::regclass);


--
-- TOC entry 3496 (class 2604 OID 16762)
-- Name: permissao_usuario id_permissao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario ALTER COLUMN id_permissao SET DEFAULT nextval('public.permissao_usuario_id_permissao_seq'::regclass);


--
-- TOC entry 3530 (class 2604 OID 17740)
-- Name: plano_associacao id_plano; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.plano_associacao ALTER COLUMN id_plano SET DEFAULT nextval('public.plano_associacao_id_plano_seq'::regclass);


--
-- TOC entry 3499 (class 2604 OID 16763)
-- Name: profissao id_profissao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao ALTER COLUMN id_profissao SET DEFAULT nextval('public.profissao_id_profissao_seq'::regclass);


--
-- TOC entry 3539 (class 2604 OID 17790)
-- Name: relacionamento_lancamento id_relacionamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.relacionamento_lancamento ALTER COLUMN id_relacionamento SET DEFAULT nextval('public.relacionamento_lancamento_id_relacionamento_seq'::regclass);


--
-- TOC entry 3500 (class 2604 OID 16764)
-- Name: reserva_espaco id_reserva; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_espaco_id_reserva_seq'::regclass);


--
-- TOC entry 3504 (class 2604 OID 16765)
-- Name: status_agenda id_status_agenda; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda ALTER COLUMN id_status_agenda SET DEFAULT nextval('public.status_agenda_id_status_agenda_seq'::regclass);


--
-- TOC entry 3505 (class 2604 OID 16766)
-- Name: status_conta id_status_conta; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta ALTER COLUMN id_status_conta SET DEFAULT nextval('public.status_conta_id_status_conta_seq'::regclass);


--
-- TOC entry 3506 (class 2604 OID 16767)
-- Name: status_pessoa id_status; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa ALTER COLUMN id_status SET DEFAULT nextval('public.status_pessoa_id_status_seq'::regclass);


--
-- TOC entry 3507 (class 2604 OID 16768)
-- Name: status_reserva id_status_reserva; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva ALTER COLUMN id_status_reserva SET DEFAULT nextval('public.status_reserva_id_status_reserva_seq'::regclass);


--
-- TOC entry 3508 (class 2604 OID 16769)
-- Name: telefone id_telefone; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone ALTER COLUMN id_telefone SET DEFAULT nextval('public.telefone_id_telefone_seq'::regclass);


--
-- TOC entry 3509 (class 2604 OID 16770)
-- Name: telefone_parceiro id_telefone_parceiro; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro ALTER COLUMN id_telefone_parceiro SET DEFAULT nextval('public.telefone_parceiro_id_telefone_parceiro_seq'::regclass);


--
-- TOC entry 3510 (class 2604 OID 16771)
-- Name: tipo_doacao id_tipo_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao ALTER COLUMN id_tipo_doacao SET DEFAULT nextval('public.tipo_doacao_id_tipo_doacao_seq'::regclass);


--
-- TOC entry 3511 (class 2604 OID 16772)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('public.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 3519 (class 2604 OID 17579)
-- Name: tipo_lancamento id_tipo_lancamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento ALTER COLUMN id_tipo_lancamento SET DEFAULT nextval('public.tipo_lancamento_id_tipo_lancamento_seq'::regclass);


--
-- TOC entry 3518 (class 2604 OID 17556)
-- Name: tipo_telefone id_tipo_telefone; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone ALTER COLUMN id_tipo_telefone SET DEFAULT nextval('public.tipo_telefone_id_tipo_telefone_seq'::regclass);


--
-- TOC entry 3512 (class 2604 OID 16773)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 3963 (class 0 OID 16404)
-- Dependencies: 219
-- Data for Name: agenda; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.agenda (id_agenda, titulo, descricao, observacao, data_inicio, hora_inicio, data_fim, hora_fim, fk_espaco, fk_status_agenda, fk_associado, fk_parceiro, responsavel_nome, responsavel_telefone, responsavel_email, capacidade_maxima, total_participantes, valor_cobrado, valor_aluguel, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3964 (class 0 OID 16420)
-- Dependencies: 220
-- Data for Name: agenda_documento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.agenda_documento (id, fk_agenda, fk_documento, criado_em) FROM stdin;
\.


--
-- TOC entry 3967 (class 0 OID 16429)
-- Dependencies: 223
-- Data for Name: associado; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.associado (id_associado, nome, data_nascimento, cpf_cnpj, email, observacao, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, fk_estadocivil, fk_profissao, fk_categoria, fk_status, fk_genero, criado_em, criado_por, atualizado_em, atualizado_por, matricula, data_entrada) FROM stdin;
4	Maria Aparecida Lima	1972-07-25	22233344455	maria.lima@email.com	\N	t	Av. Bento Gonçalves	456	\N	91500000	Califórnia	Porto Alegre	RS	1	8	1	1	1	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
7	Roberto Carlos Mendes	1965-01-19	55566677788	roberto.mendes@email.com	\N	t	Av. Sertório	654	Bloco B	91060000	Califórnia	Porto Alegre	RS	2	7	2	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
9	Teste Backend 2	1987-11-30	88888888888	teste@teste.com	teste	t	Rua Teste	1		92000000	Bairro	Canoas	RS	2	5	\N	1	\N	2026-05-06 00:00:00	\N	2026-05-07 02:06:20.805445	\N	0001	\N
5	João Pedro Ferreira	1990-11-08	33344455566	joao.ferreira@email.com	\N	t	Rua Pinheiro Machado	789	Casa 2	91040000	Califórnia	Porto Alegre	RS	3	1	3	1	2	2026-04-23 22:04:24.009645	\N	2026-05-25 23:34:07.925987	\N	\N	\N
24	Leonardo Leote	1992-09-09	35095512015	leonardo.leote0909@gmail.com	\N	t	\N	381	\N	92480000	\N	Nova Santa Rita	RS	2	13	3	1	3	2026-05-27 22:32:37	\N	2026-05-27 22:32:37.883269	\N	0002	2026-05-27
29	Leonardo Leote	1990-09-09	01324852015	leonardo.leote0909@gmail.com	\N	t	\N	381	\N	92480000	\N	Nova Santa Rita	RS	2	13	3	1	3	2026-05-27 23:21:05	\N	2026-05-27 23:21:05.911159	\N	0003	2026-05-27
31	Leonardo Leote	1992-09-09	02522182015	leonardo.leote0909@gmail.com	\N	t	\N	381	\N	92480000	\N	Nova Santa Rita	RS	2	13	3	1	1	2026-05-27 23:21:52	\N	2026-05-27 23:21:52.713731	\N	0004	2026-05-27
32	Leonardo Leote	1993-09-09	26512345685	leonardo.leote0909@gmail.com	\N	t	Rua Barão do Rio Branco	381	\N	92480000	Califórnia	Nova Santa Rita	RS	3	12	3	1	1	2026-05-27 23:22:34	\N	2026-05-27 23:22:34.277976	\N	0005	2026-05-27
34	Maria da Silva	1950-05-22	12345678920	mariadasilva@gmail.com	\N	t	R. São João Batista	108	casa	92480000	Califórnia	Nova Santa Rita	RS	2	8	3	1	1	2026-05-27 23:26:06	\N	2026-05-27 23:26:06.435707	\N	0006	2026-05-27
35	rosa ribeiro	1990-12-20	12121212121	rosa@gmail.com	\N	t	Rua Garibaldi	321	casa	92480000	Califórnia	Nova Santa Rita	RS	2	1	3	1	1	2026-05-27 23:36:38	\N	2026-05-27 23:36:38.845481	\N	0007	2026-05-27
\.


--
-- TOC entry 4035 (class 0 OID 17658)
-- Dependencies: 291
-- Data for Name: associado_dependente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.associado_dependente (fk_associado, fk_dependente, principal, criado_em, atualizado_em) FROM stdin;
\.


--
-- TOC entry 3969 (class 0 OID 16442)
-- Dependencies: 225
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.categoria (id_categoria, descricao) FROM stdin;
1	Fundador
2	Honorário
3	Contribuinte
\.


--
-- TOC entry 4036 (class 0 OID 17687)
-- Dependencies: 292
-- Data for Name: configuracao_sistema; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.configuracao_sistema (chave, valor, atualizado_em) FROM stdin;
idioma	pt-BR	2026-05-11 12:52:00.406057
fuso_horario	America/Sao_Paulo	2026-05-11 12:52:00.578417
formato_data	DD/MM/YYYY	2026-05-11 12:52:00.805427
moeda	BRL	2026-05-11 12:52:01.006669
notif_vencimentos	true	2026-05-11 12:52:01.204141
notif_inadimplencia	true	2026-05-11 12:52:01.404964
notif_resumo_semanal	false	2026-05-11 12:52:01.573943
notif_novos_cadastros	true	2026-05-11 12:52:01.744022
seg_2fa	false	2026-05-11 12:52:01.912994
seg_expirar_sessao	true	2026-05-11 12:52:02.082723
dias_alerta_vencimento	5	2026-05-11 12:52:02.252946
\.


--
-- TOC entry 4037 (class 0 OID 17706)
-- Dependencies: 293
-- Data for Name: configuracoes; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.configuracoes (chave, valor, atualizado_em) FROM stdin;
logo	data:image/png;base64,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	2026-05-19 22:10:41.62411
logo_historico	["data:image/webp;base64,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","data:image/png;base64,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"]	2026-05-19 22:10:41.62411
favicon	data:image/png;base64,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	2026-05-19 22:10:41.62411
notif_vencimentos	false	2026-05-19 22:10:41.62411
notif_inadimplencia	false	2026-05-19 22:10:41.62411
notif_resumo_semanal	false	2026-05-19 22:10:41.62411
notif_novos_cadastros	false	2026-05-19 22:10:41.62411
seg_expirar_sessao	true	2026-05-19 22:10:41.62411
dias_alerta_vencimento	5	2026-05-19 22:10:41.62411
assoc_nome	Associação de Moradores do Bairro Califórnia	2026-05-19 22:10:41.62411
assoc_sigla	AMBC	2026-05-19 22:10:41.62411
assoc_cnpj	12.345.678/0001-90	2026-05-19 22:10:41.62411
assoc_email	contato@ambc.org.br	2026-05-19 22:10:41.62411
assoc_telefone	(51) 3333-0000	2026-05-19 22:10:41.62411
assoc_site	www.ambc.org.br	2026-05-19 22:10:41.62411
assoc_cep	90000-000	2026-05-19 22:10:41.62411
assoc_endereco	Rua das Flores, 100 — Bairro Califórnia	2026-05-19 22:10:41.62411
assoc_bairro	Bairro Califórnia	2026-05-19 22:10:41.62411
assoc_cidade	Porto Alegre	2026-05-19 22:10:41.62411
assoc_uf	RS	2026-05-19 22:10:41.62411
assoc_missao	Associação sem fins lucrativos que promove a melhoria da qualidade de vida dos moradores do Bairro Califórnia por meio de ações sociais, culturais e de infraestrutura.	2026-05-19 22:10:41.62411
tema	claro	2026-05-26 22:17:17.972651
\.


--
-- TOC entry 3971 (class 0 OID 16462)
-- Dependencies: 227
-- Data for Name: conta_regente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.conta_regente (id_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por, tipo, ativo) FROM stdin;
2	Contas Associação	Conta de Água e Luz	2026-05-05 01:11:11.341749	\N	2026-05-06 01:18:52.493255	\N	despesa	t
1	Receitas Associação	\N	2026-05-05 01:09:58.628197	\N	2026-05-06 12:55:03.155193	\N	receita	t
4	Alvará Associação	Pagamento do alvará de manutenção.	2026-05-06 01:17:34.023771	\N	2026-05-07 22:14:53.692323	\N	despesa	t
8	MENSALIDADE	Receber taxa de mensalidade do associado.	2026-05-12 23:34:52.198154	\N	2026-05-12 23:34:52.198154	\N	receita	t
3	padaria2	pao quentinho	2026-05-05 01:32:31.563715	\N	2026-05-28 17:06:56.33706	\N	despesa	t
\.


--
-- TOC entry 3973 (class 0 OID 16472)
-- Dependencies: 229
-- Data for Name: conta_subordinada; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.conta_subordinada (id_conta_subordinada, fk_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por, ativo) FROM stdin;
2	8	Mensalidade	Mensalidade Associado.	2026-05-12 23:35:29.874597	\N	2026-05-12 23:35:29.874597	\N	t
3	8	anual	\N	2026-05-14 01:43:50.55168	\N	2026-05-14 01:43:50.55168	\N	t
4	2	Eventos	Destinado para compra de insumos e realização de eventos.	2026-05-14 18:06:03.465939	\N	2026-05-14 18:06:03.465939	\N	t
1	2	Luz	\N	2026-05-05 02:09:03.483125	\N	2026-05-28 21:06:08.029355	\N	t
\.


--
-- TOC entry 3975 (class 0 OID 16483)
-- Dependencies: 231
-- Data for Name: dependente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.dependente (id_dependente, fk_associado, nome, data_nascimento, cpf, observacao, fk_parentesco, fk_genero, criado_em, atualizado_em, ativo) FROM stdin;
\.


--
-- TOC entry 3977 (class 0 OID 16496)
-- Dependencies: 233
-- Data for Name: doacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.doacao (id_doacao, fk_parceiro, fk_associado, nome_externo, telefone_externo, fk_tipo_doacao, fk_conta_regente, fk_conta_subordinada, descricao, data_doacao, valor_dinheiro, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3979 (class 0 OID 16509)
-- Dependencies: 235
-- Data for Name: documento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.documento (id_documento, numero, ano, fk_tipo_documento, tipo_livre, assunto, data_documento, conteudo, arquivo_path, observacao, criado_em, criado_por, atualizado_em, atualizado_por, categoria, versao) FROM stdin;
2	\N	2026	3	\N	666	2026-05-11	\N	doc_6a01dcfb093548.03819921.pdf	\N	2026-05-11 13:43:24.209728	\N	2026-05-11 13:43:24.209728	\N	institucional	1
3	\N	2026	8	\N	Estatuto da Associação	2026-05-20	\N	doc_6a0cfe4db575f3.00275541.docx	\N	2026-05-20 00:20:29.777018	\N	2026-05-20 00:20:29.777018	\N	institucional	\N
\.


--
-- TOC entry 3981 (class 0 OID 16526)
-- Dependencies: 237
-- Data for Name: espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.espaco (id_espaco, nome, descricao, capacidade, observacao, ativo, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3983 (class 0 OID 16537)
-- Dependencies: 239
-- Data for Name: estado_civil; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.estado_civil (id_estadocivil, descricao) FROM stdin;
1	Solteiro(a)
2	Casado(a)
3	Divorciado(a)
4	Viúvo(a)
\.


--
-- TOC entry 3985 (class 0 OID 16543)
-- Dependencies: 241
-- Data for Name: forma_pagamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
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
-- TOC entry 3987 (class 0 OID 16549)
-- Dependencies: 243
-- Data for Name: genero; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.genero (id_genero, descricao) FROM stdin;
1	Feminino
2	Masculino
3	Outro
7	Prefiro não informar.
\.


--
-- TOC entry 3989 (class 0 OID 16555)
-- Dependencies: 245
-- Data for Name: horario_espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.horario_espaco (id_horario_espaco, fk_espaco, dia_semana, hora_inicio, hora_fim, observacao) FROM stdin;
\.


--
-- TOC entry 3991 (class 0 OID 16566)
-- Dependencies: 247
-- Data for Name: item_doacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.item_doacao (id_item_doacao, fk_doacao, descricao, quantidade, unidade, observacao, criado_em) FROM stdin;
\.


--
-- TOC entry 4034 (class 0 OID 17590)
-- Dependencies: 290
-- Data for Name: lancamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.lancamento (id_lancamento, fk_associado, fk_conta_regente, fk_conta_subordinada, fk_tipo_lancamento, fk_forma_pagamento, fk_status_conta, descricao, valor, valor_pago, data_lancamento, data_vencimento, data_pagamento, observacao, criado_em, criado_por, atualizado_em, atualizado_por, fk_parceiro, fk_parcelamento, numero_parcela, total_parcelas) FROM stdin;
2	\N	\N	\N	3	\N	2	Maio, 26	10.00	10.00	2026-05-13	\N	2026-05-13	\N	2026-05-13 04:17:48.207786	\N	2026-05-13 04:17:48.207786	\N	16	\N	\N	\N
3	\N	\N	\N	3	\N	2	2026	10.00	10.00	2026-05-14	\N	2026-05-13	\N	2026-05-14 02:08:21.89897	\N	2026-05-14 02:08:21.89897	\N	17	\N	\N	\N
4	\N	\N	\N	\N	\N	1	Doação para Evento Beneficente	150.00	\N	2026-05-14	\N	\N	\N	2026-05-14 19:40:04.230398	\N	2026-05-14 19:40:04.230398	\N	\N	\N	\N	\N
5	\N	1	1	1	1	2	Conta de Energia elétrica	104.60	\N	2026-05-13	2026-05-13	\N	\N	2026-05-14 20:06:09.539145	\N	2026-05-14 20:06:09.539145	\N	\N	\N	\N	\N
9	\N	1	1	5	1	1	Reforma da Sede	256.00	\N	2026-05-12	2026-05-18	\N	\N	2026-05-18 21:33:51.603716	\N	2026-05-18 21:33:51.603716	\N	\N	\N	\N	\N
10	\N	1	1	1	1	1	Doação para Evento Beneficente	54.00	\N	2026-05-20	2026-05-19	\N	\N	2026-05-19 21:37:27.79487	\N	2026-05-19 21:37:27.79487	\N	\N	\N	\N	\N
11	\N	1	1	2	1	1	mensalidade	60.00	\N	2026-05-19	2026-05-21	\N	\N	2026-05-19 22:46:38.058976	\N	2026-05-19 22:46:38.058976	\N	\N	\N	\N	\N
12	\N	\N	\N	\N	\N	1	mensalidade - Parcela 1	100.00	\N	2026-05-19	2026-05-19	\N	\N	2026-05-19 22:56:45.165865	\N	2026-05-19 22:56:45.165865	\N	\N	2	\N	\N
13	\N	\N	\N	\N	\N	1	mensalidade - Parcela 2	100.00	\N	2026-05-19	2026-06-19	\N	\N	2026-05-19 22:56:45.165865	\N	2026-05-19 22:56:45.165865	\N	\N	2	\N	\N
14	\N	\N	\N	\N	\N	1	mensalidade - Parcela 3	100.00	\N	2026-05-19	2026-07-19	\N	\N	2026-05-19 22:56:45.165865	\N	2026-05-19 22:56:45.165865	\N	\N	2	\N	\N
15	\N	\N	\N	\N	\N	1	Doação - Parcela 1	100.00	\N	2026-05-19	2026-05-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	1	12
16	\N	\N	\N	\N	\N	1	Doação - Parcela 2	100.00	\N	2026-05-19	2026-06-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	2	12
17	\N	\N	\N	\N	\N	1	Doação - Parcela 3	100.00	\N	2026-05-19	2026-07-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	3	12
18	\N	\N	\N	\N	\N	1	Doação - Parcela 4	100.00	\N	2026-05-19	2026-08-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	4	12
19	\N	\N	\N	\N	\N	1	Doação - Parcela 5	100.00	\N	2026-05-19	2026-09-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	5	12
20	\N	\N	\N	\N	\N	1	Doação - Parcela 6	100.00	\N	2026-05-19	2026-10-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	6	12
21	\N	\N	\N	\N	\N	1	Doação - Parcela 7	100.00	\N	2026-05-19	2026-11-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	7	12
22	\N	\N	\N	\N	\N	1	Doação - Parcela 8	100.00	\N	2026-05-19	2026-12-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	8	12
23	\N	\N	\N	\N	\N	1	Doação - Parcela 9	100.00	\N	2026-05-19	2027-01-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	9	12
24	\N	\N	\N	\N	\N	1	Doação - Parcela 10	100.00	\N	2026-05-19	2027-02-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	10	12
25	\N	\N	\N	\N	\N	1	Doação - Parcela 11	100.00	\N	2026-05-19	2027-03-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	11	12
26	\N	\N	\N	\N	\N	1	Doação - Parcela 12	100.00	\N	2026-05-19	2027-04-20	\N	\N	2026-05-19 23:12:51.305255	\N	2026-05-19 23:12:51.305255	\N	\N	3	12	12
27	\N	\N	\N	\N	\N	1	multa - Parcela 1	100.00	\N	2026-05-19	2026-05-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	1	12
28	\N	\N	\N	\N	\N	1	multa - Parcela 2	100.00	\N	2026-05-19	2026-06-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	2	12
29	\N	\N	\N	\N	\N	1	multa - Parcela 3	100.00	\N	2026-05-19	2026-07-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	3	12
30	\N	\N	\N	\N	\N	1	multa - Parcela 4	100.00	\N	2026-05-19	2026-08-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	4	12
31	\N	\N	\N	\N	\N	1	multa - Parcela 5	100.00	\N	2026-05-19	2026-09-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	5	12
32	\N	\N	\N	\N	\N	1	multa - Parcela 6	100.00	\N	2026-05-19	2026-10-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	6	12
33	\N	\N	\N	\N	\N	1	multa - Parcela 7	100.00	\N	2026-05-19	2026-11-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	7	12
34	\N	\N	\N	\N	\N	1	multa - Parcela 8	100.00	\N	2026-05-19	2026-12-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	8	12
35	\N	\N	\N	\N	\N	1	multa - Parcela 9	100.00	\N	2026-05-19	2027-01-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	9	12
36	\N	\N	\N	\N	\N	1	multa - Parcela 10	100.00	\N	2026-05-19	2027-02-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	10	12
37	\N	\N	\N	\N	\N	1	multa - Parcela 11	100.00	\N	2026-05-19	2027-03-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	11	12
38	\N	\N	\N	\N	\N	1	multa - Parcela 12	100.00	\N	2026-05-19	2027-04-19	\N	\N	2026-05-19 23:30:00.301466	\N	2026-05-19 23:30:00.301466	\N	\N	4	12	12
39	\N	\N	\N	\N	\N	1	multa - Parcela 1	100.00	\N	2026-05-19	2026-05-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	1	12
40	\N	\N	\N	\N	\N	1	multa - Parcela 2	100.00	\N	2026-05-19	2026-06-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	2	12
41	\N	\N	\N	\N	\N	1	multa - Parcela 3	100.00	\N	2026-05-19	2026-07-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	3	12
42	\N	\N	\N	\N	\N	1	multa - Parcela 4	100.00	\N	2026-05-19	2026-08-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	4	12
43	\N	\N	\N	\N	\N	1	multa - Parcela 5	100.00	\N	2026-05-19	2026-09-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	5	12
44	\N	\N	\N	\N	\N	1	multa - Parcela 6	100.00	\N	2026-05-19	2026-10-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	6	12
45	\N	\N	\N	\N	\N	1	multa - Parcela 7	100.00	\N	2026-05-19	2026-11-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	7	12
46	\N	\N	\N	\N	\N	1	multa - Parcela 8	100.00	\N	2026-05-19	2026-12-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	8	12
47	\N	\N	\N	\N	\N	1	multa - Parcela 9	100.00	\N	2026-05-19	2027-01-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	9	12
48	\N	\N	\N	\N	\N	1	multa - Parcela 10	100.00	\N	2026-05-19	2027-02-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	10	12
49	\N	\N	\N	\N	\N	1	multa - Parcela 11	100.00	\N	2026-05-19	2027-03-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	11	12
50	\N	\N	\N	\N	\N	1	multa - Parcela 12	100.00	\N	2026-05-19	2027-04-25	\N	\N	2026-05-19 23:42:30.979479	\N	2026-05-19 23:42:30.979479	\N	\N	5	12	12
51	\N	1	1	2	1	1	teste - Parcela 1	75.00	\N	2026-05-20	2026-05-19	\N	\N	2026-05-20 00:03:56.964513	\N	2026-05-20 00:03:56.964513	\N	\N	6	1	2
52	\N	1	1	2	1	1	teste - Parcela 2	75.00	\N	2026-05-20	2026-06-19	\N	\N	2026-05-20 00:03:56.964513	\N	2026-05-20 00:03:56.964513	\N	\N	6	2	2
53	\N	3	3	12	1	1	Conta de Energia elétrica	75.00	\N	2026-05-21	2026-05-22	\N	\N	2026-05-23 00:30:12.775573	\N	2026-05-23 00:30:12.775573	\N	\N	\N	\N	\N
54	\N	1	1	1	1	1	LEONARDO PEREIRA LEOTE	50.00	\N	2026-05-27	2026-05-27	\N	\N	2026-05-28 01:16:23.729203	\N	2026-05-28 01:16:23.729203	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3993 (class 0 OID 16577)
-- Dependencies: 249
-- Data for Name: log_acesso; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.log_acesso (id_log, fk_usuario, tipo, ip, registrado_em) FROM stdin;
\.


--
-- TOC entry 3995 (class 0 OID 16585)
-- Dependencies: 251
-- Data for Name: modulo_sistema; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
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
-- TOC entry 3997 (class 0 OID 16591)
-- Dependencies: 253
-- Data for Name: parceiro; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.parceiro (id_parceiro, nome_razao_social, cpf_cnpj, email, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, criado_em, criado_por, atualizado_em, atualizado_por, tipo_servico, tipo_pessoa) FROM stdin;
8	Supermercado Bom Preço Ltda	12345678000101	contato@bompreco.com.br	t	Av. Assis Brasil	1000	\N	91000001	Sarandi	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
9	Padaria São Jorge Ltda	23456789000112	padaria@saojorge.com.br	t	Rua Coronel Aparício Borges	500	\N	91000002	Glória	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
10	Farmácia Popular Saúde Ltda	34567890000123	farmacia@popular.com.br	t	Av. Bento Gonçalves	2000	Loja 3	91000003	Partenon	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
11	Distribuidora de Bebidas RS Ltda	45678901000134	bebidas@distribuidora.com.br	t	Rua Industrial	300	\N	91000004	Navegantes	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
12	Brinquedos Alegria Ltda	56789012000145	contato@alegria.com.br	t	Shopping Bourbon	100	Loja 215	90000020	Três Figueiras	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
13	Maria Aparecida Souza Lima	98765432100	maria.aparecida@email.com	t	Rua Luciana de Abreu	450	\N	90000021	Moinhos de Vento	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
14	João Batista Ferreira Neto	87654321099	joao.batista@email.com	t	Av. Carlos Gomes	760	Sala 301	90000022	Auxiliadora	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
15	Loja Encerrada Comércio Ltda	67890123000156	\N	f	Rua dos Andradas	900	\N	90000023	Centro	Porto Alegre	RS	2026-05-13 00:54:30.773167	\N	2026-05-13 00:54:30.773167	\N	\N	PF
16	Grafica Mill	00000000000100	graficamill@graficamill.com	t	Rua João Paulo	123	Sala 2	00000000	Gloria	Glorinha	RS	2026-05-13 02:14:17.920828	\N	2026-05-13 04:17:48.207786	\N	Impressões	PJ
17	Pedro Petry	00000000000	pedropetry@pedropetry.com	t	Rua Maria Afonso	456	torre 1, ap 1001	00000000	Graça	Alvorada	RS	2026-05-14 01:12:03.583313	\N	2026-05-14 02:08:21.89897	\N	mecânico	PF
18	volfied store	01324782222	leo@leo@.com	t	barao do rio branco 381	122	\N	92110410	niteroi	Canoas	RS	2026-05-14 19:32:52.982941	\N	2026-05-14 19:32:52.982941	\N	loja	PF
21	padaria pao quentinho	11111111111	\N	t	\N	\N	\N	\N	\N	\N	\N	2026-05-27 00:30:47.935642	\N	2026-05-27 00:30:47.935642	\N	\N	PF
22	loja central	12345678920	lojacentral@gmail.com	t	R. São João Batista	88	102	92480000	Califórnia	Nova Santa Rita	RS	2026-05-27 23:41:03.143304	\N	2026-05-27 23:41:03.143304	\N	vestuário	PF
\.


--
-- TOC entry 4041 (class 0 OID 17759)
-- Dependencies: 297
-- Data for Name: parcelamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.parcelamento (id_parcelamento, fk_associado, descricao, quantidade_parcelas, valor_total, valor_parcela, data_primeiro_vencimento, criado_em) FROM stdin;
2	\N	mensalidade	3	300.00	100.00	2026-05-19	2026-05-19 22:56:45.165865
3	\N	Doação	12	1200.00	100.00	2026-05-20	2026-05-19 23:12:51.305255
4	\N	multa	12	1200.00	100.00	2026-05-19	2026-05-19 23:30:00.301466
5	\N	multa	12	1200.00	100.00	2026-05-25	2026-05-19 23:42:30.979479
6	\N	teste	2	150.00	75.00	2026-05-19	2026-05-20 00:03:56.964513
\.


--
-- TOC entry 3999 (class 0 OID 16619)
-- Dependencies: 255
-- Data for Name: parentesco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.parentesco (id_parentesco, descricao, observacao) FROM stdin;
1	Filho(a)	\N
2	Enteado(a)	\N
3	Sobrinho(a)	\N
4	Neto(a)	\N
5	Outro	\N
\.


--
-- TOC entry 4001 (class 0 OID 16627)
-- Dependencies: 257
-- Data for Name: perfil_usuario; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.perfil_usuario (id_perfil, descricao, observacao) FROM stdin;
1	Administrador	Acesso total ao sistema. Gerencia usuários e permissões.
2	Gestor	Acesso operacional configurável pelo administrador.
3	Visualizador	Somente leitura. Módulos visíveis configuráveis pelo administrador.
\.


--
-- TOC entry 4003 (class 0 OID 16635)
-- Dependencies: 259
-- Data for Name: permissao_usuario; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.permissao_usuario (id_permissao, fk_usuario, fk_modulo, pode_acessar, pode_editar) FROM stdin;
41	8	1	t	t
42	8	2	t	t
43	8	3	t	t
44	8	4	t	t
45	8	5	t	t
46	8	6	t	t
47	8	7	t	t
48	8	8	t	t
49	9	1	t	t
50	9	2	t	t
51	9	3	t	t
52	9	4	t	t
53	9	5	t	t
54	9	6	t	t
55	9	7	t	t
56	9	8	t	t
73	12	1	t	t
74	12	2	t	t
75	12	3	t	t
76	12	4	t	t
77	12	5	t	t
78	12	6	t	t
79	12	7	t	t
80	12	8	t	t
121	17	1	t	t
122	17	2	t	t
123	17	3	t	t
124	17	4	t	t
125	17	5	t	t
126	17	6	t	t
127	17	7	t	t
128	17	8	t	t
129	18	1	t	t
130	18	2	t	t
131	18	3	t	t
132	18	4	t	t
133	18	5	t	t
134	18	6	t	t
135	18	7	t	t
136	18	8	t	t
\.


--
-- TOC entry 4039 (class 0 OID 17737)
-- Dependencies: 295
-- Data for Name: plano_associacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.plano_associacao (id_plano, nome, preco, periodo, beneficios, ativo, ordem, criado_em) FROM stdin;
1	Associado Padrão	60.00	anuidade	[{"incluido": true, "descricao": "Acesso à sede social"}, {"incluido": true, "descricao": "Até 3 dependentes"}, {"incluido": true, "descricao": "Participação em eventos"}]	t	0	2026-05-18 13:02:41.27075
3	teste	12.00	anuidade	[]	t	0	2026-05-18 13:07:08.248355
\.


--
-- TOC entry 4005 (class 0 OID 16644)
-- Dependencies: 261
-- Data for Name: profissao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
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
13	médico
\.


--
-- TOC entry 4043 (class 0 OID 17787)
-- Dependencies: 299
-- Data for Name: relacionamento_lancamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.relacionamento_lancamento (id_relacionamento, fk_tipo_lancamento, fk_conta_regente, fk_conta_subordinada, natureza, modo, ativo, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
1	6	8	2	RECEBER	FIXO	t	\N	2026-05-21 00:35:37.051129	\N	2026-05-21 00:35:37.051129	\N
3	1	8	3	RECEBER	FIXO	t	\N	2026-05-21 21:22:54.684358	\N	2026-05-21 21:22:54.684358	\N
4	12	2	1	PAGAR	FIXO	t	\N	2026-05-21 22:16:47.546871	\N	2026-05-21 22:16:47.546871	\N
\.


--
-- TOC entry 4007 (class 0 OID 16650)
-- Dependencies: 263
-- Data for Name: reserva_espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.reserva_espaco (id_reserva, fk_espaco, fk_horario_espaco, fk_status_reserva, data_reserva, fk_associado, fk_parceiro, nome_externo, telefone_externo, email_externo, valor_cobrado, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 4028 (class 0 OID 17544)
-- Dependencies: 284
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.schema_migrations (versao, aplicada_em) FROM stdin;
015_sincronizar_schema_online	2026-05-09 06:11:41.937685
\.


--
-- TOC entry 4009 (class 0 OID 16665)
-- Dependencies: 265
-- Data for Name: status_agenda; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_agenda (id_status_agenda, descricao) FROM stdin;
1	Agendado
2	Cancelado
3	Concluído
4	Suspenso
\.


--
-- TOC entry 4011 (class 0 OID 16671)
-- Dependencies: 267
-- Data for Name: status_conta; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_conta (id_status_conta, descricao) FROM stdin;
1	Aberto
2	Liquidado
3	Cancelado
\.


--
-- TOC entry 4013 (class 0 OID 16677)
-- Dependencies: 269
-- Data for Name: status_pessoa; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_pessoa (id_status, descricao) FROM stdin;
1	Ativo
2	Pendente
3	Inativo
\.


--
-- TOC entry 4015 (class 0 OID 16683)
-- Dependencies: 271
-- Data for Name: status_reserva; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_reserva (id_status_reserva, descricao) FROM stdin;
1	Confirmado
2	Cancelado
3	Concluído
\.


--
-- TOC entry 4017 (class 0 OID 16689)
-- Dependencies: 273
-- Data for Name: telefone; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.telefone (id_telefone, fk_associado, ddd, numero, fk_tipo_telefone, observacao) FROM stdin;
7	4	51	987654321	\N	\N
8	5	51	993456789	\N	\N
10	7	51	995678901	\N	\N
23	34	51	99999999	\N	
24	35	51	21215050	\N	
\.


--
-- TOC entry 4019 (class 0 OID 16699)
-- Dependencies: 275
-- Data for Name: telefone_parceiro; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.telefone_parceiro (id_telefone_parceiro, fk_parceiro, ddd, numero, fk_tipo_telefone, observacao) FROM stdin;
11	8	51	33331000	\N	\N
12	8	51	988881000	\N	\N
13	9	51	33332000	\N	\N
14	10	51	33333000	\N	\N
15	11	51	33334000	\N	\N
16	11	51	988884000	\N	\N
17	12	51	33335000	\N	\N
18	13	51	988886000	\N	\N
19	14	51	988887000	\N	\N
20	14	51	33337000	\N	\N
22	16	51	999999999	3	Vendas
23	17	51	999999999	4	horario comercial apenas
24	18	51	991726262	4	\N
25	22	51	89896320	1	\N
\.


--
-- TOC entry 4021 (class 0 OID 16709)
-- Dependencies: 277
-- Data for Name: tipo_doacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.tipo_doacao (id_tipo_doacao, descricao) FROM stdin;
1	Dinheiro
2	Alimentos e bebidas
3	Brinquedos
4	Outros itens
\.


--
-- TOC entry 4023 (class 0 OID 16715)
-- Dependencies: 279
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.tipo_documento (id_tipo_documento, descricao) FROM stdin;
1	Ata
2	Ofício
3	Mensagem
4	Circular
5	Requerimento
6	Declaração
7	Outro
8	Estatuto
9	Regimento Interno
\.


--
-- TOC entry 4032 (class 0 OID 17576)
-- Dependencies: 288
-- Data for Name: tipo_lancamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.tipo_lancamento (id_tipo_lancamento, descricao, observacao) FROM stdin;
1	Anuidade	\N
2	Mensalidade	\N
3	Doação	\N
4	Multa	\N
5	Outro	\N
6	Mensalidades	\N
10	Multa por Atraso	Multa por atraso no pagamento
11	Manutenção	Despesa de manutenção da associação
12	Conta de Energia Elétrica	\N
\.


--
-- TOC entry 4030 (class 0 OID 17553)
-- Dependencies: 286
-- Data for Name: tipo_telefone; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.tipo_telefone (id_tipo_telefone, descricao) FROM stdin;
1	Celular
2	Residencial
3	Comercial
4	WhatsApp
5	Outro
\.


--
-- TOC entry 4025 (class 0 OID 16721)
-- Dependencies: 281
-- Data for Name: uf; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
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
-- TOC entry 4026 (class 0 OID 16726)
-- Dependencies: 282
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.usuario (id_usuario, nome, email, senha_hash, fk_perfil, fk_associado, ativo, primeiro_acesso, ultimo_acesso, token_reset, token_expira_em, criado_em, atualizado_em) FROM stdin;
17	fabiolopes	fabiomachado1212@gmail.com	$2y$10$ngNB..SC6KHKMW81SY6w/eHHWVVZzLO1Ty6feVNLuv50Im0kpCpki	1	\N	t	f	2026-05-25 22:23:10.023774	\N	\N	2026-05-02 00:19:40.239912	2026-05-25 22:23:10.023774
9	Fabio	fabiomachadolopes@hotmail.com	$2y$10$RtQS/0O3bqT7/xjH0XaAg.SXrcU9TCahTYFDmk5R.J2B5/md.Qof.	1	\N	t	f	2026-05-27 00:20:15.419617	\N	\N	2026-04-27 22:58:57.453115	2026-05-27 00:20:15.419617
22	Adriane Reis	adrianeb.reis22@gmail.com	$2y$10$x0GsyKNUdWJ2qsWZGY3JEORusoj1Ne9.0PqeSJXt1NTwCm5VhenJu	1	\N	t	f	2026-05-27 23:24:51.837062	\N	\N	2026-05-14 22:16:45.668028	2026-05-27 23:24:51.837062
18	Mikaela Thais Silva Kichler	mikaelatsk@gmail.com	$2y$10$XTMVRQL4jTAgEaeH9JjRg.bG.xoCMBPurZnrimV2HODKRBo0MwtFK	1	\N	t	f	\N	\N	\N	2026-05-02 00:26:38.464967	2026-05-02 00:26:38.464967
8	Leonardo Pereira Leote	leonardo.leote0909@gmail.com	$2y$10$7mFTe0VtaL8bXpuY8hjaSecyjN3zUQKGdPHlUMbpT2GUMuaeo6dn2	1	\N	t	f	2026-05-28 01:31:28.69519	\N	\N	2026-04-27 22:57:58.284863	2026-05-28 01:31:28.69519
20	adminAMBC	admin@ambc.com	$2y$10$64WUVSRBW1V79YGdPcsozeVxu5.EO/4nB1D7cMm65F8s6fumtWilG	1	\N	t	f	2026-05-28 21:16:42.807285	\N	\N	2026-05-05 02:06:48.185973	2026-05-28 21:16:42.807285
12	admin	admin@admin.com	$2y$10$WINMYpdKI7nvRaRvyMHra.g0HYRBgBrmewBRnEGvbNLKp/5BQyRi6	1	\N	t	f	2026-05-28 21:28:53.753404	\N	\N	2026-04-30 01:40:14.336256	2026-05-28 21:28:53.753404
\.


--
-- TOC entry 4087 (class 0 OID 0)
-- Dependencies: 221
-- Name: agenda_documento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.agenda_documento_id_seq', 1, false);


--
-- TOC entry 4088 (class 0 OID 0)
-- Dependencies: 222
-- Name: agenda_id_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.agenda_id_agenda_seq', 1, false);


--
-- TOC entry 4089 (class 0 OID 0)
-- Dependencies: 224
-- Name: associado_id_associado_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.associado_id_associado_seq', 35, true);


--
-- TOC entry 4090 (class 0 OID 0)
-- Dependencies: 226
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 4091 (class 0 OID 0)
-- Dependencies: 228
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.conta_regente_id_conta_regente_seq', 8, true);


--
-- TOC entry 4092 (class 0 OID 0)
-- Dependencies: 230
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.conta_subordinada_id_conta_subordinada_seq', 4, true);


--
-- TOC entry 4093 (class 0 OID 0)
-- Dependencies: 232
-- Name: dependente_id_dependente_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.dependente_id_dependente_seq', 26, true);


--
-- TOC entry 4094 (class 0 OID 0)
-- Dependencies: 234
-- Name: doacao_id_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.doacao_id_doacao_seq', 1, false);


--
-- TOC entry 4095 (class 0 OID 0)
-- Dependencies: 236
-- Name: documento_id_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.documento_id_documento_seq', 3, true);


--
-- TOC entry 4096 (class 0 OID 0)
-- Dependencies: 238
-- Name: espaco_id_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.espaco_id_espaco_seq', 1, false);


--
-- TOC entry 4097 (class 0 OID 0)
-- Dependencies: 240
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.estado_civil_id_estadocivil_seq', 6, true);


--
-- TOC entry 4098 (class 0 OID 0)
-- Dependencies: 242
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.forma_pagamento_id_forma_pagamento_seq', 1, false);


--
-- TOC entry 4099 (class 0 OID 0)
-- Dependencies: 244
-- Name: genero_id_genero_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.genero_id_genero_seq', 7, true);


--
-- TOC entry 4100 (class 0 OID 0)
-- Dependencies: 246
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.horario_espaco_id_horario_espaco_seq', 1, false);


--
-- TOC entry 4101 (class 0 OID 0)
-- Dependencies: 248
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.item_doacao_id_item_doacao_seq', 1, false);


--
-- TOC entry 4102 (class 0 OID 0)
-- Dependencies: 289
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.lancamento_id_lancamento_seq', 55, true);


--
-- TOC entry 4103 (class 0 OID 0)
-- Dependencies: 250
-- Name: log_acesso_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.log_acesso_id_log_seq', 1, false);


--
-- TOC entry 4104 (class 0 OID 0)
-- Dependencies: 252
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.modulo_sistema_id_modulo_seq', 1, false);


--
-- TOC entry 4105 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.parceiro_id_parceiro_seq', 22, true);


--
-- TOC entry 4106 (class 0 OID 0)
-- Dependencies: 296
-- Name: parcelamento_id_parcelamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.parcelamento_id_parcelamento_seq', 6, true);


--
-- TOC entry 4107 (class 0 OID 0)
-- Dependencies: 256
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.parentesco_id_parentesco_seq', 6, true);


--
-- TOC entry 4108 (class 0 OID 0)
-- Dependencies: 258
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.perfil_usuario_id_perfil_seq', 1, false);


--
-- TOC entry 4109 (class 0 OID 0)
-- Dependencies: 260
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.permissao_usuario_id_permissao_seq', 136, true);


--
-- TOC entry 4110 (class 0 OID 0)
-- Dependencies: 294
-- Name: plano_associacao_id_plano_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.plano_associacao_id_plano_seq', 3, true);


--
-- TOC entry 4111 (class 0 OID 0)
-- Dependencies: 262
-- Name: profissao_id_profissao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.profissao_id_profissao_seq', 14, true);


--
-- TOC entry 4112 (class 0 OID 0)
-- Dependencies: 298
-- Name: relacionamento_lancamento_id_relacionamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.relacionamento_lancamento_id_relacionamento_seq', 4, true);


--
-- TOC entry 4113 (class 0 OID 0)
-- Dependencies: 264
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.reserva_espaco_id_reserva_seq', 1, false);


--
-- TOC entry 4114 (class 0 OID 0)
-- Dependencies: 266
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_agenda_id_status_agenda_seq', 1, false);


--
-- TOC entry 4115 (class 0 OID 0)
-- Dependencies: 268
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_conta_id_status_conta_seq', 1, false);


--
-- TOC entry 4116 (class 0 OID 0)
-- Dependencies: 270
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_pessoa_id_status_seq', 4, true);


--
-- TOC entry 4117 (class 0 OID 0)
-- Dependencies: 272
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_reserva_id_status_reserva_seq', 1, false);


--
-- TOC entry 4118 (class 0 OID 0)
-- Dependencies: 274
-- Name: telefone_id_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.telefone_id_telefone_seq', 24, true);


--
-- TOC entry 4119 (class 0 OID 0)
-- Dependencies: 276
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.telefone_parceiro_id_telefone_parceiro_seq', 25, true);


--
-- TOC entry 4120 (class 0 OID 0)
-- Dependencies: 278
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_doacao_id_tipo_doacao_seq', 1, false);


--
-- TOC entry 4121 (class 0 OID 0)
-- Dependencies: 280
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_documento_id_tipo_documento_seq', 9, true);


--
-- TOC entry 4122 (class 0 OID 0)
-- Dependencies: 287
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_lancamento_id_tipo_lancamento_seq', 12, true);


--
-- TOC entry 4123 (class 0 OID 0)
-- Dependencies: 285
-- Name: tipo_telefone_id_tipo_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_telefone_id_tipo_telefone_seq', 5, true);


--
-- TOC entry 4124 (class 0 OID 0)
-- Dependencies: 283
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 22, true);


--
-- TOC entry 3566 (class 2606 OID 16775)
-- Name: agenda_documento agenda_documento_fk_agenda_fk_documento_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fk_documento_key UNIQUE (fk_agenda, fk_documento);


--
-- TOC entry 3568 (class 2606 OID 16777)
-- Name: agenda_documento agenda_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_pkey PRIMARY KEY (id);


--
-- TOC entry 3563 (class 2606 OID 16779)
-- Name: agenda agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_pkey PRIMARY KEY (id_agenda);


--
-- TOC entry 3570 (class 2606 OID 16781)
-- Name: associado associado_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 3711 (class 2606 OID 17667)
-- Name: associado_dependente associado_dependente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_pkey PRIMARY KEY (fk_associado, fk_dependente);


--
-- TOC entry 3572 (class 2606 OID 17248)
-- Name: associado associado_matricula_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_matricula_key UNIQUE (matricula);


--
-- TOC entry 3574 (class 2606 OID 16783)
-- Name: associado associado_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_pkey PRIMARY KEY (id_associado);


--
-- TOC entry 3577 (class 2606 OID 16785)
-- Name: categoria categoria_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_descricao_key UNIQUE (descricao);


--
-- TOC entry 3579 (class 2606 OID 16787)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 3715 (class 2606 OID 17696)
-- Name: configuracao_sistema configuracao_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.configuracao_sistema
    ADD CONSTRAINT configuracao_sistema_pkey PRIMARY KEY (chave);


--
-- TOC entry 3717 (class 2606 OID 17714)
-- Name: configuracoes configuracoes_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.configuracoes
    ADD CONSTRAINT configuracoes_pkey PRIMARY KEY (chave);


--
-- TOC entry 3581 (class 2606 OID 16791)
-- Name: conta_regente conta_regente_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_descricao_key UNIQUE (descricao);


--
-- TOC entry 3583 (class 2606 OID 16793)
-- Name: conta_regente conta_regente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_pkey PRIMARY KEY (id_conta_regente);


--
-- TOC entry 3585 (class 2606 OID 16795)
-- Name: conta_subordinada conta_subordinada_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_pkey PRIMARY KEY (id_conta_subordinada);


--
-- TOC entry 3587 (class 2606 OID 16797)
-- Name: dependente dependente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_pkey PRIMARY KEY (id_dependente);


--
-- TOC entry 3591 (class 2606 OID 16799)
-- Name: doacao doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_pkey PRIMARY KEY (id_doacao);


--
-- TOC entry 3594 (class 2606 OID 16801)
-- Name: documento documento_numero_ano_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_numero_ano_key UNIQUE (numero, ano);


--
-- TOC entry 3596 (class 2606 OID 16803)
-- Name: documento documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 3599 (class 2606 OID 16805)
-- Name: espaco espaco_nome_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_nome_key UNIQUE (nome);


--
-- TOC entry 3601 (class 2606 OID 16807)
-- Name: espaco espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_pkey PRIMARY KEY (id_espaco);


--
-- TOC entry 3603 (class 2606 OID 16809)
-- Name: estado_civil estado_civil_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_descricao_key UNIQUE (descricao);


--
-- TOC entry 3605 (class 2606 OID 16811)
-- Name: estado_civil estado_civil_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_pkey PRIMARY KEY (id_estadocivil);


--
-- TOC entry 3607 (class 2606 OID 16813)
-- Name: forma_pagamento forma_pagamento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3609 (class 2606 OID 16815)
-- Name: forma_pagamento forma_pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_pkey PRIMARY KEY (id_forma_pagamento);


--
-- TOC entry 3611 (class 2606 OID 16817)
-- Name: genero genero_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_descricao_key UNIQUE (descricao);


--
-- TOC entry 3613 (class 2606 OID 16819)
-- Name: genero genero_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_pkey PRIMARY KEY (id_genero);


--
-- TOC entry 3615 (class 2606 OID 16821)
-- Name: horario_espaco horario_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_pkey PRIMARY KEY (id_horario_espaco);


--
-- TOC entry 3617 (class 2606 OID 16823)
-- Name: item_doacao item_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_pkey PRIMARY KEY (id_item_doacao);


--
-- TOC entry 3709 (class 2606 OID 17609)
-- Name: lancamento lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_pkey PRIMARY KEY (id_lancamento);


--
-- TOC entry 3620 (class 2606 OID 16825)
-- Name: log_acesso log_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_pkey PRIMARY KEY (id_log);


--
-- TOC entry 3622 (class 2606 OID 16827)
-- Name: modulo_sistema modulo_sistema_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_descricao_key UNIQUE (descricao);


--
-- TOC entry 3624 (class 2606 OID 16829)
-- Name: modulo_sistema modulo_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_pkey PRIMARY KEY (id_modulo);


--
-- TOC entry 3628 (class 2606 OID 16831)
-- Name: parceiro parceiro_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 3630 (class 2606 OID 16833)
-- Name: parceiro parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_pkey PRIMARY KEY (id_parceiro);


--
-- TOC entry 3721 (class 2606 OID 17772)
-- Name: parcelamento parcelamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parcelamento
    ADD CONSTRAINT parcelamento_pkey PRIMARY KEY (id_parcelamento);


--
-- TOC entry 3632 (class 2606 OID 16837)
-- Name: parentesco parentesco_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_descricao_key UNIQUE (descricao);


--
-- TOC entry 3634 (class 2606 OID 16839)
-- Name: parentesco parentesco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_pkey PRIMARY KEY (id_parentesco);


--
-- TOC entry 3636 (class 2606 OID 16841)
-- Name: perfil_usuario perfil_usuario_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_descricao_key UNIQUE (descricao);


--
-- TOC entry 3638 (class 2606 OID 16843)
-- Name: perfil_usuario perfil_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_pkey PRIMARY KEY (id_perfil);


--
-- TOC entry 3640 (class 2606 OID 16845)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fk_modulo_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fk_modulo_key UNIQUE (fk_usuario, fk_modulo);


--
-- TOC entry 3642 (class 2606 OID 16847)
-- Name: permissao_usuario permissao_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_pkey PRIMARY KEY (id_permissao);


--
-- TOC entry 3719 (class 2606 OID 17757)
-- Name: plano_associacao plano_associacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.plano_associacao
    ADD CONSTRAINT plano_associacao_pkey PRIMARY KEY (id_plano);


--
-- TOC entry 3644 (class 2606 OID 16849)
-- Name: profissao profissao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_descricao_key UNIQUE (descricao);


--
-- TOC entry 3646 (class 2606 OID 16851)
-- Name: profissao profissao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_pkey PRIMARY KEY (id_profissao);


--
-- TOC entry 3725 (class 2606 OID 17805)
-- Name: relacionamento_lancamento relacionamento_lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.relacionamento_lancamento
    ADD CONSTRAINT relacionamento_lancamento_pkey PRIMARY KEY (id_relacionamento);


--
-- TOC entry 3649 (class 2606 OID 16853)
-- Name: reserva_espaco reserva_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_pkey PRIMARY KEY (id_reserva);


--
-- TOC entry 3691 (class 2606 OID 17551)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (versao);


--
-- TOC entry 3651 (class 2606 OID 16855)
-- Name: status_agenda status_agenda_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_descricao_key UNIQUE (descricao);


--
-- TOC entry 3653 (class 2606 OID 16857)
-- Name: status_agenda status_agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_pkey PRIMARY KEY (id_status_agenda);


--
-- TOC entry 3655 (class 2606 OID 16859)
-- Name: status_conta status_conta_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_descricao_key UNIQUE (descricao);


--
-- TOC entry 3657 (class 2606 OID 16861)
-- Name: status_conta status_conta_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_pkey PRIMARY KEY (id_status_conta);


--
-- TOC entry 3659 (class 2606 OID 16863)
-- Name: status_pessoa status_pessoa_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_descricao_key UNIQUE (descricao);


--
-- TOC entry 3661 (class 2606 OID 16865)
-- Name: status_pessoa status_pessoa_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_pkey PRIMARY KEY (id_status);


--
-- TOC entry 3663 (class 2606 OID 16867)
-- Name: status_reserva status_reserva_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_descricao_key UNIQUE (descricao);


--
-- TOC entry 3665 (class 2606 OID 16869)
-- Name: status_reserva status_reserva_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_pkey PRIMARY KEY (id_status_reserva);


--
-- TOC entry 3668 (class 2606 OID 16871)
-- Name: telefone telefone_fk_associado_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_ddd_numero_key UNIQUE (fk_associado, ddd, numero);


--
-- TOC entry 3673 (class 2606 OID 16873)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_ddd_numero_key UNIQUE (fk_parceiro, ddd, numero);


--
-- TOC entry 3675 (class 2606 OID 16875)
-- Name: telefone_parceiro telefone_parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_pkey PRIMARY KEY (id_telefone_parceiro);


--
-- TOC entry 3670 (class 2606 OID 16877)
-- Name: telefone telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_pkey PRIMARY KEY (id_telefone);


--
-- TOC entry 3677 (class 2606 OID 16879)
-- Name: tipo_doacao tipo_doacao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_descricao_key UNIQUE (descricao);


--
-- TOC entry 3679 (class 2606 OID 16881)
-- Name: tipo_doacao tipo_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_pkey PRIMARY KEY (id_tipo_doacao);


--
-- TOC entry 3681 (class 2606 OID 16883)
-- Name: tipo_documento tipo_documento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3683 (class 2606 OID 16885)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 3697 (class 2606 OID 17585)
-- Name: tipo_lancamento tipo_lancamento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento
    ADD CONSTRAINT tipo_lancamento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3699 (class 2606 OID 17583)
-- Name: tipo_lancamento tipo_lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento
    ADD CONSTRAINT tipo_lancamento_pkey PRIMARY KEY (id_tipo_lancamento);


--
-- TOC entry 3693 (class 2606 OID 17562)
-- Name: tipo_telefone tipo_telefone_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone
    ADD CONSTRAINT tipo_telefone_descricao_key UNIQUE (descricao);


--
-- TOC entry 3695 (class 2606 OID 17560)
-- Name: tipo_telefone tipo_telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone
    ADD CONSTRAINT tipo_telefone_pkey PRIMARY KEY (id_tipo_telefone);


--
-- TOC entry 3685 (class 2606 OID 16887)
-- Name: uf uf_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.uf
    ADD CONSTRAINT uf_pkey PRIMARY KEY (sigla);


--
-- TOC entry 3687 (class 2606 OID 16889)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 3689 (class 2606 OID 16891)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 3564 (class 1259 OID 16892)
-- Name: idx_agenda_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_agenda_data ON public.agenda USING btree (data_inicio);


--
-- TOC entry 3712 (class 1259 OID 17679)
-- Name: idx_assoc_dep_associado; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_assoc_dep_associado ON public.associado_dependente USING btree (fk_associado);


--
-- TOC entry 3713 (class 1259 OID 17680)
-- Name: idx_assoc_dep_dependente; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_assoc_dep_dependente ON public.associado_dependente USING btree (fk_dependente);


--
-- TOC entry 3575 (class 1259 OID 16893)
-- Name: idx_associado_nome; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_associado_nome ON public.associado USING btree (nome);


--
-- TOC entry 3588 (class 1259 OID 17681)
-- Name: idx_dependente_ativo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_dependente_ativo ON public.dependente USING btree (ativo);


--
-- TOC entry 3589 (class 1259 OID 17682)
-- Name: idx_dependente_nascimento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_dependente_nascimento ON public.dependente USING btree (data_nascimento);


--
-- TOC entry 3592 (class 1259 OID 16894)
-- Name: idx_doacao_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_doacao_data ON public.doacao USING btree (data_doacao);


--
-- TOC entry 3597 (class 1259 OID 16895)
-- Name: idx_documento_indice; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_documento_indice ON public.documento USING btree (ano, numero);


--
-- TOC entry 3700 (class 1259 OID 17650)
-- Name: idx_lancamento_associado; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_associado ON public.lancamento USING btree (fk_associado);


--
-- TOC entry 3701 (class 1259 OID 17651)
-- Name: idx_lancamento_conta_regente; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_conta_regente ON public.lancamento USING btree (fk_conta_regente);


--
-- TOC entry 3702 (class 1259 OID 17652)
-- Name: idx_lancamento_conta_subordinada; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_conta_subordinada ON public.lancamento USING btree (fk_conta_subordinada);


--
-- TOC entry 3703 (class 1259 OID 17656)
-- Name: idx_lancamento_data_lancamento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_data_lancamento ON public.lancamento USING btree (data_lancamento);


--
-- TOC entry 3704 (class 1259 OID 17705)
-- Name: idx_lancamento_fk_parceiro; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_fk_parceiro ON public.lancamento USING btree (fk_parceiro);


--
-- TOC entry 3705 (class 1259 OID 17655)
-- Name: idx_lancamento_status; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_status ON public.lancamento USING btree (fk_status_conta);


--
-- TOC entry 3706 (class 1259 OID 17653)
-- Name: idx_lancamento_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_tipo ON public.lancamento USING btree (fk_tipo_lancamento);


--
-- TOC entry 3707 (class 1259 OID 17654)
-- Name: idx_lancamento_vencimento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_vencimento ON public.lancamento USING btree (data_vencimento);


--
-- TOC entry 3618 (class 1259 OID 16896)
-- Name: idx_log_usuario; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_log_usuario ON public.log_acesso USING btree (fk_usuario);


--
-- TOC entry 3625 (class 1259 OID 16897)
-- Name: idx_parceiro_nome; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_parceiro_nome ON public.parceiro USING btree (nome_razao_social);


--
-- TOC entry 3626 (class 1259 OID 17684)
-- Name: idx_parceiro_tipo_pessoa; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_parceiro_tipo_pessoa ON public.parceiro USING btree (tipo_pessoa);


--
-- TOC entry 3722 (class 1259 OID 17822)
-- Name: idx_relacionamento_ativo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_relacionamento_ativo ON public.relacionamento_lancamento USING btree (ativo);


--
-- TOC entry 3723 (class 1259 OID 17821)
-- Name: idx_relacionamento_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_relacionamento_tipo ON public.relacionamento_lancamento USING btree (fk_tipo_lancamento);


--
-- TOC entry 3647 (class 1259 OID 16899)
-- Name: idx_reserva_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_reserva_data ON public.reserva_espaco USING btree (data_reserva);


--
-- TOC entry 3671 (class 1259 OID 17686)
-- Name: idx_telefone_parceiro_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_telefone_parceiro_tipo ON public.telefone_parceiro USING btree (fk_tipo_telefone);


--
-- TOC entry 3666 (class 1259 OID 17685)
-- Name: idx_telefone_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_telefone_tipo ON public.telefone USING btree (fk_tipo_telefone);


--
-- TOC entry 3798 (class 2620 OID 16900)
-- Name: agenda trg_conflito_agenda; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_conflito_agenda BEFORE INSERT OR UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_agenda();


--
-- TOC entry 3810 (class 2620 OID 16901)
-- Name: reserva_espaco trg_conflito_reserva; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_conflito_reserva BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_reserva();


--
-- TOC entry 3800 (class 2620 OID 16902)
-- Name: associado trg_cpf_cnpj_associado; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_cpf_cnpj_associado BEFORE INSERT OR UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 3808 (class 2620 OID 16903)
-- Name: parceiro trg_cpf_cnpj_parceiro; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_cpf_cnpj_parceiro BEFORE INSERT OR UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 3799 (class 2620 OID 16904)
-- Name: agenda trg_ts_agenda; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_agenda BEFORE UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3815 (class 2620 OID 17683)
-- Name: associado_dependente trg_ts_assoc_dep; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_assoc_dep BEFORE UPDATE ON public.associado_dependente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3801 (class 2620 OID 16905)
-- Name: associado trg_ts_associado; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_associado BEFORE UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3802 (class 2620 OID 16907)
-- Name: conta_regente trg_ts_conta_regente; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_conta_regente BEFORE UPDATE ON public.conta_regente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3803 (class 2620 OID 16908)
-- Name: conta_subordinada trg_ts_conta_sub; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_conta_sub BEFORE UPDATE ON public.conta_subordinada FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3804 (class 2620 OID 16909)
-- Name: dependente trg_ts_dependente; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_dependente BEFORE UPDATE ON public.dependente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3805 (class 2620 OID 16910)
-- Name: doacao trg_ts_doacao; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_doacao BEFORE UPDATE ON public.doacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3806 (class 2620 OID 16911)
-- Name: documento trg_ts_documento; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_documento BEFORE UPDATE ON public.documento FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3807 (class 2620 OID 16912)
-- Name: espaco trg_ts_espaco; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_espaco BEFORE UPDATE ON public.espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3814 (class 2620 OID 17657)
-- Name: lancamento trg_ts_lancamento; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_lancamento BEFORE UPDATE ON public.lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3809 (class 2620 OID 16913)
-- Name: parceiro trg_ts_parceiro; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_parceiro BEFORE UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3811 (class 2620 OID 16915)
-- Name: reserva_espaco trg_ts_reserva; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_reserva BEFORE UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3813 (class 2620 OID 16916)
-- Name: usuario trg_ts_usuario; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_usuario BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3812 (class 2620 OID 16917)
-- Name: reserva_espaco trg_validar_horario_espaco; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_validar_horario_espaco BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_validar_horario_espaco();


--
-- TOC entry 3732 (class 2606 OID 16919)
-- Name: agenda_documento agenda_documento_fk_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fkey FOREIGN KEY (fk_agenda) REFERENCES public.agenda(id_agenda) ON DELETE CASCADE;


--
-- TOC entry 3733 (class 2606 OID 16924)
-- Name: agenda_documento agenda_documento_fk_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_documento_fkey FOREIGN KEY (fk_documento) REFERENCES public.documento(id_documento) ON DELETE CASCADE;


--
-- TOC entry 3726 (class 2606 OID 16929)
-- Name: agenda agenda_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 3727 (class 2606 OID 16934)
-- Name: agenda agenda_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE SET NULL;


--
-- TOC entry 3728 (class 2606 OID 16939)
-- Name: agenda agenda_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE SET NULL;


--
-- TOC entry 3729 (class 2606 OID 16944)
-- Name: agenda agenda_fk_status_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_status_agenda_fkey FOREIGN KEY (fk_status_agenda) REFERENCES public.status_agenda(id_status_agenda);


--
-- TOC entry 3793 (class 2606 OID 17668)
-- Name: associado_dependente associado_dependente_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3794 (class 2606 OID 17673)
-- Name: associado_dependente associado_dependente_fk_dependente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_fk_dependente_fkey FOREIGN KEY (fk_dependente) REFERENCES public.dependente(id_dependente) ON DELETE CASCADE;


--
-- TOC entry 3734 (class 2606 OID 16949)
-- Name: associado associado_fk_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_categoria_fkey FOREIGN KEY (fk_categoria) REFERENCES public.categoria(id_categoria);


--
-- TOC entry 3735 (class 2606 OID 16954)
-- Name: associado associado_fk_estadocivil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_estadocivil_fkey FOREIGN KEY (fk_estadocivil) REFERENCES public.estado_civil(id_estadocivil);


--
-- TOC entry 3736 (class 2606 OID 16959)
-- Name: associado associado_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 3737 (class 2606 OID 16964)
-- Name: associado associado_fk_profissao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_profissao_fkey FOREIGN KEY (fk_profissao) REFERENCES public.profissao(id_profissao);


--
-- TOC entry 3738 (class 2606 OID 16969)
-- Name: associado associado_fk_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_status_fkey FOREIGN KEY (fk_status) REFERENCES public.status_pessoa(id_status);


--
-- TOC entry 3739 (class 2606 OID 16974)
-- Name: associado associado_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 3744 (class 2606 OID 16999)
-- Name: conta_subordinada conta_subordinada_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 3747 (class 2606 OID 17004)
-- Name: dependente dependente_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3748 (class 2606 OID 17009)
-- Name: dependente dependente_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 3749 (class 2606 OID 17014)
-- Name: dependente dependente_fk_parentesco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_parentesco_fkey FOREIGN KEY (fk_parentesco) REFERENCES public.parentesco(id_parentesco);


--
-- TOC entry 3750 (class 2606 OID 17019)
-- Name: doacao doacao_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3751 (class 2606 OID 17024)
-- Name: doacao doacao_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente);


--
-- TOC entry 3752 (class 2606 OID 17029)
-- Name: doacao doacao_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada);


--
-- TOC entry 3753 (class 2606 OID 17034)
-- Name: doacao doacao_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 3754 (class 2606 OID 17039)
-- Name: doacao doacao_fk_tipo_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_tipo_doacao_fkey FOREIGN KEY (fk_tipo_doacao) REFERENCES public.tipo_doacao(id_tipo_doacao);


--
-- TOC entry 3757 (class 2606 OID 17044)
-- Name: documento documento_fk_tipo_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_fk_tipo_documento_fkey FOREIGN KEY (fk_tipo_documento) REFERENCES public.tipo_documento(id_tipo_documento);


--
-- TOC entry 3730 (class 2606 OID 17049)
-- Name: agenda fk_ag_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3731 (class 2606 OID 17054)
-- Name: agenda fk_ag_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3740 (class 2606 OID 17059)
-- Name: associado fk_assoc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3741 (class 2606 OID 17064)
-- Name: associado fk_assoc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3742 (class 2606 OID 17079)
-- Name: conta_regente fk_cr_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3743 (class 2606 OID 17084)
-- Name: conta_regente fk_cr_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3745 (class 2606 OID 17089)
-- Name: conta_subordinada fk_cs_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3746 (class 2606 OID 17094)
-- Name: conta_subordinada fk_cs_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3755 (class 2606 OID 17099)
-- Name: doacao fk_doac_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3756 (class 2606 OID 17104)
-- Name: doacao fk_doac_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3758 (class 2606 OID 17109)
-- Name: documento fk_doc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3759 (class 2606 OID 17114)
-- Name: documento fk_doc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3760 (class 2606 OID 17119)
-- Name: espaco fk_esp_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3761 (class 2606 OID 17124)
-- Name: espaco fk_esp_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3783 (class 2606 OID 17776)
-- Name: lancamento fk_lancamento_parcelamento; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT fk_lancamento_parcelamento FOREIGN KEY (fk_parcelamento) REFERENCES public.parcelamento(id_parcelamento);


--
-- TOC entry 3765 (class 2606 OID 17129)
-- Name: parceiro fk_parc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3766 (class 2606 OID 17134)
-- Name: parceiro fk_parc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3770 (class 2606 OID 17139)
-- Name: reserva_espaco fk_res_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3771 (class 2606 OID 17144)
-- Name: reserva_espaco fk_res_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3762 (class 2606 OID 17149)
-- Name: horario_espaco horario_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE CASCADE;


--
-- TOC entry 3763 (class 2606 OID 17154)
-- Name: item_doacao item_doacao_fk_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_fk_doacao_fkey FOREIGN KEY (fk_doacao) REFERENCES public.doacao(id_doacao) ON DELETE CASCADE;


--
-- TOC entry 3784 (class 2606 OID 17645)
-- Name: lancamento lancamento_atualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_atualizado_por_fkey FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3785 (class 2606 OID 17640)
-- Name: lancamento lancamento_criado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3786 (class 2606 OID 17610)
-- Name: lancamento lancamento_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3787 (class 2606 OID 17615)
-- Name: lancamento lancamento_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 3788 (class 2606 OID 17620)
-- Name: lancamento lancamento_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada) ON DELETE RESTRICT;


--
-- TOC entry 3789 (class 2606 OID 17630)
-- Name: lancamento lancamento_fk_forma_pagamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_forma_pagamento_fkey FOREIGN KEY (fk_forma_pagamento) REFERENCES public.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 3790 (class 2606 OID 17700)
-- Name: lancamento lancamento_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE SET NULL;


--
-- TOC entry 3791 (class 2606 OID 17635)
-- Name: lancamento lancamento_fk_status_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_status_conta_fkey FOREIGN KEY (fk_status_conta) REFERENCES public.status_conta(id_status_conta);


--
-- TOC entry 3792 (class 2606 OID 17625)
-- Name: lancamento lancamento_fk_tipo_lancamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_tipo_lancamento_fkey FOREIGN KEY (fk_tipo_lancamento) REFERENCES public.tipo_lancamento(id_tipo_lancamento);


--
-- TOC entry 3764 (class 2606 OID 17159)
-- Name: log_acesso log_acesso_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 3767 (class 2606 OID 17164)
-- Name: parceiro parceiro_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 3768 (class 2606 OID 17184)
-- Name: permissao_usuario permissao_usuario_fk_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_modulo_fkey FOREIGN KEY (fk_modulo) REFERENCES public.modulo_sistema(id_modulo);


--
-- TOC entry 3769 (class 2606 OID 17189)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 3795 (class 2606 OID 17811)
-- Name: relacionamento_lancamento relacionamento_lancamento_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.relacionamento_lancamento
    ADD CONSTRAINT relacionamento_lancamento_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 3796 (class 2606 OID 17816)
-- Name: relacionamento_lancamento relacionamento_lancamento_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.relacionamento_lancamento
    ADD CONSTRAINT relacionamento_lancamento_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada) ON DELETE RESTRICT;


--
-- TOC entry 3797 (class 2606 OID 17806)
-- Name: relacionamento_lancamento relacionamento_lancamento_fk_tipo_lancamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.relacionamento_lancamento
    ADD CONSTRAINT relacionamento_lancamento_fk_tipo_lancamento_fkey FOREIGN KEY (fk_tipo_lancamento) REFERENCES public.tipo_lancamento(id_tipo_lancamento) ON DELETE RESTRICT;


--
-- TOC entry 3772 (class 2606 OID 17194)
-- Name: reserva_espaco reserva_espaco_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3773 (class 2606 OID 17199)
-- Name: reserva_espaco reserva_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE RESTRICT;


--
-- TOC entry 3774 (class 2606 OID 17204)
-- Name: reserva_espaco reserva_espaco_fk_horario_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_horario_espaco_fkey FOREIGN KEY (fk_horario_espaco) REFERENCES public.horario_espaco(id_horario_espaco) ON DELETE RESTRICT;


--
-- TOC entry 3775 (class 2606 OID 17209)
-- Name: reserva_espaco reserva_espaco_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 3776 (class 2606 OID 17214)
-- Name: reserva_espaco reserva_espaco_fk_status_reserva_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_status_reserva_fkey FOREIGN KEY (fk_status_reserva) REFERENCES public.status_reserva(id_status_reserva);


--
-- TOC entry 3777 (class 2606 OID 17219)
-- Name: telefone telefone_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3778 (class 2606 OID 17563)
-- Name: telefone telefone_fk_tipo_telefone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_tipo_telefone_fkey FOREIGN KEY (fk_tipo_telefone) REFERENCES public.tipo_telefone(id_tipo_telefone);


--
-- TOC entry 3779 (class 2606 OID 17224)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE CASCADE;


--
-- TOC entry 3780 (class 2606 OID 17568)
-- Name: telefone_parceiro telefone_parceiro_fk_tipo_telefone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_tipo_telefone_fkey FOREIGN KEY (fk_tipo_telefone) REFERENCES public.tipo_telefone(id_tipo_telefone);


--
-- TOC entry 3781 (class 2606 OID 17229)
-- Name: usuario usuario_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 3782 (class 2606 OID 17234)
-- Name: usuario usuario_fk_perfil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_perfil_fkey FOREIGN KEY (fk_perfil) REFERENCES public.perfil_usuario(id_perfil);


--
-- TOC entry 2264 (class 826 OID 16391)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON SEQUENCES TO ambc_db_user;


--
-- TOC entry 2266 (class 826 OID 16393)
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TYPES TO ambc_db_user;


--
-- TOC entry 2265 (class 826 OID 16392)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON FUNCTIONS TO ambc_db_user;


--
-- TOC entry 2263 (class 826 OID 16390)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO ambc_db_user;


-- Completed on 2026-05-29 10:04:04

--
-- PostgreSQL database dump complete
--

\unrestrict kCiDgdrMFyd27WfF6B7G8wZw1wu6jGxfEuU6QfjcdUBdBcQ2vsmf68Agc2dLzRh

