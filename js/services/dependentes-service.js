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

export const DependentesService = {
  listar(filtros = {}) {
    return api.get(`/dependentes/listar-todos.php${montarQuery(filtros)}`);
  },
};