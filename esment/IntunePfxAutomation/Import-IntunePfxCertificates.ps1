#requires -Version 5.1

using module .\Classes\PfxConfiguration.psm1
using module .\Classes\EntraService.psm1
using module .\Classes\IntunePfxService.psm1
using module .\Classes\PfxImportResult.psm1
using module .\Classes\PfxImportProcessor.psm1
using module .\Classes\PfxAuditLogger.psm1

param(
    [ValidateSet('Import', 'Remove')]
    [string] $Action = 'Import',
    [switch] $Execute
)

if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5) {
    throw 'IntunePfxAutomation requiere Windows PowerShell 5.1.'
}
Write-Output 'Iniciando script de importación de certificados PFX...' 
$settings = Import-PowerShellDataFile `
    -Path "$PSScriptRoot\Config\Config.psd1"

Write-Output 'Cargando configuración...' 
$config = [PfxConfiguration]::new()
$config.ClientId = $settings.ClientId
$config.TenantId = $settings.TenantId
$config.CertificateThumbprint = $settings.CertificateThumbprint
$config.PfxPath = $settings.PfxPath
$config.PfxPassword = ConvertTo-SecureString -String $settings.PfxPassword -AsPlainText -Force
$config.PublicKeyPath = $settings.PublicKeyPath
$config.GroupName = $settings.GroupName
$config.AllowedDomains = $settings.AllowedDomains
$config.ProviderName = $settings.ProviderName
$config.KeyName = $settings.KeyName
$config.IntendedPurpose = $settings.IntendedPurpose
$config.IntuneModulePath = $settings.IntuneModulePath
$config.LogDirectory = $settings.LogDirectory
Write-Output 'Inicializando servicios...' 
$logger = [PfxAuditLogger]::new($config)
$entraService = [EntraService]::new($config)
$intunePfxService = [IntunePfxService]::new($config)
$processor = [PfxImportProcessor]::new(
    $config,
    $intunePfxService
)
Write-Output 'Servicios inicializados.'
Write-Output 'Procesador de certificados inicializado.' 

try {

    Write-Output 'Conectando a Entra ID via Certificado'
    $entraService.Connect()

    $group = $entraService.GetGroup()
    $users = $entraService.GetGroupUsers($group.Id)

    Write-Output "Usuarios obtenidos del grupo: $($users.Count)"

    Write-Output 'Conectando a Intune mediante IntunePfxImport 2.1...'
    $intunePfxService.Connect()

    switch ($Action) {

        'Import' {
            Write-Output 'Procesando importación de certificados...' 
            $results = $processor.ProcessUsers(
                $users,
                $Execute
            )

            if ($Execute) {
                $changedResults = @(
                    $results | Where-Object { $_.Status -eq 'Imported' }
                )
            }
            else {
                $changedResults = @(
                    $results | Where-Object { $_.Status -eq 'Simulation' }
                )
            }

            Write-Output ""
            Write-Output "Cambios detectados: $($changedResults.Count)"

            foreach ($result in $changedResults) {
                Write-Output " - $($result.UserPrincipalName)"
            }

        }
        'Remove' {
            Write-Output 'Procesando eliminación de certificados...'

            $results = $processor.ProcessRemovals(
                $users,
                $Execute
            )

            if ($Execute) {
                $changedResults = @(
                    $results | Where-Object { $_.Status -eq 'Removed' }
                )
            }
            else {
                $changedResults = @(
                    $results | Where-Object { $_.Status -eq 'Simulation' }
                )
            }

            Write-Output ""
            Write-Output "Cambios detectados: $($changedResults.Count)"

            foreach ($result in $changedResults) {
                Write-Output " - $($result.UserPrincipalName)"
            }
        }
    }
    # Registrar cambios reales y errores
    $logger.Write($Action, $results)
}
catch {
    Write-Output "Ocurrió un error: $($_.Exception.Message)" 
    throw
}
finally {
    Write-Output 'Desconectando de Intune y Entra ID...' 
    $intunePfxService.Disconnect()
    $entraService.Disconnect()
}   