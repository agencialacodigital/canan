# Canan Home Decor

Site estático multipágina em português para a Canan Home Decor (Maringá/PR). A pasta `dist/` contém somente os arquivos públicos e é a versão publicada.

## Publicar

O site é 100% estático. Basta servir a pasta `dist/`.

- **Vercel:** o `vercel.json` já aponta `outputDirectory` para `dist` e não usa build. Importe o repositório e faça o deploy.
- **Outra hospedagem:** envie o conteúdo de `dist/` e sirva `index.html` em cada diretório, respondendo com status 404 para páginas inexistentes (`dist/404.html`).

## Rodar localmente

```bash
python3 -m http.server 8080 --directory dist
```

Abra `http://localhost:8080/`. No Windows também funciona `serve.ps1`.

> **Atenção:** a pasta `dist/` é a fonte da verdade atual. Os ajustes de copy, galerias, carrossel, faixa rotativa, rodapé e endereço foram feitos direto nela. O `build.ps1` e o `content/Canan_Home_Decor_Copy_Completa.md` **não** reproduzem todas essas alterações. Não rode o `build.ps1` sem antes revisá-lo, pois ele sobrescreve `dist/`.

## Configurações rápidas

- **WhatsApp:** preencha `WHATSAPP_NUMBER` no início do bloco "Botão flutuante do WhatsApp" em `assets/site.js` (e em `dist/assets/site.js`), com DDI e DDD, só dígitos (ex.: `5544999999999`). Enquanto estiver vazio, o botão leva à página de Contato.
- **Endereço:** R. Santos Dumont, 129 - loja A - Zona 01, Maringá - PR, 87050-100 (rodapé, Contato e dados estruturados).
- **Carrossel da home:** imagens `dist/assets/hero-sala.jpg` e `hero-persianas.jpg`, intervalo de 5 s em `assets/site.js`.

## O que está implementado

- Home, índice de produtos, Sobre, Contato e dez páginas de linhas de produtos.
- Logos oficiais em versões para fundo claro e escuro; identidade em grafite `#333333` e dourado `#B59548`.
- Layout responsivo, navegação para celular, metadados por página, URLs canônicas, sitemap, robots.txt, dados estruturados e página 404.
- Fotos em tamanhos responsivos e CSS consolidado na geração para reduzir transferências e solicitações de arquivos.
- Fotos reais da Canan nas páginas de produtos. Permanecem ilustrativas (geradas) apenas a imagem da página Sobre e a hero antiga (`hero.jpg`), identificadas na página.
- Formulário que prepara um e-mail no aplicativo do visitante. Não há envio por servidor nem armazenamento de dados.
- Carrossel na home, faixa de linhas rotativa e botão flutuante do WhatsApp com convite após 10 segundos.

## Antes de publicar

- Confirmar telefone, e-mail, WhatsApp, horário e condições de atendimento. O número de WhatsApp e o horário aguardam dados oficiais.
- Substituir o formulário por um endpoint real quando o backend for definido e publicar uma Política de Privacidade correspondente.
- Conferir se o domínio cananhomedecor.com.br será o destino final e mapear redirecionamentos das URLs antigas.
- Configurar redirecionamento permanente de HTTP e `www` para a versão canônica escolhida e cadastrar o sitemap no Google Search Console, conforme a hospedagem.
- Medir Core Web Vitals na versão publicada; a pasta local não reproduz rede, cache e compressão da hospedagem.
- Validar materiais, fotos de projetos reais e direitos de uso antes de adicionar portfólio, depoimentos ou promessas comerciais.

## Imagens geradas

Modo: ferramenta integrada `image_gen`. Arquivos finais: `assets/hero.jpg`, `assets/curtains.jpg`, `assets/rugs.jpg`, `assets/bedroom.jpg`, `assets/blinds.jpg`, `assets/bath.jpg` e `assets/wallpaper.jpg`. Foram comprimidos como JPEG de qualidade 84–85 para a versão pública.

Prompts resumidos: (1) interior editorial amplo com três arcos, tecidos, sofá, tapete e céu azul; (2) cortinas claras em sala com cadeira bouclé; (3) sala com tapete orgânico e móveis escultóricos; (4) quarto com roupa de cama em camadas e papel de parede sutil; (5) persianas horizontais de madeira em uma sala; (6) toalhas em banheiro; (7) parede com papel botânico discreto. Todos pediram fotografia realista, luz natural e ausência de pessoas, textos e logotipos.
