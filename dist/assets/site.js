const menuButton = document.querySelector('.menu-toggle');
// Directory URLs stay canonical online; local previews need the explicit file.
if (location.protocol === 'file:') {
  document.querySelectorAll('a[href]').forEach(link => {
    const raw = link.getAttribute('href');
    if (!raw || !/^\.\.?\//.test(raw)) return;
    const url = new URL(raw, location.href);
    if (!url.pathname.endsWith('/')) return;
    url.pathname += 'index.html';
    link.href = url.href;
  });
}
const menu = document.querySelector('.main-nav');
if (menuButton && menu) {
  menuButton.addEventListener('click', () => {
    const open = menu.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Fechar menu' : 'Abrir menu');
  });
  menu.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
    menu.classList.remove('open');
    menuButton.setAttribute('aria-expanded', 'false');
    menuButton.setAttribute('aria-label', 'Abrir menu');
  }));
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
      menu.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
      menuButton.setAttribute('aria-label', 'Abrir menu');
    }
  });
}

const form = document.querySelector('#contact-form');
if (form) {
  const interest = new URLSearchParams(location.search).get('interesse');
  const map = {
    cortinas: 'Cortinas', persianas: 'Persianas', tapetes: 'Tapetes',
    'papeis-de-parede': 'Papéis de parede', moveis: 'Móveis', decoracao: 'Decoração',
    cama: 'Cama', banho: 'Banho', 'mantas-almofadas': 'Estar',
    'cama-banho-estar': 'Ainda quero conhecer as opções'
  };
  if (interest && map[interest]) form.elements.produto.value = map[interest];
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const data = new FormData(form);
    const fields = [
      `Nome: ${data.get('nome')}`,
      `Telefone: ${data.get('telefone')}`,
      `E-mail: ${data.get('email') || 'não informado'}`,
      `Produto: ${data.get('produto')}`,
      '',
      String(data.get('mensagem')).trim()
    ];
    const subject = `Contato pelo site Canan — ${data.get('produto')}`;
    const url = `mailto:contato@cananhomedecor.com.br?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(fields.join('\n'))}`;
    form.querySelector('.form-status').textContent = 'Abrindo seu aplicativo de e-mail. Revise e envie a mensagem por lá.';
    location.href = url;
  });
}

// ---- Botão flutuante do WhatsApp ----
// Informe o número oficial (com DDI e DDD, só dígitos), ex.: '5544999999999'.
// Enquanto estiver vazio, o botão leva à página de contato.
const WHATSAPP_NUMBER = '5544999469402';
(function () {
  const scriptSrc = document.currentScript && document.currentScript.src;
  const root = scriptSrc ? new URL('../', scriptSrc) : new URL('./', location.href);
  const fileMode = location.protocol === 'file:';
  const contactUrl = new URL('contato/', root).href + (fileMode ? 'index.html' : '');
  const messages = {
    cortinas: 'Olá! Vim pelo site e gostaria de solicitar um orçamento de cortinas sob medida.',
    persianas: 'Olá! Vim pelo site e gostaria de conhecer as opções de persianas para meu ambiente.',
    tapetes: 'Olá! Vim pelo site e gostaria de consultar tapetes para meu ambiente.',
    'papeis-de-parede': 'Olá! Vim pelo site e gostaria de conhecer os modelos de papel de parede.',
    moveis: 'Olá! Vim pelo site e gostaria de consultar os móveis disponíveis.',
    decoracao: 'Olá! Vim pelo site e gostaria de conhecer os objetos decorativos disponíveis.',
    cama: 'Olá! Vim pelo site e gostaria de conhecer a linha Cama.',
    banho: 'Olá! Vim pelo site e gostaria de consultar as toalhas disponíveis.',
    'mantas-almofadas': 'Olá! Vim pelo site e gostaria de conhecer as mantas e almofadas decorativas.'
  };
  const general = 'Olá! Vim pelo site da Canan Home Decor e gostaria de conhecer as opções para o meu ambiente.';
  const parts = location.pathname.split('/').filter(Boolean).filter(p => p !== 'index.html');
  const message = messages[parts[parts.length - 1]] || general;
  const href = WHATSAPP_NUMBER
    ? `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`
    : contactUrl;
  const external = Boolean(WHATSAPP_NUMBER);

  document.querySelectorAll('a[data-wa]').forEach(a => { a.href = href; });
  if (WHATSAPP_NUMBER) document.querySelectorAll('[data-wa-card]').forEach(el => { el.hidden = false; });

  const widget = document.createElement('div');
  widget.className = 'wa-widget';
  widget.innerHTML =
    '<div class="wa-bubble" role="dialog" aria-label="Convite para atendimento" hidden>' +
      '<button class="wa-close" type="button" aria-label="Fechar mensagem">&times;</button>' +
      '<strong>Olá!</strong>' +
      '<p>Que tal solicitar um orçamento agora, sem compromisso? Conte o que você procura e a equipe da Canan ajuda você.</p>' +
      '<a class="wa-go" href="#">Solicitar orçamento</a>' +
    '</div>' +
    '<a class="wa-fab" href="#" aria-label="Falar com a Canan pelo WhatsApp">' +
      '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M16.04 3C9.4 3 4.02 8.37 4.02 15c0 2.12.55 4.18 1.6 6L4 29l8.2-1.58A12 12 0 0 0 16.04 27C22.67 27 28.05 21.63 28.05 15S22.67 3 16.04 3Zm0 21.9c-1.8 0-3.55-.48-5.08-1.38l-.36-.21-4.87.94.99-4.74-.24-.38A9.9 9.9 0 0 1 6.1 15c0-5.46 4.46-9.9 9.94-9.9 5.47 0 9.93 4.44 9.93 9.9 0 5.46-4.46 9.9-9.93 9.9Zm5.45-7.4c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.47-.89-.79-1.49-1.76-1.66-2.06-.17-.3-.02-.46.13-.6.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.08-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.8.37-.27.3-1.04 1.02-1.04 2.49s1.07 2.89 1.22 3.09c.15.2 2.1 3.2 5.08 4.49.71.3 1.26.49 1.7.63.71.23 1.36.2 1.87.12.57-.08 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.07-.12-.27-.2-.57-.35Z"/></svg>' +
    '</a>';
  document.body.appendChild(widget);
  const fab = widget.querySelector('.wa-fab');
  const bubble = widget.querySelector('.wa-bubble');
  const go = widget.querySelector('.wa-go');
  [fab, go].forEach(a => {
    a.href = href;
    if (external) { a.target = '_blank'; a.rel = 'noopener'; }
  });

  let dismissed = false;
  try { dismissed = sessionStorage.getItem('canan-wa-dismissed') === '1'; } catch (e) { /* storage indisponível */ }
  const close = () => {
    bubble.classList.remove('is-visible');
    setTimeout(() => { bubble.hidden = true; }, 350);
    try { sessionStorage.setItem('canan-wa-dismissed', '1'); } catch (e) { /* ignora */ }
  };
  widget.querySelector('.wa-close').addEventListener('click', close);
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && !bubble.hidden) close(); });
  if (!dismissed) {
    setTimeout(() => {
      bubble.hidden = false;
      requestAnimationFrame(() => bubble.classList.add('is-visible'));
    }, 10000);
  }
})();

// ---- Carrossel da home ----
(function () {
  const root = document.querySelector('.hero-carousel');
  if (!root) return;
  const slides = Array.from(root.querySelectorAll('.hero-slide'));
  const dots = Array.from(root.querySelectorAll('.hero-dots button'));
  if (slides.length < 2) return;
  // Rotação automática sempre ativa (pedido do cliente); em aparelhos sem mouse não há pausa por hover.
  const canHover = window.matchMedia && window.matchMedia('(hover: hover)').matches;
  const INTERVAL = 5000;
  let current = 0;
  let timer = null;
  const show = index => {
    current = (index + slides.length) % slides.length;
    slides.forEach((slide, i) => slide.classList.toggle('is-active', i === current));
    dots.forEach((dot, i) => {
      dot.classList.toggle('is-active', i === current);
      if (i === current) dot.setAttribute('aria-current', 'true'); else dot.removeAttribute('aria-current');
    });
  };
  const start = () => { if (!timer) timer = setInterval(() => show(current + 1), INTERVAL); };
  const stop = () => { clearInterval(timer); timer = null; };
  dots.forEach((dot, i) => dot.addEventListener('click', () => { show(i); stop(); start(); }));
  if (canHover) {
    root.addEventListener('mouseenter', stop);
    root.addEventListener('mouseleave', start);
  }
  document.addEventListener('visibilitychange', () => { if (document.hidden) stop(); else start(); });
  start();
})();

// ---- Velocidade da faixa de linhas ----
// A duração é calculada pela largura real do conteúdo, para manter a mesma
// velocidade (px/s) em qualquer tela. Valores menores = mais devagar.
(function () {
  const track = document.querySelector('.ticker-track');
  const group = track && track.querySelector('.ticker-group');
  if (!group) return;
  const SPEED_DESKTOP = 30; // px por segundo
  const SPEED_MOBILE = 14;  // px por segundo
  const apply = () => {
    const width = group.getBoundingClientRect().width;
    if (!width) return;
    const speed = window.innerWidth <= 760 ? SPEED_MOBILE : SPEED_DESKTOP;
    track.style.animationDuration = Math.round(width / speed) + 's';
  };
  apply();
  window.addEventListener('resize', apply);
  window.addEventListener('load', apply);
  // Recalcula quando as fontes terminam de carregar (a largura muda).
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(apply);
  if (window.ResizeObserver) new ResizeObserver(apply).observe(group);
})();
