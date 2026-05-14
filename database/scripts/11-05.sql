--
-- PostgreSQL database dump
--

\restrict ZSZ6VS6hvjximV0LW9fcFvqMIh0Hrldai7gyFPyD3RUSXUecAZ3P4kH5z4IUSW3

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg12+1)
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-11 10:22:43

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
-- TOC entry 304 (class 1255 OID 16398)
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
-- TOC entry 305 (class 1255 OID 16399)
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
-- TOC entry 306 (class 1255 OID 16400)
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
-- TOC entry 307 (class 1255 OID 16401)
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
-- TOC entry 308 (class 1255 OID 16402)
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
-- TOC entry 309 (class 1255 OID 16403)
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
-- TOC entry 3991 (class 0 OID 0)
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
-- TOC entry 3992 (class 0 OID 0)
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
-- TOC entry 3993 (class 0 OID 0)
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
-- TOC entry 3994 (class 0 OID 0)
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
-- TOC entry 3995 (class 0 OID 0)
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
-- TOC entry 3996 (class 0 OID 0)
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
-- TOC entry 3997 (class 0 OID 0)
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
-- TOC entry 3998 (class 0 OID 0)
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
-- TOC entry 3999 (class 0 OID 0)
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
-- TOC entry 4000 (class 0 OID 0)
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
-- TOC entry 4001 (class 0 OID 0)
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
-- TOC entry 4002 (class 0 OID 0)
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
-- TOC entry 4003 (class 0 OID 0)
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
-- TOC entry 4004 (class 0 OID 0)
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
-- TOC entry 4005 (class 0 OID 0)
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
-- TOC entry 4006 (class 0 OID 0)
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
-- TOC entry 4007 (class 0 OID 0)
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
-- TOC entry 4008 (class 0 OID 0)
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
-- TOC entry 4009 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.parceiro_id_parceiro_seq OWNED BY public.parceiro.id_parceiro;


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
-- TOC entry 4010 (class 0 OID 0)
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
-- TOC entry 4011 (class 0 OID 0)
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
-- TOC entry 4012 (class 0 OID 0)
-- Dependencies: 260
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.permissao_usuario_id_permissao_seq OWNED BY public.permissao_usuario.id_permissao;


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
-- TOC entry 4013 (class 0 OID 0)
-- Dependencies: 262
-- Name: profissao_id_profissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.profissao_id_profissao_seq OWNED BY public.profissao.id_profissao;


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
-- TOC entry 4014 (class 0 OID 0)
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
-- TOC entry 4015 (class 0 OID 0)
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
-- TOC entry 4016 (class 0 OID 0)
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
-- TOC entry 4017 (class 0 OID 0)
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
-- TOC entry 4018 (class 0 OID 0)
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
-- TOC entry 4019 (class 0 OID 0)
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
-- TOC entry 4020 (class 0 OID 0)
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
-- TOC entry 4021 (class 0 OID 0)
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
-- TOC entry 4022 (class 0 OID 0)
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
    descricao character varying(30) NOT NULL
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
-- TOC entry 4023 (class 0 OID 0)
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
-- TOC entry 4024 (class 0 OID 0)
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
-- TOC entry 4025 (class 0 OID 0)
-- Dependencies: 283
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ambc_db_user
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 3421 (class 2604 OID 16740)
-- Name: agenda id_agenda; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda ALTER COLUMN id_agenda SET DEFAULT nextval('public.agenda_id_agenda_seq'::regclass);


--
-- TOC entry 3426 (class 2604 OID 16741)
-- Name: agenda_documento id; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento ALTER COLUMN id SET DEFAULT nextval('public.agenda_documento_id_seq'::regclass);


--
-- TOC entry 3428 (class 2604 OID 16742)
-- Name: associado id_associado; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado ALTER COLUMN id_associado SET DEFAULT nextval('public.associado_id_associado_seq'::regclass);


--
-- TOC entry 3432 (class 2604 OID 16743)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 3433 (class 2604 OID 16745)
-- Name: conta_regente id_conta_regente; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente ALTER COLUMN id_conta_regente SET DEFAULT nextval('public.conta_regente_id_conta_regente_seq'::regclass);


--
-- TOC entry 3438 (class 2604 OID 16746)
-- Name: conta_subordinada id_conta_subordinada; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada ALTER COLUMN id_conta_subordinada SET DEFAULT nextval('public.conta_subordinada_id_conta_subordinada_seq'::regclass);


--
-- TOC entry 3442 (class 2604 OID 16747)
-- Name: dependente id_dependente; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente ALTER COLUMN id_dependente SET DEFAULT nextval('public.dependente_id_dependente_seq'::regclass);


--
-- TOC entry 3446 (class 2604 OID 16748)
-- Name: doacao id_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao ALTER COLUMN id_doacao SET DEFAULT nextval('public.doacao_id_doacao_seq'::regclass);


--
-- TOC entry 3450 (class 2604 OID 16749)
-- Name: documento id_documento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento ALTER COLUMN id_documento SET DEFAULT nextval('public.documento_id_documento_seq'::regclass);


--
-- TOC entry 3457 (class 2604 OID 16750)
-- Name: espaco id_espaco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco ALTER COLUMN id_espaco SET DEFAULT nextval('public.espaco_id_espaco_seq'::regclass);


--
-- TOC entry 3461 (class 2604 OID 16751)
-- Name: estado_civil id_estadocivil; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil ALTER COLUMN id_estadocivil SET DEFAULT nextval('public.estado_civil_id_estadocivil_seq'::regclass);


--
-- TOC entry 3462 (class 2604 OID 16752)
-- Name: forma_pagamento id_forma_pagamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento ALTER COLUMN id_forma_pagamento SET DEFAULT nextval('public.forma_pagamento_id_forma_pagamento_seq'::regclass);


--
-- TOC entry 3463 (class 2604 OID 16753)
-- Name: genero id_genero; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero ALTER COLUMN id_genero SET DEFAULT nextval('public.genero_id_genero_seq'::regclass);


--
-- TOC entry 3464 (class 2604 OID 16754)
-- Name: horario_espaco id_horario_espaco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco ALTER COLUMN id_horario_espaco SET DEFAULT nextval('public.horario_espaco_id_horario_espaco_seq'::regclass);


--
-- TOC entry 3465 (class 2604 OID 16755)
-- Name: item_doacao id_item_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao ALTER COLUMN id_item_doacao SET DEFAULT nextval('public.item_doacao_id_item_doacao_seq'::regclass);


--
-- TOC entry 3501 (class 2604 OID 17593)
-- Name: lancamento id_lancamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento ALTER COLUMN id_lancamento SET DEFAULT nextval('public.lancamento_id_lancamento_seq'::regclass);


--
-- TOC entry 3467 (class 2604 OID 16756)
-- Name: log_acesso id_log; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso ALTER COLUMN id_log SET DEFAULT nextval('public.log_acesso_id_log_seq'::regclass);


--
-- TOC entry 3469 (class 2604 OID 16757)
-- Name: modulo_sistema id_modulo; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema ALTER COLUMN id_modulo SET DEFAULT nextval('public.modulo_sistema_id_modulo_seq'::regclass);


--
-- TOC entry 3470 (class 2604 OID 16758)
-- Name: parceiro id_parceiro; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro ALTER COLUMN id_parceiro SET DEFAULT nextval('public.parceiro_id_parceiro_seq'::regclass);


--
-- TOC entry 3475 (class 2604 OID 16760)
-- Name: parentesco id_parentesco; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco ALTER COLUMN id_parentesco SET DEFAULT nextval('public.parentesco_id_parentesco_seq'::regclass);


--
-- TOC entry 3476 (class 2604 OID 16761)
-- Name: perfil_usuario id_perfil; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario ALTER COLUMN id_perfil SET DEFAULT nextval('public.perfil_usuario_id_perfil_seq'::regclass);


--
-- TOC entry 3477 (class 2604 OID 16762)
-- Name: permissao_usuario id_permissao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario ALTER COLUMN id_permissao SET DEFAULT nextval('public.permissao_usuario_id_permissao_seq'::regclass);


--
-- TOC entry 3480 (class 2604 OID 16763)
-- Name: profissao id_profissao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao ALTER COLUMN id_profissao SET DEFAULT nextval('public.profissao_id_profissao_seq'::regclass);


--
-- TOC entry 3481 (class 2604 OID 16764)
-- Name: reserva_espaco id_reserva; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_espaco_id_reserva_seq'::regclass);


--
-- TOC entry 3485 (class 2604 OID 16765)
-- Name: status_agenda id_status_agenda; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda ALTER COLUMN id_status_agenda SET DEFAULT nextval('public.status_agenda_id_status_agenda_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 16766)
-- Name: status_conta id_status_conta; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta ALTER COLUMN id_status_conta SET DEFAULT nextval('public.status_conta_id_status_conta_seq'::regclass);


--
-- TOC entry 3487 (class 2604 OID 16767)
-- Name: status_pessoa id_status; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa ALTER COLUMN id_status SET DEFAULT nextval('public.status_pessoa_id_status_seq'::regclass);


--
-- TOC entry 3488 (class 2604 OID 16768)
-- Name: status_reserva id_status_reserva; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva ALTER COLUMN id_status_reserva SET DEFAULT nextval('public.status_reserva_id_status_reserva_seq'::regclass);


--
-- TOC entry 3489 (class 2604 OID 16769)
-- Name: telefone id_telefone; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone ALTER COLUMN id_telefone SET DEFAULT nextval('public.telefone_id_telefone_seq'::regclass);


--
-- TOC entry 3490 (class 2604 OID 16770)
-- Name: telefone_parceiro id_telefone_parceiro; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro ALTER COLUMN id_telefone_parceiro SET DEFAULT nextval('public.telefone_parceiro_id_telefone_parceiro_seq'::regclass);


--
-- TOC entry 3491 (class 2604 OID 16771)
-- Name: tipo_doacao id_tipo_doacao; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao ALTER COLUMN id_tipo_doacao SET DEFAULT nextval('public.tipo_doacao_id_tipo_doacao_seq'::regclass);


--
-- TOC entry 3492 (class 2604 OID 16772)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('public.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 3500 (class 2604 OID 17579)
-- Name: tipo_lancamento id_tipo_lancamento; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento ALTER COLUMN id_tipo_lancamento SET DEFAULT nextval('public.tipo_lancamento_id_tipo_lancamento_seq'::regclass);


--
-- TOC entry 3499 (class 2604 OID 17556)
-- Name: tipo_telefone id_tipo_telefone; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone ALTER COLUMN id_tipo_telefone SET DEFAULT nextval('public.tipo_telefone_id_tipo_telefone_seq'::regclass);


--
-- TOC entry 3493 (class 2604 OID 16773)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 3912 (class 0 OID 16404)
-- Dependencies: 219
-- Data for Name: agenda; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.agenda (id_agenda, titulo, descricao, observacao, data_inicio, hora_inicio, data_fim, hora_fim, fk_espaco, fk_status_agenda, fk_associado, fk_parceiro, responsavel_nome, responsavel_telefone, responsavel_email, capacidade_maxima, total_participantes, valor_cobrado, valor_aluguel, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3913 (class 0 OID 16420)
-- Dependencies: 220
-- Data for Name: agenda_documento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.agenda_documento (id, fk_agenda, fk_documento, criado_em) FROM stdin;
\.


--
-- TOC entry 3916 (class 0 OID 16429)
-- Dependencies: 223
-- Data for Name: associado; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.associado (id_associado, nome, data_nascimento, cpf_cnpj, email, observacao, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, fk_estadocivil, fk_profissao, fk_categoria, fk_status, fk_genero, criado_em, criado_por, atualizado_em, atualizado_por, matricula, data_entrada) FROM stdin;
3	Carlos Eduardo Souza	1985-03-12	11122233344	carlos.souza@email.com	\N	t	Rua das Acácias	123	Apto 201	91030010	Califórnia	Porto Alegre	RS	2	4	3	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
4	Maria Aparecida Lima	1972-07-25	22233344455	maria.lima@email.com	\N	t	Av. Bento Gonçalves	456	\N	91500000	Califórnia	Porto Alegre	RS	1	8	1	1	1	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
5	João Pedro Ferreira	1990-11-08	33344455566	joao.ferreira@email.com	\N	t	Rua Pinheiro Machado	789	Casa 2	91040000	Califórnia	Porto Alegre	RS	3	1	3	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
6	Ana Paula Rodrigues	1998-05-30	44455566677	ana.rodrigues@email.com	\N	t	Rua Garibaldi	321	\N	91020000	Califórnia	Porto Alegre	RS	1	9	3	2	1	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
7	Roberto Carlos Mendes	1965-01-19	55566677788	roberto.mendes@email.com	\N	t	Av. Sertório	654	Bloco B	91060000	Califórnia	Porto Alegre	RS	2	7	2	1	2	2026-04-23 22:04:24.009645	\N	2026-04-23 22:04:24.009645	\N	\N	\N
9	Teste Backend 2	1987-11-30	88888888888	teste@teste.com	teste	t	Rua Teste	1		92000000	Bairro	Canoas	RS	2	5	\N	1	\N	2026-05-06 00:00:00	\N	2026-05-07 02:06:20.805445	\N	0001	\N
12	joao alfredo corninho	1987-11-30	99999999999	fabiomachadolopes@hotmail.com	vaiiiiiii	t	Rua Araguaia	760	casa	92410000	Igara	Canoas	RS	2	11	\N	1	\N	2026-05-06 00:00:00	\N	2026-05-07 02:16:49.924711	\N	0002	\N
13	joao alfredo zé	2026-04-01	00000000000	fabiomachadolopes@hotmail.com	testessssss	t	Rua Araguaia	760	casa	92410000	Igara	Canoas	\N	1	1	\N	1	\N	2026-05-07 00:00:00	\N	2026-05-07 21:05:41.762968	\N	0003	\N
14	LEONARDO PEREIRA LEOTE	1999-09-09	35095512015	leonardo.leote0909@gmail.com	\N	t	Rua Barão do Rio Branco	188	\N	92110410	niteroi	Canoas	\N	\N	\N	\N	1	\N	2026-05-10 00:00:00	\N	2026-05-11 01:14:15.557971	\N	0004	\N
15	LEONARDO PEREIRA LEOTE2	1993-12-12	12345678990	leonardo.leote0909@gmail.com	\N	t	Rua Barão do Rio Branco	188	\N	92110410	niteroi	Canoas	\N	\N	\N	\N	1	\N	2026-05-10 00:00:00	\N	2026-05-11 01:24:15.414935	\N	0005	\N
16	LEONARDO PEREIRA LEOTE3	1212-12-12	12312312312	leonardo.leote0909@gmail.com	\N	f	Rua Barão do Rio Branco	188	\N	92110410	niteroi	Canoas	\N	\N	\N	\N	3	\N	2026-05-10 00:00:00	\N	2026-05-11 01:25:11.308639	\N	0006	\N
\.


--
-- TOC entry 3984 (class 0 OID 17658)
-- Dependencies: 291
-- Data for Name: associado_dependente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.associado_dependente (fk_associado, fk_dependente, principal, criado_em, atualizado_em) FROM stdin;
\.


--
-- TOC entry 3918 (class 0 OID 16442)
-- Dependencies: 225
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.categoria (id_categoria, descricao) FROM stdin;
1	Fundador
2	Honorário
3	Contribuinte
\.


--
-- TOC entry 3985 (class 0 OID 17687)
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
-- TOC entry 3920 (class 0 OID 16462)
-- Dependencies: 227
-- Data for Name: conta_regente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.conta_regente (id_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por, tipo, ativo) FROM stdin;
2	Contas Associação	Conta de Água e Luz	2026-05-05 01:11:11.341749	\N	2026-05-06 01:18:52.493255	\N	despesa	t
3	padaria2	pao quentinho	2026-05-05 01:32:31.563715	\N	2026-05-06 12:53:36.750516	\N	despesa	t
1	Receitas Associação	\N	2026-05-05 01:09:58.628197	\N	2026-05-06 12:55:03.155193	\N	receita	t
4	Alvará Associação	Pagamento do alvará de manutenção.	2026-05-06 01:17:34.023771	\N	2026-05-07 22:14:53.692323	\N	despesa	t
\.


--
-- TOC entry 3922 (class 0 OID 16472)
-- Dependencies: 229
-- Data for Name: conta_subordinada; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.conta_subordinada (id_conta_subordinada, fk_conta_regente, descricao, observacao, criado_em, criado_por, atualizado_em, atualizado_por, ativo) FROM stdin;
1	2	Luz	\N	2026-05-05 02:09:03.483125	\N	2026-05-05 02:09:03.483125	\N	t
\.


--
-- TOC entry 3924 (class 0 OID 16483)
-- Dependencies: 231
-- Data for Name: dependente; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.dependente (id_dependente, fk_associado, nome, data_nascimento, cpf, observacao, fk_parentesco, fk_genero, criado_em, atualizado_em, ativo) FROM stdin;
\.


--
-- TOC entry 3926 (class 0 OID 16496)
-- Dependencies: 233
-- Data for Name: doacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.doacao (id_doacao, fk_parceiro, fk_associado, nome_externo, telefone_externo, fk_tipo_doacao, fk_conta_regente, fk_conta_subordinada, descricao, data_doacao, valor_dinheiro, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3928 (class 0 OID 16509)
-- Dependencies: 235
-- Data for Name: documento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.documento (id_documento, numero, ano, fk_tipo_documento, tipo_livre, assunto, data_documento, conteudo, arquivo_path, observacao, criado_em, criado_por, atualizado_em, atualizado_por, categoria, versao) FROM stdin;
\.


--
-- TOC entry 3930 (class 0 OID 16526)
-- Dependencies: 237
-- Data for Name: espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.espaco (id_espaco, nome, descricao, capacidade, observacao, ativo, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3932 (class 0 OID 16537)
-- Dependencies: 239
-- Data for Name: estado_civil; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.estado_civil (id_estadocivil, descricao) FROM stdin;
1	Solteiro(a)
2	Casado(a)
3	Divorciado(a)
4	Viúvo(a)
5	Amasiado(a)
6	só ficando
\.


--
-- TOC entry 3934 (class 0 OID 16543)
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
-- TOC entry 3936 (class 0 OID 16549)
-- Dependencies: 243
-- Data for Name: genero; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.genero (id_genero, descricao) FROM stdin;
1	Feminino
2	Masculino
3	Não binário
4	abube
5	abube2
\.


--
-- TOC entry 3938 (class 0 OID 16555)
-- Dependencies: 245
-- Data for Name: horario_espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.horario_espaco (id_horario_espaco, fk_espaco, dia_semana, hora_inicio, hora_fim, observacao) FROM stdin;
\.


--
-- TOC entry 3940 (class 0 OID 16566)
-- Dependencies: 247
-- Data for Name: item_doacao; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.item_doacao (id_item_doacao, fk_doacao, descricao, quantidade, unidade, observacao, criado_em) FROM stdin;
\.


--
-- TOC entry 3983 (class 0 OID 17590)
-- Dependencies: 290
-- Data for Name: lancamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.lancamento (id_lancamento, fk_associado, fk_conta_regente, fk_conta_subordinada, fk_tipo_lancamento, fk_forma_pagamento, fk_status_conta, descricao, valor, valor_pago, data_lancamento, data_vencimento, data_pagamento, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3942 (class 0 OID 16577)
-- Dependencies: 249
-- Data for Name: log_acesso; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.log_acesso (id_log, fk_usuario, tipo, ip, registrado_em) FROM stdin;
\.


--
-- TOC entry 3944 (class 0 OID 16585)
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
-- TOC entry 3946 (class 0 OID 16591)
-- Dependencies: 253
-- Data for Name: parceiro; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.parceiro (id_parceiro, nome_razao_social, cpf_cnpj, email, ativo, logradouro, numero, complemento, cep, bairro, cidade, uf, criado_em, criado_por, atualizado_em, atualizado_por, tipo_servico, tipo_pessoa) FROM stdin;
\.


--
-- TOC entry 3948 (class 0 OID 16619)
-- Dependencies: 255
-- Data for Name: parentesco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.parentesco (id_parentesco, descricao, observacao) FROM stdin;
1	Filho(a)	\N
2	Enteado(a)	\N
3	Sobrinho(a)	\N
4	Neto(a)	\N
5	Outro	\N
6	Encosto	\N
\.


--
-- TOC entry 3950 (class 0 OID 16627)
-- Dependencies: 257
-- Data for Name: perfil_usuario; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.perfil_usuario (id_perfil, descricao, observacao) FROM stdin;
1	Administrador	Acesso total ao sistema. Gerencia usuários e permissões.
2	Gestor	Acesso operacional configurável pelo administrador.
3	Visualizador	Somente leitura. Módulos visíveis configuráveis pelo administrador.
\.


--
-- TOC entry 3952 (class 0 OID 16635)
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
-- TOC entry 3954 (class 0 OID 16644)
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
-- TOC entry 3956 (class 0 OID 16650)
-- Dependencies: 263
-- Data for Name: reserva_espaco; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.reserva_espaco (id_reserva, fk_espaco, fk_horario_espaco, fk_status_reserva, data_reserva, fk_associado, fk_parceiro, nome_externo, telefone_externo, email_externo, valor_cobrado, observacao, criado_em, criado_por, atualizado_em, atualizado_por) FROM stdin;
\.


--
-- TOC entry 3977 (class 0 OID 17544)
-- Dependencies: 284
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.schema_migrations (versao, aplicada_em) FROM stdin;
015_sincronizar_schema_online	2026-05-09 06:11:41.937685
\.


--
-- TOC entry 3958 (class 0 OID 16665)
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
-- TOC entry 3960 (class 0 OID 16671)
-- Dependencies: 267
-- Data for Name: status_conta; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_conta (id_status_conta, descricao) FROM stdin;
1	Aberto
2	Liquidado
3	Cancelado
\.


--
-- TOC entry 3962 (class 0 OID 16677)
-- Dependencies: 269
-- Data for Name: status_pessoa; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_pessoa (id_status, descricao) FROM stdin;
1	Ativo
2	Pendente
3	Inativo
4	Peste
\.


--
-- TOC entry 3964 (class 0 OID 16683)
-- Dependencies: 271
-- Data for Name: status_reserva; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.status_reserva (id_status_reserva, descricao) FROM stdin;
1	Confirmado
2	Cancelado
3	Concluído
\.


--
-- TOC entry 3966 (class 0 OID 16689)
-- Dependencies: 273
-- Data for Name: telefone; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.telefone (id_telefone, fk_associado, ddd, numero, fk_tipo_telefone, observacao) FROM stdin;
6	3	51	991234567	\N	\N
7	4	51	987654321	\N	\N
8	5	51	993456789	\N	\N
9	6	51	994567890	\N	\N
10	7	51	995678901	\N	\N
\.


--
-- TOC entry 3968 (class 0 OID 16699)
-- Dependencies: 275
-- Data for Name: telefone_parceiro; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.telefone_parceiro (id_telefone_parceiro, fk_parceiro, ddd, numero, fk_tipo_telefone, observacao) FROM stdin;
\.


--
-- TOC entry 3970 (class 0 OID 16709)
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
-- TOC entry 3972 (class 0 OID 16715)
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
-- TOC entry 3981 (class 0 OID 17576)
-- Dependencies: 288
-- Data for Name: tipo_lancamento; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.tipo_lancamento (id_tipo_lancamento, descricao) FROM stdin;
1	Anuidade
2	Mensalidade
3	Doação
4	Multa
5	Outro
\.


--
-- TOC entry 3979 (class 0 OID 17553)
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
-- TOC entry 3974 (class 0 OID 16721)
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
-- TOC entry 3975 (class 0 OID 16726)
-- Dependencies: 282
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: ambc_db_user
--

COPY public.usuario (id_usuario, nome, email, senha_hash, fk_perfil, fk_associado, ativo, primeiro_acesso, ultimo_acesso, token_reset, token_expira_em, criado_em, atualizado_em) FROM stdin;
9	Fabio	fabiomachadolopes@hotmail.com	$2y$10$RtQS/0O3bqT7/xjH0XaAg.SXrcU9TCahTYFDmk5R.J2B5/md.Qof.	1	\N	t	f	2026-05-05 02:00:13.577937	\N	\N	2026-04-27 22:58:57.453115	2026-05-05 02:00:13.577937
12	admin	admin@admin.com	$2y$10$WINMYpdKI7nvRaRvyMHra.g0HYRBgBrmewBRnEGvbNLKp/5BQyRi6	1	\N	t	f	2026-05-10 17:05:24.666152	\N	\N	2026-04-30 01:40:14.336256	2026-05-10 17:05:24.666152
17	fabiolopes	fabiomachado1212@gmail.com	$2y$10$ngNB..SC6KHKMW81SY6w/eHHWVVZzLO1Ty6feVNLuv50Im0kpCpki	1	\N	t	f	2026-05-10 22:16:49.611151	\N	\N	2026-05-02 00:19:40.239912	2026-05-10 22:16:49.611151
18	Mikaela Thais Silva Kichler	mikaelatsk@gmail.com	$2y$10$XTMVRQL4jTAgEaeH9JjRg.bG.xoCMBPurZnrimV2HODKRBo0MwtFK	1	\N	t	f	\N	\N	\N	2026-05-02 00:26:38.464967	2026-05-02 00:26:38.464967
20	adminAMBC	admin@ambc.com	$2y$10$64WUVSRBW1V79YGdPcsozeVxu5.EO/4nB1D7cMm65F8s6fumtWilG	1	\N	t	f	2026-05-11 00:41:54.717487	\N	\N	2026-05-05 02:06:48.185973	2026-05-11 00:41:54.717487
8	Leonardo Pereira Leote	leonardo.leote0909@gmail.com	$2y$10$7mFTe0VtaL8bXpuY8hjaSecyjN3zUQKGdPHlUMbpT2GUMuaeo6dn2	1	\N	t	f	2026-05-11 12:13:08.412635	\N	\N	2026-04-27 22:57:58.284863	2026-05-11 12:13:08.412635
\.


--
-- TOC entry 4026 (class 0 OID 0)
-- Dependencies: 221
-- Name: agenda_documento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.agenda_documento_id_seq', 1, false);


--
-- TOC entry 4027 (class 0 OID 0)
-- Dependencies: 222
-- Name: agenda_id_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.agenda_id_agenda_seq', 1, false);


--
-- TOC entry 4028 (class 0 OID 0)
-- Dependencies: 224
-- Name: associado_id_associado_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.associado_id_associado_seq', 17, false);


--
-- TOC entry 4029 (class 0 OID 0)
-- Dependencies: 226
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 4030 (class 0 OID 0)
-- Dependencies: 228
-- Name: conta_regente_id_conta_regente_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.conta_regente_id_conta_regente_seq', 7, true);


--
-- TOC entry 4031 (class 0 OID 0)
-- Dependencies: 230
-- Name: conta_subordinada_id_conta_subordinada_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.conta_subordinada_id_conta_subordinada_seq', 1, true);


--
-- TOC entry 4032 (class 0 OID 0)
-- Dependencies: 232
-- Name: dependente_id_dependente_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.dependente_id_dependente_seq', 1, false);


--
-- TOC entry 4033 (class 0 OID 0)
-- Dependencies: 234
-- Name: doacao_id_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.doacao_id_doacao_seq', 1, false);


--
-- TOC entry 4034 (class 0 OID 0)
-- Dependencies: 236
-- Name: documento_id_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.documento_id_documento_seq', 1, false);


--
-- TOC entry 4035 (class 0 OID 0)
-- Dependencies: 238
-- Name: espaco_id_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.espaco_id_espaco_seq', 1, false);


--
-- TOC entry 4036 (class 0 OID 0)
-- Dependencies: 240
-- Name: estado_civil_id_estadocivil_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.estado_civil_id_estadocivil_seq', 6, true);


--
-- TOC entry 4037 (class 0 OID 0)
-- Dependencies: 242
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.forma_pagamento_id_forma_pagamento_seq', 1, false);


--
-- TOC entry 4038 (class 0 OID 0)
-- Dependencies: 244
-- Name: genero_id_genero_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.genero_id_genero_seq', 6, true);


--
-- TOC entry 4039 (class 0 OID 0)
-- Dependencies: 246
-- Name: horario_espaco_id_horario_espaco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.horario_espaco_id_horario_espaco_seq', 1, false);


--
-- TOC entry 4040 (class 0 OID 0)
-- Dependencies: 248
-- Name: item_doacao_id_item_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.item_doacao_id_item_doacao_seq', 1, false);


--
-- TOC entry 4041 (class 0 OID 0)
-- Dependencies: 289
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.lancamento_id_lancamento_seq', 1, false);


--
-- TOC entry 4042 (class 0 OID 0)
-- Dependencies: 250
-- Name: log_acesso_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.log_acesso_id_log_seq', 1, false);


--
-- TOC entry 4043 (class 0 OID 0)
-- Dependencies: 252
-- Name: modulo_sistema_id_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.modulo_sistema_id_modulo_seq', 1, false);


--
-- TOC entry 4044 (class 0 OID 0)
-- Dependencies: 254
-- Name: parceiro_id_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.parceiro_id_parceiro_seq', 1, false);


--
-- TOC entry 4045 (class 0 OID 0)
-- Dependencies: 256
-- Name: parentesco_id_parentesco_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.parentesco_id_parentesco_seq', 6, true);


--
-- TOC entry 4046 (class 0 OID 0)
-- Dependencies: 258
-- Name: perfil_usuario_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.perfil_usuario_id_perfil_seq', 1, false);


--
-- TOC entry 4047 (class 0 OID 0)
-- Dependencies: 260
-- Name: permissao_usuario_id_permissao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.permissao_usuario_id_permissao_seq', 136, true);


--
-- TOC entry 4048 (class 0 OID 0)
-- Dependencies: 262
-- Name: profissao_id_profissao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.profissao_id_profissao_seq', 13, true);


--
-- TOC entry 4049 (class 0 OID 0)
-- Dependencies: 264
-- Name: reserva_espaco_id_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.reserva_espaco_id_reserva_seq', 1, false);


--
-- TOC entry 4050 (class 0 OID 0)
-- Dependencies: 266
-- Name: status_agenda_id_status_agenda_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_agenda_id_status_agenda_seq', 1, false);


--
-- TOC entry 4051 (class 0 OID 0)
-- Dependencies: 268
-- Name: status_conta_id_status_conta_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_conta_id_status_conta_seq', 1, false);


--
-- TOC entry 4052 (class 0 OID 0)
-- Dependencies: 270
-- Name: status_pessoa_id_status_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_pessoa_id_status_seq', 4, true);


--
-- TOC entry 4053 (class 0 OID 0)
-- Dependencies: 272
-- Name: status_reserva_id_status_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.status_reserva_id_status_reserva_seq', 1, false);


--
-- TOC entry 4054 (class 0 OID 0)
-- Dependencies: 274
-- Name: telefone_id_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.telefone_id_telefone_seq', 10, true);


--
-- TOC entry 4055 (class 0 OID 0)
-- Dependencies: 276
-- Name: telefone_parceiro_id_telefone_parceiro_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.telefone_parceiro_id_telefone_parceiro_seq', 1, false);


--
-- TOC entry 4056 (class 0 OID 0)
-- Dependencies: 278
-- Name: tipo_doacao_id_tipo_doacao_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_doacao_id_tipo_doacao_seq', 1, false);


--
-- TOC entry 4057 (class 0 OID 0)
-- Dependencies: 280
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_documento_id_tipo_documento_seq', 9, true);


--
-- TOC entry 4058 (class 0 OID 0)
-- Dependencies: 287
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_lancamento_id_tipo_lancamento_seq', 5, true);


--
-- TOC entry 4059 (class 0 OID 0)
-- Dependencies: 285
-- Name: tipo_telefone_id_tipo_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.tipo_telefone_id_tipo_telefone_seq', 5, true);


--
-- TOC entry 4060 (class 0 OID 0)
-- Dependencies: 283
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: ambc_db_user
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 21, true);


--
-- TOC entry 3531 (class 2606 OID 16775)
-- Name: agenda_documento agenda_documento_fk_agenda_fk_documento_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fk_documento_key UNIQUE (fk_agenda, fk_documento);


--
-- TOC entry 3533 (class 2606 OID 16777)
-- Name: agenda_documento agenda_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_pkey PRIMARY KEY (id);


--
-- TOC entry 3528 (class 2606 OID 16779)
-- Name: agenda agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_pkey PRIMARY KEY (id_agenda);


--
-- TOC entry 3535 (class 2606 OID 16781)
-- Name: associado associado_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 3675 (class 2606 OID 17667)
-- Name: associado_dependente associado_dependente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_pkey PRIMARY KEY (fk_associado, fk_dependente);


--
-- TOC entry 3537 (class 2606 OID 17248)
-- Name: associado associado_matricula_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_matricula_key UNIQUE (matricula);


--
-- TOC entry 3539 (class 2606 OID 16783)
-- Name: associado associado_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_pkey PRIMARY KEY (id_associado);


--
-- TOC entry 3542 (class 2606 OID 16785)
-- Name: categoria categoria_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_descricao_key UNIQUE (descricao);


--
-- TOC entry 3544 (class 2606 OID 16787)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 3679 (class 2606 OID 17696)
-- Name: configuracao_sistema configuracao_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.configuracao_sistema
    ADD CONSTRAINT configuracao_sistema_pkey PRIMARY KEY (chave);


--
-- TOC entry 3546 (class 2606 OID 16791)
-- Name: conta_regente conta_regente_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_descricao_key UNIQUE (descricao);


--
-- TOC entry 3548 (class 2606 OID 16793)
-- Name: conta_regente conta_regente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT conta_regente_pkey PRIMARY KEY (id_conta_regente);


--
-- TOC entry 3550 (class 2606 OID 16795)
-- Name: conta_subordinada conta_subordinada_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_pkey PRIMARY KEY (id_conta_subordinada);


--
-- TOC entry 3552 (class 2606 OID 16797)
-- Name: dependente dependente_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_pkey PRIMARY KEY (id_dependente);


--
-- TOC entry 3556 (class 2606 OID 16799)
-- Name: doacao doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_pkey PRIMARY KEY (id_doacao);


--
-- TOC entry 3559 (class 2606 OID 16801)
-- Name: documento documento_numero_ano_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_numero_ano_key UNIQUE (numero, ano);


--
-- TOC entry 3561 (class 2606 OID 16803)
-- Name: documento documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 3564 (class 2606 OID 16805)
-- Name: espaco espaco_nome_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_nome_key UNIQUE (nome);


--
-- TOC entry 3566 (class 2606 OID 16807)
-- Name: espaco espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT espaco_pkey PRIMARY KEY (id_espaco);


--
-- TOC entry 3568 (class 2606 OID 16809)
-- Name: estado_civil estado_civil_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_descricao_key UNIQUE (descricao);


--
-- TOC entry 3570 (class 2606 OID 16811)
-- Name: estado_civil estado_civil_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.estado_civil
    ADD CONSTRAINT estado_civil_pkey PRIMARY KEY (id_estadocivil);


--
-- TOC entry 3572 (class 2606 OID 16813)
-- Name: forma_pagamento forma_pagamento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3574 (class 2606 OID 16815)
-- Name: forma_pagamento forma_pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT forma_pagamento_pkey PRIMARY KEY (id_forma_pagamento);


--
-- TOC entry 3576 (class 2606 OID 16817)
-- Name: genero genero_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_descricao_key UNIQUE (descricao);


--
-- TOC entry 3578 (class 2606 OID 16819)
-- Name: genero genero_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_pkey PRIMARY KEY (id_genero);


--
-- TOC entry 3580 (class 2606 OID 16821)
-- Name: horario_espaco horario_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_pkey PRIMARY KEY (id_horario_espaco);


--
-- TOC entry 3582 (class 2606 OID 16823)
-- Name: item_doacao item_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_pkey PRIMARY KEY (id_item_doacao);


--
-- TOC entry 3673 (class 2606 OID 17609)
-- Name: lancamento lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_pkey PRIMARY KEY (id_lancamento);


--
-- TOC entry 3585 (class 2606 OID 16825)
-- Name: log_acesso log_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_pkey PRIMARY KEY (id_log);


--
-- TOC entry 3587 (class 2606 OID 16827)
-- Name: modulo_sistema modulo_sistema_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_descricao_key UNIQUE (descricao);


--
-- TOC entry 3589 (class 2606 OID 16829)
-- Name: modulo_sistema modulo_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.modulo_sistema
    ADD CONSTRAINT modulo_sistema_pkey PRIMARY KEY (id_modulo);


--
-- TOC entry 3593 (class 2606 OID 16831)
-- Name: parceiro parceiro_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 3595 (class 2606 OID 16833)
-- Name: parceiro parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_pkey PRIMARY KEY (id_parceiro);


--
-- TOC entry 3597 (class 2606 OID 16837)
-- Name: parentesco parentesco_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_descricao_key UNIQUE (descricao);


--
-- TOC entry 3599 (class 2606 OID 16839)
-- Name: parentesco parentesco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_pkey PRIMARY KEY (id_parentesco);


--
-- TOC entry 3601 (class 2606 OID 16841)
-- Name: perfil_usuario perfil_usuario_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_descricao_key UNIQUE (descricao);


--
-- TOC entry 3603 (class 2606 OID 16843)
-- Name: perfil_usuario perfil_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.perfil_usuario
    ADD CONSTRAINT perfil_usuario_pkey PRIMARY KEY (id_perfil);


--
-- TOC entry 3605 (class 2606 OID 16845)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fk_modulo_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fk_modulo_key UNIQUE (fk_usuario, fk_modulo);


--
-- TOC entry 3607 (class 2606 OID 16847)
-- Name: permissao_usuario permissao_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_pkey PRIMARY KEY (id_permissao);


--
-- TOC entry 3609 (class 2606 OID 16849)
-- Name: profissao profissao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_descricao_key UNIQUE (descricao);


--
-- TOC entry 3611 (class 2606 OID 16851)
-- Name: profissao profissao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.profissao
    ADD CONSTRAINT profissao_pkey PRIMARY KEY (id_profissao);


--
-- TOC entry 3614 (class 2606 OID 16853)
-- Name: reserva_espaco reserva_espaco_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_pkey PRIMARY KEY (id_reserva);


--
-- TOC entry 3656 (class 2606 OID 17551)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (versao);


--
-- TOC entry 3616 (class 2606 OID 16855)
-- Name: status_agenda status_agenda_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_descricao_key UNIQUE (descricao);


--
-- TOC entry 3618 (class 2606 OID 16857)
-- Name: status_agenda status_agenda_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_agenda
    ADD CONSTRAINT status_agenda_pkey PRIMARY KEY (id_status_agenda);


--
-- TOC entry 3620 (class 2606 OID 16859)
-- Name: status_conta status_conta_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_descricao_key UNIQUE (descricao);


--
-- TOC entry 3622 (class 2606 OID 16861)
-- Name: status_conta status_conta_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_conta
    ADD CONSTRAINT status_conta_pkey PRIMARY KEY (id_status_conta);


--
-- TOC entry 3624 (class 2606 OID 16863)
-- Name: status_pessoa status_pessoa_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_descricao_key UNIQUE (descricao);


--
-- TOC entry 3626 (class 2606 OID 16865)
-- Name: status_pessoa status_pessoa_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_pessoa
    ADD CONSTRAINT status_pessoa_pkey PRIMARY KEY (id_status);


--
-- TOC entry 3628 (class 2606 OID 16867)
-- Name: status_reserva status_reserva_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_descricao_key UNIQUE (descricao);


--
-- TOC entry 3630 (class 2606 OID 16869)
-- Name: status_reserva status_reserva_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.status_reserva
    ADD CONSTRAINT status_reserva_pkey PRIMARY KEY (id_status_reserva);


--
-- TOC entry 3633 (class 2606 OID 16871)
-- Name: telefone telefone_fk_associado_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_ddd_numero_key UNIQUE (fk_associado, ddd, numero);


--
-- TOC entry 3638 (class 2606 OID 16873)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_ddd_numero_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_ddd_numero_key UNIQUE (fk_parceiro, ddd, numero);


--
-- TOC entry 3640 (class 2606 OID 16875)
-- Name: telefone_parceiro telefone_parceiro_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_pkey PRIMARY KEY (id_telefone_parceiro);


--
-- TOC entry 3635 (class 2606 OID 16877)
-- Name: telefone telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_pkey PRIMARY KEY (id_telefone);


--
-- TOC entry 3642 (class 2606 OID 16879)
-- Name: tipo_doacao tipo_doacao_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_descricao_key UNIQUE (descricao);


--
-- TOC entry 3644 (class 2606 OID 16881)
-- Name: tipo_doacao tipo_doacao_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_doacao
    ADD CONSTRAINT tipo_doacao_pkey PRIMARY KEY (id_tipo_doacao);


--
-- TOC entry 3646 (class 2606 OID 16883)
-- Name: tipo_documento tipo_documento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3648 (class 2606 OID 16885)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 3662 (class 2606 OID 17585)
-- Name: tipo_lancamento tipo_lancamento_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento
    ADD CONSTRAINT tipo_lancamento_descricao_key UNIQUE (descricao);


--
-- TOC entry 3664 (class 2606 OID 17583)
-- Name: tipo_lancamento tipo_lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_lancamento
    ADD CONSTRAINT tipo_lancamento_pkey PRIMARY KEY (id_tipo_lancamento);


--
-- TOC entry 3658 (class 2606 OID 17562)
-- Name: tipo_telefone tipo_telefone_descricao_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone
    ADD CONSTRAINT tipo_telefone_descricao_key UNIQUE (descricao);


--
-- TOC entry 3660 (class 2606 OID 17560)
-- Name: tipo_telefone tipo_telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.tipo_telefone
    ADD CONSTRAINT tipo_telefone_pkey PRIMARY KEY (id_tipo_telefone);


--
-- TOC entry 3650 (class 2606 OID 16887)
-- Name: uf uf_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.uf
    ADD CONSTRAINT uf_pkey PRIMARY KEY (sigla);


--
-- TOC entry 3652 (class 2606 OID 16889)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 3654 (class 2606 OID 16891)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 3529 (class 1259 OID 16892)
-- Name: idx_agenda_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_agenda_data ON public.agenda USING btree (data_inicio);


--
-- TOC entry 3676 (class 1259 OID 17679)
-- Name: idx_assoc_dep_associado; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_assoc_dep_associado ON public.associado_dependente USING btree (fk_associado);


--
-- TOC entry 3677 (class 1259 OID 17680)
-- Name: idx_assoc_dep_dependente; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_assoc_dep_dependente ON public.associado_dependente USING btree (fk_dependente);


--
-- TOC entry 3540 (class 1259 OID 16893)
-- Name: idx_associado_nome; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_associado_nome ON public.associado USING btree (nome);


--
-- TOC entry 3553 (class 1259 OID 17681)
-- Name: idx_dependente_ativo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_dependente_ativo ON public.dependente USING btree (ativo);


--
-- TOC entry 3554 (class 1259 OID 17682)
-- Name: idx_dependente_nascimento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_dependente_nascimento ON public.dependente USING btree (data_nascimento);


--
-- TOC entry 3557 (class 1259 OID 16894)
-- Name: idx_doacao_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_doacao_data ON public.doacao USING btree (data_doacao);


--
-- TOC entry 3562 (class 1259 OID 16895)
-- Name: idx_documento_indice; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_documento_indice ON public.documento USING btree (ano, numero);


--
-- TOC entry 3665 (class 1259 OID 17650)
-- Name: idx_lancamento_associado; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_associado ON public.lancamento USING btree (fk_associado);


--
-- TOC entry 3666 (class 1259 OID 17651)
-- Name: idx_lancamento_conta_regente; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_conta_regente ON public.lancamento USING btree (fk_conta_regente);


--
-- TOC entry 3667 (class 1259 OID 17652)
-- Name: idx_lancamento_conta_subordinada; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_conta_subordinada ON public.lancamento USING btree (fk_conta_subordinada);


--
-- TOC entry 3668 (class 1259 OID 17656)
-- Name: idx_lancamento_data_lancamento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_data_lancamento ON public.lancamento USING btree (data_lancamento);


--
-- TOC entry 3669 (class 1259 OID 17655)
-- Name: idx_lancamento_status; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_status ON public.lancamento USING btree (fk_status_conta);


--
-- TOC entry 3670 (class 1259 OID 17653)
-- Name: idx_lancamento_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_tipo ON public.lancamento USING btree (fk_tipo_lancamento);


--
-- TOC entry 3671 (class 1259 OID 17654)
-- Name: idx_lancamento_vencimento; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_lancamento_vencimento ON public.lancamento USING btree (data_vencimento);


--
-- TOC entry 3583 (class 1259 OID 16896)
-- Name: idx_log_usuario; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_log_usuario ON public.log_acesso USING btree (fk_usuario);


--
-- TOC entry 3590 (class 1259 OID 16897)
-- Name: idx_parceiro_nome; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_parceiro_nome ON public.parceiro USING btree (nome_razao_social);


--
-- TOC entry 3591 (class 1259 OID 17684)
-- Name: idx_parceiro_tipo_pessoa; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_parceiro_tipo_pessoa ON public.parceiro USING btree (tipo_pessoa);


--
-- TOC entry 3612 (class 1259 OID 16899)
-- Name: idx_reserva_data; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_reserva_data ON public.reserva_espaco USING btree (data_reserva);


--
-- TOC entry 3636 (class 1259 OID 17686)
-- Name: idx_telefone_parceiro_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_telefone_parceiro_tipo ON public.telefone_parceiro USING btree (fk_tipo_telefone);


--
-- TOC entry 3631 (class 1259 OID 17685)
-- Name: idx_telefone_tipo; Type: INDEX; Schema: public; Owner: ambc_db_user
--

CREATE INDEX idx_telefone_tipo ON public.telefone USING btree (fk_tipo_telefone);


--
-- TOC entry 3747 (class 2620 OID 16900)
-- Name: agenda trg_conflito_agenda; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_conflito_agenda BEFORE INSERT OR UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_agenda();


--
-- TOC entry 3759 (class 2620 OID 16901)
-- Name: reserva_espaco trg_conflito_reserva; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_conflito_reserva BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_conflito_reserva();


--
-- TOC entry 3749 (class 2620 OID 16902)
-- Name: associado trg_cpf_cnpj_associado; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_cpf_cnpj_associado BEFORE INSERT OR UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 3757 (class 2620 OID 16903)
-- Name: parceiro trg_cpf_cnpj_parceiro; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_cpf_cnpj_parceiro BEFORE INSERT OR UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_validar_cpf_cnpj();


--
-- TOC entry 3748 (class 2620 OID 16904)
-- Name: agenda trg_ts_agenda; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_agenda BEFORE UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3764 (class 2620 OID 17683)
-- Name: associado_dependente trg_ts_assoc_dep; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_assoc_dep BEFORE UPDATE ON public.associado_dependente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3750 (class 2620 OID 16905)
-- Name: associado trg_ts_associado; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_associado BEFORE UPDATE ON public.associado FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3751 (class 2620 OID 16907)
-- Name: conta_regente trg_ts_conta_regente; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_conta_regente BEFORE UPDATE ON public.conta_regente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3752 (class 2620 OID 16908)
-- Name: conta_subordinada trg_ts_conta_sub; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_conta_sub BEFORE UPDATE ON public.conta_subordinada FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3753 (class 2620 OID 16909)
-- Name: dependente trg_ts_dependente; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_dependente BEFORE UPDATE ON public.dependente FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3754 (class 2620 OID 16910)
-- Name: doacao trg_ts_doacao; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_doacao BEFORE UPDATE ON public.doacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3755 (class 2620 OID 16911)
-- Name: documento trg_ts_documento; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_documento BEFORE UPDATE ON public.documento FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3756 (class 2620 OID 16912)
-- Name: espaco trg_ts_espaco; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_espaco BEFORE UPDATE ON public.espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3763 (class 2620 OID 17657)
-- Name: lancamento trg_ts_lancamento; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_lancamento BEFORE UPDATE ON public.lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3758 (class 2620 OID 16913)
-- Name: parceiro trg_ts_parceiro; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_parceiro BEFORE UPDATE ON public.parceiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3760 (class 2620 OID 16915)
-- Name: reserva_espaco trg_ts_reserva; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_reserva BEFORE UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3762 (class 2620 OID 16916)
-- Name: usuario trg_ts_usuario; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_ts_usuario BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_timestamp();


--
-- TOC entry 3761 (class 2620 OID 16917)
-- Name: reserva_espaco trg_validar_horario_espaco; Type: TRIGGER; Schema: public; Owner: ambc_db_user
--

CREATE TRIGGER trg_validar_horario_espaco BEFORE INSERT OR UPDATE ON public.reserva_espaco FOR EACH ROW EXECUTE FUNCTION public.fn_validar_horario_espaco();


--
-- TOC entry 3686 (class 2606 OID 16919)
-- Name: agenda_documento agenda_documento_fk_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_agenda_fkey FOREIGN KEY (fk_agenda) REFERENCES public.agenda(id_agenda) ON DELETE CASCADE;


--
-- TOC entry 3687 (class 2606 OID 16924)
-- Name: agenda_documento agenda_documento_fk_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda_documento
    ADD CONSTRAINT agenda_documento_fk_documento_fkey FOREIGN KEY (fk_documento) REFERENCES public.documento(id_documento) ON DELETE CASCADE;


--
-- TOC entry 3680 (class 2606 OID 16929)
-- Name: agenda agenda_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 3681 (class 2606 OID 16934)
-- Name: agenda agenda_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE SET NULL;


--
-- TOC entry 3682 (class 2606 OID 16939)
-- Name: agenda agenda_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE SET NULL;


--
-- TOC entry 3683 (class 2606 OID 16944)
-- Name: agenda agenda_fk_status_agenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT agenda_fk_status_agenda_fkey FOREIGN KEY (fk_status_agenda) REFERENCES public.status_agenda(id_status_agenda);


--
-- TOC entry 3745 (class 2606 OID 17668)
-- Name: associado_dependente associado_dependente_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3746 (class 2606 OID 17673)
-- Name: associado_dependente associado_dependente_fk_dependente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado_dependente
    ADD CONSTRAINT associado_dependente_fk_dependente_fkey FOREIGN KEY (fk_dependente) REFERENCES public.dependente(id_dependente) ON DELETE CASCADE;


--
-- TOC entry 3688 (class 2606 OID 16949)
-- Name: associado associado_fk_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_categoria_fkey FOREIGN KEY (fk_categoria) REFERENCES public.categoria(id_categoria);


--
-- TOC entry 3689 (class 2606 OID 16954)
-- Name: associado associado_fk_estadocivil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_estadocivil_fkey FOREIGN KEY (fk_estadocivil) REFERENCES public.estado_civil(id_estadocivil);


--
-- TOC entry 3690 (class 2606 OID 16959)
-- Name: associado associado_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 3691 (class 2606 OID 16964)
-- Name: associado associado_fk_profissao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_profissao_fkey FOREIGN KEY (fk_profissao) REFERENCES public.profissao(id_profissao);


--
-- TOC entry 3692 (class 2606 OID 16969)
-- Name: associado associado_fk_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_fk_status_fkey FOREIGN KEY (fk_status) REFERENCES public.status_pessoa(id_status);


--
-- TOC entry 3693 (class 2606 OID 16974)
-- Name: associado associado_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT associado_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 3698 (class 2606 OID 16999)
-- Name: conta_subordinada conta_subordinada_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT conta_subordinada_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 3701 (class 2606 OID 17004)
-- Name: dependente dependente_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3702 (class 2606 OID 17009)
-- Name: dependente dependente_fk_genero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_genero_fkey FOREIGN KEY (fk_genero) REFERENCES public.genero(id_genero);


--
-- TOC entry 3703 (class 2606 OID 17014)
-- Name: dependente dependente_fk_parentesco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.dependente
    ADD CONSTRAINT dependente_fk_parentesco_fkey FOREIGN KEY (fk_parentesco) REFERENCES public.parentesco(id_parentesco);


--
-- TOC entry 3704 (class 2606 OID 17019)
-- Name: doacao doacao_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3705 (class 2606 OID 17024)
-- Name: doacao doacao_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente);


--
-- TOC entry 3706 (class 2606 OID 17029)
-- Name: doacao doacao_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada);


--
-- TOC entry 3707 (class 2606 OID 17034)
-- Name: doacao doacao_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 3708 (class 2606 OID 17039)
-- Name: doacao doacao_fk_tipo_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_fk_tipo_doacao_fkey FOREIGN KEY (fk_tipo_doacao) REFERENCES public.tipo_doacao(id_tipo_doacao);


--
-- TOC entry 3711 (class 2606 OID 17044)
-- Name: documento documento_fk_tipo_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_fk_tipo_documento_fkey FOREIGN KEY (fk_tipo_documento) REFERENCES public.tipo_documento(id_tipo_documento);


--
-- TOC entry 3684 (class 2606 OID 17049)
-- Name: agenda fk_ag_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3685 (class 2606 OID 17054)
-- Name: agenda fk_ag_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_ag_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3694 (class 2606 OID 17059)
-- Name: associado fk_assoc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3695 (class 2606 OID 17064)
-- Name: associado fk_assoc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.associado
    ADD CONSTRAINT fk_assoc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3696 (class 2606 OID 17079)
-- Name: conta_regente fk_cr_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3697 (class 2606 OID 17084)
-- Name: conta_regente fk_cr_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_regente
    ADD CONSTRAINT fk_cr_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3699 (class 2606 OID 17089)
-- Name: conta_subordinada fk_cs_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3700 (class 2606 OID 17094)
-- Name: conta_subordinada fk_cs_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.conta_subordinada
    ADD CONSTRAINT fk_cs_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3709 (class 2606 OID 17099)
-- Name: doacao fk_doac_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3710 (class 2606 OID 17104)
-- Name: doacao fk_doac_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT fk_doac_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3712 (class 2606 OID 17109)
-- Name: documento fk_doc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3713 (class 2606 OID 17114)
-- Name: documento fk_doc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_doc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3714 (class 2606 OID 17119)
-- Name: espaco fk_esp_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3715 (class 2606 OID 17124)
-- Name: espaco fk_esp_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.espaco
    ADD CONSTRAINT fk_esp_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3719 (class 2606 OID 17129)
-- Name: parceiro fk_parc_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3720 (class 2606 OID 17134)
-- Name: parceiro fk_parc_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT fk_parc_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3724 (class 2606 OID 17139)
-- Name: reserva_espaco fk_res_atualizado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3725 (class 2606 OID 17144)
-- Name: reserva_espaco fk_res_criado_por; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT fk_res_criado_por FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3716 (class 2606 OID 17149)
-- Name: horario_espaco horario_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.horario_espaco
    ADD CONSTRAINT horario_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE CASCADE;


--
-- TOC entry 3717 (class 2606 OID 17154)
-- Name: item_doacao item_doacao_fk_doacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.item_doacao
    ADD CONSTRAINT item_doacao_fk_doacao_fkey FOREIGN KEY (fk_doacao) REFERENCES public.doacao(id_doacao) ON DELETE CASCADE;


--
-- TOC entry 3737 (class 2606 OID 17645)
-- Name: lancamento lancamento_atualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_atualizado_por_fkey FOREIGN KEY (atualizado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3738 (class 2606 OID 17640)
-- Name: lancamento lancamento_criado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 3739 (class 2606 OID 17610)
-- Name: lancamento lancamento_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3740 (class 2606 OID 17615)
-- Name: lancamento lancamento_fk_conta_regente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_conta_regente_fkey FOREIGN KEY (fk_conta_regente) REFERENCES public.conta_regente(id_conta_regente) ON DELETE RESTRICT;


--
-- TOC entry 3741 (class 2606 OID 17620)
-- Name: lancamento lancamento_fk_conta_subordinada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_conta_subordinada_fkey FOREIGN KEY (fk_conta_subordinada) REFERENCES public.conta_subordinada(id_conta_subordinada) ON DELETE RESTRICT;


--
-- TOC entry 3742 (class 2606 OID 17630)
-- Name: lancamento lancamento_fk_forma_pagamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_forma_pagamento_fkey FOREIGN KEY (fk_forma_pagamento) REFERENCES public.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 3743 (class 2606 OID 17635)
-- Name: lancamento lancamento_fk_status_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_status_conta_fkey FOREIGN KEY (fk_status_conta) REFERENCES public.status_conta(id_status_conta);


--
-- TOC entry 3744 (class 2606 OID 17625)
-- Name: lancamento lancamento_fk_tipo_lancamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.lancamento
    ADD CONSTRAINT lancamento_fk_tipo_lancamento_fkey FOREIGN KEY (fk_tipo_lancamento) REFERENCES public.tipo_lancamento(id_tipo_lancamento);


--
-- TOC entry 3718 (class 2606 OID 17159)
-- Name: log_acesso log_acesso_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.log_acesso
    ADD CONSTRAINT log_acesso_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 3721 (class 2606 OID 17164)
-- Name: parceiro parceiro_uf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.parceiro
    ADD CONSTRAINT parceiro_uf_fkey FOREIGN KEY (uf) REFERENCES public.uf(sigla);


--
-- TOC entry 3722 (class 2606 OID 17184)
-- Name: permissao_usuario permissao_usuario_fk_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_modulo_fkey FOREIGN KEY (fk_modulo) REFERENCES public.modulo_sistema(id_modulo);


--
-- TOC entry 3723 (class 2606 OID 17189)
-- Name: permissao_usuario permissao_usuario_fk_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.permissao_usuario
    ADD CONSTRAINT permissao_usuario_fk_usuario_fkey FOREIGN KEY (fk_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 3726 (class 2606 OID 17194)
-- Name: reserva_espaco reserva_espaco_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE RESTRICT;


--
-- TOC entry 3727 (class 2606 OID 17199)
-- Name: reserva_espaco reserva_espaco_fk_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_espaco_fkey FOREIGN KEY (fk_espaco) REFERENCES public.espaco(id_espaco) ON DELETE RESTRICT;


--
-- TOC entry 3728 (class 2606 OID 17204)
-- Name: reserva_espaco reserva_espaco_fk_horario_espaco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_horario_espaco_fkey FOREIGN KEY (fk_horario_espaco) REFERENCES public.horario_espaco(id_horario_espaco) ON DELETE RESTRICT;


--
-- TOC entry 3729 (class 2606 OID 17209)
-- Name: reserva_espaco reserva_espaco_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE RESTRICT;


--
-- TOC entry 3730 (class 2606 OID 17214)
-- Name: reserva_espaco reserva_espaco_fk_status_reserva_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.reserva_espaco
    ADD CONSTRAINT reserva_espaco_fk_status_reserva_fkey FOREIGN KEY (fk_status_reserva) REFERENCES public.status_reserva(id_status_reserva);


--
-- TOC entry 3731 (class 2606 OID 17219)
-- Name: telefone telefone_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE CASCADE;


--
-- TOC entry 3732 (class 2606 OID 17563)
-- Name: telefone telefone_fk_tipo_telefone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone
    ADD CONSTRAINT telefone_fk_tipo_telefone_fkey FOREIGN KEY (fk_tipo_telefone) REFERENCES public.tipo_telefone(id_tipo_telefone);


--
-- TOC entry 3733 (class 2606 OID 17224)
-- Name: telefone_parceiro telefone_parceiro_fk_parceiro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_parceiro_fkey FOREIGN KEY (fk_parceiro) REFERENCES public.parceiro(id_parceiro) ON DELETE CASCADE;


--
-- TOC entry 3734 (class 2606 OID 17568)
-- Name: telefone_parceiro telefone_parceiro_fk_tipo_telefone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.telefone_parceiro
    ADD CONSTRAINT telefone_parceiro_fk_tipo_telefone_fkey FOREIGN KEY (fk_tipo_telefone) REFERENCES public.tipo_telefone(id_tipo_telefone);


--
-- TOC entry 3735 (class 2606 OID 17229)
-- Name: usuario usuario_fk_associado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_associado_fkey FOREIGN KEY (fk_associado) REFERENCES public.associado(id_associado) ON DELETE SET NULL;


--
-- TOC entry 3736 (class 2606 OID 17234)
-- Name: usuario usuario_fk_perfil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ambc_db_user
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_fk_perfil_fkey FOREIGN KEY (fk_perfil) REFERENCES public.perfil_usuario(id_perfil);


--
-- TOC entry 2245 (class 826 OID 16391)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON SEQUENCES TO ambc_db_user;


--
-- TOC entry 2247 (class 826 OID 16393)
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TYPES TO ambc_db_user;


--
-- TOC entry 2246 (class 826 OID 16392)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON FUNCTIONS TO ambc_db_user;


--
-- TOC entry 2244 (class 826 OID 16390)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO ambc_db_user;


-- Completed on 2026-05-11 10:23:03

--
-- PostgreSQL database dump complete
--

\unrestrict ZSZ6VS6hvjximV0LW9fcFvqMIh0Hrldai7gyFPyD3RUSXUecAZ3P4kH5z4IUSW3

