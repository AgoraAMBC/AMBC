/* =========================================================
   Pagina: Dashboard
   Descricao: Consome /backend/dashboard/resumo.php e renderiza o painel.
========================================================= */

import { DashboardService } from '../services/dashboard-service.js';
import Toast from '../componentes/toast.js';
import { formatarData } from '../core/formatadores.js';

const DashboardPage = {
  _resizeHandler: null,
  _grafico: [],

  async init() {
    this._atualizarMesAtual();
    this._registrarResize();
    await this.carregarResumo();
  },

  async carregarResumo() {
    try {
      const dados = await DashboardService.resumo();
      this._grafico = dados.grafico || [];

      this.renderizarCards(dados.cards || {});
      this.renderizarGrafico(this._grafico);
      this.renderizarDistribuicao(dados.distribuicao || {});
      this.renderizarTransacoes(dados.ultimas_transacoes || []);
    } catch (erro) {
      console.error('[DashboardPage] Erro ao carregar resumo:', erro);
      Toast.erro('Não foi possível carregar o painel. Tente novamente.');
      this._renderizarErroTabela();
    }
  },

  renderizarCards(cards) {
    this._setCard('associados',    cards.associados);
    this._setCard('dependentes',   cards.dependentes);
    this._setCard('parceiros',     cards.parceiros);
    this._setCard('resultado-mes', cards.resultado_mes, true);
  },

  _setCard(id, dados = {}, isMoeda = false) {
    const card = document.querySelector(`[data-card="${id}"]`);
    if (!card) return;

    const total    = Number(dados.total    || 0);
    const variacao = Number(dados.variacao || 0);
    const elTotal   = card.querySelector('[data-card-total]');
    const elVariacao = card.querySelector('[data-card-variacao]');

    if (elTotal) {
      elTotal.textContent = isMoeda
        ? this._formatarMoeda(total)
        : total.toLocaleString('pt-BR');
      elTotal.classList.remove('dashboard-card__valor--carregando');
    }

    if (elVariacao) {
      const sinal = variacao > 0 ? '+' : '';
      elVariacao.textContent = `${sinal}${variacao.toFixed(1)}%`;
      elVariacao.dataset.estado = variacao > 0 ? 'alta' : variacao < 0 ? 'baixa' : 'neutro';
    }
  },

  renderizarGrafico(grafico) {
    const canvas = document.getElementById('grafico-receita-despesa');
    if (!canvas) return;

    const larguraCss = canvas.clientWidth || 720;
    const alturaCss  = canvas.clientHeight || 300;
    const escala     = window.devicePixelRatio || 1;
    canvas.width  = Math.round(larguraCss * escala);
    canvas.height = Math.round(alturaCss  * escala);

    const ctx = canvas.getContext('2d');
    ctx.setTransform(escala, 0, 0, escala, 0, 0);
    ctx.clearRect(0, 0, larguraCss, alturaCss);

    const dados  = grafico.length ? grafico : this._mesesVazios();
    const maximo = Math.max(1, ...dados.flatMap(item => [
      Number(item.receita || 0),
      Number(item.despesa || 0)
    ]));

    const margem = { top: 18, right: 20, bottom: 42, left: 54 };
    const areaW  = larguraCss - margem.left - margem.right;
    const areaH  = alturaCss  - margem.top  - margem.bottom;
    const grupoW = areaW / dados.length;
    const barraW = Math.min(24, grupoW / 4);

    ctx.font        = '12px Inter, Segoe UI, sans-serif';
    ctx.lineWidth   = 1;
    ctx.strokeStyle = '#e2e8f0';
    ctx.fillStyle   = '#64748b';
    ctx.textAlign      = 'right';
    ctx.textBaseline   = 'middle';

    for (let i = 0; i <= 4; i++) {
      const y     = margem.top + areaH - (areaH * i) / 4;
      const valor = (maximo * i) / 4;
      ctx.beginPath();
      ctx.moveTo(margem.left, y);
      ctx.lineTo(larguraCss - margem.right, y);
      ctx.stroke();
      ctx.fillText(this._formatarMoedaCurta(valor), margem.left - 10, y);
    }

    dados.forEach((item, index) => {
      const centroX  = margem.left + grupoW * index + grupoW / 2;
      const receitaH = (Number(item.receita || 0) / maximo) * areaH;
      const despesaH = (Number(item.despesa || 0) / maximo) * areaH;
      const baseY    = margem.top + areaH;

      this._desenharBarra(ctx, centroX - barraW - 3, baseY - receitaH, barraW, receitaH, '#1a73e8');
      this._desenharBarra(ctx, centroX + 3,           baseY - despesaH, barraW, despesaH, '#dc2626');

      ctx.fillStyle    = '#64748b';
      ctx.textAlign    = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(item.mes_abrev || item.mes || '', centroX, baseY + 12);
    });
  },

  _desenharBarra(ctx, x, y, w, h, cor) {
    const altura = Math.max(2, h);
    ctx.fillStyle = cor;
    ctx.beginPath();
    ctx.roundRect(x, y + (h < 2 ? h - 2 : 0), w, altura, 4);
    ctx.fill();
  },

  renderizarDistribuicao(distribuicao) {
    const associados = Number(distribuicao.associados || 0);
    const dependentes = Number(distribuicao.dependentes || 0);
    const parceiros   = Number(distribuicao.parceiros   || 0);
    const total = associados + dependentes + parceiros;

    this._setTexto('[data-dist="associados"]',  associados.toLocaleString('pt-BR'));
    this._setTexto('[data-dist="dependentes"]', dependentes.toLocaleString('pt-BR'));
    this._setTexto('[data-dist="parceiros"]',   parceiros.toLocaleString('pt-BR'));
    this._setTexto('[data-dist-total]',         total.toLocaleString('pt-BR'));

    const donut = document.getElementById('dashboard-distribuicao');
    if (!donut) return;

    if (total === 0) {
      donut.style.background = 'conic-gradient(#e2e8f0 0 360deg)';
      return;
    }

    const p1 = (associados  / total) * 360;
    const p2 = p1 + (dependentes / total) * 360;
    donut.style.background =
      `conic-gradient(#1a73e8 0 ${p1}deg, #7c3aed ${p1}deg ${p2}deg, #ca8a04 ${p2}deg 360deg)`;
  },

  renderizarTransacoes(transacoes) {
    const tbody = document.querySelector('[data-tabela="ultimas-transacoes"] tbody');
    if (!tbody) return;

    if (!transacoes.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="tabela__vazio">Nenhuma transação registrada.</td></tr>';
      return;
    }

    tbody.innerHTML = transacoes.map(item => `
      <tr>
        <td>${formatarData(item.data_lancamento)}</td>
        <td>
          <span class="dashboard-tabela__principal">${this._escapar(item.descricao || '-')}</span>
          ${item.associado ? `<span class="dashboard-tabela__secundario">${this._escapar(item.associado)}</span>` : ''}
        </td>
        <td>${this._escapar(item.categoria || '-')}</td>
        <td class="tabela__num ${item.tipo === 'despesa' ? 'dashboard-tabela__valor--despesa' : 'dashboard-tabela__valor--receita'}">
          ${this._formatarMoeda(Number(item.valor_total || 0))}
        </td>
        <td><span class="badge badge-pilula ${this._statusClasse(item.status)}">${this._escapar(item.status || '-')}</span></td>
      </tr>
    `).join('');
  },

  _renderizarErroTabela() {
    const tbody = document.querySelector('[data-tabela="ultimas-transacoes"] tbody');
    if (tbody) {
      tbody.innerHTML = '<tr><td colspan="5" class="tabela__vazio">Não foi possível carregar os dados.</td></tr>';
    }
  },

  _registrarResize() {
    this._resizeHandler = () => this.renderizarGrafico(this._grafico);
    window.addEventListener('resize', this._resizeHandler);
  },

  _atualizarMesAtual() {
    const el = document.getElementById('dashboard-mes-atual');
    if (!el) return;
    el.textContent = new Date().toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
  },

  _mesesVazios() {
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return Array.from({ length: 6 }, (_, index) => {
      const data = new Date();
      data.setMonth(data.getMonth() - (5 - index));
      return { mes_abrev: meses[data.getMonth()], receita: 0, despesa: 0 };
    });
  },

  _formatarMoeda(valor) {
    return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  },

  _formatarMoedaCurta(valor) {
    const numero = Number(valor || 0);
    if (Math.abs(numero) >= 1000) return `R$ ${(numero / 1000).toFixed(1)}k`;
    return `R$ ${numero.toFixed(0)}`;
  },

  _statusClasse(status) {
    const s = String(status || '').toLowerCase();
    if (s.includes('liquidado') || s.includes('pago'))       return 'badge-verde';
    if (s.includes('aberto')    || s.includes('pendente'))   return 'badge-amarelo';
    if (s.includes('cancelado') || s.includes('atrasado'))   return 'badge-vermelho';
    return 'badge-cinza';
  },

  _setTexto(seletor, texto) {
    const el = document.querySelector(seletor);
    if (el) el.textContent = texto;
  },

  _escapar(texto) {
    const div = document.createElement('div');
    div.textContent = String(texto ?? '');
    return div.innerHTML;
  },

  destroy() {
    if (this._resizeHandler) {
      window.removeEventListener('resize', this._resizeHandler);
      this._resizeHandler = null;
    }
    this._grafico = [];
  },
};

export default DashboardPage;
