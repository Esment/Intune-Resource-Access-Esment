class PfxImportResult {

    [datetime] $Timestamp
    [string] $UserPrincipalName
    [string] $Status
    [string] $Detail

    PfxImportResult(
        [string] $UserPrincipalName,
        [string] $Status,
        [string] $Detail
    ) {
        $this.Timestamp = Get-Date
        $this.UserPrincipalName = $UserPrincipalName
        $this.Status = $Status
        $this.Detail = $Detail
    }
}