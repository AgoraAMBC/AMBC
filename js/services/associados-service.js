import { api } from './api.js';

function montarQuery(filtros = {}) {
  const params = new URLSearchParams();

  Object.entries(filtros).forEach(([chave, valor]) => {
    if (valor !== '' && valor !== null && valor !== undefined) {
      params.append(chave, valor);
    }
  });

  const qs = params.toString();
  return qs ? `?${qs}` : '';
}

export const AssociadosService = {
  listar(filtros = {}) {
    return api.get(`/associados/listar.php${montarQuery(filtros)}`);
  },

  obter(id) {
    return api.get(`/associados/obter.php?id=${id}`);
  },

  criar(dados) {
    return api.post('/associados/cadastrar.php', dados);
  },

  atualizar(dados) {
    return api.put('/associados/editar.php', dados);
  },

  alternarStatus(id) {
    return api.patch('/associados/alternar-status.php', {
      id_associado: id
    });
  },

  deletar(id) {
    return api.delete('/associados/deletar.php', {
      id_associado: id
    });
  },

  verificarCpf(cpf_cnpj, idIgnorar = null) {
    return api.get(`/associados/verificar-cpf.php${montarQuery({
      cpf_cnpj,
      ignorar_id: idIgnorar
    })}`);
  },

  proximaMatricula() {
    return api.get('/associados/proxima-matricula.php');
  }
};
