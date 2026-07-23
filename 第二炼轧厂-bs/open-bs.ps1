param(
    [switch]$NoBrowser,
    [ValidateSet("mock", "sqlserver")]
    [string]$Provider = "mock"
)

$ErrorActionPreference = "Stop"

$rootPath = $PSScriptRoot
$serverScript = Join-Path $rootPath "backend\server.ps1"
$pidFile = Join-Path $rootPath ".bs-server.pid"
$port = 8091
$baseUrl = "http://127.0.0.1:$port/"

function Test-ServerAlive {
    param([string]$Url)
    try {
        Invoke-RestMethod -Uri ($Url + "api/health") -Method Get -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-RunningProcess {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return $null
    }
    $pidValue = Get-Content $Path -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $pidValue) {
        return $null
    }
    try {
        return Get-Process -Id ([int]$pidValue) -ErrorAction Stop
    } catch {
        return $null
    }
}

$running = Get-RunningProcess -Path $pidFile
if (-not $running -or -not (Test-ServerAlive -Url $baseUrl)) {
    $process = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$serverScript`" -Port $port -Provider $Provider" -WindowStyle Hidden -PassThru
    Set-Content -Path $pidFile -Value $process.Id -Encoding UTF8
    $started = $false
    foreach ($i in 1..12) {
        Start-Sleep -Milliseconds 500
        if (Test-ServerAlive -Url $baseUrl) {
            $started = $true
            break
        }
    }
    if (-not $started) {
        throw "Second Lianzha B/S $Provider API failed to start. Run backend/server.ps1 manually for logs."
    }
}

if (-not $NoBrowser) {
    try {
        Start-Process $baseUrl -ErrorAction Stop
    } catch {
        Write-Host "Browser auto-open failed. Open this URL manually: $baseUrl"
    }
}

Write-Host "Second Lianzha B/S prototype is ready: $baseUrl"
