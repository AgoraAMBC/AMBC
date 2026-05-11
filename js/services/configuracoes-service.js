import { api } from './api.js';

export const ConfiguracoesService = {
    listar:  ()       => api.get('/configuracoes/listar.php'),
    salvar:  (dados)  => api.post('/configuracoes/salvar.php', dados),
};
