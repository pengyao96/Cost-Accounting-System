$pidFile = Join-Path $PSScriptRoot ".bs-server.pid"

if (-not (Test-Path $pidFile)) {
    Write-Host "No running Second Lianzha B/S service was found."
    exit 0
}

$pidValue = Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pidValue) {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    Write-Host "PID file was empty and has been removed."
    exit 0
}

try {
    Stop-Process -Id ([int]$pidValue) -Force -ErrorAction Stop
    Write-Host "Stopped Second Lianzha B/S service: $pidValue"
} catch {
    Write-Host "Process was not found and PID file has been removed."
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
