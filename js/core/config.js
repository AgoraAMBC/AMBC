/**
 * ============================================================
 * CONFIGURAÇÕES GLOBAIS — AMBC V2
 * ============================================================
 * URL base do backend PHP.
 *
 * - Em desenvolvimento (Laragon): mantém caminho relativo,
 *   pois frontend e backend rodam na MESMA origem (ambc-v2.test).
 * - Em produção: também funciona se backend estiver no mesmo domínio.
 * - Para apontar para outro servidor, troque por URL absoluta
 *   (ex: 'https://api.ambc.com.br') e ajuste CORS no backend.
 * ============================================================
 */

// Live Server (porta 5500/5501) precisa de URL absoluta para o PHP server separado.
// Render e Laragon (mesma origem) usam path relativo.
const _liveServer = ['5500', '5501'].includes(window.location.port);
export const API_BASE = _liveServer ? 'http://localhost:8080/backend' : '/backend';
