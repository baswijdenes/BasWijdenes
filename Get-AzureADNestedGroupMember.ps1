<#
.SYNOPSIS
Get AzureAD Group Members including nested groups in AzureAD.

.NOTES 
The script is using the AzureAD module.

.DESCRIPTION
Script has an inline function to re-call itself to search for nested group members.

.PARAMETER Group
The Group you want to get the members from.
This can be the DisplayName or ObjectId.
Warning: DisplayName is not unique, so it can happen that it's erroring out or getting the members of the wrong group.

.PARAMETER ObjectType
ObjectType can be:
User
Device
Group
Contact

Default is User.

.EXAMPLE
Get-AzureADNestedGroupMember -Groups GROUPNAME -ObjectType User

.LINK
https://bwit.blog/how-to-get-azuread-group-members-nested-groups-in-powershell/
#>
function Get-AzureADNestedGroupMember {
  [CmdletBinding()]
  param (
    [parameter(Mandatory, Position = 0)]
    $Group,
    [parameter(mandatory = $false)]
    [ValidateSet('User', 'Device', 'Group', 'Contact')]
    $ObjectType = 'User'
  )
  begin {
    function Get-AzureADNestedGroupMemberInLine {
      [CmdletBinding()]
      param (
        $Group,
        $ObjectType
      )
      begin {
        $ErrorActionPreference = 'Stop'
        Write-Verbose "Get-AzureADNestedGroupMemberInLine: begin: Running script for $Group"
        # We first have to check if the group is an ObjectId aka Guid or DisplayName.
        # By trying to parse the $Group variable we will get a true or false statement.
        $ObjectId = [guid]::TryParse($Group, $([ref][guid]::Empty))
      } 
      process {
        try {
          if ($ObjectId -eq $true) {
            Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Group Variable contains a Guid string: $Group"
            # Because the Group is a Guid we do not need to search for the group by DisplayName first. 
            # We can add the Guid to the $Grp Variable to get the members instantly.
            $Grp = $Group
          }
          else {
            Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Group Variable contains a DisplayName string: $Group"
            Write-Warning "DisplayNames are not unique. There is a chance that another group has the same DisplayName and you'll retrieve the members of the wrong group."
            # Because the $Group variable contains a DisplayName string we will have to search for the Group first & retrieve the ObjectId.
            $Grp = (Get-AzureADGroup -Filter "DisplayName eq '$Group'" -ErrorAction Stop).ObjectId
          }
          Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Getting members for: $Group"
          # The AzureAD cmdlet Get-AzureADGroupMember contains an -all bool Parameter. When we do not use this parameter, we will get a max of 100 users back.
          $Members = Get-AzureADGroupMember -All $true -ObjectId $Grp -ErrorAction Stop
          # 
          Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Filtering out members by ObjectTypes: Group & $ObjectType"
          # By filtering before the foreach loop we save time.
          $Members = $Members | Where-Object { ($_.ObjectType -eq 'Group') -or ($_.ObjectType -eq $ObjectType) }
          Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Start looping through each member. Total member count: $($Members.Count)"
          foreach ($Member in $Members) {
            Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Looping through: $($Member.DisplayName) | ObjectType: $($Member.ObjectType)"
            if ($Member.ObjectType -eq $ObjectType) {
              Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Member ObjectType: $($Member.ObjectType) equals $ObjectType | Adding member to ReturnList"
              $script:ReturnList.Add($member)
            }
            elseif ($Member.ObjectType -eq 'Group' ) {
              Write-Verbose "Get-AzureADNestedGroupMemberInLine: process: Nested Group found: $($Member.DisplayName)"
              if ($ObjectType -eq 'Group') {
                # Only when the ObjectType also equals Group we will add it to our list.
                $script:ReturnList.Add($member)
              }
              # Because we found a nested group we will have to re-run our script to find nested members.
              Get-AzureADNestedGroupMemberInLine -Group $Member.ObjectId -ObjectType $ObjectType -ErrorAction Stop
            }
          }
        }
        catch {
          throw $_.Exception.Message
        }
      }
      end { 
        Write-Verbose "Get-AzureADNestedGroupMemberInLine: end: Finished Inline script for $Group"
      }
    }
    Write-Verbose 'Get-AzureADNestedGroupMember: begin: Starting script... Creating UsersList'
    # We have to create a ReturnList do add members & nested members in. 
    # We will only do this when it's not a nested call. otherwise we will override the current list.
    # The ReturnList is added to the script scope so it can be re-used in the function.
    $script:ReturnList = [System.Collections.Generic.List[System.Object]]::new()
  }
  process {
    Write-Verbose 'Get-AzureADNestedGroupMember: process: Starting inline function'
    Get-AzureADNestedGroupMemberInLine -Group $Group -ObjectType $ObjectType -ErrorAction Stop
  }
  end {
    Write-Verbose "Get-AzureADNestedGroupMember: end: Finished search for $ObjectType"
    # By using Select-Object -Unique we will filter out duplicate members (due to members being part of more than one nested group).
    return ($script:ReturnList | Select-Object -Unique)
  }
}