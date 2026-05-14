import { api } from './api.js';

export const ContasService = {
  listarRegentes(filtros = {}) {
    const params = new URLSearchParams(filtros);
    return api.get(`/financeiro/contas-regentes/listar.php?${params}`);
  },

  listarSubordinadas(fk_conta_regente) {
    return api.get(`/financeiro/contas-subordinadas/listar.php?fk_conta_regente=${fk_conta_regente}`);
  },

  listarTodasSubordinadas() {
    return api.get('/financeiro/contas-subordinadas/listar.php');
  }
};