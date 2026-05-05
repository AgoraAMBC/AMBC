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

  listarSituacoesImovel() {
    return api.get('/situacoes-imovel/listar.php');
  },

  listarUfs() {
    return Promise.resolve([
      { sigla: 'AC', descricao: 'Acre' },
      { sigla: 'AL', descricao: 'Alagoas' },
      { sigla: 'AP', descricao: 'Amapá' },
      { sigla: 'AM', descricao: 'Amazonas' },
      { sigla: 'BA', descricao: 'Bahia' },
      { sigla: 'CE', descricao: 'Ceará' },
      { sigla: 'DF', descricao: 'Distrito Federal' },
      { sigla: 'ES', descricao: 'Espírito Santo' },
      { sigla: 'GO', descricao: 'Goiás' },
      { sigla: 'MA', descricao: 'Maranhão' },
      { sigla: 'MT', descricao: 'Mato Grosso' },
      { sigla: 'MS', descricao: 'Mato Grosso do Sul' },
      { sigla: 'MG', descricao: 'Minas Gerais' },
      { sigla: 'PA', descricao: 'Pará' },
      { sigla: 'PB', descricao: 'Paraíba' },
      { sigla: 'PR', descricao: 'Paraná' },
      { sigla: 'PE', descricao: 'Pernambuco' },
      { sigla: 'PI', descricao: 'Piauí' },
      { sigla: 'RJ', descricao: 'Rio de Janeiro' },
      { sigla: 'RN', descricao: 'Rio Grande do Norte' },
      { sigla: 'RS', descricao: 'Rio Grande do Sul' },
      { sigla: 'RO', descricao: 'Rondônia' },
      { sigla: 'RR', descricao: 'Roraima' },
      { sigla: 'SC', descricao: 'Santa Catarina' },
      { sigla: 'SP', descricao: 'São Paulo' },
      { sigla: 'SE', descricao: 'Sergipe' },
      { sigla: 'TO', descricao: 'Tocantins' }
    ]);
  },

  async carregarTodas() {
    const [
      generos,
      estadosCivis,
      profissoes,
      statusPessoa,
      situacoesImovel,
      ufs
    ] = await Promise.all([
      this.listarGeneros(),
      this.listarEstadosCivis(),
      this.listarProfissoes(),
      this.listarStatusPessoa(),
      this.listarSituacoesImovel(),
      this.listarUfs()
    ]);

    return {
      generos,
      estadosCivis,
      profissoes,
      statusPessoa,
      situacoesImovel,
      ufs
    };
  }
};
