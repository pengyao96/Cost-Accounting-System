function ConvertTo-MockStoreValue {
    param($Value)

    if ($null -eq $Value -or $Value -is [string] -or $Value -is [bool] -or $Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) { return $Value }
    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) { $result[$key] = ConvertTo-MockStoreValue $Value[$key] }
        return $result
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @()
        foreach ($item in $Value) { $items += ,(ConvertTo-MockStoreValue $item) }
        return $items
    }
    $result = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) { $result[$property.Name] = ConvertTo-MockStoreValue $property.Value }
    return $result
}

function Get-MockStateFilePath {
    $backendPath = Split-Path -Parent $PSScriptRoot
    return Join-Path $backendPath "data\mock-state.json"
}

function Restore-MockPersistentState {
    param([Parameter(Mandatory = $true)]$State)
    $path = Get-MockStateFilePath
    if (-not (Test-Path $path -PathType Leaf)) { return $State }
    try {
        $stored = ConvertTo-MockStoreValue (Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json)
        if ($stored.datasets) { foreach ($name in $stored.datasets.Keys) { if ($State.datasets.Contains($name)) { $State.datasets[$name] = @($stored.datasets[$name]) } } }
        if ($stored.systemUsers) { $State.systemUsers = @($stored.systemUsers) }
        if ($stored.userGroups) { $State.userGroups = @($stored.userGroups) }
    } catch {
        Write-Warning "Mock persistent state could not be loaded; seed data will be used. $($_.Exception.Message)"
    }
    return $State
}

function Save-MockPersistentState {
    param([Parameter(Mandatory = $true)]$State)
    $path = Get-MockStateFilePath
    $directory = Split-Path -Parent $path
    if (-not (Test-Path $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    $payload = [ordered]@{ version = 1; savedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss"); datasets = $State.datasets; systemUsers = $State.systemUsers; userGroups = $State.userGroups }
    $tempPath = $path + ".tmp"
    [System.IO.File]::WriteAllText($tempPath, ($payload | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($true)))
    Move-Item -LiteralPath $tempPath -Destination $path -Force
}
