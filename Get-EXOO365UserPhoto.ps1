#region functions
<#
.DESCRIPTION
This script will see if there is a UserPhoto per mailbox.
With Get-UserPhoto you will get an error when there is no user photo.

.PARAMETER Mailboxes
This is not a mandatory Parameter. 
But when you want to run this script for only a set of users you can use a list of mailboxes instead.
If you do not add this parameter, the script will run a Get-Mailbox -ResultSize unlimited.

.EXAMPLE
Get-O365UserPhoto
Get-O365UserPhoto -Verbose

$Mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox
Get-O365UserPhoto -Mailboxes $Mailboxes

.LINK
https://bwit.blog/office-365-profile-picture-powershell/
#>
function Get-O365UserPhoto
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        $Mailboxes
    )
    begin
    {
        if ($null -eq $Mailboxes)
        {
            Write-Verbose 'Get-O365UserPhoto: begin: We did not receive a list of maiboxes. Getting all mailboxes in tenant....'
            try
            {
                $Mailboxes = Get-Mailbox -ResultSize unlimited
            }
            catch
            {
                throw $_.Exception.Message
            }
        }
        Write-Verbose 'Get-O365UserPhoto: begin: Creating UserList for end output.'
        $365UserPhotos = [System.Collections.Generic.List[System.Object]]::new()
    }  
    process
    {
        Write-Verbose 'Get-O365UserPhoto: process: Starting to process each mailbox.'
        foreach ($Mbx in $Mailboxes)
        {
            Write-Verbose "Get-O365UserPhoto: process: Running script for $($Mbx.UserPrincipalName)."
            try
            {
                $Photo = $null
                $Photo = Get-UserPhoto -Identity $Mbx.UserPrincipalName -ErrorAction SilentlyContinue
                if ($Photo)
                {
                    Write-Verbose "Get-O365UserPhoto: process: User $($Mbx.UserPrincipalName) has a UserPhoto."
                    $Object = [PSCustomObject]@{
                        UserPrincipalName = $Mbx.UserPrincipalName
                        HasProfilePicture = $true
                    }
                }
                else
                {
                    Write-Verbose "Get-O365UserPhoto: process: User $($Mbx.UserPrincipalName) does not have a UserPhoto."
                    $Object = [PSCustomObject]@{
                        UserPrincipalName = $Mbx.UserPrincipalName
                        HasProfilePicture = $false
                    }
                }
                $365UserPhotos.Add($Object)
            }
            catch
            {
                continue
            }
        }
    }
    end
    {
        return $365UserPhotos
    }
}
#endregion