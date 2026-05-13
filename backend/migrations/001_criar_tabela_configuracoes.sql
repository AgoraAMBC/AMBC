-- migrations/001_criar_tabela_configuracoes.sql
-- Cria a tabela de configurações da associação

CREATE TABLE IF NOT EXISTS configuracoes (
    chave VARCHAR(100) PRIMARY KEY,
    valor TEXT,
    atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Insere dados iniciais se não existirem
INSERT INTO configuracoes (chave, valor) VALUES ('nome', 'Associação de Moradores do Bairro Califórnia')
ON CONFLICT (chave) DO NOTHING;

INSERT INTO configuracoes (chave, valor) VALUES ('sigla', 'AMBC')
ON CONFLICT (chave) DO NOTHING;