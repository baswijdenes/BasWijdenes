
function Get-AzureBlobZipFiles {
    <#
.SYNOPSIS
Get Zip files from Azure Storage Blobg with Get-AzureBlobZipFiles

.PARAMETER Storage
The StorageAccountName 

.PARAMETER Container
The StorageContainer

.PARAMETER FileName
Add the filename including .zip

.PARAMETER Headers
The headers we created in the tutorial

.PARAMETER BaseDir
Add the default directory to download to in this parameter

.PARAMETER Unpack
This parameter is a switch you can use to unpack the zip file

.EXAMPLE
Get-AzureBlobZipFiles -headers $Headers -Storage 'XXXXXXX' -Container 'XXXXXXX' -BaseDir 'C:\temp' -FileName 'temp.zip' -Verbose

.EXAMPLE
Get-AzureBlobZipFiles -headers $Headers -Storage 'XXXXXXX' -Container 'XXXXXXX' -BaseDir 'C:\temp' -FileName 'temp.zip' -Unpack -Verbose

.NOTES
Author: Bas Wijdenes

.LINK
https://bwit.blog/how-to-download-a-zip-file-from-an-azure-storage-blob-powershell/
#>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        [string] 
        $Storage,
        [parameter(mandatory = $true)]
        [string] 
        $Container,
        [parameter(mandatory = $false)]
        [string] 
        $FileName,
        [parameter(mandatory = $true)]
        $headers,
        [parameter(mandatory = $true)]
        $BaseDir,
        [parameter(mandatory = $false)]  
        [switch]     
        $Unpack
    )
    begin {
        Write-Verbose "Get-StaticFiles: begin: AzureStorage: $Storage | AzureStorageBlob: $Container"

        Write-Verbose "Get-StaticFiles: begin: Filename: $Filename"
        $Uri = 'https://{0}.blob.core.windows.net/{1}/{2}' -f $($Storage), $Container, $FileName 

        Write-Verbose "Get-StaticFiles: begin: Uri: $Uri"
        $InvokeSplatting = @{
            Uri         = $Uri
            Method      = 'Get'
            headers     = $Headers
            ContentType = 'application/x-zip-compressed'
        } 
    }
    process {
        try {
            Write-Verbose "Get-StaticFiles: process: Getting content for file: $Filename"   
            $Module = Invoke-WebRequest @InvokeSplatting -UseBasicParsing -verbose
            if ($Unpack -eq $true) {
                $Stream = [System.IO.MemoryStream]::new($($Module.content))
                $ZipContent = [System.IO.Compression.ZipArchive]::new($Stream, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($file in $ZipContent.Entries) {
                    $WriteBytes = [Byte[]]::new($file.Length)
                    $FileStream = $file.Open()
                    [void]$FileStream.Read($WriteBytes, 0, $file.Length)
                    $FileStream.Dispose()
                    $FileName1 = [string]::Format('{0}\{1}', $BaseDir, $file.FullName.Replace('/', '\'))
                    if (!(Test-Path -Path $(Split-Path -Path $FileName1))) {
                        New-Item -Path $(Split-Path -Path $FileName1) -ItemType Directory
                    }
                    [System.IO.File]::WriteAllBytes($FileName1, $WriteBytes)
                }
            } else {
                $Module.Content | Set-Content "$BaseDir\$FileName" -Encoding Byte
            }
        }
        catch {
            throw $_
        }
    }   
    end {
        Write-Verbose "Get-StaticFiles: end: returning content for $Filename"
        return $Return
    }
}