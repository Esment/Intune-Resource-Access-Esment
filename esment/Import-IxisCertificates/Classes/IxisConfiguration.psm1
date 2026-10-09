class IxisConfiguration {

    # Entra ID / App Registration
    [string] $ClientId
    [string] $TenantId
    [string] $CertificateThumbprint

    # Grupo origen
    [string] $GroupName
    [string[]] $AllowedDomains

    # Certificado IXIS
    [string] $PfxPath
    [string] $PublicKeyPath

    # Intune PFX
    [string] $ProviderName
    [string] $KeyName
    [string] $IntendedPurpose

    IxisConfiguration() {

        $this.GroupName = 'AAD_Certificado Ixis'

        $this.AllowedDomains = @(
            'esment.org',
            'amadipesment.org'
        )

        $this.ProviderName = 'Microsoft Software Key Storage Provider'
        $this.KeyName = 'PFXEncryptionKey'
        $this.IntendedPurpose = 'unassigned'
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
            throw "No se encuentra el certificado IXIS: $($this.PfxPath)"
        }

        if ([System.String]::IsNullOrWhiteSpace($this.PublicKeyPath)) {
            throw 'PublicKeyPath no puede estar vacío.'
        }
        if (-not (Test-Path -LiteralPath $this.PublicKeyPath -PathType Leaf)) {
            throw "No se encuentra la clave pública: $($this.PublicKeyPath)"
        }
    }
}




