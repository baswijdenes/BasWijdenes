<#
    .DESCRIPTION
    Upload to Azure Blob or Table.
    You can upload different type of contents. 
    Tables will always be converted to .CSV unless you use the -IsAlreadyInCSVFormat switch.

    .PARAMETER Data
    This is the data you will upload to Azure. This must be an Entry. 
    See examples for an Array example. 
    
    .PARAMETER AzStorage
    Storage Account name
    
    .PARAMETER AzStorageRG
    Storage Account resource Group name
    
    .PARAMETER AzBlobContainer
    Blob container name
    
    .PARAMETER AzStorageTable
    StorageTable name
    
    .PARAMETER AzStorageAccountKey
    Partitionkey you can find in Azure Storage account > Keys.
    
    .PARAMETER Filename
    Your filename when the content is not a childitem.
    
    .PARAMETER AzBackupTime
    The time you want to keep a backup. Backup only works with Blob content.
    
    .PARAMETER FromChildItem
    When it's a childitem Entry it will use the childitems properties. This only works with blob content.
    
    .PARAMETER IsAlreadyInCSVFormat
    When the files are already in CSV format it doesn't need to format the data. This parameter is not mandatory.
    
    .EXAMPLE
From childitem:
    foreach ($Item in $Data)
        {
            Export-AzureStorageContainer -Data $Item `
                -AzStorage 'StorageAccount' `
                -AzStorageRG 'ResourceGroup' `
                -AzBlobContainer 'testblob' `
                -AzStorageAccountKey 'PartitionKey' `
                -FromChildItem
                -Verbose
        }

Blob content:
    Export-AzureStorageContainer -Data $Data `
        -AzStorage 'StorageAccount' `
        -AzStorageRG 'ResourceGroup' `
        -AzBlobContainer 'testblob' `
        -AzStorageAccountKey 'PartitionKey' `
        -Filename 'testfile' `
        -Verbose

CSV formatted blob content:
    Export-AzureStorageContainer -Data $Data `
        -AzStorage 'StorageAccount' `
        -AzStorageRG 'ResourceGroup' `
        -AzBlobContainer 'testblob' `
        -AzStorageAccountKey 'PartitionKey' `
        -Filename 'testfile2.csv' `
        -IsAlreadyInCSVFormat `
        -Verbose
    
To AzTable:
    Export-AzureStorageContainer -Data $Data `
        -AzStorage 'StorageAccount' `
        -AzStorageRG 'ResourceGroup' `
        -AzBlobContainer 'testblob' `
        -AzStorageAccountKey 'PartitionKey' `
        -Filename 'testfile' `
        -Verbose

To AzTable preformatted CSV:
    Export-AzureStorageContainer -Data $Data `
        -AzStorage 'StorageAccount' `
        -AzStorageRG 'ResourceGroup' `
        -AzBlobContainer 'testblob' `
        -AzStorageAccountKey 'PartitionKey' `
        -Filename 'testfile' `
        -IsAlreadyInCSVFormat `
        -Verbose

        .LINK
        
    #>
function Export-AzureStorageContainer
{
    [Cmdletbinding()]
    param(
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        $Data,
        [parameter(Mandatory = $True)]
        $AzStorage,
        [parameter(Mandatory = $True)]
        $AzStorageRG,
        [parameter(Mandatory = $True, ParameterSetName = 'Blob')]
        $AzBlobContainer,
        [parameter(Mandatory = $True, ParameterSetName = 'Table')]
        $AzStorageTable,
        [parameter(Mandatory = $True)]
        $AzStorageAccountKey,
        [parameter(Mandatory = $False)]
        $Filename,
        [parameter(Mandatory = $false)]
        $AzBackupTime,
        [parameter(Mandatory = $false, ParameterSetName = 'Blob')]
        [switch]
        $FromChildItem,
        [parameter(Mandatory = $false)]
        [switch]
        $IsAlreadyInCSVFormat
    )
    begin
    {
        try
        {
            Write-Verbose 'Export-StorageBlob: begin: Start running prechecks...'
            if ($null -eq $Data)
            {
                throw 'There is no data to upload to Azure Storage Blob.'
            }
            if ($FromChildItem)
            {
                Write-Verbose 'Export-StorageBlob: begin: Data comes from ChildItems. Keeping filename as is.'
            } 
            else 
            {
                if ($Filename -like "*.csv*")
                {
                    Write-Verbose 'Export-StorageBlob: begin: Trimming .csv from filename.'
                    $Filename = $Filename.trim('.csv')
                }  
            }
            $null = Get-AzResourceGroup -Name $AzStorageRG -ErrorAction stop
            $null = Get-AzStorageAccount -Name $AzStorage -ResourceGroupName $AzStorageRG -ErrorAction Stop
            $StorageContext = New-AzStorageContext -StorageAccountName $AzStorage -StorageAccountKey $AzStorageAccountKey -ErrorAction Stop  
            if ($AzBlobContainer)
            {
                $null = Get-AzStorageContainer -Name $AzBlobContainer -Context $StorageContext -ErrorAction Stop
            }
            if ($AzStorageTable)
            {
                $Table = Get-AzStorageTable -Name $AzStorageTable -Context $StorageContext -ErrorAction Stop
            }
            Write-Verbose 'Export-StorageBlob: begin: Prechecks are sucessfull.'
            Write-Verbose 'Export-StorageBlob: begin: Creating pre-formatted objects.'
            if ($FromChildItem)
            {

            }
            else 
            {
                $Path = $filename + '.csv' 
            }
        }
        catch
        {     
            throw $_.Exception.Message
            exit
        }
    }
    process 
    {
        try
        {
            if ($FromChildItem)
            {

            }
            else
            {
                if ($IsAlreadyInCSVFormat -eq $false)
                {
                    Write-Verbose 'Export-StorageBlob: process: Data is not in CSV format yet. Converting to CSV...'
                    $Data = $Data | ConvertTo-Csv -NoTypeInformation -ErrorAction Stop
                }
                else
                {
                    Write-Verbose 'Export-StorageBlob: process: Data is in CSV format.'
                }
            }
            Write-Verbose 'Export-StorageBlob: process: Starting upload data to Azure Storage Blob.'
            if ($AzBlobContainer)
            {
                if ($FromChildItem)
                {
                    Set-AzStorageBlobContent -File $Data.FullName -Container $AzBlobContainer -Blob $Data.PSChildName -Context $StorageContext -ErrorAction Stop       
                }
                else
                {
                    $null = Set-Content -Path $Path -Value $Data
                    $null = Set-AzStorageBlobContent -File $path -Container $AzBlobContainer -Blob $path -Context $StorageContext -Force -ErrorAction Stop
                }
                Write-Verbose 'Export-StorageBlob: process: Finished upload data to Azure Storage Blob.'
                Write-Verbose 'Export-StorageBlob: process: Running check to see if we need to remove older entries.'
                $BlobCount = Get-AzStorageBlob -Container $AzBlobContainer -Context $StorageContext -ErrorAction Stop | Sort-Object -Property LastModified
                if ($AzBackupTime)
                {
                    if ($blobcount.count -gt $AzBackupTime)
                    {
                        Write-Verbose 'Export-StorageBlob: process: Removing older entry.'
                        $null = Remove-AzStorageBlob -Blob ($blobcount | Sort-Object -Property LastModified -Descending | Select-Object -Last 1).Name -Container $AzBlobContainer -Context $StorageContext -ErrorAction Stop
                    }
                }
                else
                {
                    Write-Verbose 'Export-StorageBlob: process: There is no storage time defined. We will not remove older files.'
                }
            }
            elseif ($AzStorageTable) 
            {
                Write-Verbose 'Export-StorageBlob: process: Removing older row entries from table.'
                Get-AzTableRow -Table $Table.CloudTable | Remove-AzTableRow -Table $Table.CloudTable
                Write-Verbose 'Export-StorageBlob: process: Adding new entries.'
                Foreach ($Report in $Data)
                {
                    try
                    {
                        $i = 1
                        foreach ($Property in ($Report.PSObject.Properties | Select-Object Name))
                        {
                            if ($i -eq 1)
                            {
                                $Properties = '@{'
                            }
                            $Value = [string]($Report.PSObject.Properties | Where-Object { $_.Name -eq "$($Property.Name)" }).Value
                            $Line = "'{0}' = '{1}';" -f $($Property.Name), $Value
                            $Properties = $Properties + $Line
                            if ($i -eq $($Report.PSObject.Properties).Count)
                            {
                                $Properties = $Properties + '}'
                            }
                            $i++
                        }
                        Add-AzTableRow -Table $Table -PartitionKey $AzStorageAccountKey -RowKey ([guid]::NewGuid().tostring()) -property $Properties 
                    }
                    catch
                    {
                        continue
                    }
                }
            }
        }
        catch
        {
            throw $_.Exception.Message
        }
    } 
    end
    {
        Return 'Finished uploading to AzStorageAccount.'
    }
}