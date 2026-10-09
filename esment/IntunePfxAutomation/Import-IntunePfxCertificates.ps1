#requires -Version 5.1

using module .\Classes\PfxConfiguration.psm1
using module .\Classes\EntraService.psm1
using module .\Classes\IntunePfxService.psm1
using module .\Classes\PfxImportResult.psm1
using module .\Classes\PfxImportProcessor.psm1

param(
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

Write-Host 'Inicializando servicios...' -ForegroundColor Cyan
$entraService = [EntraService]::new($config)
$intunePfxService = [IntunePfxService]::new($config)
Write-Host 'Servicios inicializados.' -ForegroundColor Cyan
$processor = [PfxImportProcessor]::new(
    $config,
    $intunePfxService
)
Write-Host 'Procesador de importación de certificados inicializado.' -ForegroundColor Cyan

try {
    Write-Host 'Conectando a Entra ID via Certificado'
    $entraService.Connect()
    Write-Host 'Autenticación Entra ID correcta.' -ForegroundColor Green
    $group = $entraService.GetGroup()
    Write-Host "Grupo obtenido: $($group.DisplayName)" -ForegroundColor Green
    $users = $entraService.GetGroupUsers($group.Id)
    Write-Host "Usuarios obtenidos del grupo: $($users.Count)" -ForegroundColor Green
    Write-Host 'Conectando a Intune mediante IntunePfxImport 2.1...'
    $intunePfxService.Connect()
    Write-Host "Conexión a Intune establecida correctamente." -ForegroundColor Green

    $results = $processor.ProcessUsers(
        $users,
        $Execute
    )
    $results |
    Group-Object Status |
    Select-Object Name, Count |
    Format-Table

    $results |
    Select-Object -First 20 `
        Timestamp,
    UserPrincipalName,
    Status,
    Detail |
    Format-Table -AutoSize
    Write-Host 'Procesamiento de usuarios completado.' -ForegroundColor Green

    $results |
    Where-Object Status -eq 'Simulation' |
    Select-Object UserPrincipalName, Status, Detail |
    Format-Table -AutoSize

}
finally {
    Write-Host 'Desconectando de Intune y Entra ID...' -ForegroundColor Yellow
    $intunePfxService.Disconnect()
    $entraService.Disconnect()
}