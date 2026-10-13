using module .\PfxConfiguration.psm1
using module .\PfxImportResult.psm1

class PfxAuditLogger {

    [PfxConfiguration] $Configuration

    PfxAuditLogger([PfxConfiguration] $Configuration) {

        if ($null -eq $Configuration) {
            throw 'Configuration no puede ser null.'
        }

        if ([System.String]::IsNullOrWhiteSpace($Configuration.LogDirectory)) {
            throw 'LogDirectory no puede estar vacío.'
        }

        $this.Configuration = $Configuration

        if (-not (Test-Path -LiteralPath $this.Configuration.LogDirectory)) {
            New-Item `
                -Path $this.Configuration.LogDirectory `
                -ItemType Directory `
                -Force | Out-Null
        }
    }

    [void] Write(
        [string] $Action,
        [object[]] $Results
    ) {

        if ([System.String]::IsNullOrWhiteSpace($Action)) {
            throw 'Action no puede estar vacío.'
        }

        if ($null -eq $Results) {
            return
        }

        $auditResults = @(
            $Results | Where-Object {
                $_.Status -in @(
                    'Imported',
                    'Removed',
                    'Error',
                    'Simulation',
                    'SimulationRemove'
                )
            }
        )

        if ($auditResults.Count -eq 0) {
            return
        }

        $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

        $logPath = Join-Path `
            -Path $this.Configuration.LogDirectory `
            -ChildPath "IntunePfxAutomation-$timestamp.csv"

        $records = foreach ($result in $auditResults) {

            [PSCustomObject]@{
                Timestamp         = $result.Timestamp
                Action            = $Action
                UserPrincipalName = $result.UserPrincipalName
                Status            = $result.Status
                Detail            = $result.Detail
            }
        }

        $records |
        Export-Csv `
            -Path $logPath `
            -NoTypeInformation `
            -Encoding UTF8 `
            -Append
    }
}