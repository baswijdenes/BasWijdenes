function Get-AADPIMDirectoryRoleMembers {
    [CmdletBinding()]
    param (
        
    ) 
    begin {
        $DirectoryRolesURL = 'https://graph.microsoft.com/beta/privilegedAccess/aadRoles/resources/3fb0eae6-990e-4f5f-b997-5fcc618dd30f/roleDefinitions'
        $RoleAssignmentURL = 'https://graph.microsoft.com/beta/privilegedAccess/aadRoles/resources/3fb0eae6-990e-4f5f-b997-5fcc618dd30f/roleAssignments'
        $RolesSelectURL = '{0}?$select=id,displayName' -f $DirectoryRolesURL
        $Roles = Get-Mga -URL $RolesSelectURL
        $RolesHash = @{}
        foreach ($Role in $Roles) {
            $RolesHash.Add($Role.id, $Role)
        }
        $AllUsersURL = 'https://graph.microsoft.com/beta/users?$select=userPrincipalName,id,accountEnabled&$top=999'
        $AllUsers = Get-Mga -URL $AllUsersURL
        $AllUsersHash = @{}
        foreach ($User in $AllUsers) {
            $AllUsersHash.Add($User.id, $User)
        }
    }   
    process {
        $RoleAssignments = Get-Mga -URL $RoleAssignmentURL
        $RoleAssignmentsReport = [System.Collections.Generic.List[System.Object]]::new()  
        foreach ($Assignment in $RoleAssignments) {
            try {
                $User = $null
                $User = $AllUsersHash[$Assignment.subjectId]
                $Role = $null
                $Role = $RolesHash[$Assignment.roleDefinitionId]
                $Object = [PSCustomObject]@{
                    User           = $User.userPrincipalName
                    AccountEnabled = $User.accountEnabled
                    Role           = $Role.displayName
                }
                $RoleAssignmentsReport.Add($Object)
            }
            catch {
                continue
            }
        }
    } 
    end {
        return ($RoleAssignmentsReport | Where-Object { ($_.AccountEnabled -eq $true) -and ($null -ne $_.user) })
    }
}