function Import-AutomationRunbook {
    <#
    .SYNOPSIS
    Import an Automationrunbook from a blobstorage for PowerShell 7.XX

    .DESCRIPTION
    Import an Automationrunbook from a blobstorage for PowerShell 7.XX 
    
    .PARAMETER RunbookName
    Name of the runbook to import in the storage blob & automation account
    
    .PARAMETER RuntimeVersionRunbook
    Either 7.1 or 7.2
    
    .PARAMETER ResourceGroup
    Resource Group where the Automation Account is located

    .PARAMETER AutomationAccountName
    Automation Account to upload to
    
    .PARAMETER StorageAccountName
    Storage Account where the runbook is located
    
    .PARAMETER StorageContainer
    Storage Container where the runbook is located
    
    .PARAMETER SASToken
    SAS Token for the Storage Account (Container)
    Microsoft documentation:
    https://learn.microsoft.com/en-us/azure/ai-services/translator/document-translation/how-to-guides/create-sas-tokens?tabs=Containers

    Unfortunately we must have a SAS token as there is no other way to authenticate to the blobstorage via Invoke-AzRestMethod.
    
    .EXAMPLE
    Import-AutomationRunbook -RunbookName 'MyRunbook' -RuntimeVersionRunbook '7.2' -AutomationAccountName 'MyAutomationAccount' -StorageAccountName 'MyStorageAccount' -StorageContainer 'MyStorageContainer' -SASToken '?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacupitfx&se=2021-10-31T00:00:00Z&st=2021-10-01T00:00:00Z&spr=https&sig=MySignature'
    
    .NOTES
    Author: Bas Wijdenes
    Site: https://baswijdenes.com
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        [string]$RunbookName,
        [parameter(mandatory = $true)]
        [validateset('7.1', '7.2')]
        [string]$RuntimeVersionRunbook,
        [parameter(mandatory = $true)]
        [string]$ResourceGroup,
        [parameter(mandatory = $true)]
        [string]$AutomationAccountName,
        [parameter(mandatory = $true)]
        [string]$StorageAccountName,
        [parameter(mandatory = $true)]
        [string]$StorageContainer,
        [parameter(mandatory = $true)]
        [string]$SASToken
    
    )
    begin {
        switch ($RuntimeVersionRunbook) {
            '7.1' {
                $ApiVersion = '2019-06-01'
            }
            '7.2' {
                $ApiVersion = '2022-06-30-preview'
            }
        } 
        if ($Runbookname -like '*.ps1') {
            $RunbookName = $RunbookName -replace '.ps1', ''
        }
        Write-Verbose "Importing runbook $($RunbookName) in $($AutomationAccountName)"
        $DirectBlobUri = "https://$($StorageAccountName).blob.core.windows.net/$($StorageContainer)/{0}$SASToken" -f "$($RunbookName).ps1"
        if ($RuntimeVersionRunbook -eq '7.1') {
            $JsonPayLoad = @{
                Properties = @{
                    RunbookType        = 'PowerShell7'
                    publishContentLink = @{
                        uri = $DirectBlobUri
                    }
                    state              = 'Published'
                }
                location   = 'westeurope'
            } | ConvertTo-Json
        }
        elseif ($RuntimeVersionRunbook -eq '7.2') {
            $JsonPayLoad = @{
                Properties = @{
                    RunbookType        = 'PowerShell'
                    runtime            = 'PowerShell-7.2'
                    publishContentLink = @{
                        uri = $DirectBlobUri
                    }
                    state              = 'Published'
                }
                location   = 'westeurope'
            } | ConvertTo-Json
        }
    } 
    process {
        $InvokeAzRestMethodSplat = @{
            Method               = 'PUT'
            ResourceGroupName    = $($ResourceGroup)
            ResourceProviderName = 'Microsoft.Automation'
            ResourceType         = 'automationAccounts'
            Name                 = "$($AutomationAccountName)/runbooks/$($RunbookName)"
            ApiVersion           = $ApiVersion
            PayLoad              = $JsonPayLoad
        }
        try {
            $InvokeAzRestMethodSplat.Method = 'PUT'
            $Invoke = Invoke-AzRestMethod @InvokeAzRestMethodSplat
        }
        catch {
            throw "Failed to create runbook $($RunbookName): $($_.Exception.Message)"
        }
        if (-not(($Invoke.StatusCode -eq 200) -or ($Invoke.StatusCode -eq 201))) {
            throw "Failed to create runbook $($RunbookName) (Failed by StatusCode: $($Invoke.StatusCode)) Content: $($Invoke.Content)"
        }
    } 
    end {
        return "Uploaded $RunbookName"
    }
}