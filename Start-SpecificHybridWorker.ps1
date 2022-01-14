function Start-SpecificHybridWorker {
    <#
    .SYNOPSIS
    With this function you can start a runbook on a specific Hybrid Worker.
    Disclaimer: this is a work around that is not always useful. 
                Please read the blogpost to understand this better.

    keep in mind that it can go in to a loop when the Hybrid Worker does not exist anymore!

    .DESCRIPTION
    When the runbook is not running on the Hybrid Worker you prefer. 
    It will re-start the runbook and goes a sleep for the value described in parameter StartSleep. 

    .PARAMETER Runbook
    The Runbook's name.

    .PARAMETER HybridWorkerGroup
    This is the Group containing all the Hybrid Workers.
    This is nessecary to start the Runbook again on the correct Hybrid Worker.

    .PARAMETER HybridWorker
    The Hybrid Worker computername (Same as $env:COMPUTERNAME)

    .PARAMETER StartSleep
    This is an integer ObjectType.
    The default value is 30 Seconds.

    .EXAMPLE
    Start-SpecificHybridWorker -Runbook 'Runbook1' -HybridWorkerGroup 'HWG01'

    Start-SpecificHybridWorker -Runbook 'Runbook1' -HybridWorkerGroup 'HWG01'

    Start-SpecificHybridWorker -Runbook 'Runbook1' -HybridWorkerGroup 'HWG01' -HybridWorker 'ComputerName'

    Start-SpecificHybridWorker -Runbook 'Runbook1' -HybridWorkerGroup 'HWG01' -StartSleep 60

    Start-SpecificHybridWorker -Runbook 'Runbook1' -HybridWorkerGroup 'HWG01' -HybridWorker 'ComputerName' -StartSleep 90

    .NOTES
    Author: Bas Wijdenes

    .LINK
    https://bwit.blog/how-to-start-a-runbook-on-specific-hybrid-worker-azure-automation/
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        $Runbook,
        [parameter(Mandatory = $true)]
        $HybridWorkerGroup,
        [parameter(Mandatory = $false)]
        $HybridWorker = 'Not Specified',
        [parameter(Mandatory = $false)]
        [int]
        $StartSleep = 30
    )
    begin {
        if ($env:COMPUTERNAME -eq 'CLIENT') {
            # we have to check if the server does not
            Write-Warning: "Computername: $env:COMPUTERNAME | This means that the script is running on Azure and we cannot check the HybridWorker servername"
        }
        else {
            Write-Verbose "Start-SpecificHybridWorker: begin: HybridWorker: $($PSBoundParameters.HybridWorker) | Computername: $env:COMPUTERNAME | Runbook: $($PSBoundParameters.Runbook)"
            if ($null -eq $($PSBoundParameters.HybridWorker)) {
                Write-Verbose "Start-SpecificHybridWorker: begin: HybridWorker name equals not specified: $($PSBoundParameters.HybridWorker) | Grabbing first HybridWorker from Azure Automation"
                Write-Verbose "Start-SpecificHybridWorker: begin: DotSourcing New-ManagedIdentityAccessToken.ps1 for an AccessToken"
                # We need an AccessToken to authenticate to the Azure API to retrieve the Hybrid Workers because there is no internal Azure Automation cmdlet
                . .\New-ManagedIdentityAccessToken.ps1 
                $AccessToken = New-ManagedIDentityAccessToken -Resource 'https://management.azure.com'
                $SubscriptionId = (Get-AutomationVariable -Name 'AzureSubscription')
                $ResourceGroupName = (Get-AutomationVariable -Name 'ResourceGroupName')
                $AutomationAccountName = (Get-AutomationVariable -Name 'AzureAutomationAccount')
                Write-Verbose "Start-SpecificHybridWorker: begin: SubscriptionId: $SubscriptionId | ResourceGroupName: $ResourceGroupName | AutomationAccountName: $AutomationAccountName | HybridWorkerGroup: $HybridWorkerGroup"
                $Uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Automation/automationAccounts/{2}/hybridRunbookWorkerGroups/{3}?api-version=2015-10-31' -f $SubscriptionId, $ResourceGroupName, $AutomationAccountName, $HybridWorkerGroup
                $GetRunBookWorkerSplatting = @{
                    Uri     = $Uri
                    Method  = 'Get'
                    Headers = $AccessToken
                }
                Write-Verbose "Start-SpecificHybridWorker: begin: Getting HybridWorkers from Azure Automation via Azure REST API"
                # Using Select-Object -First 1 instead of [0] is because in the acc we have a single HybridWorker and it will return as a string. 
                # By using [0] it will then retrieve the first letter only.
                $PSBoundParameters.HybridWorker = ((Invoke-RestMethod @GetRunBookWorkerSplatting).hybridRunbookWorkers.Name) | Select-Object -first 1
            }
            if ($PSBoundParameters.HybridWorker -like "*.*") {
                Write-Verbose "Start-SpecificHybridWorker: begin: HybridWorker: $($PSBoundParameters.HybridWorker) has a . in the name | Splitting name & selecting first object"
                # We cannot compare by FQDN because $env:COMPUTERNAME does not contain the FQDN.
                # We will not use $env:USERDNSDOMAIN because we log in with the local system account.
                $PSBoundParameters.HybridWorker = ($($PSBoundParameters.HybridWorker).Split('.'))[0]
            }
        }
    }  
    process {
        if ($env:COMPUTERNAME -eq 'CLIENT') {
        }
        elseif ($env:COMPUTERNAME -ne $PSBoundParameters.HybridWorker) {
            Write-Verbose "Start-SpecificHybridWorker: process: Computername & HybridWorkerName do not equal | Re-starting Runbook in the hopes it will run on correct HybridWorker"
            # By restarting the runbook I hope that the script will now start on the correct HybridWorker
            $StartAutomationRunbookSplatting = @{
                JobId = (New-Guid)
                Name  = ($PSBoundParameters.Runbook)
                RunOn = ($PSBoundParameters.HybridWorkerGroup)
            }
            $null = Start-AutomationRunbook @StartAutomationRunbookSplatting
            # Exiting the Runbook so it will not continue on the current HybridWorker
            Start-Sleep -Seconds $StartSleep
            Exit
        }
        else {
            Write-Verbose "Start-SpecificHybridWorker: process: Computername & HybridWorkerName equals | continueing Runbook"
        }
    }   
    end {
    }
}