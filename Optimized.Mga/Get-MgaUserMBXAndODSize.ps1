
$MBXURL = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D7')"
$SPURL = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountDetail(period='D7')"
$MBXSize = New-MSGraphGetRequest -URL $MBXurl
$SPSize = New-MSGraphGetRequest -URL $SPURL

$SPHash = @{}
foreach ($user in $SPSize)
{
    $SPHash.Add($user.'Owner Principal Name', $user)
}
$FusedDataSources = [System.Collections.Generic.List[System.Object]]::new()
foreach ($MBX in $MBXSize)
{
    $CurrentSP = $null
    $CurrentSP = $SPHash[$MBX.'User Principal Name']
    if ($null -ne $CurrentSP)
    {
        $Object = [PSCustomObject]@{
            UserPrincipalName = $MBX.'User Principal Name'
            MailboxSizeInGb   = [math]::Round(((($MBX.'Storage Used (Byte)') / 1024 / 1024 / 1024)), 2)
            OneDriveSizeInGb  = [math]::Round(((($CurrentSP.'Storage Used (Byte)') / 1024 / 1024 / 1024)), 2)
        }
        $FusedDataSources.Add($Object)
    }
    else
    {
        $Object = [PSCustomObject]@{
            UserPrincipalName = $MBX.'User Principal Name'
            MailboxSizeInGb   = [math]::Round(((($MBX.'Storage Used (Byte)') / 1024 / 1024 / 1024)), 2)
            OneDriveSizeInGb  = 'No OneDrive found'
        }
        $FusedDataSources.Add($Object)
    }
}

$FusedDataSources | Export-CSV "C:\Users\Bas Wijdenes\OneDrive for Business\Abrona\_Logging\Sizes_16-12-2020.csv" -NoTypeInformation