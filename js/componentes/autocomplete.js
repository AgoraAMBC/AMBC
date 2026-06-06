let uid = 0;

function escaparHtml(texto) {
  if (typeof texto !== 'string') return '';
  const div = document.createElement('div');
  div.textContent = texto;
  return div.innerHTML;
}

export function criarAutocomplete(input, opcoes) {
  const { buscar, aoSelecionar, minimoCaracteres = 2, delay = 300 } = opcoes;

  const id = `autocomplete-${++uid}`;
  let timeoutId = null;
  let aberto = false;
  let indiceSelecionado = -1;
  let resultados = [];
  let itemSelecionado = null;

  const wrapper = document.createElement('div');
  wrapper.className = 'autocomplete';
  wrapper.id = id;
  input.parentNode.insertBefore(wrapper, input);
  wrapper.appendChild(input);

  const lista = document.createElement('ul');
  lista.className = 'autocomplete__lista';
  lista.setAttribute('role', 'listbox');
  wrapper.appendChild(lista);

  const fechar = () => {
    aberto = false;
    indiceSelecionado = -1;
    resultados = [];
    lista.innerHTML = '';
    lista.classList.remove('autocomplete__lista--aberta');
  };

  const abrir = (itens) => {
    aberto = true;
    indiceSelecionado = -1;
    resultados = itens;
    lista.innerHTML = itens
      .map(
        (item, i) =>
          `<li class="autocomplete__item" role="option" data-indice="${i}">
            <span class="autocomplete__item-nome">${escaparHtml(item.rotulo || item.nome || '')}</span>
            <span class="autocomplete__item-tipo">${item.tipo === 'associado' ? 'Associado' : 'Parceiro'}</span>
          </li>`
      )
      .join('');
    lista.classList.add('autocomplete__lista--aberta');
  };

  const selecionar = (item) => {
    itemSelecionado = item;
    input.value = item.rotulo || item.nome || '';
    input.dataset.autocompleteId = String(item.id);
    input.dataset.autocompleteTipo = item.tipo;
    fechar();
    if (typeof aoSelecionar === 'function') aoSelecionar(item);
  };

  const handlerInput = () => {
    const termo = input.value.trim();
    itemSelecionado = null;
    input.dataset.autocompleteId = '';

    if (timeoutId) clearTimeout(timeoutId);

    if (termo.length < minimoCaracteres) {
      fechar();
      return;
    }

    timeoutId = setTimeout(async () => {
      try {
        const itens = await buscar(termo);
        if (!Array.isArray(itens) || itens.length === 0) {
          fechar();
          return;
        }
        abrir(itens);
      } catch {
        fechar();
      }
    }, delay);
  };

  const handlerTecla = (e) => {
    if (!aberto) return;
    const itensLi = lista.querySelectorAll('.autocomplete__item');
    if (!itensLi.length) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      indiceSelecionado = Math.min(indiceSelecionado + 1, itensLi.length - 1);
      atualizarDestaque(itensLi);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      indiceSelecionado = Math.max(indiceSelecionado - 1, 0);
      atualizarDestaque(itensLi);
    } else if (e.key === 'Enter' || e.key === 'Tab') {
      if (indiceSelecionado >= 0 && resultados[indiceSelecionado]) {
        e.preventDefault();
        selecionar(resultados[indiceSelecionado]);
      }
    } else if (e.key === 'Escape') {
      fechar();
    }
  };

  const handlerBlur = () => {
    setTimeout(() => {
      if (!wrapper.contains(document.activeElement)) fechar();
    }, 200);
  };

  const handlerFocus = () => {
    if (input.value.trim().length >= minimoCaracteres) {
      handlerInput();
    }
  };

  const handlerClickFora = (e) => {
    if (!wrapper.contains(e.target)) fechar();
  };

  const atualizarDestaque = (itensLi) => {
    itensLi.forEach((el, i) => {
      el.classList.toggle('autocomplete__item--destacado', i === indiceSelecionado);
      if (i === indiceSelecionado) el.scrollIntoView({ block: 'nearest' });
    });
  };

  lista.addEventListener('mousedown', (e) => {
    const li = e.target.closest('.autocomplete__item');
    if (!li) return;
    e.preventDefault();
    const idx = parseInt(li.dataset.indice);
    if (resultados[idx]) selecionar(resultados[idx]);
  });

  input.addEventListener('input', handlerInput);
  input.addEventListener('keydown', handlerTecla);
  input.addEventListener('blur', handlerBlur);
  input.addEventListener('focus', handlerFocus);
  document.addEventListener('mousedown', handlerClickFora);

  const destruir = () => {
    if (timeoutId) clearTimeout(timeoutId);
    input.removeEventListener('input', handlerInput);
    input.removeEventListener('keydown', handlerTecla);
    input.removeEventListener('blur', handlerBlur);
    input.removeEventListener('focus', handlerFocus);
    document.removeEventListener('mousedown', handlerClickFora);
    wrapper.replaceWith(input);
  };

  const limpar = () => {
    itemSelecionado = null;
    input.value = '';
    input.dataset.autocompleteId = '';
    input.dataset.autocompleteTipo = '';
    fechar();
  };

  return { destruir, limpar, valor: () => itemSelecionado };
}
