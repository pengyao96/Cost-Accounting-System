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
        $finalTableByMigration = @{
            "003-heat-treatment-requirements.sql" = "yclyq"
            "004-grade-datasets.sql" = "lggrade"
            "006-thickness-indexes.sql" = "lgthick"
        }
        if ($migrationPath.Name -eq "004-grade-datasets.sql") {
            $schemaCheck = $connection.CreateCommand()
            $schemaCheck.CommandText = "SELECT CASE WHEN EXISTS (SELECT 1 FROM SecondRollingCost.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME IN (N'lggradeForm', N'lggrade') AND COLUMN_NAME = N'钢种') THEN 1 ELSE 0 END"
            if ([System.Convert]::ToInt32($schemaCheck.ExecuteScalar()) -eq 1) {
                Write-Host "Skipping 004-grade-datasets.sql because grade columns are already installed."
                continue
            }
        }
        if ($migrationPath.Name -ne "004-grade-datasets.sql" -and $finalTableByMigration.ContainsKey($migrationPath.Name)) {
            $schemaCheck = $connection.CreateCommand()
            $finalTable = $finalTableByMigration[$migrationPath.Name]
            $schemaCheck.CommandText = "SELECT CASE WHEN EXISTS (SELECT 1 FROM SecondRollingCost.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'$finalTable') THEN 1 ELSE 0 END"
            if ([System.Convert]::ToInt32($schemaCheck.ExecuteScalar()) -eq 1) {
                Write-Host "Skipping $($migrationPath.Name) because final table $finalTable is already installed."
                continue
            }
        }
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
