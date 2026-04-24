/**
 * ============================================================
 * SERVIÇO DE ASSOCIADOS — AMBC V2
 * ============================================================
 * Encapsula todas as operações relacionadas a associados.
 * Isola o restante do código dos detalhes da API.
 * ============================================================
 */

import { api } from './api.js';

const ENDPOINT = '/associados';

export const AssociadosService = {
    /**
     * Lista todos os associados.
     * @returns {Promise<Array>}
     */
    async listarTodos() {
        const resposta = await api.get(ENDPOINT);
        // json-server retorna array direto; API real retorna { data: [...] }
        return Array.isArray(resposta) ? resposta : resposta.data;
    },

    /**
     * Busca um associado pelo ID.
     * @param {number} id
     * @returns {Promise<Object>}
     */
    async buscarPorId(id) {
        const resposta = await api.get(`${ENDPOINT}/${id}`);
        return resposta.data || resposta;
    },

    /**
     * Cria um novo associado.
     * @param {Object} dados
     * @returns {Promise<Object>}
     */
    async criar(dados) {
        const novoAssociado = {
            ...dados,
            data_cadastro: new Date().toISOString().slice(0, 19).replace('T', ' '),
            ativo: dados.ativo ?? true
        };
        const resposta = await api.post(ENDPOINT, novoAssociado);
        return resposta.data || resposta;
    },

    /**
     * Atualiza um associado existente.
     * @param {number} id
     * @param {Object} dados
     * @returns {Promise<Object>}
     */
    async atualizar(id, dados) {
        const resposta = await api.put(`${ENDPOINT}/${id}`, dados);
        return resposta.data || resposta;
    },

    /**
     * Exclui um associado.
     * @param {number} id
     * @returns {Promise<void>}
     */
    async excluir(id) {
        await api.delete(`${ENDPOINT}/${id}`);
    }
};
