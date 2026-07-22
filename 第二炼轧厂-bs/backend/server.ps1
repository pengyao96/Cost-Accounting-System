param(
    [int]$Port = 8091,
    [string]$Provider = "mock"
)

$ErrorActionPreference = "Stop"

$script:RootPath = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "providers\repository.ps1")
$script:Repository = Get-Repository -ProviderName $Provider

function Parse-QueryString {
    param([AllowEmptyString()][string]$Query)

    $result = @{}
    if ([string]::IsNullOrWhiteSpace($Query)) {
        return $result
    }

    $trimmed = $Query.TrimStart("?")
    if (-not $trimmed) {
        return $result
    }

    foreach ($part in $trimmed.Split("&")) {
        if (-not $part) { continue }
        $pair = $part.Split("=", 2)
        $key = [System.Uri]::UnescapeDataString($pair[0])
        $value = if ($pair.Length -gt 1) { [System.Uri]::UnescapeDataString($pair[1]) } else { "" }
        $result[$key] = $value
    }
    return $result
}

function Find-HeaderEnd {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    for ($i = 0; $i -le $Bytes.Length - 4; $i++) {
        if ($Bytes[$i] -eq 13 -and $Bytes[$i + 1] -eq 10 -and $Bytes[$i + 2] -eq 13 -and $Bytes[$i + 3] -eq 10) {
            return $i
        }
    }
    return -1
}

function Read-HttpRequest {
    param([Parameter(Mandatory = $true)]$Stream)

    $buffer = New-Object byte[] 4096
    $memory = New-Object System.IO.MemoryStream
    $headerEnd = -1

    while ($headerEnd -lt 0) {
        $read = $Stream.Read($buffer, 0, $buffer.Length)
        if ($read -le 0) {
            return $null
        }
        $memory.Write($buffer, 0, $read)
        $headerEnd = Find-HeaderEnd -Bytes $memory.ToArray()
    }

    $rawBytes = $memory.ToArray()
    $headerBytesLength = $headerEnd + 4
    $headerText = [System.Text.Encoding]::ASCII.GetString($rawBytes, 0, $headerBytesLength)
    $headerLines = $headerText.Split(@("`r`n"), [System.StringSplitOptions]::None)
    $requestLine = $headerLines[0]
    $parts = $requestLine.Split(" ")
    if ($parts.Length -lt 2) {
        return $null
    }

    $headers = @{}
    foreach ($line in $headerLines[1..($headerLines.Length - 1)]) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $colonIndex = $line.IndexOf(":")
        if ($colonIndex -gt 0) {
            $name = $line.Substring(0, $colonIndex).Trim().ToLowerInvariant()
            $value = $line.Substring($colonIndex + 1).Trim()
            $headers[$name] = $value
        }
    }

    $contentLength = 0
    if ($headers.ContainsKey("content-length")) {
        $contentLength = [int]$headers["content-length"]
    }

    $bodyStart = $headerBytesLength
    $bodyBytes = New-Object byte[] $contentLength
    $availableBodyBytes = $rawBytes.Length - $bodyStart
    if ($contentLength -gt 0) {
        if ($availableBodyBytes -gt 0) {
            $copyCount = [Math]::Min($contentLength, $availableBodyBytes)
            [Array]::Copy($rawBytes, $bodyStart, $bodyBytes, 0, $copyCount)
            $bytesRead = $copyCount
        } else {
            $bytesRead = 0
        }

        while ($bytesRead -lt $contentLength) {
            $read = $Stream.Read($bodyBytes, $bytesRead, $contentLength - $bytesRead)
            if ($read -le 0) {
                break
            }
            $bytesRead += $read
        }
    }

    $bodyText = if ($contentLength -gt 0) { [System.Text.Encoding]::UTF8.GetString($bodyBytes) } else { "" }
    $uri = [System.Uri]::new("http://127.0.0.1:$Port$($parts[1])")

    return @{
        Method = $parts[0].ToUpperInvariant()
        Path = $uri.AbsolutePath
        Query = Parse-QueryString -Query $uri.Query
        BodyText = $bodyText
    }
}

function Get-ContentType {
    param([Parameter(Mandatory = $true)][string]$Path)
    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".css" { return "text/css; charset=utf-8" }
        ".js" { return "application/javascript; charset=utf-8" }
        ".jpeg" { return "image/jpeg" }
        ".jpg" { return "image/jpeg" }
        ".png" { return "image/png" }
        ".ico" { return "image/x-icon" }
        default { return "text/plain; charset=utf-8" }
    }
}

function Write-HttpResponse {
    param(
        [Parameter(Mandatory = $true)]$Stream,
        [int]$StatusCode,
        [Parameter(Mandatory = $true)][string]$ContentType,
        [Parameter(Mandatory = $true)][byte[]]$BodyBytes
    )

    $reason = switch ($StatusCode) {
        200 { "OK" }
        204 { "No Content" }
        404 { "Not Found" }
        500 { "Internal Server Error" }
        default { "OK" }
    }

    $headers = @(
        "HTTP/1.1 $StatusCode $reason",
        "Content-Type: $ContentType",
        "Content-Length: $($BodyBytes.Length)",
        "Connection: close",
        "Cache-Control: no-store, max-age=0",
        "Pragma: no-cache",
        "Access-Control-Allow-Origin: *",
        "Access-Control-Allow-Headers: Content-Type",
        "Access-Control-Allow-Methods: GET,POST,DELETE,OPTIONS",
        "",
        ""
    ) -join "`r`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($BodyBytes.Length -gt 0) {
        $Stream.Write($BodyBytes, 0, $BodyBytes.Length)
    }
    $Stream.Flush()
}

function Write-Json {
    param(
        [Parameter(Mandatory = $true)]$Stream,
        [Parameter(Mandatory = $true)]$Payload,
        [int]$StatusCode = 200
    )
    $json = $Payload | ConvertTo-Json -Depth 20
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    Write-HttpResponse -Stream $Stream -StatusCode $StatusCode -ContentType "application/json; charset=utf-8" -BodyBytes $bytes
}

function Write-Text {
    param(
        [Parameter(Mandatory = $true)]$Stream,
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$ContentType = "text/plain; charset=utf-8",
        [int]$StatusCode = 200
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    Write-HttpResponse -Stream $Stream -StatusCode $StatusCode -ContentType $ContentType -BodyBytes $bytes
}

function Write-StaticFile {
    param(
        [Parameter(Mandatory = $true)]$Stream,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or $RelativePath -eq "/") {
        $target = Join-Path $script:RootPath "index.html"
    } else {
        $trimmed = $RelativePath.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar.ToString())
        $target = Join-Path $script:RootPath $trimmed
    }

    $fullTarget = [System.IO.Path]::GetFullPath($target)
    $fullRoot = [System.IO.Path]::GetFullPath($script:RootPath)
    if (-not $fullTarget.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Text -Stream $Stream -Text "Forbidden" -StatusCode 404
        return
    }
    if (-not (Test-Path $fullTarget -PathType Leaf)) {
        Write-Text -Stream $Stream -Text "Not Found" -StatusCode 404
        return
    }

    $content = [System.IO.File]::ReadAllBytes($fullTarget)
    Write-HttpResponse -Stream $Stream -StatusCode 200 -ContentType (Get-ContentType $fullTarget) -BodyBytes $content
}

function Handle-Api {
    param(
        [Parameter(Mandatory = $true)]$Request,
        [Parameter(Mandatory = $true)]$Stream
    )

    if ($Request.Method -eq "OPTIONS") {
        Write-Text -Stream $Stream -Text "" -StatusCode 204
        return
    }

    if ($Request.Path -eq "/api/health") {
        Write-Json -Stream $Stream -Payload @{
            status = "ok"
            port = $Port
            provider = $script:Repository.ProviderName
        }
        return
    }

    if ($Request.Path -eq "/api/bootstrap") {
        Write-Json -Stream $Stream -Payload ($script:Repository.GetBootstrap())
        return
    }

    if ($Request.Path -eq "/api/auth/login" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.Login($payload))
        return
    }

    if ($Request.Path -eq "/api/auth/users" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.GetUsers([string]$payload.token))
        return
    }

    if ($Request.Path -eq "/api/auth/users/save" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.SaveUser([string]$payload.token, $payload.user))
        return
    }

    if ($Request.Path -eq "/api/auth/users/delete" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.DeleteUser([string]$payload.token, [int]$payload.id))
        return
    }

    if ($Request.Path -eq "/api/auth/password" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.ChangePassword([string]$payload.token, $payload))
        return
    }

    if ($Request.Path -eq "/api/auth/groups" -and $Request.Method -eq "GET") {
        Write-Json -Stream $Stream -Payload ($script:Repository.GetUserGroups())
        return
    }

    if ($Request.Path -eq "/api/cost/run" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.RunCost($payload))
        return
    }

    if ($Request.Path -eq "/api/cost/detail" -and $Request.Method -eq "GET") {
        Write-Json -Stream $Stream -Payload ($script:Repository.GetCostDetail([string]$Request.Query["detailKey"]))
        return
    }

    if ($Request.Path -eq "/api/standard-cost/run" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.RunStandardCost($payload))
        return
    }

    if ($Request.Path -eq "/api/schedules/run" -and $Request.Method -eq "POST") {
        $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
        Write-Json -Stream $Stream -Payload ($script:Repository.RunSchedule($payload))
        return
    }

    $segments = @($Request.Path.Trim("/").Split("/", [System.StringSplitOptions]::RemoveEmptyEntries))
    if ($segments.Length -ge 3 -and $segments[0] -eq "api" -and $segments[1] -eq "datasets") {
        $datasetName = $segments[2]

        if ($Request.Method -eq "GET" -and $segments.Length -eq 3) {
            Write-Json -Stream $Stream -Payload ($script:Repository.GetDataset($datasetName))
            return
        }

        if ($Request.Method -eq "POST" -and $segments.Length -eq 4 -and $segments[3] -eq "collect") {
            Write-Json -Stream $Stream -Payload ($script:Repository.CollectDataset($datasetName))
            return
        }

        if ($Request.Method -eq "POST" -and $segments.Length -eq 3) {
            $payload = if ($Request.BodyText) { ConvertFrom-Json $Request.BodyText } else { [ordered]@{} }
            Write-Json -Stream $Stream -Payload ($script:Repository.SaveDatasetRow($datasetName, $payload))
            return
        }

        if ($Request.Method -eq "DELETE" -and $segments.Length -eq 4) {
            Write-Json -Stream $Stream -Payload ($script:Repository.DeleteDatasetRow($datasetName, [int]$segments[3]))
            return
        }
    }

    Write-Text -Stream $Stream -Text "API Not Found" -StatusCode 404
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("127.0.0.1"), $Port)
$listener.Start()
Write-Host "Second Lianzha B/S mock server started: http://127.0.0.1:$Port/"

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $request = Read-HttpRequest -Stream $stream
            if ($null -eq $request) {
                continue
            }

            try {
                if ($request.Path.StartsWith("/api")) {
                    Handle-Api -Request $request -Stream $stream
                } else {
                    Write-StaticFile -Stream $stream -RelativePath $request.Path
                }
            } catch {
                Write-Text -Stream $stream -Text $_.Exception.Message -StatusCode 500
            }
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
