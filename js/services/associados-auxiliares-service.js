import { api } from './api.js';

export const AuxiliaresService = {
  listarGeneros() {
    return api.get('/generos/listar.php');
  },

  listarEstadosCivis() {
    return api.get('/estados-civis/listar.php');
  },

  listarProfissoes() {
    return api.get('/profissoes/listar.php');
  },

  listarStatusPessoa() {
    return api.get('/status-pessoa/listar.php');
  },

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
    const [
      rGeneros,
      rEstadosCivis,
      rProfissoes,
      rStatusPessoa,
      rUfs
    ] = await Promise.allSettled([
      this.listarGeneros(),
      this.listarEstadosCivis(),
      this.listarProfissoes(),
      this.listarStatusPessoa(),
      this.listarUfs()
    ]);

    const extrair = (resultado, nome) => {
      if (resultado.status === 'fulfilled') return resultado.value ?? [];
      console.warn(`[AuxiliaresService] Falha ao carregar "${nome}":`, resultado.reason?.message);
      return [];
    };

    return {
      generos:      extrair(rGeneros,      'generos'),
      estadosCivis: extrair(rEstadosCivis, 'estadosCivis'),
      profissoes:   extrair(rProfissoes,   'profissoes'),
      statusPessoa: extrair(rStatusPessoa, 'statusPessoa'),
      ufs:          extrair(rUfs,          'ufs')
    };
  }
};
