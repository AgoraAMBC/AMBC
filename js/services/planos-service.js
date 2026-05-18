import { api } from './api.js';

export const PlanosService = {
    listar:          ()     => api.get('/planos/listar.php'),
    criar:           (dados) => api.post('/planos/criar.php', dados),
    editar:          (dados) => api.put('/planos/editar.php', dados),
    excluir:         (id)   => api.delete('/planos/excluir.php', { id_plano: id }),
    alternarStatus:  (id)   => api.patch('/planos/alternar-status.php', { id_plano: id }),
};
