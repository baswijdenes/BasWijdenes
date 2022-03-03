function Add-ResourcePermissionsToManagedIdentity {
    <#
    .SYNOPSIS
    With Add-ResourcePermissionsToManagedIdentity you can add permissions to AzureAD resources like Microsoft Graph.

    .DESCRIPTION
    List of current resources accepting permissions for resources: 
    - Windows Azure Active Directory
    - Office 365 Exchange Online
    - Microsoft Graph
    - Office 365 SharePoint Online
    - Skype for Business Online
    - Microsoft Exchange Online Protection
    - Power BI Service
    - Microsoft Rights Management Services
    - MicrosoftAzureActiveAuthn
    
    .PARAMETER AppServicePrincipalObjectId
    This is the ObjectId for the Managed Identity. Which usually can be found where you enable the Managed Identity.
    
    .PARAMETER Permission
    Array of permissions is accepted. 
    Permissions generally look like: 
    - AuditLog.Read.All
    - Directory.ReadWrite.All
    - Directory.Read.All
    - Reports.Read.All

    .PARAMETER Resource
    The resource you want to add permissions for to your Managed Identity. 
    This parameter has a ValidateSet as it will look up the Resource by DisplayName.
    The Microsoft Graph API is the default value.

    .PARAMETER ShowPermissionsOnly
    This is a switch to show you the permissions that contain in the Resource
    
    .EXAMPLE
    Add-ResourcePermissionsToManagedIdentity -AppServicePrincipalObjectId 'e569e0ca-6c26-4297-a855-a3c5596f669f' -Permissions 'CrossTenantUserProfileSharing.ReadWrite.All','CrossTenantInformation.ReadBasic.All' -Resource 'Microsoft Graph'

    .NOTES
    Author: Bas Wijdenes

    .LINK
    https://baswijdenes.com/how-to-use-managed-identities-with-microsoft-graph-api
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'AddPermissions')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ShowPermissions')]
        [guid]
        $AppServicePrincipalObjectId,
        [Parameter(Mandatory = $true, ParameterSetName = 'AddPermissions')]
        # [ValidatePattern(".*\.*\.*")]
        [string[]]
        $Permission,
        [Parameter(Mandatory = $false, ParameterSetName = 'ShowPermissions')]
        [switch]
        $ShowPermissionsOnly,
        [Parameter(Mandatory = $false, ParameterSetName = 'AddPermissions')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ShowPermissions')]
        # [ValidateSet('All', 'Azure ESTS Service', 'Windows Azure Active Directory', 'Office 365 Exchange Online', 'Microsoft Graph', 'Office 365 SharePoint Online', 'Skype for Business Online', 'Microsoft Azure Workflow', 'Yammer', 'Microsoft Office 365 Portal', 'Common Data Service', 'Microsoft Exchange Online Protection', 'Microsoft.Azure.DataMarket', 'Power BI Service', 'Microsoft Intune', 'Microsoft Seller Dashboard', 'Microsoft App Access Panel', 'Microsoft.Azure.GraphExplorer', 'Microsoft Rights Management Services', 'Azure Classic Portal', 'Microsoft.Azure.SyncFabric', 'MicrosoftAzureActiveAuthn', 'Microsoft Power BI Information Service', 'Azure SQL Database', 'MDATPNetworkScanAgent', 'Microsoft Cloud App Security', 'ProjectWorkManagement', 'Microsoft Teams UIS', 'Skype Presence Service', 'IC3 Long Running Operations Service', 'Cortana at Work Bing Services', 'Microsoft Stream Service', 'Cortana at Work Service', 'Office 365 Information Protection', 'Microsoft Teams ADL', 'Microsoft Information Protection API', 'Windows Store for Business', 'PushChannel', 'Skype and Teams Tenant Admin API', 'Configuration Manager Microservice', 'Graph Connector Service', 'Azure AD Identity Governance Insights', 'Windows Virtual Desktop', 'CABProvisioning', 'StreamToSubstrateRepl', 'Office Scripts Service', 'Skype Core Calling Service', 'Networking-MNC', 'Microsoft Teams Retail Service', 'Directory and Policy Cache', 'Cortana Runtime Service', 'Microsoft Information Protection Sync Service', 'PowerAI', 'DeploymentScheduler', 'Power Query Online GCC-L5', 'Microsoft Teams Targeting Application', 'Microsoft Threat Protection', 'Sway', 'Power Query Online GCC-L2', 'O365 Demeter', 'Dynamics 365 Business Central', 'Bing', 'Microsoft Teams Graph Service', 'M365 License Manager', 'Microsoft Teams Chat Aggregator', 'Signup', 'Microsoft Teams Templates Service', 'Microsoft.MileIQ.RESTService', 'Microsoft Invoicing', 'Compute Recommendation Service', 'M365DataAtRestEncryption', 'Microsoft Intune API', 'Office 365 Management APIs', 'Microsoft To-Do', 'PowerApps-Advisor', 'Microsoft Forms', 'Log Analytics API', 'Microsoft Teams Services', 'Office 365 Mover', 'MileIQ Admin Center', 'Power Query Online GCC-L4', 'Power Query Online', 'Media Recording for Dynamics 365 Sales', 'Application Insights API', 'Office 365 Enterprise Insights', 'WindowsDefenderATP')]
        [string]
        $Resource
    )
    begin {

        if (($Resource.length -eq 0) -and ($ShowPermissionsOnly -eq $true)) {
            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: begin: ShowPermissionsOnly: $ShowPermissionsOnly | Resource -equals null | changing Resource to All"
            $Resource = 'All'
        }
        elseif ($ShowPermissionsOnly -eq $true) {
            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: begin: ShowPermissionsOnly: $ShowPermissionsOnly | Resource: $Resource"
        }
        else {
            if (($Resource.length -eq 0) -and ($null -ne $AppServicePrincipalObjectId)) {
                $Resource = 'Microsoft Graph'
            }
            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: begin: AppServicePrincipalObjectId: $AppServicePrincipalObjectId | Permissions: $([string]$Permission) | Resource: $Resource"
        }
    } 
    process {
        try {
            if ($ShowPermissionsOnly -eq $false) {
                Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for AppServicePrincipal $appServicePrincipalObjectId by ObjectId"
                $AppServicePrincipal = Get-AzureADServicePrincipal -Filter "ObjectId eq '$AppServicePrincipalObjectId'"  
                if ($null -eq $AppServicePrincipal) {
                    Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Cannot find AppServicePrincipal $appServicePrincipalObjectId by ObjectId"
                    Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for AppServicePrincipal $appServicePrincipalObjectId by AppId"
                    $AppServicePrincipal = Get-AzureADServicePrincipal -Filter "AppId eq '$AppServicePrincipalObjectId'"  
                }
                if ($null -eq $AppServicePrincipal) {
                    throw "Cannot find Service Principal for $PrincipalObjectId"
                }
                Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for Resource: $Resource"
                $ResourceServicePrincipalNotAll = Get-AzureADServicePrincipal -Filter "DisplayName eq '$Resource'" 
                if ($null -eq $ResourceServicePrincipalNotAll) {
                    throw "Cannot find Service Principal for $Resource"
                }
                Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Checking if the appropriate permissions exist for the resource"
                $ServicePrincipalPermissions = $ResourceServicePrincipalNotAll.AppRoles | Where-Object { $_.Value -in $Permission }
                if ($null -eq $ServicePrincipalPermissions) {
                    throw "Permission: $([string]$Permission) do not exist for $($ResourceServicePrincipalNotAll.DisplayName)"
                }
                else {
                    $Result = foreach ($Perm in $ServicePrincipalPermissions) {
                        Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Adding permission: $($Perm.DisplayName) of resource: $($ResourceServicePrincipalNotAll.DisplayName) to AppServicePrincipal: $($AppServicePrincipal.DisplayName)"
                        New-AzureAdServiceAppRoleAssignment -ObjectId $ResourceServicePrincipalNotAll.ObjectId -PrincipalId $AppServicePrincipal.ObjectId -ResourceId $ResourceServicePrincipalNotAll.ObjectId -Id $Perm.Id
                    }
                }
            }
            else {
                if ($Resource -ne 'All') {
                    Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for Resource: $Resource"
                    $ResourceServicePrincipalNotAll = Get-AzureADServicePrincipal -Filter "DisplayName eq '$Resource'" 
                    if ($null -eq $ResourceServicePrincipalNotAll) {
                        throw "Cannot find Service Principal for $Resource"
                    }
                }
                else {
                    Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for all Resources"
                    $AllAzureADServicePrincipal = Get-AzureADServicePrincipal -All $true
                    $AllAzureADServicePrincipalHashTable = [System.Collections.Generic.List[System.Object]]::new()
                    $AllAzureADServicePrincipal = $AllAzureADServicePrincipal | Where-Object { $_.AppRoles.count -ge 2 }
                    foreach ($AzureADServicePrincipal in $AllAzureADServicePrincipal) {
                        Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: looping through $($AzureADServicePrincipal.DisplayName)"
                        foreach ($AzureADServicePrincipalPerm in $AzureADServicePrincipal.AppRoles) {
                            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: AppDisplayName: $($AzureADServicePrincipal.DisplayName) | PermDisplayName: $($AzureADServicePrincipalPerm.DisplayName)"
                            $Object = $null
                            $Object = [PSCustomObject]@{
                                AppDisplayName        = $AzureADServicePrincipal.DisplayName
                                AppId                 = $AzureADServicePrincipal.AppId
                                PermissionDisplayName = $AzureADServicePrincipalPerm.DisplayName
                                PermissionDescription = $AzureADServicePrincipalPerm.Description
                                PermissionValue       = $AzureADServicePrincipalPerm.Value
                                PermissionType        = $($AzureADServicePrincipalPerm.AllowedMemberTypes)
                                PermissionId          = $AzureADServicePrincipalPerm.Id
                                PermissionIsEnabled   = $AzureADServicePrincipalPerm.IsEnabled
                            }
                            $AllAzureADServicePrincipalHashTable.Add($Object)
                        }
                    }
                }

            }
        }
        catch {
            throw $_
        }
    }
    end {
        if (($ShowPermissionsOnly -eq $true) -and ($Resource -eq 'All')) {
            $Result = $AllAzureADServicePrincipalHashTable
        }
        elseif (($null -eq $ResourceServicePrincipalNotAll.AppRoles) -and ($ShowPermissionsOnly -eq $true)) {
            $Result = "There are no permissions found for $($ResourceServicePrincipalNotAll.DisplayName)" 
        }
        elseif (($null -ne $ResourceServicePrincipalNotAll.AppRoles) -and ($ShowPermissionsOnly -eq $true)) {
            $Result = $ResourceServicePrincipalNotAll.AppRoles
        } 
        return $Result
    }
}