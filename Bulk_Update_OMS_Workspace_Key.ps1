$scriptblock =  
    {  
        $WorkspaceID = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        $WorkspaceKey = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        $AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
        $AgentCfg.GetCloudWorkspaces()
        $AgentCfg.AddCloudWorkspace($WorkspaceID,$WorkspaceKey)
        restart-service HealthService
    }

foreach ($server in $servers)
{
    write-output $server.dnshostname
    invoke-command -ComputerName $server.dnshostname -ScriptBlock $scriptblock
}