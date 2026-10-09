@{
    ClientId              = ''
    TenantId              = ''
    CertificateThumbprint = ''

    GroupName             = ''

    AllowedDomains        = @(
        '',
        ''
    )

    ProviderName          = 'Microsoft Software Key Storage Provider'
    KeyName               = 'PFXEncryptionKey'
    IntendedPurpose       = 'unassigned'

    PfxPath               = 'C:\IntunePfxImport\certificate.p12'
    PfxPassword           = ''
    PublicKeyPath         = 'C:\IntunePfxImport\PFXEncryptionKey.cer'
    IntuneModulePath      = 'C:\IntunePFXImport\IntunePfxImport.psd1'
}