function New-ManagedIdentityAccessToken {
    <#
    .DESCRIPTION
    Resources:
    'https://vault.azure.net'
    'https://management.azure.com'
    'https://storage.azure.com/'
    
    .PARAMETER Resource
    The Resource to get the AccessToken from.    

    .NOTES
    Author: Bas Wijdenes

    .LINK
    https://bwit.blog/how-to-download-a-zip-file-from-an-azure-storage-blob-powershell/
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $Resource
    )
    begin {
        Write-Verbose "New-ManagedIdentityAccessToken: begin: Building Headers & Body"
        $url = $env:IDENTITY_ENDPOINT  
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]" 
        $headers.Add("X-IDENTITY-HEADER", $env:IDENTITY_HEADER) 
        $headers.Add("Metadata", "True") 
        $body = @{resource = $Resource }
        Write-Verbose "New-ManagedIdentityAccessToken: begin: URL: $URL | Headers: $Headers | Body: $Body"
    }
    process {
        Write-Verbose "New-ManagedIdentityAccessToken: process: Requesting Access Token from $Resource"
        $accessToken = Invoke-RestMethod $url -Method 'POST' -Headers $headers -ContentType 'application/x-www-form-urlencoded' -Body $body 
        $Headers = @{
            Authorization = "Bearer $($accessToken.access_token)"
        }
    }
    end {
        return $Headers
    }
}