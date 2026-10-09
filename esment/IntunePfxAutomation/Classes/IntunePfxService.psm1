using module .\PfxConfiguration.psm1

class IntunePfxService {

    [PfxConfiguration] $Configuration

    IntunePfxService([PfxConfiguration] $Configuration) {

        if ($null -eq $Configuration) {
            throw 'Configuration no puede ser null.'
        }

        $this.Configuration = $Configuration
    }

    [void] Connect() {

        $this.Configuration.Validate()

        Import-Module $this.Configuration.IntuneModulePath -Force -Global
        $module = Get-Module IntunePfxImport
        if ($null -eq $module) {
            throw 'No se ha podido cargar el módulo IntunePfxImport.'
        }

        $module.PrivateData['ClientId'] = $this.Configuration.ClientId
        $module.PrivateData['TenantId'] = $this.Configuration.TenantId
        $module.PrivateData['CertificateThumbprint'] = $this.Configuration.CertificateThumbprint

        Set-IntuneAuthenticationToken
    }

}