param(
    [parameter(Mandatory = $false)][string[]]$Domains,
    [parameter(Mandatory = $false)][string[]]$Emails,
    [parameter(Mandatory = $false)][string[]]$IPS,
    [parameter(Mandatory = $true)][string[]]$ListedAs,
    [switch]$Inboxrules
)
<# 
  .SYNOPSIS  
   Scan black or white lists in O365 for Domains,Emails, or IPAddresses
  .DESCRIPTION
   See if a Domain, Email, or IPAddress is black or white listed in Exchange Online.
   Multiple values are allowed, and the IPAddresses will scan through subnets.
   Get-IPRange is from Technet.
  .EXAMPLE 
   .\Isitlisted.ps1 -domains contoso.com -ListedAs blacklisted
   .\Isitlisted.ps1 -domains "contoso.com","Baswijdenes.com" -ListedAs Whitelisted
  .EXAMPLE 
   .\Isitlisted.ps1 -Emails Mike.Tyson@contoso.com -ListedAs Whitelisted 
   .\Isitlisted.ps1 -Emails "Mike.Tyson@contoso.com","Info@Baswijdenes.com" -ListedAs blacklisted
  .EXAMPLE 
   .\Isitlisted.ps1 -IPS "192.168.100.1" -ListedAs blacklisted
   .\Isitlisted.ps1 -IPS "192.168.100.1","10.0.0.2" -ListedAs Whitelisted
  .EXAMPLE 
   .\Isitlisted.ps1 -domains "contoso.com","Baswijdenes.com" -Emails "Mike.Tyson@contoso.com","Info@Baswijdenes.com"  -IPS "192.168.100.1","10.0.0.2" -ListedAs blacklisted
#> 


function Get-IPrange
{
    param 
    ( 
        [string]$start, 
        [string]$end, 
        [string]$ip, 
        [string]$mask, 
        [int]$cidr 
    ) 

    function IP-toINT64 ()
    { 
        param ($ip) 

        $octets = $ip.split(".") 
        return [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3]) 
    } 

    function INT64-toIP()
    { 
        param ([int64]$int) 

        return (([math]::truncate($int / 16777216)).tostring() + "." + ([math]::truncate(($int % 16777216) / 65536)).tostring() + "." + ([math]::truncate(($int % 65536) / 256)).tostring() + "." + ([math]::truncate($int % 256)).tostring() )
    } 

    if ($ip)
    {
        $ipaddr = [Net.IPAddress]::Parse($ip)
    } 
    if ($cidr)
    {
        $maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1" * $cidr + "0" * (32 - $cidr)), 2)))) 
    } 
    if ($mask)
    {
        $maskaddr = [Net.IPAddress]::Parse($mask)
    } 
    if ($ip)
    {
        $networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)
    } 
    if ($ip)
    {
        $broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))
    } 

    if ($ip)
    { 
        $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
        $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
    }
    else
    { 
        $startaddr = IP-toINT64 -ip $start 
        $endaddr = IP-toINT64 -ip $end 
    } 


    for ($i = $startaddr; $i -le $endaddr; $i++) 
    { 
        INT64-toIP -int $i 
    }

}

Function Search-Inboxrules
{
    If ($Emails)
    { 
        Foreach ($email in $emails)
        {
            ### INBOXRULES EMAILS
            Write-Host "Going through the user InboxRules for $Email..." 
            foreach ($inboxrule in (Get-inboxrule | where-object {($_.deletemessage -eq "$true") -or ($_.movetofoler -ne "$null")}))
            { 
                $RuleName = $inboxRule.name
                $ruleowner = $InboxRule.MailboxownerId
                if ($Inboxrule.From)
                {     
                    foreach ($InboxRule in $inboxrule.From)
                    {
                        if ($Inboxrule -like "*$email*")
                        {
                            write-host "$Ruleowner has rule $Rulename that contains $email" -BackgroundColor Magenta -ForegroundColor white
                        }
                    }
                }
            }
        }
    }
    if ($domains)
    {
        foreach ($domain in $domains)
        {
            ### INBOXRULES DOMAINS
            Write-Host "Going through the user InboxRules for $Domain..." 
            foreach ($inboxrule in (Get-inboxrule | where-object {($_.deletemessage -eq "$true") -or ($_.movetofoler -ne "$null")}))
            {
                $RuleName = $inboxRule.name
                $ruleowner = $InboxRule.MailboxownerId
                if ($Inboxrule.FromAddressContainsWords)
                {     
                    foreach ($Rule in $inboxrule.FromAddressContainsWords)
                    {
                        if ($rule -like "*$domain*")
                        {
                            write-host "$Ruleowner has rule $Rulename that contains $domain" -BackgroundColor Magenta -ForegroundColor white
                        }
                    }
                }
            }
        }
    }
}


If ($listedAs -eq "whitelisted")
{
    If ($Domains -or $emails)
    {
        Function Scan_ExO_For_Domain_Email
        {
            param(
                [parameter(Mandatory = $false)][string[]]$Domains,
                [parameter(Mandatory = $false)][string[]]$Emails
            )
            ### START EMAILS
            if ($Emails)
            {
                if (!($domains))
                {
                    $Domains = @()
                }
                foreach ($email in $emails)
                {
                    $domains += $email.Split('@')[-1]
                    ### TRANSPORTRULES EMAIL
                    Write-Host "Scanning ExO for $Email" -BackgroundColor DarkBlue  -ForegroundColor white
                    Write-Host "Going through the TransportRules for $Email..." 
                    foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.SetSCL -eq "-1"}))
                    { 
                        $Rule = $TransportRule.Identity
                        if ($Transportrule.FromAddressMatchesPatterns)
                        {       
                            foreach ($AOPEmail in $transportrule.FromAddressMatchesPatterns)
                            {
                                if ($AOPEmail -like "*$Email*")
                                {
                                    write-host "$Rule contains $Email" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                    ### ANTI SPAM EMAIL
                    Write-Host "Going through the Anti-Spam policies for $Email..."
                    foreach ($AntispamPolicy in (Get-HostedContentFilterPolicy))
                    {
                        if ($antispampolicy.AllowedSenders)
                        {
                            $AntiSpam = $antispampolicy.identity
                            foreach ($AntiSpamEmail in $AntispamPolicy.AllowedSenders.Sender.Address)
                            {
                                if ($AntiSpamEmail -like "*$Email*")
                                {
                                    write-host "$AntiSpam contains $Email" -BackgroundColor Red  -ForegroundColor white      
                                }
                            }
                        }
                    }
                    ### ATP ANTI PHISHING EMAIL
                    Write-Host "Going through the Anti-phishing policies for $Email..."
                    foreach ($AntiphishingPolicy in (Get-AntiPhishPolicy))
                    {
                        if ($AntiphishingPolicy.ExcludedSenders)
                        {
                            $AntiPhishing = $AntiphishingPolicy.identity
                            foreach ($AntiphishingEmail in $AntiphishingPolicy.ExcludedSenders)
                            {
                                if ($AntiphishingEmail -like "*$Email*")
                                {
                                    write-host "$AntiPhishing contains $Email" -BackgroundColor Red  -ForegroundColor white     
                                }
                            }
                        }
                    }
                } 
            }
            ### END EMAILS
            ### START DOMAINS
            foreach ($domain in $domains)
            {
                ### TRANSPORTRULES DOMAIN
                Write-Host "Scanning ExO for $Domain" -BackgroundColor DarkBlue  -ForegroundColor white
                Write-Host "Going through the TransportRules for $domain..." 
                foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.SetSCL -eq "-1"}))
                { 
                    $Rule = $TransportRule.Identity
                    if ($Transportrule.SenderDomainIs)
                    {       
                        foreach ($AOPDomain in $transportrule.senderdomainis)
                        {
                            if ($AOPDomain -like "*$domain*")
                            {
                                write-host "$Rule contains $domain" -BackgroundColor Red  -ForegroundColor white
                            }
                        }
                    }
                }

                ### ANTI SPAM DOMAIN
                Write-Host "Going through the Anti-Spam policies for $domain..."
                foreach ($AntispamPolicy in (Get-HostedContentFilterPolicy))
                {
                    if ($antispampolicy.AllowedSenderDomains)
                    {
                        $AntiSpam = $antispampolicy.identity
                        foreach ($AntiSpamDomain in $AntispamPolicy.AllowedSenderDomains)
                        {
                            if ($AntiSpamDomain.domain -like "*$domain*")
                            {
                                write-host "$AntiSpam contains $domain" -BackgroundColor Red   -ForegroundColor white   
                            }
                        }
                    }
                }
                ### ATP ANTI PHISHING DOMAIN
                Write-Host "Going through the Anti-phishing policies for $domain..."
                foreach ($AntiphishingPolicy in (Get-AntiPhishPolicy))
                {
                    if ($AntiphishingPolicy.ExcludedDomains)
                    {
                        $AntiPhishing = $AntiphishingPolicy.identity
                        foreach ($AntiphishingDomain in $AntiphishingPolicy.ExcludedDomains)
                        {
                            if ($AntiphishingDomain -like "*$domain*")
                            {
                                write-host "$AntiPhishing contains $domain" -BackgroundColor Red  -ForegroundColor white    
                            }
                        }
                    }
                }
                ### INBOUND CONNECTORS DOMAIN
                Write-Host "Going through the inboundConnectors policies for $domain..."
                foreach ($InboundConnector in (Get-InboundConnector))
                {
                    $Connector = $InboundConnector.identity
                    if ($InboundConnector.SenderDomains)
                    {
                        foreach ($InboundConnectorDomain in $InboundConnector.SenderDomains)
                        {
                            if ($InboundConnectordomain.Substring(5) -like "*$domain*")
                            {
                                write-host "$Connector contains $domain" -BackgroundColor Red      -ForegroundColor white
                            }
                        }
                    }
                }
                
            }  ### END DOMAINS
        }
        If ($inboxrules)
        {
            Search-Inboxrules
        }
        Scan_ExO_For_Domain_Email -Domains $Domains -Emails $Emails
    }

    If ($IPS)
    {
        Function Scan_ExO_For_IPS
        {
            param(
                [parameter(Mandatory = $false)][string[]]$IPS
            )
            ### START IP
            Foreach ($IP in $IPS)
            {
                ### TRANSPORTRULES IP
                Write-Host "Scanning ExO for $IP" -BackgroundColor DarkBlue -ForegroundColor white
                Write-Host "Going through the TransportRules for $IP..." 
                foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.SetSCL -eq "-1"}))
                { 
                    $Rule = $TransportRule.Identity
                    if ($Transportrule.SenderIpRanges)
                    {
                        $EXTRAIPS = @()  
                        foreach ($AOPIP in $transportrule.SenderIpRanges) 
                        {
                            IF ($AOPIP -like "*/*")
                            { 
                                Write-Host "$RULE contains subnet $AOPIP. Scanning through subnet..."
                                $IPSubnet, $CIDR = $AOPIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$Rule contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($AOPIP -like "*$IP*")
                                {
                                    write-host "$Rule contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                } ### END TRANSPORTRULES IP
                ### START CONNECTION FILTER IP
                Write-Host "Going through the Connections Filter Policies for $IP..." 
                foreach ($HostedConnectionFilterPolicy in (Get-HostedConnectionFilterPolicy))
                { 
                    $Policy = $HostedConnectionFilterPolicy.Identity
                    if ($HostedConnectionFilterPolicy.IPAllowList)
                    {
                        $EXTRAIPS = @()  
                        foreach ($CHIP in $HostedConnectionFilterPolicy.IPAllowList) 
                        {
                            IF ($CHIP -like "*/*")
                            { 
                                Write-Host "$Policy contains subnet $CHIP. Scanning through subnet..."
                                $IPsubnet, $CIDR = $CHIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$Policy contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($CHIP -like "*$IP*")
                                {
                                    write-host "$Policy contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                }  ### END CONNECTION FILTER IP
                ### START INBOUND CONNECTOR IP
                Write-Host "Going through the Inbound Connectors for $IP..." 
                foreach ($InboundConnector in (Get-InboundConnector))
                { 
                    $InboundConnectorID = $InboundConnector.Identity
                    if ($InboundConnector.SenderIPAddresses)
                    {
                        $EXTRAIPS = @()  
                        foreach ($CHIP in $InboundConnector.SenderIPAddresses) 
                        {
                            IF ($CHIP -like "*/*")
                            { 
                                Write-Host "$InboundConnectorID contains subnet $CHIP. Scanning through subnet..."
                                $IPSubnet, $CIDR = $CHIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$InboundConnectorID contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($CHIP -like "*$IP*")
                                {
                                    write-host "$InboundConnectorID contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                } ### END INBOUND CONNECTOR IP
            }
            
            ### END IP
        }
        Scan_ExO_For_IPS -IPS $IPS
    }
}

If ($listedAs -eq "blacklisted")
{ 
    If ($Domains -or $emails)
    {
        Function Scan_ExO_For_Domain_Email
        {
            param(
                [parameter(Mandatory = $false)][string[]]$Domains,
                [parameter(Mandatory = $false)][string[]]$Emails
            )
            ### START EMAILS
            if ($Emails)
            {           
                if (!($domains))
                {              
                    $Domains = @()
                }  
                foreach ($email in $emails)
                {
                    $domains += $email.Split('@')[-1]
                    ### TRANSPORTRULES EMAIL
                    Write-Host "Scanning ExO for $Email" -BackgroundColor DarkBlue  -ForegroundColor white
                    Write-Host "Going through the TransportRules for $Email..." 
                    foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.DeleteMessage -eq "$True"}))
                    { 
                        $Rule = $TransportRule.Identity
                        if ($Transportrule.FromAddressMatchesPatterns)
                        {       
                            foreach ($AOPEmail in $transportrule.FromAddressMatchesPatterns)
                            {
                                if ($AOPEmail -like "*$Email*")
                                {
                                    write-host "$Rule contains $Email" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                        if ($Transportrule.FromAddressContainsWords)
                        {       
                            foreach ($AOPEmail in $transportrule.FromAddressContainsWords)
                            {
                                if ($AOPEmail -like "*$Email*")
                                {
                                    write-host "$Rule contains $Email" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                }
                ### ANTI SPAM EMAIL
                Write-Host "Going through the Anti-Spam policies for $Email..."
                foreach ($AntispamPolicy in (Get-HostedContentFilterPolicy))
                {
                    if ($antispampolicy.BlockedSenders)
                    {
                        $AntiSpam = $antispampolicy.identity
                        foreach ($AntiSpamEmail in $AntispamPolicy.BlockedSenders.Sender.Address)
                        {
                            if ($AntiSpamEmail -like "*$Email*")
                            {
                                write-host "$AntiSpam contains $Email" -BackgroundColor Red      -ForegroundColor white
                            }
                        }
                    }
                }
            } 
            ### END EMAILS
            ### START DOMAINS
            foreach ($domain in $domains)
            {  
                ### TRANSPORTRULES DOMAIN
                Write-Host "Scanning ExO for $Domain" -BackgroundColor DarkBlue  -ForegroundColor white
                Write-Host "Going through the TransportRules for $domain..." 
                foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.DeleteMessage -eq "$true"}))
                { 
                    $Rule = $TransportRule.Identity
                    if ($Transportrule.SenderDomainIs)
                    {       
                        foreach ($AOPDomain in $transportrule.senderdomainis)
                        {
                            if ($AOPDomain -like "*$domain*")
                            {
                                write-host "$Rule contains $domain" -BackgroundColor Red  -ForegroundColor white
                            }
                        }
                    }
                }
                ### ANTI SPAM DOMAIN
                Write-Host "Going through the Anti-Spam policies for $domain..."
                foreach ($AntispamPolicy in (Get-HostedContentFilterPolicy))
                {
                    if ($antispampolicy.BlockedSenderDomains)
                    {
                        $AntiSpam = $antispampolicy.identity
                        foreach ($AntiSpamDomain in $AntispamPolicy.BlockedSenderDomains)
                        {
                            if ($AntiSpamDomain.domain -like "*$domain*")
                            {
                                write-host "$AntiSpam contains $domain" -BackgroundColor Red    -ForegroundColor white 
                            }
                        }
                    }
                }
                ### INBOUND CONNECTORS DOMAIN
                Write-Host "Going through the inboundConnectors policies for $domain..."
                foreach ($InboundConnector in (Get-InboundConnector))
                {
                    $Connector = $InboundConnector.identity
                    if ($InboundConnector.SenderDomains)
                    {
                        foreach ($InboundConnectorDomain in $InboundConnector.SenderDomains)
                        {
                            if ($InboundConnectordomain.Substring(5) -like "*$domain*")
                            {
                                write-host "$Connector contains $domain" -BackgroundColor Red   -ForegroundColor white  
                            }
                        }
                    }
                }
            
            }  ### END DOMAINS 
        }
        If ($inboxrules)
        {
            Search-Inboxrules
        }
        Scan_ExO_For_Domain_Email -Domains $Domains -Emails $Emails
    }

    If ($IPS)
    {
        Function Scan_ExO_For_IPS
        {
            param(
                [parameter(Mandatory = $false)][string[]]$IPS
            )
            ### START IP
            Foreach ($IP in $IPS)
            {
                ### TRANSPORTRULES IP
                Write-Host "Scanning ExO for $IP" -BackgroundColor DarkBlue  -ForegroundColor white
                Write-Host "Going through the TransportRules for $IP..." 
                foreach ($TransportRule in (Get-TransportRule | Where-Object {$_.DeleteMessage -eq "$true"}))
                { 
                    $Rule = $TransportRule.Identity
                    if ($Transportrule.SenderIpRanges)
                    {
                        $EXTRAIPS = @()  
                        foreach ($AOPIP in $transportrule.SenderIpRanges) 
                        {
                            IF ($AOPIP -like "*/*")
                            { 
                                Write-Host "$RULE contains subnet $AOPIP. Scanning through subnet..."
                                $IPSubnet, $CIDR = $AOPIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$Rule contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($AOPIP -like "*$IP*")
                                {
                                    write-host "$Rule contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                } ### END TRANSPORTRULES IP
                ### START CONNECTION FILTER IP
                Write-Host "Going through the Connections Filter Policies for $IP..." 
                foreach ($HostedConnectionFilterPolicy in (Get-HostedConnectionFilterPolicy))
                { 
                    $Policy = $HostedConnectionFilterPolicy.Identity
                    if ($HostedConnectionFilterPolicy.IPBlockList)
                    {
                        $EXTRAIPS = @()  
                        foreach ($CHIP in $HostedConnectionFilterPolicy.IPBlockList) 
                        {
                            IF ($CHIP -like "*/*")
                            { 
                                Write-Host "$Policy contains subnet $CHIP. Scanning through subnet..."
                                $IPSubnet, $CIDR = $CHIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$Policy contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($CHIP -like "*$IP*")
                                {
                                    write-host "$Policy contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                }  ### END CONNECTION FILTER IP
                ### START INBOUND CONNECTOR IP
                Write-Host "Going through the Inbound Connectors for $IP..." 
                foreach ($InboundConnector in (Get-InboundConnector))
                { 
                    $InboundConnectorID = $InboundConnector.Identity
                    if ($InboundConnector.SenderIPAddresses)
                    {
                        $EXTRAIPS = @()  
                        foreach ($CHIP in $InboundConnector.SenderIPAddresses) 
                        {
                            IF ($CHIP -like "*/*")
                            { 
                                Write-Host "$InboundConnectorID contains subnet $CHIP. Scanning through subnet..."
                                $IPSubnet, $CIDR = $CHIP.split('/')
                                $EXTRAIPS += Get-IPrange -ip $IPSubnet -cidr $CIDR
                                Foreach ($EXTRAIP in $EXTRAIPS)
                                {
                                    if ($EXTRAIP -like "*$IP*")
                                    {
                                        write-host "$InboundConnectorID contains $IP" -BackgroundColor Red  -ForegroundColor white
                                    } 
                                }
                            }
                            else
                            {
                                if ($CHIP -like "*$IP*")
                                {
                                    write-host "$InboundConnectorID contains $IP" -BackgroundColor Red  -ForegroundColor white
                                }
                            }
                        }
                    }
                } ### END INBOUND CONNECTOR IP
            }
            
            ### END IP
        }
        Scan_ExO_For_IPS -IPS $IPS
    }
}
