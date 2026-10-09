using module .\Classes\PfxConfiguration.psm1
using module .\Classes\EntraService.psm1
using module .\Classes\IntunePfxService.psm1

$settings = Import-PowerShellDataFile `
    -Path "$PSScriptRoot\Config\Config.psd1"

$config = [PfxConfiguration]::new()

$config.ClientId = $settings.ClientId
$config.TenantId = $settings.TenantId
$config.CertificateThumbprint = $settings.CertificateThumbprint
$config.PfxPath = $settings.PfxPath
$config.PublicKeyPath = $settings.PublicKeyPath
$config.GroupName       = $settings.GroupName
$config.AllowedDomains  = $settings.AllowedDomains
$config.ProviderName    = $settings.ProviderName
$config.KeyName         = $settings.KeyName
$config.IntendedPurpose = $settings.IntendedPurpose
$config.IntuneModulePath = $settings.IntuneModulePath

$entraService = [EntraService]::new($config)

$intunePfxService = [IntunePfxService]::new($config)

try {
    Write-Host 'Conectando a Intune mediante IntunePfxImport 2.1...'

    $intunePfxService.Connect()

    Write-Host 'Autenticación Intune correcta.' -ForegroundColor Green
}
catch {
    Write-Error "Error autenticando en Intune: $($_.Exception.Message)"
}

<# try {
    $entraService.Connect()

    $group = $entraService.GetGroup()
    $users = $entraService.GetGroupUsers($group.Id)

    $users |
    Select-Object -First 10 DisplayName, UserPrincipalName, AccountEnabled |
    Format-Table
}
finally {
    $entraService.Disconnect()
} #>