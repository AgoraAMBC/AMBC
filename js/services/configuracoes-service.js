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
      console.log('[ConfigService] Buscando configuracoes do banco...');
      const result = await api.get('/configuracoes/obter.php');
      console.log('[ConfigService] Recebido do banco:', result);
      return result;
    } catch (erro) {
      console.error('[ConfiguracoesService] Erro ao obter configurações:', erro);
      return this.obterLocal();
    }
  },

  async salvar(config) {
    try {
      console.log('[ConfigService] Salvando no banco:', config);
      return await api.post('/configuracoes/salvar.php', config);
    } catch (erro) {
      console.error('[ConfiguracoesService] Erro ao salvar configurações:', erro);
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