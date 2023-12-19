function Update-StorageBlob {
    <#
    .SYNOPSIS
    Uploads files to Azure Storage Blob
    
    .DESCRIPTION
    Uploads files to Azure Storage Blob from a local folder
    
    .PARAMETER Path
    Path to file or local folder
    
    .PARAMETER StorageContainer
    StorageContainer name
    
    .PARAMETER StorageAccount
    StorageAccount name

    .PARAMETER ResourceGroup
    ResourceGroup name

    .PARAMETER Recurse
    Recurse through subfolders
    
    .EXAMPLE
    Update-StorageBlob -Path "C:\Temp\MyFolder" -StorageContainer "mycontainer" -StorageAccount "mystorageaccount" -ResourceGroup "myresourcegroup" -Recurse $true
    
    .NOTES
    Author: Bas Wijdenes
    Site: https://baswijdenes.com
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        [string]$Path,
        [parameter(mandatory = $true)]
        $StorageContainer,
        [parameter(mandatory = $true)]
        $StorageAccount,
        [parameter(mandatory = $true)]
        $ResourceGroup,
        [parameter(mandatory = $false)]
        [bool]$Recurse
    )
    try {
        Write-Verbose "Getting StorageAccount: $($StorageAccount) in ResourceGroup: $($ResourceGroup)"
        $storageAccount = Get-AzStorageAccount -ResourceGroupName "$($ResourceGroup)" -AccountName "$StorageAccount"
    }
    catch {
        throw $_.Exception.Message
    }
    if ($null -eq $StorageAccount) {
        throw "StorageAccount: $StorageAccount not found under ResourceGroup: $ResourceGroup"
    }
    $CTX = $storageAccount.Context
    try {
        if ($Recurse -eq $true) {
            # Write-Output 'recurse equals $true'
            Get-ChildItem -Path $Path -File -Recurse | Set-AzStorageBlobContent -Container ($StorageContainer) -Context $CTX -Force
            $Items = Get-ChildItem -Path $Path -Recurse
        }
        else {
            $Items = Get-ChildItem -Path $Path   
        }
    }
    catch {
        throw $_.Exception.Message
    }
    if ($null -eq $Items) {
        throw "No files found under $Path"
    }
    else {
        if ($Recurse -eq $false) {
            $UploadedItems = [System.Collections.Generic.List[Object]]::new()
            foreach ($Item in $Items) {
                $Object = [PSCustomObject]@{
                    Item       = $Item.Name
                    Successful = $null
                }
                Write-Verbose "Uploading $($Item.BaseName) to $($StorageContainer)"
                try {
                    $null = $Item | Set-AzStorageBlobContent -Container $($StorageContainer) -Context $CTX -Force
                    $Object.Successful = $true
                }
                catch {
                    Write-Warning "Something went wrong uploading $($Item.BaseName) to $($StorageContainer): $($_.Exception.Message)"
                    $Object.Successful = $false
                }
                $UploadedItems.Add($Object)
            } 
        }
        return $UploadedItems
    }
}