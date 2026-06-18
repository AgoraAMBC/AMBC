import { api } from './api.js';
import Sessao from '../core/sessao.js';

export const NotificacoesService = {
    async notificarNovoCadastro({ nome, matricula }) {
        const usuario = Sessao.obter();
        if (!usuario?.email) return;

        return api.post('/notificacoes/enviar-email.php', {
            tipo: 'novos_cadastros',
            para: usuario.email,
            dados: { nome, matricula },
        });
    },
};
