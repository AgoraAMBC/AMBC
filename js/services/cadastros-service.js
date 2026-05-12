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

export const CadastrosService = {
  listar(filtros = {}) {
    return api.get(`/cadastros/listar-todos.php${montarQuery(filtros)}`);
  },

  // Excluir conforme o tipo
  // Associado usa query param, dependente e parceiro usam body
  excluir(id, tipo) {
    switch (tipo) {
      case 'associado':
        return api.delete(`/associados/excluir.php?id=${id}`);
      case 'dependente':
        return api.delete('/dependentes/deletar.php', { id_dependente: id });
      case 'parceiro':
        return api.delete('/parceiros/excluir.php', { id_parceiro: id });
      default:
        return Promise.reject(new Error('Tipo de cadastro inválido'));
    }
  },
};