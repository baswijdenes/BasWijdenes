#region functions
<#
.SYNOPSIS
Get-MailboxLimits will get mailboxes that are over the limit of 50 (by default)

.DESCRIPTION
Script will show which mailboxes are over the limit in the return.
When the property OverLimit equals True, the mailbox reached the limit.

.PARAMETER RecipientTypeDetails
The default is SharedMailbox. You can also use the script for other RecipientTypes.

.PARAMETER MaximumLimit
The default is 50Gb. You can set the MaximumLimit with Gb only. The script will convert this to bytes.
You can set this to a lower amount to see which mailboxes are close to 50Gb.

.EXAMPLE
Get-MailboxLimits

.EXAMPLE
Get-MailboxLimits -RecipientTypeDetails 'UserMailbox'

.EXAMPLE
Get-MailboxLimits -MaximumLimit 48

.EXAMPLE
Get-MailboxLimits -RecipientTypeDetails 'UserMailbox' -MaximumLimit 45

.LINK
https://bwit.blog/shared-mailboxes-above-50gb-will-need-a-license-in-exchange-online/
#>
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