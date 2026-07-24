param(
    [string]$Root,
    [int]$Port = 8080
)

$listener = [System.Net.Sockets.TcpListener]::new(
    [System.Net.IPAddress]::Parse("127.0.0.1"),
    $Port
)
$listener.Start()

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $requestLine = $reader.ReadLine()
        while (($line = $reader.ReadLine()) -ne $null -and $line -ne "") {}

        $parts = if ($requestLine) { $requestLine.Split(" ") } else { @() }
        $requestPath = if ($parts.Count -gt 1) { $parts[1].TrimStart("/") } else { "" }
        $requestPath = [System.Uri]::UnescapeDataString($requestPath.Split("?")[0])
        if ([string]::IsNullOrWhiteSpace($requestPath)) {
            $requestPath = "index.html"
        }

        $fullPath = Join-Path $Root $requestPath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            $fullPath = Join-Path $Root "index.html"
        }

        $extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
        $contentType = switch ($extension) {
            ".html" { "text/html; charset=utf-8" }
            ".js" { "application/javascript; charset=utf-8" }
            ".css" { "text/css; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".png" { "image/png" }
            ".ico" { "image/x-icon" }
            ".svg" { "image/svg+xml" }
            ".wasm" { "application/wasm" }
            default { "application/octet-stream" }
        }

        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
        $client.Close()
    }
}
finally {
    if ($listener) {
        $listener.Stop()
    }
}
