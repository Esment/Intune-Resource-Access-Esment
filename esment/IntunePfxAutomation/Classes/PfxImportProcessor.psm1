using module .\PfxConfiguration.psm1
using module .\IntunePfxService.psm1
using module .\PfxImportResult.psm1

class PfxImportProcessor {

    [PfxConfiguration] $Configuration
    [IntunePfxService] $IntuneService

    PfxImportProcessor(
        [PfxConfiguration] $Configuration,
        [IntunePfxService] $IntuneService
    ) {
        if ($null -eq $Configuration) {
            throw 'Configuration no puede ser null.'
        }

        if ($null -eq $IntuneService) {
            throw 'IntuneService no puede ser null.'
        }

        $this.Configuration = $Configuration
        $this.IntuneService = $IntuneService
    }

    hidden [string] GetPfxThumbprint() {

        $pfxData = Get-PfxData `
            -FilePath $this.Configuration.PfxPath `
            -Password $this.Configuration.PfxPassword

        $thumbprint = $pfxData.EndEntityCertificates[0].Thumbprint

        if ([System.String]::IsNullOrWhiteSpace($thumbprint)) {
            throw 'No se ha podido obtener la huella del certificado PFX.'
        }

        return $thumbprint.ToUpperInvariant()
    }

    hidden [bool] IsEligibleUser([object] $User) {

        if ($null -eq $User) {
            return $false
        }

        if ($User.UserType -ne 'Member') {
            return $false
        }

        if (-not $User.AccountEnabled) {
            return $false
        }

        $upn = [string] $User.UserPrincipalName

        if ([System.String]::IsNullOrWhiteSpace($upn)) {
            return $false
        }

        if ($upn -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
            return $false
        }

        $domain = $upn.Split('@')[-1].ToLowerInvariant()

        return $domain -in $this.Configuration.AllowedDomains
    }

    hidden [bool] CertificateExists(
        [object[]] $ExistingCertificates,
        [string] $Upn,
        [string] $Thumbprint
    ) {
        $matches = @(
            $ExistingCertificates | Where-Object {
                $_.UserPrincipalName -ieq $Upn -and
                $_.Thumbprint -ieq $Thumbprint -and
                ([string] $_.IntendedPurpose) -ieq $this.Configuration.IntendedPurpose
            }
        )

        return $matches.Count -gt 0
    }

    [object[]] ProcessUsers(
        [object[]] $Users,
        [bool] $Execute
    ) {
        if ($null -eq $Users) {
            throw 'Users no puede ser null.'
        }

        $results = [System.Collections.Generic.List[object]]::new()

        $thumbprint = $this.GetPfxThumbprint()

        try {
            $existingCertificates = @(
                $this.IntuneService.GetExistingCertificates()
            )
        }
        catch {
            throw "Error al consultar los certificados existentes para Remove: $($_.Exception.Message)"
        }


        foreach ($user in $Users) {

            $upn = [string] $user.UserPrincipalName

            if (-not $this.IsEligibleUser($user)) {
                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Invalid',
                        'Usuario deshabilitado, externo, sin UPN válido o con dominio no permitido.'
                    )
                )

                continue
            }

            if ($this.CertificateExists(
                    $existingCertificates,
                    $upn,
                    $thumbprint
                )) {
                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Skipped',
                        'El certificado ya está importado para el usuario.'
                    )
                )

                continue
            }

            if (-not $Execute) {
                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Simulation',
                        'El certificado se importaría en una ejecución real.'
                    )
                )

                continue
            }

            try {
                $certificate = $this.IntuneService.CreateUserCertificate(
                    $upn,
                    $this.Configuration.PfxPassword
                )

                $this.IntuneService.ImportCertificate($certificate)

                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Imported',
                        'Certificado importado correctamente.'
                    )
                )
            }
            catch {
                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Error',
                        $_.Exception.Message
                    )
                )
            }
        }

        return $results.ToArray()
    }

    [object[]] ProcessRemovals(
        [object[]] $Users,
        [bool] $Execute
    ) {

        if ($null -eq $Users) {
            throw 'Users no puede ser null.'
        }

        $results = [System.Collections.Generic.List[object]]::new()

        $thumbprint = $this.GetPfxThumbprint()

        $existingCertificates = @(
            $this.IntuneService.GetExistingCertificates()
        )

        # Crear lista de UPN actualmente autorizados por el grupo
        $allowedUsers = @{}

        foreach ($user in $Users) {

            if ($this.IsEligibleUser($user)) {
                $upn = ([string] $user.UserPrincipalName).ToLowerInvariant()
                $allowedUsers[$upn] = $true
            }
        }

        foreach ($certificate in $existingCertificates) {

            # Solo gestionamos certificados correspondientes
            # al PFX configurado actualmente
            if ($certificate.Thumbprint -ine $thumbprint) {
                continue
            }

            if (([string] $certificate.IntendedPurpose) -ine $this.Configuration.IntendedPurpose) {
                continue
            }

            $upn = ([string] $certificate.UserPrincipalName).ToLowerInvariant()

            # Continúa perteneciendo al grupo
            if ($allowedUsers.ContainsKey($upn)) {
                continue
            }

            # Simulación
            if (-not $Execute) {

                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'SimulationRemove',
                        'El certificado se eliminaría en una ejecución real.'
                    )
                )

                continue
            }

            # Ejecución real
            try {

                $this.IntuneService.RemoveCertificate($certificate)

                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Removed',
                        'Certificado eliminado correctamente.'
                    )
                )
            }
            catch {

                $results.Add(
                    [PfxImportResult]::new(
                        $upn,
                        'Error',
                        $_.Exception.Message
                    )
                )
            }
        }

        return $results.ToArray()
    }
}