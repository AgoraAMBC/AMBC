📘 DOCUMENTO DE ESPECIFICAÇÃO FUNCIONAL
Sistema AMBC — Associação de Moradores do Bairro Califórnia
Versão: 1.2 (CONSOLIDADA)
Data: 20/04/2026
Localização: Nova Santa Rita / RS — Brasil
Responsável Frontend: Fabio
Stack Frontend: HTML5 + CSS3 + JavaScript Vanilla (SPA)
Stack Backend (planejada): PHP + PostgreSQL
Ícones: Material Icons
Idioma: Português (Brasil) — fixo

📑 SUMÁRIO
Visão Geral do Sistema
Tela de Login
Painel (Dashboard)
Cadastro → Listar Todos
Cadastro → Novo Associado
Cadastro → Novo Parceiro
Cadastro → Dependentes (Consulta)
Financeiro → Visão Geral
Financeiro → Novo Lançamento
Financeiro → Relatórios
Financeiro → Contas Regentes
Financeiro → Contas Subordinadas
Tabelas Auxiliares
Configurações → Associação
Configurações → Relacionamentos
Configurações → Gerais
Entidades de Banco de Dados
Padrões Visuais e UX
Integrações Previstas
Estrutura de Pastas
Checklist de Desenvolvimento
Próximos Passos
Observações Finais
🎯 1. VISÃO GERAL DO SISTEMA
Plataforma digital de gestão dos associados do bairro Califórnia, administrada pela AMBC. O sistema gerencia associados, dependentes, parceiros, estrutura financeira hierárquica (contas regentes/subordinadas), tabelas auxiliares e configurações da associação.

🗂️ Estrutura de Menu Final


PRINCIPAL
├── 📊 Painel (Dashboard)
├── 👥 Cadastro
│   ├── Listar Todos
│   ├── Novo Associado
│   ├── Novo Parceiro
│   └── 👨‍👩‍👧 Dependentes
├── 💰 Financeiro
│   ├── Visão Geral
│   ├── Novo Lançamento
│   ├── Relatórios
│   ├── Contas Regentes
│   └── Contas Subordinadas
└── 📋 Tabelas Auxiliares
    └── Ver Tabelas

SISTEMA
├── ⚙️ Configurações
│   ├── Associação
│   ├── Relacionamentos
│   └── Config. Gerais
└── 🚪 Sair (Logout)
🔐 2. TELA DE LOGIN



Item	Especificação
Campos	E-mail + Senha
Validação	E-mail formato válido + senha mínima
Recursos	"Lembrar-me" (checkbox) + "Esqueci minha senha"
Layout	Centralizado, logo AMBC no topo
Segurança	Bloqueio após X tentativas (configurável em Config. Gerais)
Destino pós-login	Dashboard (Painel)
📊 3. PAINEL (DASHBOARD)
Cards de Estatísticas (topo)
Total de Associados (ativos)
Total de Parceiros
Saldo financeiro atual
Mensalidades em atraso
Seções
📈 Gráfico: Receitas x Despesas (últimos 6 meses)
🎂 Aniversariantes do dia/mês
⚠️ Alertas: vencimentos próximos, pendências
🕒 Atividades recentes (últimos lançamentos/cadastros)
🔗 Atalhos rápidos para ações frequentes
👥 4. CADASTRO → LISTAR TODOS



Item	Especificação
Tipo	Lista unificada (Associados + Parceiros)
Diferenciação	Badge/tag visual indicando o tipo
Colunas	Foto, Nome, Tipo, Documento, Telefone, Status, Ações
Filtros	Tipo, Status, Busca por nome/documento
Ações/linha	Ver, Editar, Excluir (com confirmação)
Paginação	Sim, com seletor de itens por página
Exportação	PDF / Excel
➕ 5. CADASTRO → NOVO ASSOCIADO
📑 Estrutura em Abas
Aba 1 — Identificação
Nome completo
CPF (com máscara)
RG
Data de nascimento
Gênero (dropdown da tabela auxiliar)
Estado civil (dropdown da tabela auxiliar)
Escolaridade (texto livre)
Profissão (dropdown da tabela auxiliar)
Foto (upload)
Aba 2 — Endereço
CEP (com autocompletar ViaCEP)
Rua
Número
Complemento
Bairro
Cidade (default: Nova Santa Rita)
Estado (default: RS)
Tipo de Imóvel (texto livre)
Situação do Imóvel (dropdown da tabela auxiliar)
Aba 3 — Contato
Telefone principal
Telefone secundário
E-mail
WhatsApp
Aba 4 — Associação
Código (auto-gerado)
Data de entrada
Status do Associado (dropdown da tabela auxiliar)
Valor da mensalidade
Observações
Aba 5 — Dependentes
Lista dinâmica vinculada ao associado
Campos por dependente:
Nome completo
CPF (opcional — pode ser criança)
Data de nascimento
Gênero (dropdown da tabela auxiliar)
Parentesco (dropdown da tabela auxiliar)
Foto (opcional)
Telefone (opcional)
Observações (opcional)
Status (Ativo/Inativo)
Ações: Adicionar, Editar, Remover, Ativar/Inativar
Contador: "Dependentes cadastrados: X"
Idade calculada automaticamente
🤝 6. CADASTRO → NOVO PARCEIRO
📑 Abas
Aba 1 — Identificação
Razão social
Nome fantasia
CNPJ/CPF
Tipo (PJ/PF)
Ramo de Atividade (texto livre)
Logo (upload)
Aba 2 — Endereço
Mesmo padrão do associado
Aba 3 — Contato
Telefone
E-mail
Site
Responsável (nome + contato)
Aba 4 — Parceria
Tipo de Parceria (texto livre)
Benefícios oferecidos / Tipo de Benefício (texto livre)
Data início
Data fim
Status
Observações
👨‍👩‍👧 7. CADASTRO → DEPENDENTES (CONSULTA)
Tela dedicada de consulta/listagem de todos os dependentes cadastrados no sistema. Não substitui a Aba 5 do Associado (onde são criados/editados), mas serve como visão transversal para filtros, buscas e relatórios operacionais (ex: ações de Natal, distribuição por rua).

🎯 Função
Visualizar, filtrar e exportar a lista completa de dependentes vinculados aos associados, permitindo ações estratégicas da associação.

🧩 Cabeçalho
👨‍👩‍👧 Título: "Listagem de Dependentes"
Contador de registros: "Total: X dependentes"
Botão "Gerar Relatório" (PDF/Excel)
🔍 Filtros (barra superior)



Filtro	Descrição
🔎 Busca por nome	Localização rápida
👪 Parentesco	Dropdown (filhos, cônjuge, etc.)
🎂 Faixa de idade	De/Até (ex: 0–12 para Natal)
⚥ Gênero	M/F/Outro
🏘️ Rua/Bairro ⭐	Essencial para distribuição geográfica
👤 Associado responsável	Dependentes de um titular específico
✅ Status do associado	Só associados ativos, por exemplo
🧹 Limpar filtros	Reset
📊 Tabela (colunas)



Coluna	Observação
ID	#001, #002...
Nome	Nome do dependente
Associado	Nome do titular (link clicável → abre cadastro)
Parentesco	Badge colorido
Idade	Calculada automaticamente
Nascimento	DD/MM/AAAA
Rua ⭐	Rua do associado responsável
Gênero	M/F
Ações	👁️ Ver / ✏️ Editar
🔗 Ação "Editar"
Ao clicar em editar um dependente → abre o cadastro do Associado titular direto na Aba 5 (Dependentes) com o item em foco
Mantém consistência: dependentes são sempre gerenciados dentro do contexto do titular
🎁 Relatórios disponíveis
Ao clicar em "Gerar Relatório", abrir modal com opções:

📋 Lista completa — todos os registros filtrados (lista corrida)
🎄 Crianças por Rua — agrupa por rua, mostra quantas crianças em cada (ideal para Natal)
📊 Estatísticas — total por faixa etária, parentesco, gênero
Formatos: PDF (com cabeçalho/logo AMBC) + Excel

📋 Rodapé
"Exibindo X de Y registros"
Paginação com seletor de itens por página
⚙️ Regras
Idade calculada a partir da data de nascimento
Tela é apenas de consulta (criação/edição acontece via Associado)
Respeita status do associado nos filtros
💰 8. FINANCEIRO → VISÃO GERAL
💵 Cards: Saldo total, Receitas do mês, Despesas do mês, A receber
📊 Gráficos: Fluxo mensal, Distribuição por categoria
📋 Tabela de lançamentos recentes
🎚️ Filtros: Período, Tipo, Conta regente/subordinada
🔗 Atalhos: Novo Lançamento, Relatórios
➕ 9. FINANCEIRO → NOVO LANÇAMENTO



Campo	Detalhe
Tipo	Receita / Despesa
Conta Regente	Dropdown (obrigatório)
Conta Subordinada	Dropdown dependente da Regente
Valor	Máscara R$
Data	Date picker
Descrição	Texto livre
Associado/Parceiro vinculado	Opcional (autocomplete)
Forma de pagamento	Dropdown (tabela auxiliar)
Status	Pago / Pendente / Cancelado
Anexos	Upload de comprovantes
Recorrência	Não / Mensal / Anual (opcional)
📊 10. FINANCEIRO → RELATÓRIOS
Tipos: Fluxo de caixa, Por categoria, Por associado, Por período, DRE simplificado, Inadimplência
Filtros: Período, Conta regente, Conta subordinada, Associado, Status
Exportação: PDF (com logo/cabeçalho AMBC), Excel
Pré-visualização antes de exportar
🏦 11. FINANCEIRO → CONTAS REGENTES



Item	Especificação
Função	Categorias "pai" do plano de contas
Layout	Tabela com CRUD completo
Campos	Código, Nome, Tipo (Receita/Despesa), Descrição, Status
Ações	Novo, Editar, Excluir (bloqueia se tiver subordinadas vinculadas)
Filtros	Tipo, Status, Busca
🏛️ 12. FINANCEIRO → CONTAS SUBORDINADAS



Item	Especificação
Função	Subcategorias vinculadas a uma Regente
Campos	Código, Nome, Conta Regente (obrigatória), Descrição, Status
Validação	Toda subordinada DEVE ter uma regente
Filtros	Por Regente, Status, Busca
📋 13. TABELAS AUXILIARES
Tela única com menu lateral para gerenciar listas de apoio do sistema. Cada tabela alimenta dropdowns em cadastros.

🗂️ Tabelas Finais (6)



#	Tabela	Uso
1	Gênero	Associados e dependentes
2	Parentesco	Dependentes
3	Profissão	Associados
4	Estado Civil	Associados
5	Status do Associado	Associados
6	Situação do Imóvel	Endereço do associado
🔧 Estrutura padrão de cada tabela
Campos: Nome, Descrição, Status (Ativo/Inativo)
Ações: Novo, Editar, Excluir, Ativar/Inativar
Recursos: Busca + Ordenação + Paginação
📝 Campos de TEXTO LIVRE (NÃO são tabelas auxiliares)
Os campos abaixo foram definidos como texto livre — digitados manualmente a cada cadastro, sem dropdown:

🎓 Escolaridade
🏠 Tipo de Imóvel
🤝 Tipo de Parceria
🏭 Ramo de Atividade
🎁 Tipo de Benefício
🏢 14. CONFIGURAÇÕES → ASSOCIAÇÃO
📑 Abas
Aba 1 — Identificação
Razão social
Nome fantasia
CNPJ
Data fundação
Logo (substitui "AMBC" no topo do sistema)
Aba 2 — Endereço
Campos padrão (cidade default: Nova Santa Rita)
Aba 3 — Contato
Telefone, E-mail, Site, Redes sociais
Aba 4 — Diretoria
Presidente atual (nome, CPF, contato, mandato)
Lista dinâmica de membros (cargo + nome configuráveis)



Regra	Detalhe
Tipo de registro	Único (só existe 1 AMBC)
Permissão	Apenas admin/super-admin
Botões	Salvar / Cancelar
🔗 15. CONFIGURAÇÕES → RELACIONAMENTOS



Item	Especificação
Função	Mapa visual de vínculos Regentes ↔ Subordinadas
Layout	🌳 Árvore expansível (estilo Windows Explorer)
Info exibida	Nome + quantidade de subordinadas (ex: "Receitas (3)")
Ação disponível	Mover subordinada entre regentes
Como mover	Clique na subordinada → modal → dropdown → salvar
Filtros	Busca + Tipo + Status + Expandir/Recolher tudo
Regra de integridade	Nenhuma subordinada pode ficar órfã
Botões topo	Atualizar + Exportar (PDF/Excel) + Atalhos para criar novo
⚙️ 16. CONFIGURAÇÕES → GERAIS
Layout: 📋 Menu lateral com seções
🎨 Aparência
Tema: Claro / Escuro / Automático
💰 Financeiro (Padrões)
Moeda padrão, Dia de vencimento, Valor padrão da mensalidade, Dias de tolerância, Ano fiscal
👥 Associados (Padrões)
Formato do código, Status padrão, Campos obrigatórios, Idade mínima
🔔 Notificações
Alertas de vencimento, Aniversariantes, E-mail automático, WhatsApp
🔐 Segurança
Tempo de sessão, Política de senha, Bloqueio por tentativas, Log de atividades
💾 Backup
Backup automático (diário/semanal)
📄 Relatórios
Orientação padrão, Cabeçalho com logo, Rodapé, Numeração de páginas
🌐 Regionalização
❌ Não configurável — tudo fixo em PT-BR
ℹ️ Sobre
Versão, Créditos, Suporte, Termos de uso
💾 Persistência
Salva automaticamente (sem botões Salvar/Cancelar)
🗄️ 17. ENTIDADES DE BANCO DE DADOS (Sugestão p/ Backend)


┌─────────────────────────────────────────┐
│ PRINCIPAIS                              │
├─────────────────────────────────────────┤
│ • usuarios          (login/acesso)      │
│ • associacao        (registro único)    │
│ • associados                            │
│ • dependentes       (FK → associados)   │
│ • parceiros                             │
│ • contas_regentes                       │
│ • contas_subordinadas                   │
│ • lancamentos                           │
│ • anexos_lancamentos                    │
├─────────────────────────────────────────┤
│ AUXILIARES (6 tabelas)                  │
├─────────────────────────────────────────┤
│ • generos                               │
│ • parentescos                           │
│ • profissoes                            │
│ • estados_civis                         │
│ • status_associado                      │
│ • situacoes_imovel                      │
├─────────────────────────────────────────┤
│ SISTEMA                                 │
├─────────────────────────────────────────┤
│ • configuracoes_gerais (key/value)      │
│ • diretoria_membros                     │
│ • log_atividades                        │
│ • sessoes                               │
└─────────────────────────────────────────┘
🎨 18. PADRÕES VISUAIS E UX
Componentes recorrentes
Sidebar (menu principal fixo à esquerda)
Topbar (logo AMBC, usuário logado, notificações)
Breadcrumb (caminho atual)
Modais para edição rápida e confirmações
Toasts para feedback (sucesso, erro, aviso)
Loaders durante requisições
Tabelas com paginação, busca e ordenação padronizadas
Badges coloridos para status e categorias
Formulários
Validação em tempo real
Máscaras (CPF, CNPJ, telefone, CEP, moeda)
Feedback visual (borda verde/vermelha)
Campos obrigatórios marcados com *
Responsividade
Mobile-first
Sidebar colapsável em telas pequenas
Tabelas com scroll horizontal em mobile
🔌 19. INTEGRAÇÕES PREVISTAS (Backend)
📬 ViaCEP — Autocompletar endereço
📧 SMTP — Envio de e-mails
💬 WhatsApp API — Notificações
📄 Geração de PDF — Relatórios e comprovantes
📊 Exportação Excel — Listagens e relatórios
🔐 JWT/Session — Autenticação
📐 20. ESTRUTURA DE PASTAS (Frontend)


ambc-v2/
├── index.html
├── login.html
├── assets/
│   ├── css/
│   │   ├── global.css
│   │   ├── components.css
│   │   └── themes.css
│   ├── js/
│   │   ├── core/
│   │   │   ├── router.js
│   │   │   ├── api.js
│   │   │   └── utils.js
│   │   ├── pages/
│   │   │   ├── dashboard.js
│   │   │   ├── cadastro-listar.js
│   │   │   ├── cadastro-associado.js
│   │   │   ├── cadastro-parceiro.js
│   │   │   ├── cadastro-dependentes.js
│   │   │   ├── financeiro-visao.js
│   │   │   ├── financeiro-lancamento.js
│   │   │   ├── financeiro-relatorios.js
│   │   │   ├── financeiro-regentes.js
│   │   │   ├── financeiro-subordinadas.js
│   │   │   ├── tabelas-auxiliares.js
│   │   │   ├── config-associacao.js
│   │   │   ├── config-relacionamentos.js
│   │   │   └── config-gerais.js
│   │   └── components/
│   │       ├── sidebar.js
│   │       ├── topbar.js
│   │       ├── modal.js
│   │       └── toast.js
│   ├── img/
│   └── icons/
├── pages/
│   ├── dashboard.html
│   ├── cadastro/
│   ├── financeiro/
│   ├── tabelas/
│   └── config/
└── docs/
    └── especificacao.md
✅ 21. CHECKLIST DE DESENVOLVIMENTO
FASE 1 — Fundação
 Estrutura de pastas
 index.html (SPA base)
 CSS global (variáveis, reset, temas)
 Router SPA
 Layout principal (sidebar + topbar)
FASE 2 — Autenticação
 login.html com validações
FASE 3 — Páginas principais
 Dashboard
 Cadastro → Listar Todos
 Cadastro → Novo Associado (5 abas, incluindo Dependentes)
 Cadastro → Novo Parceiro (4 abas)
 Cadastro → Dependentes (consulta)
 Financeiro → Visão Geral
 Financeiro → Novo Lançamento
 Financeiro → Relatórios
 Financeiro → Contas Regentes
 Financeiro → Contas Subordinadas
 Tabelas Auxiliares (6 tabelas)
 Configurações → Associação
 Configurações → Relacionamentos
 Configurações → Gerais
FASE 4 — Refinamentos
 Responsividade completa
 Temas claro/escuro
 Validações robustas
 Documentação para equipe backend
 Mock de dados para testes
📌 22. PRÓXIMOS PASSOS
✅ Revisar este documento e aprovar versão 1.2
📄 Colar o HTML de referência para análise final
📂 Confirmar estrutura de pastas atual no VS Code
🎨 Definir identidade visual (paleta de cores, fonte, logo)
🏗️ Iniciar FASE 1 — Fundação do frontend
📝 23. OBSERVAÇÕES FINAIS
Frontend será construído desacoplado do backend (consumirá API REST futura em PHP)
Estrutura modular pensada para receber Bootstrap posteriormente, se desejado
Todo dado mockado no frontend será facilmente substituível por chamadas reais à API
Código seguirá padrões de clean code e comentários em PT-BR para facilitar entrada da equipe backend
Banco planejado em PostgreSQL
Sistema monoempresa (apenas AMBC) — não suporta múltiplas associações
📊 Resumo Estatístico



Métrica	Valor
Telas especificadas	15
Abas em formulários	13 (5 Associado + 4 Parceiro + 4 Associação)
Tabelas auxiliares	6
Campos de texto livre	5
Módulos principais	5 (Dashboard + Cadastro + Financeiro + Tabelas + Configurações)
Sessões de especificação	15+
Decisões registradas	100+
Documento final — versão 1.2
Pronto para iniciar desenvolvimento (FASE 1) 🚀