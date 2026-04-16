# Simple static file server using .NET HttpListener
# Usage: powershell -File serve.ps1 [-Port 8080] [-Root .]
param(
    [int]$Port = 8080,
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.woff2'= 'font/woff2'
    '.woff' = 'font/woff'
    '.ttf'  = 'font/ttf'
    '.txt'  = 'text/plain'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host ""
Write-Host "  RoundUp Dev Server" -ForegroundColor Cyan
Write-Host "  Serving: $Root" -ForegroundColor Gray
Write-Host "  URL:     http://localhost:$Port" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

try {
    while ($listener.IsListening) {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        $urlPath = $req.Url.LocalPath -replace '/', [System.IO.Path]::DirectorySeparatorChar
        if ($urlPath -eq '\' -or $urlPath -eq '/') { $urlPath = '\index.html' }

        $filePath = Join-Path $Root $urlPath.TrimStart('\/')

        if (Test-Path $filePath -PathType Leaf) {
            $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $resp.ContentType   = $mime
            $resp.ContentLength64 = $bytes.Length
            $resp.StatusCode    = 200
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
            Write-Host "  200 $($req.Url.LocalPath)" -ForegroundColor DarkGray
        } else {
            $msg   = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $($req.Url.LocalPath)")
            $resp.StatusCode    = 404
            $resp.ContentType   = 'text/plain'
            $resp.ContentLength64 = $msg.Length
            $resp.OutputStream.Write($msg, 0, $msg.Length)
            Write-Host "  404 $($req.Url.LocalPath)" -ForegroundColor DarkGray
        }
        $resp.OutputStream.Close()
    }
} finally {
    $listener.Stop()
}
