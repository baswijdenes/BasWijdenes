#region functions
function Get-MailboxLimits {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false)]
        $RecipientTypeDetails = 'SharedMailbox',
        [parameter(mandatory = $false)]
        [int]
        $MaximumLimit = 50
    )
    begin {
        Write-Verbose "Get-MailboxLimits: begin: converting $MaximumLimit to bytes"
        $MaximumLimitInBytes = $MaximumLimit * 1.073.741.824
        $Output = [System.Collections.Generic.List[System.Object]]::new()
    }
    process {
        try {
            Write-Verbose "Get-MailboxLimits: process: Getting all mailboxes of type $RecipientTypeDetails"
            $MBXs = Get-EXOMailbox -ResultSize Unlimited -Filter { RecipientTypeDetails -eq "$RecipientTypeDetails" }
        }
        catch {
            throw $_.Exception.Message
        }
        Write-Verbose "Get-MailboxLimits: process: Processing mailboxes in foreach loop"
        foreach ($MBX in $MBXs) {
            try {
                $Stats = $null
                $Stats = Get-EXOMailboxStatistics -Identity $MBX.UserPrincipalName
                $Object = [PSCustomObject]@{
                    UserPrincipalName = $MBX.UserPrincipalName
                    DisplayName       = $MBX.DisplayName
                    TotalSize         = $Stats.TotalItemSize
                    'OverLimit'       = $null
                }
                if ($($Stats.TotalItemSize.Value.ToBytes()) -ge $MaximumLimitInBytes) {
                    Write-Verbose "Get-MailboxLimits: process: $($MBX.UserPrincipalName) is over the Limit of $MaximumLimit"
                    $Object.OverLimit = $true
                }
                else {
                    $Object.OverLimit = $false
                }
                $Output.Add($Object)
            }
            catch {
                continue
            }
        }
    } 
    end {
        return $Output
    }
}             
#endregion