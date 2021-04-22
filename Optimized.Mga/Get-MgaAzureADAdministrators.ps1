function Get-AADDirectoryRoleMembers {
    [CmdletBinding()]
    param (
    )   
    begin {
        $AzureADAdmins = [System.Collections.Generic.List[System.Object]]::new()  
    }  
    process {
        $Roles = Get-Mga -URL 'https://graph.microsoft.com/v1.0/directoryRoles?$Select=id,displayName'
        foreach ($Role in $Roles) {
            try {
                $URL = 'https://graph.microsoft.com/v1.0/directoryRoles/{0}/members?$select=id,userPrincipalName,givenName,surname,displayName' -f $Role.Id 
                $Members = $null
                $Members = Get-Mga -URL $URL
                if ($null -ne $Members -and ($null -eq $Members.value)) {
                    foreach ($Member in $Members) {
                        try {
                            $Object = [PSCustomObject]@{
                                UserPrincipalName    = $Member.userPrincipalName
                                AdminRole            = $Role.displayName
                                PermanentlyActivated = $true
                            }
                            $AzureADAdmins.Add($Object)  
                        }
                        catch {
                            continue
                        }
                    }
                }
            }
            catch {
                continue
            }
        }
    }   
    end {
        return $AzureADAdmins
    }
}
