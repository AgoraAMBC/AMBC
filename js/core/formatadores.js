const estado = {
  fusoHorario: 'America/Sao_Paulo',
  formatoData:  'DD/MM/YYYY',
};

export function configurar(fusoHorario, formatoData) {
  if (fusoHorario) estado.fusoHorario = fusoHorario;
  if (formatoData)  estado.formatoData  = formatoData;
}

function localeParaFormato(formato) {
  if (formato === 'MM/DD/YYYY') return 'en-US';
  if (formato === 'YYYY-MM-DD') return 'sv-SE';
  return 'pt-BR';
}

function normalizarData(valor) {
  // Strings YYYY-MM-DD são interpretadas como UTC midnight pelo JS.
  // Sem ajuste, horários negativos (ex: UTC-3) exibem o dia anterior.
  if (/^\d{4}-\d{2}-\d{2}$/.test(String(valor))) return `${valor}T12:00:00`;
  return valor;
}

export function formatarData(valor) {
  if (!valor) return '—';
  const locale = localeParaFormato(estado.formatoData);
  return new Date(normalizarData(valor)).toLocaleDateString(locale, { timeZone: estado.fusoHorario });
}

export function formatarDataHora(valor) {
  if (!valor) return '—';
  const locale = localeParaFormato(estado.formatoData);
  return new Date(valor).toLocaleString(locale, {
    dateStyle: 'short',
    timeStyle: 'short',
    timeZone: estado.fusoHorario,
  });
}
