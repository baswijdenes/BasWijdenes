#region functions
<#
.SYNOPSIS
Function to disable PowerShell for users

.DESCRIPTION
Function will auto exclude Organization Management group (NOT NESTED) from disabling PowerShell for users

.PARAMETER RolesToExclude
You don't need to exclude Organization Management, for other roles in ExO you can exclude them with and array of roles

.EXAMPLE
Disable-EXOPowerShellForUsers

.EXAMPLE
Disable-EXOPowerShellForUsers -RolesToExclude 'Security Reader','Security Administrator'

.LINK

#>
function Disable-EXOPowerShellForUsers {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false)]
        $RolesToExclude 
    ) 
    begin {
        Write-Verbose "Disable-EXOPowerShellForUsers: begin: By default Organization Management is excluded"
        $rolesToExclude = $RolesToExclude + "Organization Management"
        $AdminUsers = @()
        foreach ($role in $roles) {
            try {
                Write-Verbose "Disable-EXOPowerShellForUsers: begin: Getting users from role $Role to exclude from disabling PowerShell"
                $Users = (Get-RoleGroup -Identity $Role).Members
                $AdminUsers += $users
            }
            catch {
                throw $_.Exception.Message
            }
        }
    }   
    process {
        Write-Verbose "Disable-EXOPowerShellForUsers: process: Getting all users from tenant (Roles excluded)"
        $Users = Get-User -ResultSize Unlimited -filter { RemotePowerShellEnabled -eq $true } | Where-Object { $([string]$AdminUsers) -notmatch $_.Name }
        foreach ($User in $Users) {
            try {
                Write-Verbose "Disable-EXOPowerShellForUsers: process: Updating $($User.WindowsLiveId)"
                Set-User -Identity $User.WindowsLiveId -RemotePowerShellEnabled $false
            }
            catch {
                Write-Warning "Something went wrong with $($User.WindowsLiveID)"
                continue
            }
        }
    }   
    end {
        return "For $($Users.count) user(s) PowerShell has been disabled"
    }
}
#endregion