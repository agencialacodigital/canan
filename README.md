# Canan Home Decor

Site estático multipágina em português, gerado a partir de `content/Canan_Home_Decor_Copy_Completa.md`. A pasta `dist/` contém somente os arquivos públicos.

## Rodar no Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\serve.ps1
```

Abra `http://localhost:8080/`. Também é possível abrir `dist/index.html` diretamente: nesse modo, o JavaScript adapta os links para os arquivos `index.html`. Na publicação, os links usam as URLs canônicas com barra final. Envie o conteúdo de `dist/` para uma hospedagem de arquivos estáticos que sirva `index.html` em cada diretório e responda com status HTTP 404 quando a página não existir.

## O que está implementado

- Home, índice de produtos, Sobre, Contato e dez páginas de linhas de produtos.
- Logos oficiais em versões para fundo claro e escuro; identidade em grafite `#333333` e dourado `#B59548`.
- Layout responsivo, navegação para celular, metadados por página, URLs canônicas, sitemap, robots.txt, dados estruturados e página 404.
- Fotos em tamanhos responsivos e CSS consolidado na geração para reduzir transferências e solicitações de arquivos.
- Fotos editoriais geradas para este projeto, identificadas como ilustrativas. Não representam projetos realizados da Canan.
- Formulário que prepara um e-mail no aplicativo do visitante. Não há envio por servidor nem armazenamento de dados.

## Antes de publicar

- Confirmar telefone, e-mail, WhatsApp, endereço, horário e condições de atendimento. O WhatsApp e o mapa aguardam dados oficiais.
- Substituir o formulário por um endpoint real quando o backend for definido e publicar uma Política de Privacidade correspondente.
- Conferir se o domínio cananhomedecor.com.br será o destino final e mapear redirecionamentos das URLs antigas.
- Configurar redirecionamento permanente de HTTP e `www` para a versão canônica escolhida e cadastrar o sitemap no Google Search Console, conforme a hospedagem.
- Medir Core Web Vitals na versão publicada; a pasta local não reproduz rede, cache e compressão da hospedagem.
- Validar materiais, fotos de projetos reais e direitos de uso antes de adicionar portfólio, depoimentos ou promessas comerciais.

## Imagens geradas

Modo: ferramenta integrada `image_gen`. Arquivos finais: `assets/hero.jpg`, `assets/curtains.jpg`, `assets/rugs.jpg`, `assets/bedroom.jpg`, `assets/blinds.jpg`, `assets/bath.jpg` e `assets/wallpaper.jpg`. Foram comprimidos como JPEG de qualidade 84–85 para a versão pública.

Prompts resumidos: (1) interior editorial amplo com três arcos, tecidos, sofá, tapete e céu azul; (2) cortinas claras em sala com cadeira bouclé; (3) sala com tapete orgânico e móveis escultóricos; (4) quarto com roupa de cama em camadas e papel de parede sutil; (5) persianas horizontais de madeira em uma sala; (6) toalhas em banheiro; (7) parede com papel botânico discreto. Todos pediram fotografia realista, luz natural e ausência de pessoas, textos e logotipos.
