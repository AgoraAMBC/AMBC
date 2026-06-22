-- ============================================================
--  BANCO DE DADOS — SISTEMA DE GESTÃO AMBC
--  Versão Final
--  PostgreSQL
--
--  MÓDULOS:
--  1.  Tabelas de domínio
--  2.  Associados, telefones e dependentes
--  3.  Parceiros e telefones
--  4.  Financeiro — mensalidades e doações
--  5.  Reserva de espaço
--  6.  Agenda de atividades
--  7.  Documentação
--  8.  Integração agenda ↔ documento
--  9.  Usuários e permissões
--  10. Triggers e índices
-- ============================================================
 
 
-- ============================================================
--  PARTE 1 — TABELAS DE DOMÍNIO
-- ============================================================
 
CREATE TABLE genero (
    id_genero   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO genero (id_genero, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Feminino'),
    (2, 'Masculino'),
    (3, 'Não binário');
 
 
CREATE TABLE estado_civil (
    id_estadocivil  SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO estado_civil (id_estadocivil, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Solteiro(a)'),
    (2, 'Casado(a)'),
    (3, 'Divorciado(a)'),
    (4, 'Viúvo(a)'),
    (5, 'Amasiado(a)');
 
 
CREATE TABLE categoria (
    id_categoria    SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO categoria (id_categoria, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Fundador'),
    (2, 'Honorário'),
    (3, 'Contribuinte');
 
 
CREATE TABLE status_pessoa (
    id_status   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_pessoa (id_status, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Ativo'),
    (2, 'Pendente'),
    (3, 'Inativo');
 
 
CREATE TABLE profissao (
    id_profissao    SERIAL      PRIMARY KEY,
    descricao       VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO profissao (id_profissao, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1,  'Autônomo formal'),
    (2,  'Autônomo informal'),
    (3,  'Empregado informal'),
    (4,  'Empregado formal'),
    (5,  'Trabalhador doméstico'),
    (6,  'Trabalhador rural'),
    (7,  'Servidor público'),
    (8,  'Aposentado/Pensionista'),
    (9,  'Estudante'),
    (10, 'Estagiário'),
    (11, 'Não trabalha'),
    (12, 'Outro');
 
 
CREATE TABLE parentesco (
    id_parentesco   SERIAL      PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE,
    observacao      TEXT
);
INSERT INTO parentesco (id_parentesco, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Filho(a)'),
    (2, 'Enteado(a)'),
    (3, 'Sobrinho(a)'),
    (4, 'Neto(a)'),
    (5, 'Outro');
 
 
CREATE TABLE uf (
    sigla   CHAR(2)     PRIMARY KEY,
    nome    VARCHAR(30) NOT NULL
);
INSERT INTO uf (sigla, nome) VALUES
    ('AC','Acre'),('AL','Alagoas'),('AP','Amapá'),('AM','Amazonas'),
    ('BA','Bahia'),('CE','Ceará'),('DF','Distrito Federal'),('ES','Espírito Santo'),
    ('GO','Goiás'),('MA','Maranhão'),('MT','Mato Grosso'),('MS','Mato Grosso do Sul'),
    ('MG','Minas Gerais'),('PA','Pará'),('PB','Paraíba'),('PR','Paraná'),
    ('PE','Pernambuco'),('PI','Piauí'),('RJ','Rio de Janeiro'),('RN','Rio Grande do Norte'),
    ('RS','Rio Grande do Sul'),('RO','Rondônia'),('RR','Roraima'),('SC','Santa Catarina'),
    ('SP','São Paulo'),('SE','Sergipe'),('TO','Tocantins');
 
 
CREATE TABLE forma_pagamento (
    id_forma_pagamento  SERIAL      PRIMARY KEY,
    descricao           VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO forma_pagamento (id_forma_pagamento, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'PIX'),
    (2, 'Boleto'),
    (3, 'Cartão de crédito'),
    (4, 'Cartão de débito'),
    (5, 'Dinheiro'),
    (6, 'Transferência bancária');
 
 
CREATE TABLE status_conta (
    id_status_conta SERIAL      PRIMARY KEY,
    descricao       VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_conta (id_status_conta, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Aberto'),
    (2, 'Liquidado'),
    (3, 'Cancelado');
 
 
CREATE TABLE tipo_doacao (
    id_tipo_doacao  SERIAL      PRIMARY KEY,
    descricao       VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO tipo_doacao (id_tipo_doacao, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Dinheiro'),
    (2, 'Alimentos e bebidas'),
    (3, 'Brinquedos'),
    (4, 'Outros itens');
 
 
CREATE TABLE status_reserva (
    id_status_reserva   SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_reserva (id_status_reserva, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Confirmado'),
    (2, 'Cancelado'),
    (3, 'Concluído');
 
 
CREATE TABLE status_agenda (
    id_status_agenda    SERIAL      PRIMARY KEY,
    descricao           VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO status_agenda (id_status_agenda, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Agendado'),
    (2, 'Cancelado'),
    (3, 'Concluído'),
    (4, 'Suspenso');
 
 
CREATE TABLE tipo_documento (
    id_tipo_documento   SERIAL      PRIMARY KEY,
    descricao           VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO tipo_documento (id_tipo_documento, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Ata'),
    (2, 'Ofício'),
    (3, 'Mensagem'),
    (4, 'Circular'),
    (5, 'Requerimento'),
    (6, 'Declaração'),
    (7, 'Outro');
 
 
CREATE TABLE perfil_usuario (
    id_perfil   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE,
    observacao  TEXT
);
INSERT INTO perfil_usuario (id_perfil, descricao, observacao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Administrador',   'Presidente e Vice. Acesso total ao sistema, incluindo usuários e configurações.'),
    (2, 'Operacional',    'Secretários. Acesso ao cadastro de associados e gestão operacional.'),
    (3, 'Conselho Fiscal','Apenas leitura. Acesso para visualização e fiscalização das informações.'),
    (4, 'Financeiro',     'Tesoureiros. Acesso ao módulo financeiro e relatórios.');
 
 
CREATE TABLE modulo_sistema (
    id_modulo   SERIAL      PRIMARY KEY,
    descricao   VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO modulo_sistema (id_modulo, descricao) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Dashboard'),
    (2, 'Associados'),
    (3, 'Parceiros'),
    (4, 'Financeiro'),
    (5, 'Reserva de Espaço'),
    (6, 'Agenda'),
    (7, 'Documentação'),
    (8, 'Usuários e Permissões');
 
 
-- ============================================================
--  PARTE 2 — ASSOCIADOS
-- ============================================================
 
CREATE TABLE associado (
    id_associado        SERIAL          PRIMARY KEY,
 
    -- Obrigatórios: nome composto + data de nascimento
    nome                VARCHAR(150)    NOT NULL,
    data_nascimento     DATE            NOT NULL,
 
    -- Nome composto obrigatório (mínimo dois nomes)
    CONSTRAINT chk_associado_nome_composto CHECK (
        TRIM(nome) LIKE '% %'
    ),
 
    cpf_cnpj            VARCHAR(14)     UNIQUE,    -- opcional, PHP valida 11 ou 14 dígitos
    email               VARCHAR(150),
    observacao          TEXT,
 
    -- Soft delete
    ativo               BOOLEAN         DEFAULT TRUE,
 
    -- Endereço
    logradouro          VARCHAR(200),
    numero              VARCHAR(10),
    complemento         VARCHAR(100),
    cep                 CHAR(8),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    uf                  CHAR(2)         REFERENCES uf(sigla),
 
    -- Chaves estrangeiras
    fk_estadocivil      INT             REFERENCES estado_civil(id_estadocivil),
    fk_profissao        INT             REFERENCES profissao(id_profissao),
    fk_categoria        INT             REFERENCES categoria(id_categoria),
    fk_status           INT             REFERENCES status_pessoa(id_status),
    fk_genero           INT             REFERENCES genero(id_genero),
 
    -- Auditoria
    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,            -- FK para usuario (definida após criar usuario)
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT             -- FK para usuario (definida após criar usuario)
);
 
 
CREATE TABLE telefone (
    id_telefone     SERIAL      PRIMARY KEY,
    fk_associado    INT         NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
    ddd             CHAR(2)     NOT NULL,
    numero          VARCHAR(9)  NOT NULL,
 
    -- Só números
    CONSTRAINT chk_telefone_numero CHECK (numero ~ '^[0-9]+$'),
    CONSTRAINT chk_telefone_ddd    CHECK (ddd ~ '^[0-9]+$'),
 
    -- Mesmo associado não cadastra o mesmo número duas vezes
    UNIQUE (fk_associado, ddd, numero)
);
 
 
CREATE TABLE dependente (
    id_dependente       SERIAL          PRIMARY KEY,
    fk_associado        INT             NOT NULL REFERENCES associado(id_associado) ON DELETE CASCADE,
 
    -- Obrigatórios: nome composto + data de nascimento
    nome                VARCHAR(150)    NOT NULL,
    data_nascimento     DATE            NOT NULL,
 
    CONSTRAINT chk_dependente_nome_composto CHECK (
        TRIM(nome) LIKE '% %'
    ),
 
    cpf                 CHAR(11),
    observacao          TEXT,
 
    fk_parentesco       INT             REFERENCES parentesco(id_parentesco),
    fk_genero           INT             REFERENCES genero(id_genero),
 
    criado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_em       TIMESTAMP       DEFAULT NOW()
);
 
 
-- ============================================================
--  PARTE 3 — PARCEIROS
-- ============================================================
 
CREATE TABLE parceiro (
    id_parceiro         SERIAL          PRIMARY KEY,
 
    -- Obrigatórios: nome composto + CPF/CNPJ
    nome_razao_social   VARCHAR(200)    NOT NULL,
    cpf_cnpj            VARCHAR(14)     NOT NULL UNIQUE,
 
    CONSTRAINT chk_parceiro_nome_composto CHECK (
        TRIM(nome_razao_social) LIKE '% %'
    ),
 
    email               VARCHAR(150),
 
    -- Soft delete
    ativo               BOOLEAN         DEFAULT TRUE,
 
    -- Endereço
    logradouro          VARCHAR(200),
    numero              VARCHAR(10),
    complemento         VARCHAR(100),
    cep                 CHAR(8),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    uf                  CHAR(2)         REFERENCES uf(sigla),
 
    -- Auditoria
    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT
);
 
 
CREATE TABLE telefone_parceiro (
    id_telefone_parceiro    SERIAL      PRIMARY KEY,
    fk_parceiro             INT         NOT NULL REFERENCES parceiro(id_parceiro) ON DELETE CASCADE,
    ddd                     CHAR(2)     NOT NULL,
    numero                  VARCHAR(9)  NOT NULL,
 
    CONSTRAINT chk_tel_parceiro_numero CHECK (numero ~ '^[0-9]+$'),
    CONSTRAINT chk_tel_parceiro_ddd    CHECK (ddd ~ '^[0-9]+$'),
 
    UNIQUE (fk_parceiro, ddd, numero)
);
 
 
-- ============================================================
--  PARTE 4 — MÓDULO FINANCEIRO
-- ============================================================
 
CREATE TABLE conta_regente (
    id_conta_regente    SERIAL          PRIMARY KEY,
    descricao           VARCHAR(100)    NOT NULL UNIQUE,
    observacao          TEXT,
    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT
);
 
 
CREATE TABLE conta_subordinada (
    id_conta_subordinada    SERIAL          PRIMARY KEY,
    fk_conta_regente        INT             NOT NULL REFERENCES conta_regente(id_conta_regente)
                                            ON DELETE RESTRICT,
    descricao               VARCHAR(100)    NOT NULL,
    observacao              TEXT,
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);
 
 
CREATE TABLE conta (
    id_conta                SERIAL          PRIMARY KEY,
 
    fk_associado            INT             NOT NULL REFERENCES associado(id_associado)
                                            ON DELETE RESTRICT,
    fk_conta_regente        INT             REFERENCES conta_regente(id_conta_regente)
                                            ON DELETE RESTRICT,
    fk_conta_subordinada    INT             REFERENCES conta_subordinada(id_conta_subordinada)
                                            ON DELETE RESTRICT,
    fk_status_conta         INT             NOT NULL REFERENCES status_conta(id_status_conta),
 
    descricao               VARCHAR(200),
    valor_total             NUMERIC(10,2)   NOT NULL,
    data_lancamento         DATE            NOT NULL DEFAULT CURRENT_DATE,
    observacao              TEXT,
 
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);
 
 
CREATE TABLE parcela (
    id_parcela              SERIAL          PRIMARY KEY,
 
    fk_conta                INT             NOT NULL REFERENCES conta(id_conta)
                                            ON DELETE RESTRICT,
    fk_status_conta         INT             NOT NULL REFERENCES status_conta(id_status_conta),
    fk_forma_pagamento      INT             REFERENCES forma_pagamento(id_forma_pagamento),
 
    numero_parcela          INT             NOT NULL,
    total_parcelas          INT             NOT NULL,
    valor                   NUMERIC(10,2)   NOT NULL,
    data_vencimento         DATE            NOT NULL,
    data_pagamento          DATE,
    valor_pago              NUMERIC(10,2),
    observacao              TEXT,
 
    criado_em               TIMESTAMP       DEFAULT NOW(),
    atualizado_em           TIMESTAMP       DEFAULT NOW()
);
 
 
CREATE TABLE doacao (
    id_doacao               SERIAL          PRIMARY KEY,
 
    -- Pelo menos um dos três obrigatório
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro)
                                            ON DELETE RESTRICT,
    fk_associado            INT             REFERENCES associado(id_associado)
                                            ON DELETE RESTRICT,
    nome_externo            VARCHAR(150),   -- doador não cadastrado
    telefone_externo        VARCHAR(11),
 
    CONSTRAINT chk_doacao_doador CHECK (
        fk_parceiro  IS NOT NULL OR
        fk_associado IS NOT NULL OR
        nome_externo IS NOT NULL
    ),
 
    fk_tipo_doacao          INT             NOT NULL REFERENCES tipo_doacao(id_tipo_doacao),
    fk_conta_regente        INT             REFERENCES conta_regente(id_conta_regente),
    fk_conta_subordinada    INT             REFERENCES conta_subordinada(id_conta_subordinada),
 
    descricao               VARCHAR(200),
    data_doacao             DATE            NOT NULL DEFAULT CURRENT_DATE,
    valor_dinheiro          NUMERIC(10,2),
    observacao              TEXT,
 
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);
 
 
CREATE TABLE item_doacao (
    id_item_doacao  SERIAL          PRIMARY KEY,
    fk_doacao       INT             NOT NULL REFERENCES doacao(id_doacao) ON DELETE CASCADE,
    descricao       VARCHAR(200)    NOT NULL,
    quantidade      NUMERIC(10,2)   NOT NULL,
    unidade         VARCHAR(20),
    observacao      TEXT,
    criado_em       TIMESTAMP       DEFAULT NOW()
);
 
 
-- ============================================================
--  PARTE 5 — RESERVA DE ESPAÇO
-- ============================================================
 
CREATE TABLE espaco (
    id_espaco       SERIAL          PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL UNIQUE,
    descricao       TEXT,
    capacidade      INT,
    observacao      TEXT,
    ativo           BOOLEAN         DEFAULT TRUE,
    criado_em       TIMESTAMP       DEFAULT NOW(),
    criado_por      INT,
    atualizado_em   TIMESTAMP       DEFAULT NOW(),
    atualizado_por  INT
);
 
 
CREATE TABLE horario_espaco (
    id_horario_espaco   SERIAL          PRIMARY KEY,
    fk_espaco           INT             NOT NULL REFERENCES espaco(id_espaco) ON DELETE CASCADE,
    dia_semana          VARCHAR(15)     NOT NULL,
    hora_inicio         TIME            NOT NULL,
    hora_fim            TIME            NOT NULL,
    observacao          TEXT
);
 
 
CREATE TABLE reserva_espaco (
    id_reserva              SERIAL          PRIMARY KEY,
 
    fk_espaco               INT             NOT NULL REFERENCES espaco(id_espaco)
                                            ON DELETE RESTRICT,
    fk_horario_espaco       INT             NOT NULL REFERENCES horario_espaco(id_horario_espaco)
                                            ON DELETE RESTRICT,
    fk_status_reserva       INT             NOT NULL REFERENCES status_reserva(id_status_reserva)
                                            DEFAULT 1,
 
    data_reserva            DATE            NOT NULL,
 
    -- Exatamente um responsável
    fk_associado            INT             REFERENCES associado(id_associado)
                                            ON DELETE RESTRICT,
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro)
                                            ON DELETE RESTRICT,
    nome_externo            VARCHAR(150),
    telefone_externo        VARCHAR(11),
    email_externo           VARCHAR(150),
 
    CONSTRAINT chk_reserva_responsavel CHECK (
        (fk_associado IS NOT NULL AND fk_parceiro IS NULL     AND nome_externo IS NULL) OR
        (fk_parceiro  IS NOT NULL AND fk_associado IS NULL    AND nome_externo IS NULL) OR
        (nome_externo IS NOT NULL AND fk_associado IS NULL    AND fk_parceiro IS NULL)
    ),
 
    valor_cobrado           NUMERIC(10,2),
    observacao              TEXT,
 
    -- Auditoria
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);
 
 
-- ============================================================
--  PARTE 6 — AGENDA DE ATIVIDADES
-- ============================================================
 
CREATE TABLE agenda (
    id_agenda               SERIAL          PRIMARY KEY,
 
    titulo                  VARCHAR(150)    NOT NULL,
    descricao               TEXT,
    observacao              TEXT,
 
    data_inicio             DATE            NOT NULL,
    hora_inicio             TIME            NOT NULL,
    data_fim                DATE,
    hora_fim                TIME            NOT NULL,   -- obrigatório para evitar bug no trigger
 
    -- Espaço físico opcional
    fk_espaco               INT             REFERENCES espaco(id_espaco) ON DELETE SET NULL,
 
    fk_status_agenda        INT             NOT NULL REFERENCES status_agenda(id_status_agenda)
                                            DEFAULT 1,
 
    -- Responsável — associado, parceiro ou externo
    -- Não permite dois cadastrados ao mesmo tempo
    fk_associado            INT             REFERENCES associado(id_associado) ON DELETE SET NULL,
    fk_parceiro             INT             REFERENCES parceiro(id_parceiro) ON DELETE SET NULL,
    responsavel_nome        VARCHAR(150),
    responsavel_telefone    VARCHAR(11),
    responsavel_email       VARCHAR(150),
 
    CONSTRAINT chk_agenda_responsavel CHECK (
        NOT (fk_associado IS NOT NULL AND fk_parceiro IS NOT NULL)
    ),
 
    -- Participantes — opcionais
    capacidade_maxima       INT,            -- limitador — NULL = sem limite
    total_participantes     INT DEFAULT 0,  -- contador atualizado pelo sistema
 
    -- Financeiro opcional
    valor_cobrado           NUMERIC(10,2),
    valor_aluguel           NUMERIC(10,2),
 
    -- Auditoria
    criado_em               TIMESTAMP       DEFAULT NOW(),
    criado_por              INT,
    atualizado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_por          INT
);
 
 
-- ============================================================
--  PARTE 7 — DOCUMENTAÇÃO
--  Criada antes de agenda_documento
-- ============================================================
 
CREATE TABLE documento (
    id_documento        SERIAL          PRIMARY KEY,
 
    -- Índice totalmente automático — PHP busca próximo número:
    -- SELECT COALESCE(MAX(numero),0)+1 FROM documento WHERE ano=EXTRACT(YEAR FROM NOW())
    numero              INT             NOT NULL,
    ano                 INT             NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    indice              VARCHAR(20)     GENERATED ALWAYS AS
                        (LPAD(numero::TEXT, 3, '0') || '/' || ano::TEXT) STORED,
 
    -- Exatamente um tipo obrigatório — lista fixa OU livre
    fk_tipo_documento   INT             REFERENCES tipo_documento(id_tipo_documento),
    tipo_livre          VARCHAR(50),
 
    CONSTRAINT chk_documento_tipo CHECK (
        (fk_tipo_documento IS NOT NULL AND tipo_livre IS NULL) OR
        (fk_tipo_documento IS NULL     AND tipo_livre IS NOT NULL)
    ),
 
    assunto             VARCHAR(200)    NOT NULL,
    data_documento      DATE            NOT NULL DEFAULT CURRENT_DATE,
 
    -- Conteúdo — escrito no sistema OU arquivo anexado
    conteudo            TEXT,
    arquivo_path        VARCHAR(500),
 
    observacao          TEXT,
 
    -- Auditoria
    criado_em           TIMESTAMP       DEFAULT NOW(),
    criado_por          INT,
    atualizado_em       TIMESTAMP       DEFAULT NOW(),
    atualizado_por      INT,
 
    UNIQUE (numero, ano)
);
 
 
-- ============================================================
--  PARTE 8 — INTEGRAÇÃO AGENDA ↔ DOCUMENTO
--  Criada depois de agenda e documento
-- ============================================================
 
CREATE TABLE agenda_documento (
    id              SERIAL      PRIMARY KEY,
    fk_agenda       INT         NOT NULL REFERENCES agenda(id_agenda)    ON DELETE CASCADE,
    fk_documento    INT         NOT NULL REFERENCES documento(id_documento) ON DELETE CASCADE,
    criado_em       TIMESTAMP   DEFAULT NOW(),
    UNIQUE (fk_agenda, fk_documento)
);
 
 
-- ============================================================
--  PARTE 9 — USUÁRIOS E PERMISSÕES
-- ============================================================
 
CREATE TABLE usuario (
    id_usuario          SERIAL          PRIMARY KEY,
 
    nome                VARCHAR(150)    NOT NULL,
    email               VARCHAR(150)    NOT NULL UNIQUE,
    senha_hash          VARCHAR(255),               -- NULL até primeiro acesso
 
    fk_perfil           INT             NOT NULL REFERENCES perfil_usuario(id_perfil),
    fk_associado        INT             REFERENCES associado(id_associado) ON DELETE SET NULL,
 
    -- Soft delete
    ativo               BOOLEAN         DEFAULT TRUE,
    primeiro_acesso     BOOLEAN         DEFAULT TRUE,
    ultimo_acesso       TIMESTAMP,
 
    -- Recuperação de senha
    token_reset         VARCHAR(255),
    token_expira_em     TIMESTAMP,
 
    criado_em           TIMESTAMP       DEFAULT NOW(),
    atualizado_em       TIMESTAMP       DEFAULT NOW()
);
 
 
-- FKs de auditoria — definidas aqui pois usuario só existe agora
ALTER TABLE associado       ADD CONSTRAINT fk_assoc_criado_por     FOREIGN KEY (criado_por)      REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE associado       ADD CONSTRAINT fk_assoc_atualizado_por FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE parceiro        ADD CONSTRAINT fk_parc_criado_por      FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE parceiro        ADD CONSTRAINT fk_parc_atualizado_por  FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_regente   ADD CONSTRAINT fk_cr_criado_por        FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_regente   ADD CONSTRAINT fk_cr_atualizado_por    FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_subordinada ADD CONSTRAINT fk_cs_criado_por      FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta_subordinada ADD CONSTRAINT fk_cs_atualizado_por  FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta           ADD CONSTRAINT fk_conta_criado_por     FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE conta           ADD CONSTRAINT fk_conta_atualizado_por FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE doacao          ADD CONSTRAINT fk_doac_criado_por      FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE doacao          ADD CONSTRAINT fk_doac_atualizado_por  FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE espaco          ADD CONSTRAINT fk_esp_criado_por       FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE espaco          ADD CONSTRAINT fk_esp_atualizado_por   FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE reserva_espaco  ADD CONSTRAINT fk_res_criado_por       FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE reserva_espaco  ADD CONSTRAINT fk_res_atualizado_por   FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE agenda          ADD CONSTRAINT fk_ag_criado_por        FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE agenda          ADD CONSTRAINT fk_ag_atualizado_por    FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE documento       ADD CONSTRAINT fk_doc_criado_por       FOREIGN KEY (criado_por)       REFERENCES usuario(id_usuario) ON DELETE SET NULL;
ALTER TABLE documento       ADD CONSTRAINT fk_doc_atualizado_por   FOREIGN KEY (atualizado_por)   REFERENCES usuario(id_usuario) ON DELETE SET NULL;
 
 
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
    tipo            VARCHAR(10) NOT NULL,   -- 'login' ou 'logout'
    ip              VARCHAR(45),
    registrado_em   TIMESTAMP   DEFAULT NOW()
);
 
 
-- ============================================================
--  PARTE 10 — TRIGGERS E ÍNDICES
-- ============================================================
 
 
-- ----------------------------------------------------------
--  TRIGGER 1 — Valida CPF/CNPJ
--  Aceita apenas 11 dígitos (CPF) ou 14 dígitos (CNPJ)
--  A validação do dígito verificador é responsabilidade do PHP
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_validar_cpf_cnpj()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_cpf_cnpj_associado
    BEFORE INSERT OR UPDATE ON associado
    FOR EACH ROW EXECUTE FUNCTION fn_validar_cpf_cnpj();
 
CREATE TRIGGER trg_cpf_cnpj_parceiro
    BEFORE INSERT OR UPDATE ON parceiro
    FOR EACH ROW EXECUTE FUNCTION fn_validar_cpf_cnpj();
 
 
-- ----------------------------------------------------------
--  TRIGGER 2 — Valida soma das parcelas
--  Garante que a soma não ultrapasse o valor total da conta
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_validar_parcelas()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_validar_parcelas
    BEFORE INSERT OR UPDATE ON parcela
    FOR EACH ROW EXECUTE FUNCTION fn_validar_parcelas();
 
 
-- ----------------------------------------------------------
--  TRIGGER 3 — Valida que horário pertence ao espaço reservado
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_validar_horario_espaco()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_validar_horario_espaco
    BEFORE INSERT OR UPDATE ON reserva_espaco
    FOR EACH ROW EXECUTE FUNCTION fn_validar_horario_espaco();
 
 
-- ----------------------------------------------------------
--  TRIGGER 4 — Impede conflito de reserva de espaço
--  Considera horário — não bloqueia o dia inteiro
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_conflito_reserva()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_conflito_reserva
    BEFORE INSERT OR UPDATE ON reserva_espaco
    FOR EACH ROW EXECUTE FUNCTION fn_conflito_reserva();
 
 
-- ----------------------------------------------------------
--  TRIGGER 5 — Impede conflito de agenda com reserva de espaço
--  Considera horário — não bloqueia o dia inteiro
-- ----------------------------------------------------------
 
CREATE OR REPLACE FUNCTION fn_conflito_agenda()
RETURNS TRIGGER AS $$
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
 
CREATE TRIGGER trg_ts_associado        BEFORE UPDATE ON associado        FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_parceiro         BEFORE UPDATE ON parceiro         FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_dependente       BEFORE UPDATE ON dependente       FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta            BEFORE UPDATE ON conta            FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_parcela          BEFORE UPDATE ON parcela          FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_doacao           BEFORE UPDATE ON doacao           FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_espaco           BEFORE UPDATE ON espaco           FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_reserva          BEFORE UPDATE ON reserva_espaco   FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_agenda           BEFORE UPDATE ON agenda           FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_documento        BEFORE UPDATE ON documento        FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_usuario          BEFORE UPDATE ON usuario          FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta_regente    BEFORE UPDATE ON conta_regente    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
CREATE TRIGGER trg_ts_conta_sub        BEFORE UPDATE ON conta_subordinada FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();
 
 
-- ----------------------------------------------------------
--  ÍNDICES DE PERFORMANCE
-- ----------------------------------------------------------
 
CREATE INDEX idx_reserva_data       ON reserva_espaco(data_reserva);
CREATE INDEX idx_agenda_data        ON agenda(data_inicio);
CREATE INDEX idx_parcela_conta      ON parcela(fk_conta);
CREATE INDEX idx_doacao_data        ON doacao(data_doacao);
CREATE INDEX idx_associado_nome     ON associado(nome);
CREATE INDEX idx_parceiro_nome      ON parceiro(nome_razao_social);
CREATE INDEX idx_documento_indice   ON documento(ano, numero);
CREATE INDEX idx_log_usuario        ON log_acesso(fk_usuario);