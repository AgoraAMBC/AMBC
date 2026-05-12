import { api } from './api.js';

export const AuxiliaresService = {

  /* ── LISTAR ── */
  listarGeneros()      { return api.get('/generos/listar.php'); },
  listarParentescos()  { return api.get('/parentesco/listar.php'); },
  listarProfissoes()   { return api.get('/profissoes/listar.php'); },
  listarEstadosCivis() { return api.get('/estados-civis/listar.php'); },
  listarStatusPessoa() { return api.get('/status-pessoa/listar.php'); },

  /* ── CRIAR ── */
  criarGenero(descricao)      { return api.post('/generos/cadastrar.php',       { descricao }); },
  criarParentesco(descricao)  { return api.post('/parentesco/cadastrar.php',    { descricao }); },
  criarProfissao(descricao)   { return api.post('/profissoes/cadastrar.php',    { descricao }); },
  criarEstadoCivil(descricao) { return api.post('/estados-civis/cadastrar.php', { descricao }); },
  criarStatus(descricao)      { return api.post('/status-pessoa/cadastrar.php', { descricao }); },

  /* ── EDITAR ── */
  editarGenero(id, descricao)      { return api.put('/generos/editar.php',       { id, descricao }); },
  editarParentesco(id, descricao)  { return api.put('/parentesco/editar.php',    { id, descricao }); },
  editarProfissao(id, descricao)   { return api.put('/profissoes/editar.php',    { id, descricao }); },
  editarEstadoCivil(id, descricao) { return api.put('/estados-civis/editar.php', { id, descricao }); },
  editarStatus(id, descricao)      { return api.put('/status-pessoa/editar.php', { id, descricao }); },

  /* ── EXCLUIR ── */
  excluirGenero(id)      { return api.delete('/generos/deletar.php',       { id }); },
  excluirParentesco(id)  { return api.delete('/parentesco/deletar.php',    { id }); },
  excluirProfissao(id)   { return api.delete('/profissoes/deletar.php',    { id }); },
  excluirEstadoCivil(id) { return api.delete('/estados-civis/deletar.php', { id }); },
  excluirStatus(id)      { return api.delete('/status-pessoa/deletar.php', { id }); },

  listarUfs() {
    return Promise.resolve([
      { id: 'AC', descricao: 'AC' }, { id: 'AL', descricao: 'AL' },
      { id: 'AP', descricao: 'AP' }, { id: 'AM', descricao: 'AM' },
      { id: 'BA', descricao: 'BA' }, { id: 'CE', descricao: 'CE' },
      { id: 'DF', descricao: 'DF' }, { id: 'ES', descricao: 'ES' },
      { id: 'GO', descricao: 'GO' }, { id: 'MA', descricao: 'MA' },
      { id: 'MT', descricao: 'MT' }, { id: 'MS', descricao: 'MS' },
      { id: 'MG', descricao: 'MG' }, { id: 'PA', descricao: 'PA' },
      { id: 'PB', descricao: 'PB' }, { id: 'PR', descricao: 'PR' },
      { id: 'PE', descricao: 'PE' }, { id: 'PI', descricao: 'PI' },
      { id: 'RJ', descricao: 'RJ' }, { id: 'RN', descricao: 'RN' },
      { id: 'RS', descricao: 'RS' }, { id: 'RO', descricao: 'RO' },
      { id: 'RR', descricao: 'RR' }, { id: 'SC', descricao: 'SC' },
      { id: 'SP', descricao: 'SP' }, { id: 'SE', descricao: 'SE' },
      { id: 'TO', descricao: 'TO' }
    ]);
  },

  async carregarTodas() {
    const [rGeneros, rEstadosCivis, rProfissoes, rStatusPessoa, rUfs, rParentescos, rCategorias] =
      await Promise.allSettled([
        this.listarGeneros(),
        this.listarEstadosCivis(),
        this.listarProfissoes(),
        this.listarStatusPessoa(),
        this.listarUfs(),
        this.listarParentescos(),
        api.get('/categorias/listar.php'),
      ]);

    const extrair = (r, nome) => {
      if (r.status === 'fulfilled') return r.value ?? [];
      console.warn(`[AuxiliaresService] Falha ao carregar "${nome}":`, r.reason?.message);
      return [];
    };

    return {
      generos:      extrair(rGeneros,      'generos'),
      estadosCivis: extrair(rEstadosCivis, 'estadosCivis'),
      profissoes:   extrair(rProfissoes,   'profissoes'),
      statusPessoa: extrair(rStatusPessoa, 'statusPessoa'),
      ufs:          extrair(rUfs,          'ufs'),
      parentescos:  extrair(rParentescos,  'parentescos'),
      categorias:   extrair(rCategorias,   'categorias'),
    };
  },
};
