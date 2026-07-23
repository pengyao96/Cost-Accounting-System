$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "config.local.ps1"
$migrationDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) "database"

if (-not (Test-Path $configPath -PathType Leaf)) {
    throw "Missing backend/config.local.ps1. Copy config.example.ps1 and set SQL authentication credentials first."
}

$config = . $configPath
$builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new([string]$config.ConnectionString)
$builder["Initial Catalog"] = "master"
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()

try {
    $migrationPaths = Get-ChildItem -Path $migrationDirectory -Filter "*.sql" -File | Sort-Object Name
    foreach ($migrationPath in $migrationPaths) {
        $script = Get-Content -Raw -Encoding UTF8 $migrationPath.FullName
        $batches = $script -split '(?im)^\s*GO\s*$'
        foreach ($batch in $batches) {
            if ([string]::IsNullOrWhiteSpace($batch)) { continue }
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.CommandTimeout = 60
            [void]$command.ExecuteNonQuery()
        }
    }

    $verify = $connection.CreateCommand()
    $verify.CommandText = @"
SELECT DB_ID(N'SecondRollingCost') AS database_id;
SELECT COUNT(1) AS group_count FROM SecondRollingCost.dbo.sys_user_groups;
SELECT COUNT(1) AS user_count FROM SecondRollingCost.dbo.sys_users;
"@
    $reader = $verify.ExecuteReader()
    $reader.Read() | Out-Null
    $databaseId = [System.Convert]::ToInt32($reader.GetValue(0))
    $reader.NextResult() | Out-Null
    $reader.Read() | Out-Null
    $groupCount = [System.Convert]::ToInt32($reader.GetValue(0))
    $reader.NextResult() | Out-Null
    $reader.Read() | Out-Null
    $userCount = [System.Convert]::ToInt32($reader.GetValue(0))
    Write-Host "SQL initialization completed. databaseId=$databaseId groups=$groupCount users=$userCount migrations=$($migrationPaths.Count)"
} finally {
    $connection.Close()
    $connection.Dispose()
}
