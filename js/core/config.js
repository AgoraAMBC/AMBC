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

export const API_BASE = '/backend';
