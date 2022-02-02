function Get-KeyVaultCredential {
    <#
    .SYNOPSIS
    Use this to get secrets from the KeyVault.

    .DESCRIPTION
    Function gets an AccessToken for the managed Identity by DotSourcing: New-ManagedIdentityAccessToken.ps1
    
    .PARAMETER Username
    Username should be the same name as the secretname in the KeyVault.
    
    .PARAMETER KeyVault
    Default is Azure Automation Variable KeyVaultName.  

    .PARAMETER SecretOnly
    By Default the function gives back the Credentials as a Credential. 
    By using SecretOnly it will return the secret as plain text.
    
    .PARAMETER Resource
    DO NOT TOUCH THIS PARAMETER

    .EXAMPLE
    Get-KeyVaultCredential 'Exchange' -SecretOnly
    
    .NOTES
    Author: Bas Wijdenes
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $Username,
        [parameter(mandatory = $false)]
        $KeyVault = (Get-AutomationVariable -Name 'KeyVaultName'),
        [parameter(mandatory = $false)]
        [switch]
        $SecretOnly,
        [parameter(mandatory = $false)]
        [string]
        $Resource = 'https://vault.azure.net'
    )
    begin {
        Write-Verbose "Get-KeyVaultCredential: begin: DotSourcing New-ManagedIdentityAccessToken"
        . .\New-ManagedIdentityAccessToken.ps1
        Write-Verbose "Get-KeyVaultCredential: begin: Resource: $Resource"
        $Headers = New-ManagedIdentityAccessToken -Resource $Resource
    Write-Verbose "Get-KeyVaultCredential: begin: Headers: $Headers"
    }
    process {
        $KeyVaultSplatting = @{
            Uri     = 'https://{0}.vault.azure.net/secrets/{1}?api-version=2016-10-01' -f $KeyVault, $Username
            Method  = 'Get'
            Headers = $Headers
        }
        if ($SecretOnly -ne $true) {
            $Password = (Invoke-RestMethod @KeyVaultSplatting).value | ConvertTo-SecureString -AsPlainText -Force
            $Credential = [PSCredential]::new($Username, $Password)
        }
        else {
            Write-Verbose "Get-KeyVaultCredential: process: SecretOnly -eq $SecretOnly | Secret is returned in PlainText"
            $Credential = (Invoke-RestMethod @KeyVaultSplatting).value
        }
    }
    end {
        return $Credential
    }
}