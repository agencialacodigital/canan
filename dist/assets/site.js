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
