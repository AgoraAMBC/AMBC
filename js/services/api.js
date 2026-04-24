/**
 * ============================================================
 * SERVIÇO DE API — AMBC V2
 * ============================================================
 * Camada de abstração para comunicação HTTP.
 * 
 * IMPORTANTE: Para trocar entre mock e API real,
 * basta alterar a constante API_BASE_URL abaixo.
 * 
 * - Mock (json-server):  http://localhost:3000
 * - API real (PHP):      http://localhost/ambc/api
 * ============================================================
 */

// 🔧 CONFIGURAÇÃO — troque aqui quando o backend real estiver pronto
const API_BASE_URL = 'http://localhost:3000';

/**
 * Wrapper genérico de requisições HTTP.
 * Padroniza tratamento de erros e parsing de JSON.
 */
async function request(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;

    const config = {
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        },
        ...options
    };

    try {
        const response = await fetch(url, config);

        // Tenta parsear JSON mesmo em caso de erro
        const data = await response.json().catch(() => null);

        if (!response.ok) {
            throw {
                status: response.status,
                message: data?.error || `Erro ${response.status}`,
                details: data?.details || null
            };
        }

        return data;
    } catch (error) {
        console.error(`❌ Erro na requisição ${endpoint}:`, error);
        throw error;
    }
}

/**
 * Métodos HTTP disponíveis.
 */
export const api = {
    get: (endpoint) => request(endpoint, { method: 'GET' }),

    post: (endpoint, body) => request(endpoint, {
        method: 'POST',
        body: JSON.stringify(body)
    }),

    put: (endpoint, body) => request(endpoint, {
        method: 'PUT',
        body: JSON.stringify(body)
    }),

    delete: (endpoint) => request(endpoint, { method: 'DELETE' })
};
