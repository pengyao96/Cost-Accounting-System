. (Join-Path $PSScriptRoot "mock-repository.ps1")

function Get-Repository {
    param([string]$ProviderName = "mock")

    switch ($ProviderName.ToLowerInvariant()) {
        "mock" {
            return New-MockRepository
        }
        "sqlserver" {
            throw "SQL Server provider is not implemented yet. Add sql-repository.ps1 and switch here later."
        }
        default {
            throw "Unsupported provider: $ProviderName"
        }
    }
}
