/**
 * ============================================================
 * SERVIÇO DE PARCEIROS — AMBC V2
 * ============================================================
 * Camada de domínio para operações com parceiros.
 * Segue o mesmo padrão do usuarios-service.js
 * ============================================================
 */

import { api } from './api.js';

export const ParceirosService = {

    /**
     * Lista parceiros com filtros e paginação.
     * @param {object} filtros - { pagina, busca, status }
     */
    listar(filtros = {}) {
        const params = new URLSearchParams();
        Object.entries(filtros).forEach(([chave, valor]) => {
            if (valor !== '' && valor !== null && valor !== undefined) {
                params.append(chave, valor);
            }
        });
        const qs = params.toString();
        return api.get(`/parceiros/listar.php${qs ? '?' + qs : ''}`);
    },

    /**
     * Busca um parceiro pelo ID com telefones.
     * @param {number} id
     */
    buscar(id) {
        return api.get(`/parceiros/buscar.php?id=${id}`);
    },

    /**
     * Cadastra um novo parceiro.
     * @param {object} dados - Dados do parceiro + array de telefones
     */
    cadastrar(dados) {
        return api.post('/parceiros/cadastrar.php', dados);
    },

    /**
     * Atualiza um parceiro existente.
     * @param {object} dados - Dados atualizados + id_parceiro
     */
    editar(dados) {
        return api.put('/parceiros/editar.php', dados);
    },

    /**
     * Ativa ou inativa um parceiro.
     * @param {number} id
     */
    alternarStatus(id) {
        return api.patch('/parceiros/alternar-status.php', { id_parceiro: id });
    },
};
