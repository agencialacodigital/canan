$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$outputRoot = Join-Path $root 'dist'
$copy = [System.IO.File]::ReadAllText((Join-Path $root 'content\Canan_Home_Decor_Copy_Completa.md'), [System.Text.Encoding]::UTF8).Replace("`r`n", "`n")
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force -Path (Join-Path $outputRoot 'assets') | Out-Null
Copy-Item -Path (Join-Path $root 'assets\*') -Destination (Join-Path $outputRoot 'assets') -Force
[System.IO.File]::WriteAllText((Join-Path $outputRoot 'assets\site.css'), ([System.IO.File]::ReadAllText((Join-Path $root 'assets\site.css')) + "`n" + [System.IO.File]::ReadAllText((Join-Path $root 'assets\brand.css'))), $utf8)

function Save-Page([string]$route, [string]$html) {
  $path = if ($route -eq '/') { Join-Path $outputRoot 'index.html' } else { Join-Path $outputRoot ($route.Trim('/') + '\index.html') }
  $dir = Split-Path $path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [System.IO.File]::WriteAllText($path, $html, $utf8)
}
function E([string]$value) { return [System.Net.WebUtility]::HtmlEncode($value) }
function Inline([string]$value) {
  $encoded = E ($value.Trim())
  $encoded = [regex]::Replace($encoded, '\*\*(.*?)\*\*', '<strong>$1</strong>')
  return $encoded
}
function Get-Sections([string]$body) {
  $marks = [regex]::Matches($body, '(?m)^## (?:H[12]: )?([^\n]+)$')
  $result = @()
  for ($i = 0; $i -lt $marks.Count; $i++) {
    $start = $marks[$i].Index + $marks[$i].Length
    $end = if ($i + 1 -lt $marks.Count) { $marks[$i + 1].Index } else { $body.Length }
    $result += [pscustomobject]@{ heading = $marks[$i].Groups[1].Value.Trim(); text = $body.Substring($start, $end - $start).Trim() }
  }
  return $result
}
function Render-Text([string]$value, [string]$interest) {
  $value = [regex]::Replace($value, '(?ms)^\*\*(?:Nota de implementação|Seção complementar|Bloco adicional).*$', '')
  $blocks = $value.Trim() -split '\n\s*\n'
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($block in $blocks) {
    $b = $block.Trim()
    if (-not $b -or $b -eq '---' -or $b -match '^\*\*(?:URL|Título SEO|Meta description|Texto de abertura):') { continue }
    if ($b -match '^\*\*(?:CTA(?: principal| secundário| do WhatsApp| do telefone| do e-mail)?|Botão):\*\*\s*(.+)') {
      $label = $Matches[1].Trim()
      $href = if ($label -match 'produtos|Explore nossos') { '/produtos/' } else { '/contato/?interesse=' + [uri]::EscapeDataString($interest) }
      $out.Add('<a class="text-link" href="' + $href + '">' + (E $label) + '<span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a>')
      continue
    }
    if ($b -match '^\*\*Links relacionados:\*\*\s*(.+)') {
      $related = foreach ($item in ($Matches[1] -split '\s*\|\s*')) {
        $name = $item.Trim()
        $route = switch -Regex ($name) {
          'persianas' { '/persianas/'; break }
          'cortinas' { '/cortinas/'; break }
          'tapetes' { '/tapetes/'; break }
          'papéis de parede' { '/papeis-de-parede/'; break }
          'móveis' { '/moveis/'; break }
          'mantas|almofadas' { '/mantas-almofadas/'; break }
          'banho' { '/banho/'; break }
          'cama, banho e estar' { '/cama-banho-estar/'; break }
          'cama' { '/cama/'; break }
          'decoração|decorativos' { '/decoracao/'; break }
          default { '' }
        }
        if ($route) { '<a href="' + $route + '">' + (E $name) + ' <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a>' }
      }
      if ($related) { $out.Add('<nav class="related-links" aria-label="Links relacionados">' + ($related -join '') + '</nav>') }
      continue
    }
    if ($b -match '^\*\*([^*]+\?)\*\*\n([\s\S]+)') {
      $out.Add('<details class="faq-item"><summary>' + (E $Matches[1]) + '</summary><p>' + (Inline $Matches[2].Replace("`n", ' ')) + '</p></details>')
      continue
    }
    if ($b -match '^### (?:H2: )?(.+)\n([\s\S]+)') {
      $out.Add('<h3>' + (E $Matches[1]) + '</h3><p>' + (Inline $Matches[2].Replace("`n", ' ')) + '</p>')
      continue
    }
    if ($b -match '^\*\*(?:Campos do formulário|Texto de apoio|Telefone|E-mail|WhatsApp|Endereço|Horário de atendimento):') { continue }
    $out.Add('<p>' + (Inline $b.Replace("`n", ' ')) + '</p>')
  }
  return ($out -join "`n")
}

$products = @(
  [pscustomobject]@{name='Cortinas'; slug='cortinas'; image='curtains.jpg'; text='Tecidos, acabamentos e opções de automação em soluções sob medida para cada ambiente.'; number='01'},
  [pscustomobject]@{name='Persianas'; slug='persianas'; image='blinds.jpg'; text='Controle de luz e estética em modelos personalizados, manuais ou automatizados.'; number='02'},
  [pscustomobject]@{name='Tapetes'; slug='tapetes'; image='rugs.jpg'; text='Texturas e formatos para aproximar os elementos do ambiente.'; number='03'},
  [pscustomobject]@{name='Papéis de parede'; slug='papeis-de-parede'; image='wallpaper.jpg'; text='Estampas, texturas e painéis para dar uma nova presença às paredes.'; number='04'},
  [pscustomobject]@{name='Móveis'; slug='moveis'; image='moveis.jpg'; text='Uma curadoria de peças que considera design, conforto e uso no dia a dia.'; number='05'},
  [pscustomobject]@{name='Decoração'; slug='decoracao'; image='decoracao.jpg'; text='Objetos e detalhes que completam a composição da sua casa.'; number='06'},
  [pscustomobject]@{name='Cama, Banho e Estar'; slug='cama-banho-estar'; image='bedroom.jpg'; text='Têxteis para os espaços que acompanham a sua rotina.'; number='07'}
)
$extras = @(
  [pscustomobject]@{name='Cama'; slug='cama'; image='bedroom.jpg'},
  [pscustomobject]@{name='Banho'; slug='banho'; image='bedroom.jpg'},
  [pscustomobject]@{name='Estar'; slug='mantas-almofadas'; image='rugs.jpg'}
)
$imageByRoute = @{'sobre'='hero.jpg'; 'cortinas'='curtains.jpg'; 'persianas'='blinds.jpg'; 'tapetes'='rugs.jpg'; 'papeis-de-parede'='wallpaper.jpg'; 'moveis'='moveis.jpg'; 'decoracao'='decoracao.jpg'; 'cama-banho-estar'='bedroom.jpg'; 'cama'='bedroom.jpg'; 'banho'='bath.jpg'; 'mantas-almofadas'='rugs.jpg'}
$labelByRoute = @{'sobre'='Sobre a Canan'; 'cortinas'='Cortinas'; 'persianas'='Persianas'; 'tapetes'='Tapetes'; 'papeis-de-parede'='Papéis de parede'; 'moveis'='Móveis'; 'decoracao'='Decoração'; 'cama-banho-estar'='Cama, Banho e Estar'; 'cama'='Cama'; 'banho'='Banho'; 'mantas-almofadas'='Estar'}

function Header([string]$current) {
  $items = @('<a href="/"' + $(if ($current -eq '/') {' aria-current="page"'} else {''}) + '>Início</a>', '<a href="/produtos/"' + $(if ($current -eq '/produtos/') {' aria-current="page"'} else {''}) + '>Produtos</a>', '<a href="/sobre/"' + $(if ($current -eq '/sobre/') {' aria-current="page"'} else {''}) + '>Sobre a Canan</a>', '<a href="/contato/"' + $(if ($current -eq '/contato/') {' aria-current="page"'} else {''}) + '>Contato</a>')
  return '<header class="site-header"><div class="header-inner"><a class="brand" href="/" aria-label="Canan Home Decor, início"><img src="/assets/logo-canan-dark.png" alt="" width="660" height="367"></a><button class="menu-toggle" type="button" aria-label="Abrir menu" aria-expanded="false" aria-controls="main-nav"><span></span><span></span></button><nav id="main-nav" class="main-nav" aria-label="Navegação principal">' + ($items -join '') + '</nav><a class="header-cta" href="/contato/">Fale com a Canan <span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a></div></header>'
}
function Footer() {
  $links = ($products | ForEach-Object { '<a href="/' + $_.slug + '/">' + (E $_.name) + '</a>' }) -join ''
  return '<footer class="footer"><div class="footer-top"><div><a class="footer-brand" href="/" aria-label="Canan Home Decor, início"><img src="/assets/logo-canan-light.png" alt="" width="660" height="367" loading="lazy"></a><p>Somos referência em Cortinas, Persianas, Papel de Parede, Tapetes, Móveis, Decorações, Cama, Banho e Estar em Maringá / PR.</p><p class="footer-address">R. Santos Dumont, 129 - loja A - Zona 01, Maringá - PR, 87050-100</p></div><div><h2>Explore</h2><a href="/">Início</a><a href="/produtos/">Produtos</a><a href="/sobre/">Sobre a Canan</a><a href="/contato/">Contato</a></div><div><h2>Produtos</h2>' + $links + '</div><div class="footer-contact"><h2>Seu próximo ambiente começa aqui.</h2><a class="button button-light" href="/contato/">Vamos conversar <span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a></div></div><div class="footer-bottom"><span>© 2026 Canan Home Decor</span><span>Maringá · Paraná</span><a href="#top">Voltar ao topo <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 19V5M6 11l6-6 6 6"/></svg></a></div></footer>'
}
function Layout([string]$title, [string]$description, [string]$route, [string]$content) {
  $prefix = if ($route -eq '/') { '.' } else { '..' }
  $site = 'https://cananhomedecor.com.br'
  $socialImage = if ($imageByRoute.ContainsKey($route.Trim('/'))) { $imageByRoute[$route.Trim('/')] } else { 'hero.jpg' }
  $socialWidth = if ($socialImage -eq 'hero.jpg') { 2055 }  elseif ($socialImage -eq 'decoracao.jpg') { 1086 } elseif ($socialImage -eq 'bath.jpg') { 1068 } elseif ($socialImage -in @('curtains.jpg','blinds.jpg','rugs.jpg','wallpaper.jpg','decoracao.jpg','bedroom.jpg','moveis.jpg')) { 941 } else { 1024 }
  $socialHeight = if ($socialImage -eq 'hero.jpg') { 765 } elseif ($socialImage -eq 'rugs.jpg') { 1254 }  elseif ($socialImage -eq 'decoracao.jpg') { 1448 } elseif ($socialImage -eq 'bath.jpg') { 1473 } elseif ($socialImage -in @('curtains.jpg','blinds.jpg','wallpaper.jpg','bedroom.jpg','moveis.jpg')) { 1672 } else { 1536 }
  $social = '<meta property="og:type" content="website"><meta property="og:locale" content="pt_BR"><meta property="og:site_name" content="Canan Home Decor"><meta property="og:title" content="' + (E $title) + '"><meta property="og:description" content="' + (E $description) + '"><meta property="og:url" content="' + $site + $route + '"><meta property="og:image" content="' + $site + '/assets/' + $socialImage + '"><meta property="og:image:width" content="' + $socialWidth + '"><meta property="og:image:height" content="' + $socialHeight + '"><meta name="twitter:card" content="summary_large_image">'
  $organization = @{ '@context'='https://schema.org'; '@type'='Organization'; address=@{ '@type'='PostalAddress'; streetAddress='R. Santos Dumont, 129 - loja A - Zona 01'; addressLocality='Maringá'; addressRegion='PR'; postalCode='87050-100'; addressCountry='BR' }; name='Canan Home Decor'; url=$site; logo=($site + '/assets/logo-canan-dark.png'); contactPoint=@{ '@type'='ContactPoint'; telephone='+55-44-3253-3772'; email='contato@cananhomedecor.com.br'; contactType='customer service'; availableLanguage='Portuguese' } } | ConvertTo-Json -Compress -Depth 5
  $schema = '<script type="application/ld+json">' + $organization + '</script>'
  if ($route -eq '/') {
    $website = @{ '@context'='https://schema.org'; '@type'='WebSite'; name='Canan Home Decor'; url=($site + '/'); inLanguage='pt-BR' } | ConvertTo-Json -Compress -Depth 5
    $schema += '<script type="application/ld+json">' + $website + '</script>'
  }
  if ($route -ne '/') {
    $crumbs = @(@{ '@type'='ListItem'; position=1; name='Início'; item=($site + '/') })
    if ($route -notin @('/produtos/', '/sobre/', '/contato/')) { $crumbs += @{ '@type'='ListItem'; position=2; name='Produtos'; item=($site + '/produtos/') } }
    $lastName = if ($route -eq '/produtos/') { 'Produtos' } elseif ($route -eq '/contato/') { 'Contato' } else { $labelByRoute[$route.Trim('/')] }
    $crumbs += @{ '@type'='ListItem'; position=($crumbs.Count + 1); name=$lastName; item=($site + $route) }
    $breadcrumb = @{ '@context'='https://schema.org'; '@type'='BreadcrumbList'; itemListElement=$crumbs } | ConvertTo-Json -Compress -Depth 8
    $schema += '<script type="application/ld+json">' + $breadcrumb + '</script>'
  }
  $html = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#faf8f3"><meta name="description" content="' + (E $description) + '"><link rel="canonical" href="https://cananhomedecor.com.br' + $route + '"><title>' + (E $title) + '</title><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Playfair+Display:wght@400&display=swap" rel="stylesheet"><link rel="stylesheet" href="/assets/site.css?v=20261014b"><script defer src="/assets/site.js?v=20261014b"></script></head><body id="top">' + (Header $route) + '<main id="main">' + $content + '</main>' + (Footer) + '</body></html>'
  $html = $html.Replace('</head>', $social + $schema + '</head>')
  $html = $html.Replace('<body id="top">', '<body id="top"><a class="skip-link" href="#main">Pular para o conteúdo</a>')
  $html = [regex]::Replace($html, '(<img\s[^>]*src="/assets/)([^"/]+)\.jpg("[^>]*)(>)', {
    param($m)
    if ($m.Value -match '\swidth=') { return $m.Value }
    $name = $m.Groups[2].Value
    $width = if ($name -eq 'hero') { 2055 } elseif ($name -eq 'moveis-home') { 1448 } elseif ($name -eq 'decoracao') { 1086 } elseif ($name -eq 'bath') { 1068 } elseif ($name -in @('curtains','blinds','rugs','wallpaper','bedroom','moveis')) { 941 } else { 1024 }
    $height = if ($name -eq 'hero') { 765 } elseif ($name -eq 'rugs') { 1254 } elseif ($name -eq 'moveis-home') { 1086 } elseif ($name -eq 'decoracao') { 1448 } elseif ($name -eq 'bath') { 1473 } elseif ($name -in @('curtains','blinds','wallpaper','bedroom','moveis')) { 1672 } else { 1536 }
    return $m.Groups[1].Value + $name + '.jpg' + $m.Groups[3].Value + ' width="' + $width + '" height="' + $height + '"' + $m.Groups[4].Value
  })
  $html = $html.Replace('href="/', 'href="' + $prefix + '/').Replace('src="/', 'src="' + $prefix + '/')
  $html = [regex]::Replace($html, '(<img\s[^>]*src="(?:\./|\.\./)assets/)(curtains|blinds|rugs|wallpaper|moveis-home|moveis|decoracao|bedroom|bath)(\.jpg"[^>]*)(>)', {
    param($m)
    $small = $prefix + '/assets/' + $m.Groups[2].Value + '-480.jpg'
    $large = $prefix + '/assets/' + $m.Groups[2].Value + '.jpg'
    $sizes = if ($m.Value -match '\bsizes=') { '' } else { ' sizes="(max-width: 600px) 90vw, (max-width: 1100px) 45vw, 33vw"' }
    return $m.Groups[1].Value + $m.Groups[2].Value + $m.Groups[3].Value + ' srcset="' + $small + ' 480w, ' + $large + ' ' + $(if ($m.Groups[2].Value -eq 'decoracao') { '1086' } elseif ($m.Groups[2].Value -eq 'moveis-home') { '1448' } elseif ($m.Groups[2].Value -eq 'bath') { '1068' } elseif ($m.Groups[2].Value -in @('curtains','blinds','rugs','wallpaper','bedroom','moveis')) { '941' } else { '1024' }) + 'w"' + $sizes + $m.Groups[4].Value
  })
  $html = [regex]::Replace($html, '<img\s[^>]*src="(?:\./|\.\./)assets/hero\.jpg"[^>]*>', {
    param($m)
    $sizes = if ($m.Value -match '\bsizes=') { '' } else { ' sizes="100vw"' }
    return $m.Value.TrimEnd('>') + ' srcset="' + $prefix + '/assets/hero-1024.jpg 1024w, ' + $prefix + '/assets/hero.jpg 2055w"' + $sizes + '>'
  })
  return $html
}
function Product-Cards([switch]$compact, [switch]$home) {
  $altBySlug = @{
    cortinas='Quarto com cortinas leves, cama e tapete em tons claros'
    persianas='Banheiro com persiana de madeira ao lado do box de vidro'
    tapetes='Sala de estar com tapete de fibra natural, couro e poltronas'
    'papeis-de-parede'='Sala com papel de parede de folhas em tons claros, poltrona e tapete de fibra'
    moveis='Sala com poltrona, mesas de apoio e tapete redondo de fibra natural'
    decoracao='Objetos decorativos: livros, colar de contas com borlas e vaso sobre mesa de apoio'
    'cama-banho-estar'='Quarto com cama branca, manta de tricô, almofadas e banco estofado'
  }
  $cards = foreach ($p in $products) {
    $class = if ($compact) {'product-card compact'} else {'product-card'}
    '<a class="' + $class + '" href="/' + $p.slug + '/"><div class="product-card-photo"><img src="/assets/' + $(if ($p.slug -eq 'moveis') { 'moveis-home.jpg' } else { $p.image }) + '" alt="' + (E $(if ($p.slug -eq 'moveis') { 'Sala de jantar com mesa redonda de madeira e poltronas estofadas' } else { $altBySlug[$p.slug] })) + '" loading="lazy" decoding="async" sizes="(max-width: 760px) 45vw, (max-width: 1100px) 30vw, 23vw"><span class="product-index">' + $p.number + ' / 07</span></div><div class="product-card-copy"><h3>' + (E $p.name) + '</h3><p>' + (E $p.text) + '</p><span class="round-arrow" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></div></a>'
  }
  return $cards -join "`n"
}

$homeMarkup = @'
<section class="hero-visual hero-carousel" aria-roledescription="carrossel" aria-label="Ambientes da Canan"><div class="hero-slide is-active"><img src="/assets/hero-sala.jpg" alt="Sala de estar com sofá modular branco, poltrona e grandes janelas de vidro com vista para o jardim" fetchpriority="high" width="1800" height="630"></div><div class="hero-slide"><img src="/assets/hero-persianas.jpg" alt="Sala integrada com persiana dupla visão na janela, sofá e mesa de jantar em mármore" loading="lazy" width="2000" height="684"></div><div class="hero-dots" role="group" aria-label="Escolher imagem"><button type="button" class="is-active" aria-label="Imagem 1" aria-current="true"></button><button type="button" aria-label="Imagem 2"></button></div><div class="hero-image-note">Canan Home Decor<br>Curadoria para a casa</div></section>
<section class="hero-copy shell"><div><p class="eyebrow">Canan Home Decor · Maringá</p><h1>Uma casa que <em>acolhe.</em><br>Uma decoração que tem a sua identidade.</h1></div><div class="hero-aside"><p>A luz que entra pela janela, a textura do tapete, a poltrona que convida a sentar. São escolhas que fazem diferença na maneira como você vive a sua casa.</p><p>Na Canan, você encontra soluções para compor ambientes com conforto, equilíbrio e personalidade.</p><div class="button-row"><a class="button button-dark" href="/contato/">Converse sobre seu ambiente <span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a><a class="button button-ghost" href="/produtos/">Conheça os produtos</a></div></div></section>
<div class="ticker ticker-marquee" aria-label="Linhas de produtos"><div class="ticker-track"><div class="ticker-group"><span>Cortinas sob medida</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Persianas</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Tapetes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Papéis de parede</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Móveis & detalhes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Decoração</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cama, Banho e Estar</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cortinas sob medida</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Persianas</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Tapetes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Papéis de parede</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Móveis & detalhes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Decoração</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cama, Banho e Estar</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b></div><div class="ticker-group" aria-hidden="true"><span>Cortinas sob medida</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Persianas</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Tapetes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Papéis de parede</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Móveis & detalhes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Decoração</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cama, Banho e Estar</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cortinas sob medida</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Persianas</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Tapetes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Papéis de parede</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Móveis & detalhes</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Decoração</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b><span>Cama, Banho e Estar</span><b><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></b></div></div></div>
<section class="section products-section" id="produtos"><div class="shell"><div class="section-heading"><div><p class="eyebrow">01 / Nossa seleção</p><h2>O que você procura<br>para a sua <em>casa?</em></h2></div><div><p>Você pode começar por uma janela, renovar o quarto ou escolher os detalhes que faltam na sala. Encontre possibilidades para o seu momento.</p><a class="under-link" href="/produtos/">Ver todas as linhas <span><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a></div></div><div class="product-grid">{{CARDS}}</div></div></section>
<section class="section story-section"><div class="shell story-grid"><div class="story-image"><img src="/assets/curtains.jpg" loading="lazy" alt="Quarto com cortinas leves, cama e tapete em tons claros"><span>Os detalhes mudam tudo.</span></div><div class="story-copy"><p class="eyebrow">02 / Nosso olhar</p><h2>Antes de escolher uma peça, vale olhar para o <em>ambiente.</em></h2><p>Uma cortina precisa conversar com a luz e com as proporções da janela. Um tapete precisa fazer sentido entre o sofá, as poltronas e a circulação.</p><p>Conte como você usa o espaço, o que deseja mudar e o que já faz parte da decoração. Essas informações ajudam a direcionar a escolha.</p></div></div></section>
<section class="made-section"><div class="shell made-grid"><div><p class="eyebrow">03 / Cada espaço é único</p><h2>Sob medida para as necessidades do seu <em>espaço.</em></h2></div><div class="made-aside"><p>Há ambientes em que as medidas, a entrada de luz ou a composição pedem uma solução específica.</p><div class="made-list"><a href="/cortinas/"><span>01</span>Cortinas sob medida <b><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></b></a><a href="/persianas/"><span>02</span>Persianas personalizadas <b><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></b></a><a href="/tapetes/"><span>03</span>Tapetes sob medida <b><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></b></a><a href="/papeis-de-parede/"><span>04</span>Papéis de parede <b><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></b></a></div></div></div></section>
<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">04 / Inspiração</p><h2>Cores, texturas e proporções se <em>encontram.</em></h2></div><p>Uma seleção de ambientes para inspirar suas próximas escolhas. Observe como cada detalhe participa da composição.</p></div><div class="inspiration-grid"><figure><img src="/assets/rugs.jpg" loading="lazy" alt="Sala de estar com tapete de fibra natural, couro e poltronas"><figcaption>Sala de estar</figcaption></figure><figure><img src="/assets/bedroom.jpg" loading="lazy" alt="Quarto com cama branca, manta de tricô, almofadas e banco estofado"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/curtains.jpg" loading="lazy" alt="Quarto com cortinas leves, cama e tapete em tons claros"><figcaption>Janelas</figcaption></figure></div></div></section>
<section class="about-band"><div class="shell about-band-grid"><div class="about-monogram"><img src="/assets/logo-canan-dark.png" alt="Logo Canan Home Decor" width="660" height="367" loading="lazy"></div><div><p class="eyebrow">05 / Canan Home Decor</p><h2>Canan Home Decor, em <em>Maringá.</em></h2><p>Em Maringá, a Canan oferece soluções em cortinas, persianas e decoração para transformar seus ambientes, trazendo mais conforto, beleza e personalidade para cada espaço da sua casa. Encontre o que combina com você. Nossa seleção passa por cortinas, persianas, tapetes, papéis de parede, móveis, decoração e têxteis.</p><p>É possível olhar para uma necessidade específica ou conhecer as diferentes linhas para criar uma composição mais completa. Comece pelo que faz sentido para você.</p><a class="under-link" href="/sobre/">Conheça a Canan <span><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a></div></div></section>
<section class="final-cta"><div class="shell"><p class="eyebrow">Vamos começar?</p><h2>Seu próximo ambiente<br>começa com uma <em>conversa.</em></h2><p>Envie uma foto, conte o que você procura e compartilhe as medidas que já tiver. A equipe ajuda você a conhecer as opções.</p><a class="button button-dark" href="/contato/">Fale com a Canan <span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a><span class="cta-star" aria-hidden="true"><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></span></div></section>
'@
$homeMarkup = $homeMarkup.Replace('{{CARDS}}', (Product-Cards -home))
Save-Page '/' (Layout 'Canan | Cortinas, Persianas e Decoração em Maringá' 'Encontre cortinas sob medida, persianas, roupas de cama, banho e decoração em Maringá. Na Canan, você encontra qualidade, conforto e elegância para sua casa.' '/' $homeMarkup)

$productsPage = '<div class="breadcrumbs shell"><a href="/">Início</a><span>/</span><span>Produtos</span></div><section class="collection-head shell"><p class="eyebrow">Explore a Canan</p><h1>Detalhes para viver a casa <em>do seu jeito.</em></h1><p>Do primeiro olhar para a janela aos toques finais, conheça as linhas da Canan e descubra por onde começar.</p></section><section class="section products-section"><div class="shell"><div class="product-grid">' + (Product-Cards) + '</div><div class="subcat"><h2>Conheça também a linha têxtil</h2><div class="subcat-links"><a href="/cama/">Cama <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a><a href="/banho/">Banho <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a><a href="/mantas-almofadas/">Estar <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a></div></div></div></section>'
Save-Page '/produtos/' (Layout 'Cortinas, Tapetes e Decoração em Maringá | Canan Home Decor' 'Conheça cortinas, persianas, tapetes, papéis de parede, móveis, decoração e têxteis da Canan Home Decor em Maringá.' '/produtos/' $productsPage)

$pageMatches = [regex]::Matches($copy, '(?ms)^# (\d+)\. ([^\n]+)\n(.*?)(?=^# \d+\. |\z)')
foreach ($m in $pageMatches) {
  $num = [int]$m.Groups[1].Value
  if ($num -lt 4 -or $num -gt 14) { continue }
  $body = $m.Groups[3].Value
  $routeMatch = [regex]::Match($body, '(?m)^\*\*URL:\*\*\s*(\S+)')
  if (-not $routeMatch.Success) { continue }
  $route = $routeMatch.Groups[1].Value
  $slug = $route.Trim('/')
  $title = [regex]::Match($body, '(?m)^\*\*Título SEO:\*\*\s*(.+)$').Groups[1].Value.Trim()
  $description = [regex]::Match($body, '(?m)^\*\*Meta description:\*\*\s*(.+)$').Groups[1].Value.Trim()
  $sections = @(Get-Sections $body)
  if ($sections.Count -eq 0) { continue }
  $heroSection = $sections[0]
  $image = $imageByRoute[$slug]
  $label = $labelByRoute[$slug]
  $content = '<div class="breadcrumbs shell"><a href="/">Início</a><span>/</span>' + $(if ($slug -ne 'sobre') {'<a href="/produtos/">Produtos</a><span>/</span>'} else {''}) + '<span>' + (E $label) + '</span></div>'
  $content += '<section class="inner-hero shell"><div class="inner-hero-copy"><p class="eyebrow">Canan Home Decor · Maringá</p><h1>' + (E $heroSection.heading) + '</h1>' + (Render-Text $heroSection.text $slug) + '</div><div class="inner-hero-image"><img src="/assets/' + $image + '" alt="Ambiente ilustrativo para ' + (E $label) + '" fetchpriority="high" sizes="(max-width: 760px) 90vw, 42vw">' + $(if ($image -in @('curtains.jpg','blinds.jpg','rugs.jpg','wallpaper.jpg','moveis.jpg','decoracao.jpg','bedroom.jpg','bath.jpg')) { '' } else { '<span>Imagem ilustrativa</span>' }) + '</div></section>'
  $content += '<div class="inner-intro-line shell"><span>Explore as possibilidades</span><span><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 5v14M6 13l6 6 6-6"/></svg></span></div>'
  $ordinary = @($sections | Select-Object -Skip 1 | Where-Object { $_.heading -notmatch '^(Perguntas|Dúvidas|Vamos encontrar|Encontre a peça|Qual espaço|Mostre a parede|Mostre a sala|Como você gostaria|Conheça as opções para seu banho|Encontre uma solução)' })
  $faq = @($sections | Where-Object { $_.heading -match '^(Perguntas|Dúvidas)' })
  $content += '<section class="inner-content shell">'
  for ($i=0; $i -lt $ordinary.Count; $i++) {
    $section = $ordinary[$i]
    if ($section.heading -match 'Uma história que começou|Atendimento no seu ambiente') { continue }
    $content += '<article class="editorial-block"><div class="editorial-count">' + ('{0:D2}' -f ($i+1)) + ' / ' + ('{0:D2}' -f $ordinary.Count) + '</div><div><h2>' + (E $section.heading) + '</h2>' + (Render-Text $section.text $slug) + '</div></article>'
  }
  $content += '</section>'
  if ($slug -eq 'persianas') { $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Projetos</p><h2>Persianas em <em>ambientes reais.</em></h2></div></div><div class="inspiration-grid"><figure><img src="/assets/persianas-sala.jpg" loading="lazy" alt="Sala de estar com persiana dupla visão e vista para a cidade" width="1400" height="788"><figcaption>Sala de estar</figcaption></figure><figure><img src="/assets/persianas-quarto.jpg" loading="lazy" alt="Quarto com persiana romana em tecido sobre a cabeceira" width="1000" height="1333"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/blinds.jpg" loading="lazy" alt="Banheiro com persiana de madeira" width="941" height="1672"><figcaption>Banheiro</figcaption></figure></div></div></section>' }
  if ($slug -eq 'tapetes') { $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Projetos</p><h2>Tapetes em <em>ambientes reais.</em></h2></div></div><div class="inspiration-grid"><figure><img src="/assets/tapetes-sala.jpg" loading="lazy" alt="Sala de estar ampla com tapete claro, couro e sofá modular" width="1400" height="932"><figcaption>Sala de estar</figcaption></figure><figure><img src="/assets/tapetes-quarto.jpg" loading="lazy" alt="Quarto com tapete de couro branco ao lado da cama" width="1000" height="1777"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/tapetes-estar.jpg" loading="lazy" alt="Sala com tapete de fibra natural, poltronas e cortina ao fundo" width="1000" height="1333"><figcaption>Estar</figcaption></figure></div></div></section>' }
  if ($slug -eq 'papeis-de-parede') { $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Projetos</p><h2>Papéis de parede em <em>ambientes reais.</em></h2></div></div><div class="inspiration-grid"><figure><img src="/assets/papeis-sala.jpg" loading="lazy" alt="Sala de reunião com papel de parede xadrez, persiana de madeira e cortina de linho" width="1679" height="937"><figcaption>Sala de reunião</figcaption></figure><figure><img src="/assets/papeis-quarto.jpg" loading="lazy" alt="Quarto com parede texturizada e iluminação embutida" width="941" height="1672"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/wallpaper.jpg" loading="lazy" alt="Sala com papel de parede de folhas em tons claros, poltrona e tapete de fibra" width="941" height="1672"><figcaption>Estar</figcaption></figure></div></div></section>' }
  if ($slug -eq 'decoracao') { $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Seleção</p><h2>Detalhes que <em>completam o ambiente.</em></h2></div></div><div class="inspiration-grid" style="grid-template-columns:1fr 1fr"><figure><img src="/assets/decoracao.jpg" loading="lazy" alt="Objetos decorativos: livros, colar de contas com borlas e vaso sobre mesa de apoio" width="1086" height="1448"><figcaption>Livros e contas decorativas</figcaption></figure><figure><img src="/assets/decoracao-caixas.jpg" loading="lazy" alt="Caixas de madeira empilhadas sobre mesa de mármore, com vaso e contas decorativas" width="1086" height="1448"><figcaption>Caixas de madeira</figcaption></figure></div></div></section>' }
  if ($slug -eq 'cama') { $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Projetos</p><h2>Cama em <em>ambientes reais.</em></h2></div></div><div class="inspiration-grid" style="grid-template-columns:1fr 1fr"><figure><img src="/assets/cama-quarto.jpg" loading="lazy" alt="Quarto com cabeceira estofada, cortina de linho e parede texturizada iluminada" width="1600" height="1066"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/cama-terraco.jpg" loading="lazy" alt="Quarto com cortina de linho e porta de vidro para o terraço" width="1600" height="1066"><figcaption>Suíte</figcaption></figure></div></div></section>' }
  $relatedMatch = [regex]::Match($body, '(?m)^\*\*Links relacionados:\*\*.+$')
  if ($relatedMatch.Success) { $content += '<div class="shell">' + (Render-Text $relatedMatch.Value $slug) + '</div>' }
  if ($slug -eq 'cama-banho-estar') {
    $content += '<section class="section inspiration-section"><div class="shell"><div class="section-heading"><div><p class="eyebrow">Projetos</p><h2>Cama, banho e estar em <em>ambientes reais.</em></h2></div></div><div class="inspiration-grid"><figure><img src="/assets/cama-quarto.jpg" loading="lazy" alt="Quarto com cabeceira estofada, cortina de linho e parede texturizada iluminada" width="1600" height="1066"><figcaption>Quarto</figcaption></figure><figure><img src="/assets/cama-terraco.jpg" loading="lazy" alt="Quarto com cortina de linho e porta de vidro para o terraço" width="1600" height="1066"><figcaption>Suíte</figcaption></figure><figure><img src="/assets/bath.jpg" loading="lazy" alt="Toalhas de banho empilhadas em bege, azul, cinza e branco sobre banco de madeira" width="1068" height="1473"><figcaption>Banho</figcaption></figure></div></div></section>'
    $content += '<div class="shell subcat"><h2>Escolha por onde começar</h2><div class="subcat-links"><a href="/cama/">Cama <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a><a href="/banho/">Banho <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a><a href="/mantas-almofadas/">Estar <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a></div></div>'
  }
  if ($faq.Count -gt 0) { $content += '<section class="faq-section"><div class="shell faq-grid"><div><p class="eyebrow">Perguntas frequentes</p><h2>Para escolher com mais <em>clareza.</em></h2></div><div>' + (Render-Text $faq[0].text $slug) + '</div></div></section>' }
  Save-Page $route (Layout $title $description $route $content)
}

$contact = @'
<div class="breadcrumbs shell"><a href="/">Início</a><span>/</span><span>Contato</span></div>
<section class="contact-hero shell"><div><p class="eyebrow">Canan Home Decor · Maringá</p><h1>Conte o que você está buscando para o seu <em>ambiente.</em></h1><p>Você pode ter uma ideia pronta, uma referência salva ou apenas saber que quer mudar alguma coisa. Comece por aí.</p></div><div class="contact-intro-card"><span aria-hidden="true"><svg class="ic ic-star" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 2v20M2 12h20M5 5l14 14M19 5 5 19"/></svg></span><p>Uma foto, as medidas aproximadas ou uma referência ajudam a direcionar a conversa. Se ainda não tiver essas informações, descreva o que precisa.</p></div></section>
<section class="contact-section"><div class="shell contact-grid"><div class="contact-aside"><p class="eyebrow">Vamos começar</p><h2>Uma conversa para encontrar as <em>possibilidades.</em></h2><p>Preencha seus dados e conte o que procura. O formulário prepara uma mensagem no seu aplicativo de e-mail.</p><div class="contact-detail"><span>01</span><div><h3>Por telefone</h3><p><a href="tel:+554432533772">(44) 3253-3772</a></p></div></div><div class="contact-detail"><span>02</span><div><h3>Por e-mail</h3><p><a href="mailto:contato@cananhomedecor.com.br">contato@cananhomedecor.com.br</a></p></div></div><div class="contact-detail"><span>03</span><div><h3>Encontre a Canan em Maringá</h3><p>R. Santos Dumont, 129 - loja A<br>Zona 01, Maringá - PR<br>CEP 87050-100</p><p><a class="under-link" href="https://www.google.com/maps/search/?api=1&amp;query=R.%20Santos%20Dumont%2C%20129%20-%20loja%20A%20-%20Zona%2001%2C%20Maring%C3%A1%20-%20PR%2C%2087050-100%2C%20Brasil" target="_blank" rel="noopener">Veja como chegar <span><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></a></p></div></div></div><form id="contact-form" class="contact-form"><h2>Fale sobre seu ambiente</h2><p>Conte o que procura. Quanto mais contexto, melhor para iniciar o atendimento.</p><div class="field-row"><label>Seu nome<input name="nome" autocomplete="name" placeholder="Como podemos chamar você?" required></label><label>Telefone com DDD<input name="telefone" type="tel" autocomplete="tel" inputmode="tel" placeholder="(00) 00000-0000" required></label></div><label>Seu e-mail <span>(opcional)</span><input name="email" type="email" autocomplete="email" placeholder="voce@exemplo.com"></label><label>Produto de interesse<select name="produto" required><option value="">Selecione uma opção</option><option>Cortinas</option><option>Persianas</option><option>Tapetes</option><option>Papéis de parede</option><option>Móveis</option><option>Decoração</option><option>Cama</option><option>Banho</option><option>Estar</option><option>Ainda quero conhecer as opções</option></select></label><label>Sua mensagem<textarea name="mensagem" rows="5" placeholder="Conte sobre o ambiente e o que você procura." required></textarea></label><button class="button button-dark" type="submit">Preparar e-mail <span aria-hidden="true"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></span></button><p class="form-note">Ao continuar, seu aplicativo de e-mail abrirá uma mensagem pronta. Este site não armazena os dados do formulário.</p><p class="form-status" role="status" aria-live="polite"></p></form></div></section>
<section class="faq-section"><div class="shell faq-grid"><div><p class="eyebrow">Antes de escrever</p><h2>Dúvidas <em>frequentes.</em></h2></div><div><details class="faq-item"><summary>Preciso ter as medidas exatas?</summary><p>As medidas aproximadas ajudam a iniciar o atendimento. Para produtos sob medida, a equipe informará como confirmar as medidas necessárias.</p></details><details class="faq-item"><summary>Posso consultar apenas um produto?</summary><p>Sim. Você pode procurar uma peça específica ou conhecer diferentes linhas para compor um ambiente.</p></details><details class="faq-item"><summary>Como sei o valor?</summary><p>Solicite uma consulta ou orçamento. As informações necessárias variam conforme o produto, as medidas e as opções escolhidas.</p></details><details class="faq-item"><summary>A Canan atende fora de Maringá?</summary><p>Consulte a equipe sobre sua cidade e as condições de atendimento.</p></details></div></div></section>
'@
Save-Page '/contato/' (Layout 'Contato Canan Home Decor | Atendimento em Maringá' 'Fale com a Canan Home Decor em Maringá. Tire dúvidas, consulte produtos e solicite orçamento para cortinas, persianas, tapetes e decoração.' '/contato/' $contact)

$notFound = '<section class="collection-head shell"><p class="eyebrow">Erro 404</p><h1>Esta página não foi encontrada.</h1><p>O endereço pode ter mudado. Explore nossos produtos ou volte ao início.</p><div class="button-row"><a class="button button-dark" href="/produtos/">Conheça os produtos <svg class="ic" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M7 17 17 7M8 7h9v9"/></svg></a><a class="button button-ghost" href="/">Voltar ao início</a></div></section>'
$notFoundHtml = (Layout 'Página não encontrada | Canan Home Decor' 'Página não encontrada no site da Canan Home Decor.' '/' $notFound).Replace('<link rel="canonical" href="https://cananhomedecor.com.br/">', '').Replace('</head>', '<meta name="robots" content="noindex,follow"></head>')
[System.IO.File]::WriteAllText((Join-Path $outputRoot '404.html'), $notFoundHtml, $utf8)

$allRoutes = @('/') + @('/produtos/') + @($pageMatches | Where-Object { [int]$_.Groups[1].Value -ge 4 -and [int]$_.Groups[1].Value -le 14 } | ForEach-Object { [regex]::Match($_.Groups[3].Value, '(?m)^\*\*URL:\*\*\s*(\S+)').Groups[1].Value }) + @('/contato/')
[System.IO.File]::WriteAllText((Join-Path $outputRoot 'sitemap.xml'), '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + (($allRoutes | ForEach-Object { '<url><loc>https://cananhomedecor.com.br' + $_ + '</loc></url>' }) -join '') + '</urlset>', $utf8)
[System.IO.File]::WriteAllText((Join-Path $outputRoot 'robots.txt'), "User-agent: *`nAllow: /`nSitemap: https://cananhomedecor.com.br/sitemap.xml`n", $utf8)
Write-Output "Generated $($allRoutes.Count) pages."
