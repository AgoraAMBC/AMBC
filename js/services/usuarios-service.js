/**
 * ============================================================
 * SERVIÇO DE USUÁRIOS — AMBC V2
 * ============================================================
 * Camada de domínio para operações com usuários do sistema.
 *
 * Responsabilidades:
 * - Encapsular todas as chamadas HTTP relacionadas a usuários
 * - Expor métodos semânticos (listar, criar, atualizar...)
 * - Padronizar montagem de query strings
 *
 * NÃO faz: renderização, manipulação de DOM, validação de UI.
 * Isso é responsabilidade da página (js/paginas/usuarios.js).
 * ============================================================
 */

import { api } from './api.js';

/**
 * Constrói query string a partir de um objeto de filtros.
 * Ignora valores vazios/nulos.
 *
 * @param {object} filtros - { pagina, busca, perfil, status }
 * @returns {string} - "?pagina=1&busca=joao" (ou "" se vazio)
 */
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

export const UsuariosService = {

    /**
     * Lista usuários com filtros e paginação.
     */
    listar(filtros = {}) {
        return api.get(`/usuarios/listar.php${montarQuery(filtros)}`);
    },

    /**
     * Obtém dados completos de um usuário (para edição).
     */
    obter(id) {
        return api.get(`/usuarios/obter.php?id=${id}`);
    },

    /**
     * Cria um novo usuário.
     */
    criar(dados) {
        return api.post('/usuarios/cadastrar.php', dados);
    },

    /**
     * Atualiza um usuário existente.
     */
    atualizar(dados) {
        return api.put('/usuarios/editar.php', dados);
    },

    /**
     * Alterna o status (ativo/inativo) de um usuário.
     */
    alternarStatus(id) {
        return api.patch('/usuarios/alternar-status.php', { id_usuario: id });
    },

    /**
     * Exclui permanentemente um usuário do sistema.
     * Remove também suas permissões associadas (cascata no backend).
     */
    deletar(id) {
        return api.delete('/usuarios/deletar.php', { id_usuario: id });
    },

    /**
     * Lista todos os módulos do sistema (para tela de permissões).
     */
    listarModulos() {
        return api.get('/modulos/listar.php');
    },

    /**
     * Lista todos os perfis disponíveis (para selects).
     */
    listarPerfis() {
        return api.get('/perfis/listar.php');
    },

    /**
     * Exclui permanentemente um usuário.
     * @param {number} id
     */
    deletar(id) {
        return api.delete('/usuarios/deletar.php', { id_usuario: id });
    }
};
