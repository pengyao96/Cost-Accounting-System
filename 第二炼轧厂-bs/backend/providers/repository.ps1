. (Join-Path $PSScriptRoot "mock-repository.ps1")
. (Join-Path $PSScriptRoot "sql-repository.ps1")

function Get-Repository {
    param([string]$ProviderName = "mock")

    switch ($ProviderName.ToLowerInvariant()) {
        "mock" {
            return New-MockRepository
        }
        "sqlserver" {
            return New-SqlRepository
        }
        default {
            throw "Unsupported provider: $ProviderName"
        }
    }
}
