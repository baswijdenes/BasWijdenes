#region functions
<#
.SYNOPSIS

.DESCRIPTION
Long description

.PARAMETER ItemPath
Parameter description

.PARAMETER Item
Parameter description

.PARAMETER Type
Parameter description

.PARAMETER TenantName
Parameter description

.PARAMETER Site
Parameter description

.PARAMETER ChildFolders
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Upload-MgaSharePointFiles {
    <#
.SYNOPSIS

.DESCRIPTION
Long description

.PARAMETER ItemPath
Parameter description

.PARAMETER Item
Parameter description

.PARAMETER Type
Parameter description

.PARAMETER TenantName
Parameter description

.PARAMETER Site
Parameter description

.PARAMETER ChildFolders
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true, ParameterSetName = 'ItemPath')]
        [string]
        $ItemPath,
        [Parameter(mandatory = $true, ParameterSetName = 'Item')]
        [System.IO.FileSystemInfo]
        $Item,
        [Parameter(mandatory = $false)]
        [ValidateSet('SharePoint', 'OneDrive')]
        $Type = 'SharePoint', 
        [Parameter(mandatory , HelpMessage = 'This is the URL to sharepoint, but the tenantname (before .onmicrosoft.com) is sufficient')]
        [string]
        $TenantName,
        [Parameter(mandatory, HelpMessage = 'Add the sitename')]
        [string]
        $Site,
        [Parameter(mandatory = $false, HelpMessage = 'Add childfolders as an array firstfolder,subfolder,subsubfolder')]
        [string[]]
        $ChildFolders
    )
    begin {
        if ($PSCmdlet.ParameterSetName -eq 'ItemPath') {
            if ((Test-path $ItemPath) -eq $false) {
                throw "File $ItemPath cannot be found"
            } 
            else {
                $File = Get-Item $ItemPath
                $LocalFileBytes = [System.IO.File]::ReadAllBytes($File)
            }
        }
        if ($TenantName -like '*.*') {
            $TenantName = $TenantName.split('.')[0]
            Write-Verbose "Upload-MgaSharePointFiles: begin: Converted TenantName to $TenantName"
        }
        else {
            Write-Verbose "Upload-MgaSharePointFiles: begin: TenantName is $TenantName"
        }
        Write-Verbose "Upload-MgaSharePointFiles: begin: Site is $Site" 
        $SPURL = 'https://graph.microsoft.com/v1.0/sites/{0}.sharepoint.com:/sites/{1}/' -f $TenantName, $Site
        Write-Verbose "Upload-MgaSharePointFiles: begin: SPURL is $SPURL" 
        $SPChildrenURL = "https://graph.microsoft.com/v1.0/sites/{0}/drive/items/root:"
        $i = 1
        if ($ChildFolders) {
            foreach ($ChildFolder in $ChildFolders) {
                if ($i -eq $($ChildFolders).count) {
                    $SPChildrenURL = "$($SPChildrenURL)/$($ChildFolder)/{1}:/createUploadSession"
                    Write-Verbose "Upload-MgaSharePointFiles: begin: ChildFolder URL is $SPChildrenURL"
                }
                else {
                    $SPChildrenURL = "$($SPChildrenURL)/$($ChildFolder)"
                }
                $i++
            }
        } 
        else {
            $SPChildrenURL = "$($SPChildrenURL)/{1}:/createUploadSession"

        }
        if ($Type -eq 'OneDrive') {
            $global:SPURL = $SPURL.Replace('/sites/', '/drives/')
            $global:SPChildrenURL = $SPChildrenURL.Replace('/sites/', '/drives/')
            $global:SPURL = $SPURL.Replace('/drive/', '')
            $global:SPChildrenURL = $SPChildrenURL.Replace('/drive/', '')
        } 
    }
    process {
        $SPsite = Get-Mga -URL $SPURL
        $SPItemsURL = $($SPChildrenURL) -f $SPSite.id, $File.Name
        Write-Verbose "Upload-MgaSharePointFiles: begin: Upload URL is $SPItemsURL"
        $uploadUrlResponse = Post-Mga -URL $SPItemsURL
        $contentRange = [string]::Format('bytes 0-{0}/{1}', $($LocalFileBytes.Length - 1), $LocalFileBytes.Length)
        $Header = @{}
        $Header.Add('Content-Length', $LocalFileBytes.Length)
        $Header.Add('Content-Range', $contentRange)
        $Header.Add('Content-Type', 'octet/stream')
        $UploadResult = Put-Mga -URL $uploadUrlResponse.uploadUrl -InputObject $LocalFileBytes -CustomHeader $Header
    }
    end {
        return $UploadResult
    }
}
#endregion
Upload-MgaSharePointFiles -ItemPath C:\temp\temp\100.txt -Site 'admin@m365x645154.onmicrosoft.com' -TenantName 'm365x645154' -Type OneDrive -Verbose