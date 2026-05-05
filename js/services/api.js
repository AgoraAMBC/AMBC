/**
 * ============================================================
 * SERVIÇO DE API — AMBC V2
 * ============================================================
 * Camada de abstração para comunicação HTTP com o backend.
 *
 * A URL base é centralizada em `js/core/config.js` (API_BASE).
 * Para trocar de ambiente (dev/homolog/prod), altere lá.
 *
 * Backend atual: PHP em const BASE_URL = '/backend';
 * ============================================================
 */

import { API_BASE } from '../core/config.js';

/**
 * Wrapper genérico de requisições HTTP.
 * Padroniza tratamento de erros e parsing de JSON.
 *
 * @param {string} endpoint - Caminho relativo (ex: '/usuarios')
 * @param {object} options  - Opções do fetch (method, body, headers, etc.)
 * @returns {Promise<any>}  - Dados parseados em JSON
 * @throws {Error}          - Em caso de falha HTTP ou rede
 */
async function request(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;

    const config = {
        credentials: 'same-origin',  // 🍪 envia cookie PHPSESSID
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...options.headers
        },
        ...options
    };

    try {
        const response = await fetch(url, config);

        // Tenta parsear JSON mesmo em caso de erro (backend pode retornar { error: ... })
        const data = await response.json().catch(() => null);

        if (!response.ok) {
            const erro = new Error(data?.error || data?.mensagem || `Erro HTTP ${response.status}`);
            erro.status  = response.status;
            erro.details = data?.details || null;
            throw erro;
        }

        return data;
    } catch (error) {
        console.error(`❌ Erro na requisição ${options.method || 'GET'} ${endpoint}:`, error);
        throw error;
    }
}

/**
 * Métodos HTTP disponíveis.
 * Mantém a API pública igual à versão anterior (get/post/put/patch/delete).
 */
export const api = {
    get: (endpoint) =>
        request(endpoint, { method: 'GET' }),

    post: (endpoint, body) =>
        request(endpoint, {
            method: 'POST',
            body: JSON.stringify(body)
        }),

    put: (endpoint, body) =>
        request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(body)
        }),

    patch: (endpoint, body) =>
        request(endpoint, {
            method: 'PATCH',
            body: JSON.stringify(body)
        }),

    delete: (endpoint, body = null) =>
        request(endpoint, {
            method: 'DELETE',
            ...(body ? { body: JSON.stringify(body) } : {})
        })
};
