-- ============================================================
--  SEED DEV 010 — DOCUMENTOS
--  Cobre: escrito no sistema, arquivo anexado,
--  tipo da lista, tipo livre, todos os tipos disponíveis
-- ============================================================

INSERT INTO documento (
    numero, ano,
    fk_tipo_documento, tipo_livre,
    assunto, data_documento,
    conteudo, arquivo_path,
    observacao
) VALUES

-- Ata escrita no sistema
(1, 2024,
 1, NULL,
 'Ata da Assembleia Geral Ordinária de Janeiro 2024',
 '2024-01-15',
 'Aos quinze dias do mês de janeiro de dois mil e vinte e quatro, reuniram-se os associados da AMBC em assembleia geral ordinária. Pauta: prestação de contas do exercício anterior e eleição de nova diretoria. Após deliberações, ficou aprovado por unanimidade o balanço financeiro apresentado. Nova diretoria eleita para o biênio 2024-2025.',
 NULL,
 NULL),

-- Ofício escrito no sistema
(2, 2024,
 2, NULL,
 'Solicitação de Parceria com Secretaria Municipal de Assistência Social',
 '2024-01-20',
 'Prezados Senhores, A Associação de Moradores do Bairro Califórnia vem por meio deste ofício solicitar parceria com a Secretaria Municipal de Assistência Social para desenvolvimento de atividades comunitárias. Atenciosamente, Diretoria AMBC.',
 NULL,
 NULL),

-- Mensagem escrita no sistema
(3, 2024,
 3, NULL,
 'Comunicado sobre Festa Junina 2024',
 '2024-02-01',
 'Prezados associados, informamos que a Festa Junina 2024 está confirmada para o dia 15 de junho. Contamos com a participação de todos. Maiores informações em breve.',
 NULL,
 NULL),

-- Circular escrita no sistema
(4, 2024,
 4, NULL,
 'Circular de Convocação — Assembleia Extraordinária',
 '2024-02-10',
 'Convocamos todos os associados para assembleia extraordinária a realizar-se no dia 10 de março de 2024, às 19h, na sede da associação. Pauta: alteração estatutária.',
 NULL,
 NULL),

-- Requerimento com arquivo anexado (PDF)
(5, 2024,
 5, NULL,
 'Requerimento de Alvará de Funcionamento',
 '2024-02-15',
 NULL,
 '/documentos/2024/005_requerimento_alvara.pdf',
 'Documento assinado e protocolado na Prefeitura'),

-- Declaração com arquivo anexado
(6, 2024,
 6, NULL,
 'Declaração de Utilidade Pública',
 '2024-03-01',
 NULL,
 '/documentos/2024/006_declaracao_utilidade_publica.pdf',
 NULL),

-- Tipo livre — Convite
(7, 2024,
 NULL, 'Convite',
 'Convite para Festa Junina 2024',
 '2024-03-10',
 'Convidamos você e sua família para a nossa tradicional Festa Junina! Data: 15 de junho de 2024. Local: Sede da AMBC. Entrada: 1 kg de alimento não perecível.',
 NULL,
 NULL),

-- Tipo livre — Edital
(8, 2024,
 NULL, 'Edital',
 'Edital de Eleição para Nova Diretoria 2025',
 '2024-03-15',
 NULL,
 '/documentos/2024/008_edital_eleicao.pdf',
 'Edital publicado no mural da associação'),

-- Documento tipo Outro com arquivo foto
(9, 2024,
 7, NULL,
 'Registro Fotográfico — Natal Solidário 2023',
 '2024-01-05',
 NULL,
 '/documentos/2024/009_fotos_natal_2023.pdf',
 'Álbum com fotos do evento'),

-- Ofício de resposta
(10, 2024,
 2, NULL,
 'Resposta ao Ofício 002/2024 — Secretaria Municipal',
 '2024-03-20',
 'Em resposta ao ofício recebido em 05/03/2024, informamos que a AMBC aceita os termos da parceria proposta pela Secretaria Municipal de Assistência Social.',
 NULL,
 NULL);
