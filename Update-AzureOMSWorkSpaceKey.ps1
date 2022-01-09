<#
.DESCRIPTION
Long description

.PARAMETER Servers
Script expect server names it can connect to over the network (Servername.Domain.local)
Invoke-command uses the WinRM ports. 
TCP/5985 = HTTP
TCP/5986 = HTTPS

Parameter accepts an array.

.PARAMETER WorkSpaceID
This is the workspaceDI

.PARAMETER WorkSpaceKey
This is the WorkSpaceKey.

.EXAMPLE
$servers = Get-ADComputer -Filter {operatingsystem -like "*server*"}
Update-OMSWorkSpaceKey -Servers $Servers -WorkSpaceID 'XXXXXXXXXXXXXXXXXX' -WorkSpaceKey 'XXXXXXXXXXXXXXXXXX'

.LINK
https://bwit.blog/bulk-update-oms-workspace-key-powershell/
#>
function Update-OMSWorkSpaceKey
{
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string[]]
        $Server,
        [Parameter (Mandatory = $true)]
        $WorkSpaceID,
        [Parameter (Mandatory = $true)]
        $WorkSpaceKey
    )   
    begin
    {
        Write-Verbose 'Update-OMSWorkSpaceKey: begin: Creating Scriptblock for remote servers.'
        $Scriptblock = {
            $WorkspaceID = $WorkSpaceID
            $WorkspaceKey = $WorkSpaceKey
            $AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
            $AgentCfg.GetCloudWorkspaces()
            $AgentCfg.AddCloudWorkspace($WorkspaceID, $WorkspaceKey)
            Restart-Service HealthService
        }
    }
    process
    {
        Write-Verbose 'Update-OMSWorkSpaceKey: process: Starting script to invoke scriptblock to serverlist.'
        #foreach ($Srv in $Server)
        #{
            Write-Verbose "Update-OMSWorkSpaceKey: process: Invoke-Command on srv: $Server"
            try
            {
                Invoke-Command -ComputerName $Server -ScriptBlock $scriptblock
            }
            catch
            {
                continue
            }
        #}
    }
    end
    {
        return "Script finished updating keys."
    }
}
