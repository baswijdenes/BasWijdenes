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
    
    .PARAMETER Permissions
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
    
    .EXAMPLE
    Add-ResourcePermissionsToManagedIdentity -AppServicePrincipalObjectId 'e569e0ca-6c26-4297-a855-a3c5596f669f' -Permissions 'CrossTenantUserProfileSharing.ReadWrite.All','CrossTenantInformation.ReadBasic.All' -Resource 'Microsoft Graph'

    .NOTES
    Author: Bas Wijdenes

    .LINK
    https://baswijdenes.com/how-to-use-managed-identities-with-microsoft-graph-api
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [guid]
        $AppServicePrincipalObjectId,
        [Parameter(Mandatory = $true)]
        [ValidatePattern(".*\..*\..*")]
        [string[]]
        $Permissions,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Azure ESTS Service', 'Windows Azure Active Directory', 'Office 365 Exchange Online', 'Microsoft Graph', 'Office 365 SharePoint Online', 'Skype for Business Online', 'Microsoft Azure Workflow', 'Yammer', 'Microsoft Office 365 Portal', 'Common Data Service', 'Microsoft Exchange Online Protection', 'Microsoft.Azure.DataMarket', 'Power BI Service', 'Microsoft Intune', 'Microsoft Seller Dashboard', 'Microsoft App Access Panel', 'Microsoft.Azure.GraphExplorer', 'Microsoft Rights Management Services', 'Azure Classic Portal', 'Microsoft.Azure.SyncFabric', 'MicrosoftAzureActiveAuthn', 'Microsoft Power BI Information Service')]
        [string]
        $Resource = 'Microsoft Graph'
    )
    begin {
        Write-Verbose "Add-ResourcePermissionsToManagedIdentity: begin: AppServicePrincipalObjectId: $ApServicePrincipalObjectId | Permissions: $([string]$Permissions) | Resource: $Resource"
    } 
    process {
        try {
            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Searching for Resource: $Resource"
            $ResourceServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$Resource'" 
            if ($null -eq $ResourceServicePrincipal ) {
                throw "Cannot find Service Principal for $Resource"
            }
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
            Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Checking if the appropriate permissions exist for the resource"
            $ServicePrincipalPermissions = $ResourceServicePrincipal.AppRoles | Where-Object { $_.Value -in $Permissions }
            if ($null -eq $ServicePrincipalPermissions) {
                throw "Permissions: $([string]$Permissions) do not exist for $($ResourceServicePrincipal.DisplayName)"
            }
            else {
                $Result = foreach ($Permission in $ServicePrincipalPermissions) {
                    Write-Verbose "Add-ResourcePermissionsToManagedIdentity: process: Adding permission: $($Permission.DisplayName) of resource: $($ResourceServicePrincipal.DisplayName) to AppServicePrincipal: $($AppServicePrincipal.DisplayName)"
                    New-AzureAdServiceAppRoleAssignment -ObjectId $ResourceServicePrincipal.ObjectId -PrincipalId $AppServicePrincipal.ObjectId -ResourceId $ResourceServicePrincipal.ObjectId -Id $Permission.Id
                }
            }
        }
        catch {
            throw $_
        }
    }
    end {
        return $Result
    }
}