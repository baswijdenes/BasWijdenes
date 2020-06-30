<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Scope
Parameter description

.PARAMETER Excluded
Parameter description

.EXAMPLE

Install-Modules -excluded MsolService,SFB,CRM -Scope CurrentUser

Install-Modules -excluded MsolService,SFB,CRM -Scope AllUsers

Install-Modules -excluded MsolService,SFB,CRM -Scope CurrentUser -Confirm $false

.NOTES
General notes
#>

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

Function Install-MSCloudModules
{
    param(
        [parameter(Mandatory = $True)]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]
        $Scope,
        [parameter(Mandatory = $False)]
        [string[]]
        $Excluded,
        [parameter(Mandatory = $False)]
        [string]
        $confirm
    )

    if ($Scope -eq 'AllUsers')
    {
        If ('False' -eq (Test-Administrator))
        {
            Write-Host -Object "To install the modules for all users you need to run PowerShell in an elevated prompt." -ForegroundColor Red 
            Write-Host -Object  "Exiting script..."  -ForegroundColor Red 
            Exit
        }
    }

    $array = @{
        MSO = 'MSO'
        AAD = 'AAD'
        MST = 'MST'
        SFB = 'SFB'
        SPO = 'SPO'
        PNP = 'PNP'
        CRM = 'CRM'
        AZ  = 'AZ'
    }

    foreach ($exclude in $excluded)
    {
        switch ($exclude)
        {
            'MSO'
            {
                $Array.Remove('MSO')
            }
            'AAD'
            {
                $Array.Remove('AAD')
            }
            'MST'
            {
                $Array.Remove('MST')
            }
            'SFB'
            {
                $Array.Remove('SFB')
            }
            'SPO'
            {
                $Array.Remove('SPO')
            }
            'PNP'
            {
                $Array.Remove('PNP')
            }
            'CRM'
            {
                $Array.Remove('CRM')
            }
            'AZ'
            {
                $Array.Remove('AZ')
            }
        }
    }


    $array.Values
    $confirmation = Read-Host "We will install the above modules. Is that correct? Confirm with Yes or No"
    if (($confirmation -eq 'Yes') -or ($confirmation -eq 'Y') -or ($confirm -eq $false))
    {
        foreach ($value in $array.values)
        {
            switch ($value)
            {
                'MSolService'
                { 
                    Write-Host "Installing MsolService..."
                    Install-Module -scope $Scope -Name MSOnline -AllowClobber
                }
                'AZ'
                { 
                    Write-Host "Installing AZ..."
                    Install-Module -scope $Scope -Name Az -Force -AllowClobber
                }
                'AzureAD'
                {
                    Write-Host "Installing AzureAD..."
                    Install-Module -scope $Scope -Name AzureAD -Force -AllowClobber
                }
                'MSTeams'
                {
                    Write-Host "Installing MSTeams..."
                    Install-Module -scope $scope -name MicrosoftTeams -Force -AllowClobber
                }
                'SFB'
                {
                    Write-Host "SFB module is an .EXE. Installation will start in the background."
                    invoke-webrequest -uri 'https://download.microsoft.com/download/2/0/5/2050B39B-4DA5-48E0-B768-583533B42C3B/SkypeOnlinePowerShell.exe' -outfile 'Skypemodule.exe'
                    Start-Process 'skypemodule.exe' -ArgumentList "/quiet" -Wait
                }
                'SPO'
                {
                    Write-Host "SPO module is an .MSI.  Installation will start in the background"
                    invoke-webrequest -uri 'https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/SharePointOnlineManagementShell_19418-12000_x64_en-us.msi' -outfile 'SPOmodule.MSI'
                    Start-Process 'SPOmodule.MSI' -ArgumentList "/quiet" -Wait
                }
                'PNP'
                {
                    Write-Host "Installing PNP..."
                    Install-Module -scope $scope -name 'SharePointPnPPowerShellOnline' -AllowClobber
                }
                'CRM'
                {
                    Write-Host "Installing CRM..."
                    Install-Module -scope $scope -Name 'Microsoft.Xrm.Tooling.CrmConnector.PowerShell' -AllowClobber
                }
            }
        }            
    }
    else
    {
        Write-Host "Confirmation is $confirmation.This needs to be (Y)es to continue. Please review your excluded modules, and try again." -ForegroundColor Red
        Write-Host "Exiting script..." -ForegroundColor Red
    }
}