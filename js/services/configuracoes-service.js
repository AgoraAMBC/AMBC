/**
 * ============================================================
 * SERVIÇO DE CONFIGURAÇÕES — AMBC V2
 * ============================================================
 * Gerencia as configurações da associação no banco de dados.
 */

import { api } from './api.js';

export const ConfiguracoesService = {
  async obter() {
    try {
      return await api.get('/configuracoes/obter.php');
    } catch (erro) {
      console.error('[ConfiguracoesService] Erro ao obter configurações:', erro);
      // Fallback para localStorage se API falhar
      return this.obterLocal();
    }
  },

  async salvar(config) {
    try {
      return await api.post('/configuracoes/salvar.php', config);
    } catch (erro) {
      console.error('[ConfiguracoesService] Erro ao salvar configurações:', erro);
      // Fallback para localStorage se API falhar
      this.salvarLocal(config);
      throw erro;
    }
  },

  // Fallback localStorage (mantido para compatibilidade)
  obterLocal() {
    return JSON.parse(localStorage.getItem('ambc_configuracoes') || '{}');
  },

  salvarLocal(config) {
    localStorage.setItem('ambc_configuracoes', JSON.stringify(config));
  }
};