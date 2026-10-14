param([int]$Port = 8080)
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'dist'))
if (-not (Test-Path (Join-Path $root 'index.html'))) { throw 'Execute build.ps1 primeiro.' }
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Output "Site disponível em http://localhost:$Port/ (Ctrl+C para encerrar)"
$types = @{'.html'='text/html; charset=utf-8';'.css'='text/css; charset=utf-8';'.js'='application/javascript; charset=utf-8';'.jpg'='image/jpeg';'.jpeg'='image/jpeg';'.png'='image/png';'.xml'='application/xml; charset=utf-8';'.txt'='text/plain; charset=utf-8'}
try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $request = $reader.ReadLine()
      while ($null -ne ($line = $reader.ReadLine()) -and $line -ne '') {}
      $requestPath = if ($request -match '^[A-Z]+\s+(\S+)') { $Matches[1].Split('?')[0] } else { '/' }
      $urlPath = [uri]::UnescapeDataString($requestPath).TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
      $file = [System.IO.Path]::GetFullPath((Join-Path $root $urlPath))
      $safe = $file -eq $root -or $file.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
      if ($safe -and (Test-Path $file -PathType Container)) { $file = Join-Path $file 'index.html' }
      if (-not $safe) { $status='403 Forbidden'; $bytes=[System.Text.Encoding]::UTF8.GetBytes('Forbidden'); $mime='text/plain; charset=utf-8' }
      elseif (-not (Test-Path $file -PathType Leaf)) { $status='404 Not Found'; $bytes=[System.IO.File]::ReadAllBytes((Join-Path $root '404.html')); $mime='text/html; charset=utf-8' }
      else {
        $status='200 OK'
        $bytes=[System.IO.File]::ReadAllBytes($file)
        $ext=[System.IO.Path]::GetExtension($file).ToLowerInvariant()
        $mime=if($types.ContainsKey($ext)){$types[$ext]}else{'application/octet-stream'}
      }
      $header="HTTP/1.1 $status`r`nContent-Type: $mime`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
      $headBytes=[System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headBytes,0,$headBytes.Length)
      $stream.Write($bytes,0,$bytes.Length)
      $stream.Flush()
      $reader.Dispose()
    } finally { $client.Close() }
  }
} finally { $listener.Stop() }
