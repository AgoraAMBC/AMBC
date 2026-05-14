import { API_BASE } from '../core/config.js';
import { api } from './api.js';

export const DocumentosService = {
    listar:      (categoria = 'institucional') => api.get(`/documentos/listar.php?categoria=${categoria}`),
    listarTipos: ()                            => api.get('/documentos/tipos.php'),
    excluir:     (id)                          => api.delete(`/documentos/excluir.php?id=${id}`),

    urlBaixar: (id) => `${API_BASE}/documentos/baixar.php?id=${id}`,

    enviar(formData) {
        return fetch(`${API_BASE}/documentos/enviar.php`, {
            method: 'POST',
            credentials: 'same-origin',
            body: formData,
        }).then(async res => {
            const data = await res.json().catch(() => null);
            if (!res.ok) throw new Error(data?.erro || `Erro HTTP ${res.status}`);
            return data;
        });
    },
};
