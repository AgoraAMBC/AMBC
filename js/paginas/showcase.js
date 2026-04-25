/* ==========================================================================
   AMBC - Página: Showcase de Componentes
   Arquivo: js/paginas/showcase.js
   Descrição: Controller da página de vitrine dos componentes.
   ========================================================================== */
import Modal from '../componentes/modal.js';
import Toast from '../componentes/toast.js';


/**
 * Inicializa interações da página de showcase.
 * Chamado pelo router após o HTML da view ser injetado no DOM.
 */
function init() {
  console.log('[Showcase] Página carregada ✅');

  ativarBotoesFechar();
  ativarDemoValidacao();
}

/**
 * Limpeza ao sair da página (chamado pelo router antes de trocar de rota).
 */
function destroy() {
  console.log('[Showcase] Página destruída 👋');
  // Nada específico a limpar por enquanto — listeners morrem junto com o DOM.
}

/**
 * Faz os alertas com botão "X" desaparecerem ao clicar.
 */
function ativarBotoesFechar() {
  const botoes = document.querySelectorAll('.alerta__fechar');

  botoes.forEach((btn) => {
    btn.addEventListener('click', () => {
      const alerta = btn.closest('.alerta');
      if (!alerta) return;

      alerta.style.transition = 'opacity 200ms ease';
      alerta.style.opacity = '0';

      setTimeout(() => alerta.remove(), 220);
    });
  });
}

/**
 * Demo simples: alterna classe .invalido/.valido no input com data-demo="validacao".
 */
function ativarDemoValidacao() {
  const input = document.querySelector('[data-demo="validacao"]');
  if (!input) return;

  input.addEventListener('blur', () => {
    const valor = input.value.trim();
    input.classList.remove('invalido', 'valido');

    if (valor.length === 0) return;
    if (valor.length < 3) {
      input.classList.add('invalido');
    } else {
      input.classList.add('valido');
    }
  });
}

/* ---------------------------------------------------------
   EXPORT (padrão ES6 Module)
--------------------------------------------------------- */
export default {
  init,
  destroy
};
// ============================================
// 💫 MODAIS — handlers de exemplo
// ============================================

// Modal de confirmação (exclusão — variante perigo)
document.getElementById('btn-confirmar-excluir')?.addEventListener('click', () => {
  Modal.confirmar({
    titulo: 'Excluir associado?',
    mensagem: 'Esta ação não pode ser desfeita. Todos os dados do associado serão removidos permanentemente.',
    icone: 'delete_forever',
    variante: 'erro',
    textoConfirmar: 'Sim, excluir',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'perigo',
    aoConfirmar: () => console.log('✅ Confirmou exclusão'),
    aoCancelar: () => console.log('❌ Cancelou exclusão'),
  });
});

// Modal de confirmação (salvar — variante sucesso)
document.getElementById('btn-confirmar-salvar')?.addEventListener('click', () => {
  Modal.confirmar({
    titulo: 'Salvar alterações?',
    mensagem: 'As alterações serão aplicadas imediatamente no cadastro do associado.',
    icone: 'check_circle',
    variante: 'sucesso',
    textoConfirmar: 'Salvar',
    textoCancelar: 'Cancelar',
    estiloConfirmar: 'sucesso',
    aoConfirmar: () => console.log('✅ Salvou'),
  });
});

// Modal de confirmação (logout — variante alerta)
document.getElementById('btn-confirmar-logout')?.addEventListener('click', () => {
  Modal.confirmar({
    titulo: 'Sair do sistema?',
    mensagem: 'Você precisará fazer login novamente para acessar a plataforma.',
    icone: 'logout',
    variante: 'alerta',
    textoConfirmar: 'Sair',
    textoCancelar: 'Continuar',
    estiloConfirmar: 'primario',
    aoConfirmar: () => console.log('👋 Saiu'),
  });
});

// Previne submit do form de exemplo (só pra demo)
document.getElementById('form-exemplo-modal')?.addEventListener('submit', (e) => {
  e.preventDefault();
  console.log('📝 Formulário submetido');
  Modal.fechar('modal-exemplo-form');
});
// ============================================
// 🔔 TOASTS — handlers de exemplo
// ============================================

document.getElementById('btn-toast-sucesso')?.addEventListener('click', () => {
  Toast.sucesso('Associado cadastrado com sucesso!');
});

document.getElementById('btn-toast-erro')?.addEventListener('click', () => {
  Toast.erro('Falha ao salvar. Verifique sua conexão e tente novamente.');
});

document.getElementById('btn-toast-alerta')?.addEventListener('click', () => {
  Toast.alerta('A mensalidade vence amanhã.');
});

document.getElementById('btn-toast-info')?.addEventListener('click', () => {
  Toast.info('Backup automático concluído às 14:30.');
});

document.getElementById('btn-toast-titulo')?.addEventListener('click', () => {
  Toast.exibir({
    tipo: 'sucesso',
    titulo: 'Pagamento confirmado',
    mensagem: 'O pagamento de R$ 50,00 foi registrado para João da Silva.',
  });
});

document.getElementById('btn-toast-longo')?.addEventListener('click', () => {
  Toast.exibir({
    tipo: 'info',
    titulo: 'Toast de longa duração',
    mensagem: 'Este toast ficará visível por 10 segundos. Passe o mouse pra pausar o timer.',
    duracao: 10000,
  });
});

document.getElementById('btn-toast-permanente')?.addEventListener('click', () => {
  Toast.exibir({
    tipo: 'alerta',
    titulo: 'Atenção necessária',
    mensagem: 'Este toast só fecha se você clicar no X. Útil pra mensagens críticas.',
    duracao: 0,
  });
});

document.getElementById('btn-toast-multi')?.addEventListener('click', () => {
  Toast.sucesso('Primeiro toast — Cadastro concluído');
  setTimeout(() => Toast.info('Segundo toast — Enviando e-mail...'), 300);
  setTimeout(() => Toast.alerta('Terceiro toast — Conexão lenta'), 600);
  setTimeout(() => Toast.erro('Quarto toast — Falha em uma operação'), 900);
});

document.getElementById('btn-toast-limpar')?.addEventListener('click', () => {
  Toast.limparTodos();
});

// Mudança de posição
document.querySelectorAll('[data-posicao-toast]').forEach(btn => {
  btn.addEventListener('click', () => {
    const posicao = btn.dataset.posicaoToast;
    Toast.configurar({ posicao });
    Toast.info(`Posição alterada para: ${posicao}`);
  });
});
