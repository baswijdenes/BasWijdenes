function Get-AADReports {
    [CmdletBinding()]
    param (
        [parameter(mandatory)]
        $OU
    )
    begin {
        $Select = '$Select={0}' -f "givenName,surname,Description,onPremisesSamAccountName,accountEnabled,onPremisesDistinguishedName"
        $URL = 'https://graph.microsoft.com/beta/users?$Top=999&{0}' -f $Select
    }
    process {
        try {
            $AllUsers = Get-Mga $URL
            $Return = $AllUsers | Where-Object { ($_.onPremisesDistinguishedName -like "*$OU") -and ($_.AccountEnabled -eq $true) } 
        }
        catch {
            throw $_.Exception.Message
        }
    }  
    end {
        return $Return
    }
}