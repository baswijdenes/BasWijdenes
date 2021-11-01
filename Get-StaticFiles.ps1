function Get-StaticFiles {
    <#
.SYNOPSIS
Get-StaticFiles from the Azure Storage Blob: Static

.DESCRIPTION
with this cmdlet you can get the static files that you need for your script. 
For example a HTML template.

.PARAMETER Storage
The StorageAccountName 

.PARAMETER Container
The StorageContainer

.PARAMETER FileName
Add a file name if you're only looking for 1 file.
If you leave this empty it will search for all files and return them in a CustomObject under Filename, Content:

Filename                                                     Content
--------                                                     -------
XXXXXXXXXXXXXXXXXXXXXXX.html <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">...
HybridWorker_Suspended_Import-PSSession.png                  PNG...

.EXAMPLE

Get-StaticFiles -headers $headers -Storage 'XXXXXX' -Container 'XXXXXX'

Filename                                                     Content
--------                                                     -------
XXXXXXXXXXXXXXXXXXXXXXX.html <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">...
HybridWorker_Suspended_Import-PSSession.png                  PNG...

.EXAMPLE
$filename = 'HybridWorker_Suspended_Import-PSSession.png'
Get-StaticFiles -headers $headers -Storage 'XXXXXX' -Container 'XXXXXX' -Filename

<HTML Content>

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
        $FileName = '?restype=container&comp=list',
        [parameter(mandatory = $true)]
        $headers
    )
    begin {
        Write-Verbose "Get-StaticFiles: begin: AzureStorage: $Storage | AzureStorageBlob: $Container"
        if (!($Filename -eq '?restype=container&comp=list')) {
            Write-Verbose "Get-StaticFiles: begin: Filename: $Filename"
            $Uri = 'https://{0}.blob.core.windows.net/{1}/{2}' -f $($Storage), $Container, $FileName 
        }
        else {
            Write-Verbose "Get-StaticFiles: begin: No filename defined | Getting all files"
            $Uri = 'https://{0}.blob.core.windows.net/{1}{2}' -f $($Storage), $Container, $FileName  
        }
        Write-Verbose "Get-StaticFiles: begin: Uri: $Uri"
        $InvokeSplatting = @{
            Uri = $Uri
            Method = 'Get'
            headers = $Headers
        } 
    }
    process {
 try {
        if (!($Filename -eq '?restype=container&comp=list')) {
            Write-Verbose "Get-StaticFiles: process: Getting content for file: $Filename"   
            $Return = Invoke-RestMethod @InvokeSplatting
        }
        else {
            Write-Verbose "Get-StaticFiles: process: Getting content for script: $scriptname"    
            $Invoke = Invoke-RestMethod @InvokeSplatting
            Write-Verbose 'Get-StaticFiles: process: removing prefix: ï»¿<?xml version="1.0" encoding="utf-8"?>'    
            $xml = $Invoke.Substring(3).replace('ï»¿<?xml version="1.0" encoding="utf-8"?>', '')
            Write-Verbose "XML: $XML"
            Write-Verbose 'Get-StaticFiles: process: Selecting filenames from XML'    
            $Files = Select-Xml -Content $xml -XPath '/EnumerationResults/Blobs/Blob/Name' | ForEach-Object { $_.Node.InnerXML }
            Write-Verbose "ConvertedXML: $Files"
            $Return = [System.Collections.Generic.List[System.Object]]::new()
            Write-Verbose "Get-StaticFiles: process: Filecount: $($Files.count)"  
            foreach ($File in $Files) {
                Write-Verbose "Get-StaticFiles: process: Starting Get-StaticFiles | filename: $File"  
                $Content = Get-StaticFiles -Filename $File -Storage $Storage -Container $Container -Headers $Headers
                $Object = [PSCustomObject]@{
                    Filename = $File
                    Content  = $Content
                }
                $Return.Add($Object)
            }
        }
 } catch {
     throw $_
 }
    }   
    end {
        if (!($Filename -eq '?restype=container&comp=list')) {
            Write-Verbose "Get-StaticFiles: end: returning content for $Filename"
        }
        else {
            Write-Verbose "Get-StaticFiles: end: Finished foreach loop | returning contents"  
        }
        return $Return
    }
}