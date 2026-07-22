$pidFile = Join-Path $PSScriptRoot ".bs-server.pid"

function Get-ServerProcessId {
    if (Test-Path $pidFile) {
        $savedPid = Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($savedPid) {
            try {
                Get-Process -Id ([int]$savedPid) -ErrorAction Stop | Out-Null
                return [int]$savedPid
            } catch {
                # Fall through to the port check when a stale PID file is found.
            }
        }
    }

    $listener = Get-NetTCPConnection -State Listen -LocalPort 8091 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($listener) {
        return [int]$listener.OwningProcess
    }
    return $null
}

$pidValue = Get-ServerProcessId
if (-not $pidValue) {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    Write-Host "No running Second Lianzha B/S service was found on port 8091."
    exit 0
}

try {
    Stop-Process -Id ([int]$pidValue) -Force -ErrorAction Stop
    Write-Host "Stopped Second Lianzha B/S service: $pidValue"
} catch {
    Write-Host "Process was not found and PID file has been removed."
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
