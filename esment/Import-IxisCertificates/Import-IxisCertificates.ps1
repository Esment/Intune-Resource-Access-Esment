using module .\Classes\IxisConfiguration.psm1
using module .\Classes\EntraService.psm1

$settings = Import-PowerShellDataFile `
    -Path "$PSScriptRoot\Config\Config.psd1"

$config = [IxisConfiguration]::new()

$config.ClientId = $settings.ClientId
$config.TenantId = $settings.TenantId
$config.CertificateThumbprint = $settings.CertificateThumbprint
$config.PfxPath = $settings.PfxPath
$config.PublicKeyPath = $settings.PublicKeyPath

$entraService = [EntraService]::new($Config)


try {
    $entraService.Connect()

    $group = $entraService.GetGroup()
    $users = $entraService.GetGroupUsers($group.Id)

    $users |
    Select-Object -First 10 DisplayName, UserPrincipalName, AccountEnabled |
    Format-Table
}
finally {
    $entraService.Disconnect()
}