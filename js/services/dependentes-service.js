import { api } from './api.js';

export const DependentesService = {
    listar(filtros = {}) {
        const params = new URLSearchParams();
        Object.entries(filtros).forEach(([chave, valor]) => {
            if (valor !== '' && valor !== null && valor !== undefined) {
                params.append(chave, valor);
            }
        });
        const qs = params.toString();
        return api.get(`/dependentes/listar.php${qs ? '?' + qs : ''}`);
    },
};
