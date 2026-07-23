import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';

const dump = readFileSync(resolve('Dump20260601_hostinger_v3.sql'), 'utf8');
const linhas = dump.split('\n');

const tabelasRef = new Set([
  'categoria', 'estado_civil', 'forma_pagamento', 'genero',
  'modulo_sistema', 'parentesco', 'profissao',
  'status_conta', 'status_pessoa',
  'tipo_documento', 'tipo_lancamento', 'tipo_telefone', 'uf',
]);

let saida = [];
let tabelaAtual = '';
let dentroCreate = false;

saida.push(`-- ============================================================
-- AMBC — Schema do Banco de Dados
-- Versão: 2.0  |  Gerado em: ${new Date().toLocaleDateString('pt-BR')}
--
-- Conteúdo:
--   - Estrutura completa de todas as tabelas
--   - Dados de referência (categorias, status, tipos, UFs, etc.)
--   - Perfis de acesso e módulos do sistema
--   - 1 usuário administrador genérico
--   - Nenhum dado pessoal ou de teste
--
-- Usuário padrão:
--   Login: admin@ambc.com
--   Senha: admin123   ← altere após o primeiro acesso
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
`);

for (let i = 0; i < linhas.length; i++) {
  const linha = linhas[i];

  if (linha.startsWith('DROP TABLE IF EXISTS')) {
    saida.push(linha);
    continue;
  }

  if (linha.startsWith('CREATE TABLE `')) {
    const match = linha.match(/CREATE TABLE `(\w+)`/);
    if (match) tabelaAtual = match[1];
    dentroCreate = true;
    saida.push('');
    saida.push(linha);
    continue;
  }

  if (dentroCreate) {
    saida.push(linha);
    if (linha.startsWith(') ENGINE=')) dentroCreate = false;
    continue;
  }

  if (linha.startsWith('INSERT INTO `')) {
    const match = linha.match(/INSERT INTO `(\w+)`/);
    if (match && tabelasRef.has(match[1])) {
      saida.push(linha);
    }
    continue;
  }
}

saida.push(`
-- ============================================================
-- PERFIS DE ACESSO
-- ============================================================
INSERT INTO \`perfil_usuario\` (\`id_perfil\`, \`descricao\`, \`observacao\`) VALUES
  (1, 'Administrador', NULL),
  (2, 'Gestor', 'Acesso operacional configurável pelo administrador.'),
  (3, 'Visualizador', 'Somente leitura. Módulos visíveis configuráveis pelo administrador.')
  ON DUPLICATE KEY UPDATE \`descricao\` = VALUES(\`descricao\`);

-- ============================================================
-- MÓDULOS DO SISTEMA
-- ============================================================
INSERT INTO \`modulo_sistema\` (\`id_modulo\`, \`descricao\`) VALUES
  (1, 'Dashboard'),
  (2, 'Associados'),
  (3, 'Dependentes'),
  (4, 'Financeiro'),
  (5, 'Parceiros'),
  (6, 'Documentos'),
  (7, 'Usuarios'),
  (8, 'Configuracoes')
  ON DUPLICATE KEY UPDATE \`descricao\` = VALUES(\`descricao\`);

-- ============================================================
-- CONTAS FINANCEIRAS BASE
-- ============================================================
INSERT INTO \`conta_regente\` (\`id_conta_regente\`, \`descricao\`, \`tipo\`, \`ativo\`) VALUES
  (1, 'Receitas Associação', 'receita', 1),
  (2, 'Despesas Associação', 'despesa', 1)
  ON DUPLICATE KEY UPDATE \`descricao\` = VALUES(\`descricao\`);

INSERT INTO \`conta_subordinada\` (\`id_conta_subordinada\`, \`fk_conta_regente\`, \`descricao\`, \`ativo\`) VALUES
  (1, 1, 'Mensalidade', 1),
  (2, 2, 'Manutenção', 1)
  ON DUPLICATE KEY UPDATE \`descricao\` = VALUES(\`descricao\`);

-- ============================================================
-- TIPOS DE LANÇAMENTO E RELACIONAMENTOS
-- ============================================================
INSERT INTO \`tipo_lancamento\` (\`id_tipo_lancamento\`, \`descricao\`) VALUES
  (1, 'Anuidade'),
  (2, 'Mensalidade'),
  (3, 'Doação'),
  (4, 'Multa'),
  (5, 'Outro'),
  (6, 'Mensalidades'),
  (10, 'Multa por Atraso'),
  (11, 'Manutenção'),
  (12, 'Conta de Energia Elétrica')
  ON DUPLICATE KEY UPDATE \`descricao\` = VALUES(\`descricao\`);

INSERT INTO \`relacionamento_lancamento\` (\`fk_tipo_lancamento\`, \`fk_conta_regente\`, \`fk_conta_subordinada\`, \`natureza\`, \`modo\`, \`ativo\`) VALUES
  (6, 1, 1, 'RECEBER', 'FIXO', 1),
  (2, 1, 1, 'RECEBER', 'FIXO', 1)
  ON DUPLICATE KEY UPDATE \`ativo\` = VALUES(\`ativo\`);

-- ============================================================
-- USUÁRIO ADMINISTRADOR GENÉRICO
-- Senha: admin123  —  altere após o primeiro acesso
-- ============================================================
INSERT INTO \`usuario\` (\`id_usuario\`, \`nome\`, \`email\`, \`senha_hash\`, \`fk_perfil\`, \`ativo\`, \`primeiro_acesso\`) VALUES
  (1, 'Administrador', 'admin@ambc.com',
   '$2y$12$GvOErlYEQnO7gdXQEOvxj.CEXnZOfxpHEnQ4aW2gmBZ8ihzdgHr1m',
   1, 1, 1)
  ON DUPLICATE KEY UPDATE \`nome\` = VALUES(\`nome\`);

-- Permissões: libera todos os módulos para o administrador
INSERT INTO \`permissao_usuario\` (\`fk_usuario\`, \`fk_modulo\`, \`pode_acessar\`, \`pode_editar\`)
SELECT 1, id_modulo, 1, 1 FROM \`modulo_sistema\`
ON DUPLICATE KEY UPDATE \`pode_acessar\` = 1, \`pode_editar\` = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- FIM DO SCHEMA
`);

const caminho = resolve('docs/schema.sql');
writeFileSync(caminho, saida.join('\n'));
const tamanho = (saida.join('\n').length / 1024).toFixed(1);
console.log(`✓ schema.sql gerado (${tamanho} KB)`);
