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
Write-Host 'Iniciando script de importación de certificados PFX...' -ForegroundColor Cyan
$settings = Import-PowerShellDataFile `
    -Path "$PSScriptRoot\Config\Config.psd1"

Write-Host 'Cargando configuración...' -ForegroundColor Cyan
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
Write-Host 'Inicializando servicios...' -ForegroundColor Cyan
$logger = [PfxAuditLogger]::new($config)
$entraService = [EntraService]::new($config)
$intunePfxService = [IntunePfxService]::new($config)
$processor = [PfxImportProcessor]::new(
    $config,
    $intunePfxService
)
Write-Host 'Servicios inicializados.' -ForegroundColor Cyan
Write-Host 'Procesador de certificados inicializado.' -ForegroundColor Cyan

try {

    Write-Host 'Conectando a Entra ID via Certificado'
    $entraService.Connect()

    $group = $entraService.GetGroup()
    $users = $entraService.GetGroupUsers($group.Id)

    Write-Host "Usuarios obtenidos del grupo: $($users.Count)"

    Write-Host 'Conectando a Intune mediante IntunePfxImport 2.1...'
    $intunePfxService.Connect()

    switch ($Action) {

        'Import' {
            Write-Host 'Procesando importación de certificados...' -ForegroundColor Cyan
            $results = $processor.ProcessUsers(
                $users,
                $Execute
            )
        }

        'Remove' {
            Write-Host 'Procesando eliminación de certificados...' -ForegroundColor Cyan
            $results = $processor.ProcessRemovals(
                $users,
                $Execute
            )
        }
    }
    # Registrar cambios reales y errores
    $logger.Write($Action, $results)
}
catch {
    Write-Host "Ocurrió un error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host 'Desconectando de Intune y Entra ID...' -ForegroundColor Yellow
    $intunePfxService.Disconnect()
    $entraService.Disconnect()
}   