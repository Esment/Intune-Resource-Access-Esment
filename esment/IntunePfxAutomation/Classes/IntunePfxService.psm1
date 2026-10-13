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

    [object[]] GetExistingCertificates() {

        $certificates = @(
            Get-IntuneUserPfxCertificate
        )

        return $certificates
    }

    [object] CreateUserCertificate(
        [string] $Upn,
        [securestring] $PfxPassword
    ) {

        if ([System.String]::IsNullOrWhiteSpace($Upn)) {
            throw 'UPN no puede estar vacío.'
        }

        if ($null -eq $PfxPassword) {
            throw 'PfxPassword no puede ser null.'
        }

        $certificate = New-IntuneUserPfxCertificate `
            -PathToPfxFile $this.Configuration.PfxPath `
            -PfxPassword $PfxPassword `
            -UPN $Upn `
            -ProviderName $this.Configuration.ProviderName `
            -KeyName $this.Configuration.KeyName `
            -IntendedPurpose $this.Configuration.IntendedPurpose `
            -KeyFilePath $this.Configuration.PublicKeyPath

        if ($null -eq $certificate) {
            throw "No se ha podido generar el objeto PFX para '$Upn'."
        }

        return $certificate
    }

    [void] ImportCertificate([object] $Certificate) {

        if ($null -eq $Certificate) {
            throw 'Certificate no puede ser null.'
        }

        $listType = (Get-Command Import-IntuneUserPfxCertificate).Parameters['CertificateList'].ParameterType

        $certificateList = [System.Activator]::CreateInstance($listType)

        $certificateList.Add($Certificate) | Out-Null

        Import-IntuneUserPfxCertificate `
            -CertificateList $certificateList
    }

    [void] RemoveCertificate([object] $Certificate) {

        if ($null -eq $Certificate) {
            throw 'Certificate no puede ser null.'
        }

        $listType = (Get-Command Remove-IntuneUserPfxCertificate).
        Parameters['CertificateList'].ParameterType

        $certificateList = [System.Activator]::CreateInstance($listType)

        $certificateList.Add($Certificate) | Out-Null

        Remove-IntuneUserPfxCertificate `
            -CertificateList $certificateList `
            -Confirm:$false
    }

    [void] Disconnect() {

        if (Get-Command Remove-IntuneAuthenticationToken -ErrorAction SilentlyContinue) {
            Remove-IntuneAuthenticationToken
        }
    }
}