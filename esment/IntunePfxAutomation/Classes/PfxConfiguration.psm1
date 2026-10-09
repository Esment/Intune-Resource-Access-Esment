class PfxConfiguration {

    # Entra ID / App Registration
    [string] $ClientId
    [string] $TenantId
    [string] $CertificateThumbprint

    # Grupo origen
    [string] $GroupName
    [string[]] $AllowedDomains

    # Certificado PFX
    [string] $PfxPath
    [string] $PublicKeyPath

    # Intune PFX
    [string] $ProviderName
    [string] $KeyName
    [string] $IntendedPurpose
    [string] $IntuneModulePath

    PfxConfiguration() {
    }

    [void] Validate() {

        if ([System.String]::IsNullOrWhiteSpace($this.ClientId)) {
            throw 'ClientId no puede estar vacío.'
        }

        if ([System.String]::IsNullOrWhiteSpace($this.TenantId)) {
            throw 'TenantId no puede estar vacío.'
        }

        if ([System.String]::IsNullOrWhiteSpace($this.CertificateThumbprint)) {
            throw 'CertificateThumbprint no puede estar vacío.'
        }

        if ([System.String]::IsNullOrWhiteSpace($this.PfxPath)) {
            throw 'PfxPath no puede estar vacío.'
        }

        if (-not (Test-Path -LiteralPath $this.PfxPath -PathType Leaf)) {
            throw "No se encuentra el certificado PFX: $($this.PfxPath)"
        }

        if ([System.String]::IsNullOrWhiteSpace($this.PublicKeyPath)) {
            throw 'PublicKeyPath no puede estar vacío.'
        }
        if (-not (Test-Path -LiteralPath $this.PublicKeyPath -PathType Leaf)) {
            throw "No se encuentra la clave pública: $($this.PublicKeyPath)"
        }
        
        if ([System.String]::IsNullOrWhiteSpace($this.IntuneModulePath)) {
            throw 'IntuneModulePath no puede estar vacío.'
        }

        if (-not (Test-Path -LiteralPath $this.IntuneModulePath -PathType Leaf)) {
            throw "No se encuentra el módulo IntunePfxImport: $($this.IntuneModulePath)"
        }
    }
}




