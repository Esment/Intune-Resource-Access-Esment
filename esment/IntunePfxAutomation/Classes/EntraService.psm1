
using module .\PfxConfiguration.psm1
class EntraService {

    [PfxConfiguration] $Configuration

    EntraService([PfxConfiguration] $Configuration) {

        if ($null -eq $Configuration) {
            throw 'Configuration no puede ser null.'
        }

        $this.Configuration = $Configuration
    }

    [void] Connect() {

        $this.Configuration.Validate()

        Connect-MgGraph `
            -ClientId $this.Configuration.ClientId `
            -TenantId $this.Configuration.TenantId `
            -CertificateThumbprint $this.Configuration.CertificateThumbprint `
            -NoWelcome
    }

    [object] GetGroup() {

        $groupName = $this.Configuration.GroupName

        if ([System.String]::IsNullOrWhiteSpace($groupName)) {
            throw 'GroupName no puede estar vacío.'
        }

        $escapedGroupName = $groupName.Replace("'", "''")

        $groups = @(
            Get-MgGroup `
                -Filter "displayName eq '$escapedGroupName'" `
                -Property 'id,displayName,securityEnabled'
        )

        if ($groups.Count -eq 0) {
            throw "No se ha encontrado el grupo '$groupName' en Entra ID."
        }

        if ($groups.Count -gt 1) {
            throw "Se ha encontrado más de un grupo con el nombre '$groupName'."
        }

        if (-not $groups[0].SecurityEnabled) {
            throw "'$groupName' no es un grupo de seguridad."
        }

        return $groups[0]
    }
    [object[]] GetGroupUsers([string] $GroupId) {

        if ([System.String]::IsNullOrWhiteSpace($GroupId)) {
            throw 'GroupId no puede estar vacío.'
        }

        $users = @(
            Get-MgGroupTransitiveMemberAsUser `
                -GroupId $GroupId `
                -All `
                -Property @(
                'id',
                'displayName',
                'userPrincipalName',
                'accountEnabled',
                'userType',
                'onPremisesDistinguishedName'
            )
        )

        return $users
    }
    [void] Disconnect() {

        Disconnect-MgGraph | Out-Null
    }
}