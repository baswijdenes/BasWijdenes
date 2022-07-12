function Remove-ByteOrderMark {
    <#
    .SYNOPSIS
    Remove BOM from Byte Arrays
    
    .DESCRIPTION
    Use this function to remove BOM from ByteArrays
    As for now the script will only check for BOMs for UTF8, UTF16BE and UTF16LE  

    .PARAMETER InputBytes
    The input as a Byte array.
    
    .PARAMETER OutputAsString
    This is a switch. Use this for when you want the output to be in a string format.
    
    .EXAMPLE
    $FullName = ".\StringWithBom.txt"
    $Bytes = [System.IO.File]::ReadAllBytes($FullName) 
    Remove-ByteOrderMark -InputBytes $bytes -OutputAsString

    .NOTES
    Author: Maurice Lok-hin
    At the moment the function is managed by Bas Wijdenes

    .LINK
    https://baswijdenes.com/how-to-remove-byte-order-mark-with-powershell/

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$InputBytes,
        [Parameter(Mandatory = $false)]
        [switch]$OutputAsString
    )
    begin {
        # Creating a HashTable with first Byte for UTF8, UTF16BE, and UTF16LE
        Write-Verbose "Remove-ByteOrderMark: begin: Testing UTF8, UTF16BE, and UTF16LE only"
        $BomStart = @{
            [byte]0xEF = 'UTF8'
            [byte]0xFE = 'UTF16BE'
            [byte]0xFF = 'UTF16LE'
        } 
    } process {  
        # We need to compare the first Byte in InputBytes with the Hashtable to see if there is a match
        Write-Verbose "Remove-ByteOrderMark: proecess: Grabbing first Byte"
        $PossibleBOMType = $BomStart[$InputBytes[0]]
        # If the first byte matches, we will check the next bytes
        # https://en.wikipedia.org/wiki/Byte_order_mark#Byte_order_marks_by_encoding
        if ($null -ne $PossibleBOMType) {
            # After the first byte matches we can check the second and third byte (third for UTF8 only)
            Write-Verbose "Remove-ByteOrderMark: process: There is a Possible BOM Type | Starting switch"
            switch ($PossibleBOMType) {
                'UTF8' {
                    if (($InputBytes[1]) -eq 0xBB -and ($InputBytes[2] -eq 0xBF)) {
                        # Removing first 3 bytes from array by selecting the full length and stripping first 3
                        Write-Verbose "Remove-ByteOrderMark: process: UTF8 BOM dectected"
                        $OutputBytes = $InputBytes[3..$InputBytes.Length]
                        $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
                    }
                }
                'UTF16BE' {
                    if ($InputBytes[1] -eq 0xFF) {
                        # Removing first 2 bytes from array by selecting the full length and stripping first 2
                        Write-Verbose "Remove-ByteOrderMark: process: UTF16BE BOM dectected"
                        $OutputBytes = $InputBytes[2..$InputBytes.Length]
                        $OutputString = [System.Text.Encoding]::Unicode.GetString($OutputBytes)
                    }
                }
                'UTF16LE' {
                    if ($InputBytes[1] -eq 0xFE) {
                        # Removing first 2 bytes from array by selecting the full length and stripping first 2
                        Write-Verbose "Remove-ByteOrderMark: process: UTF16LE BOM dectected"
                        $OutputBytes = $InputBytes[2..$InputBytes.Length]
                        $OutputString = [System.Text.Encoding]::Unicode.GetString($OutputBytes)
                    }
                }
                default {
                    # we couldn't find the correct BOMType, so we will assume it's UTF8
                    Write-Verbose "Remove-ByteOrderMark: process: No BOM dectected | file will be treated as UTF8"
                    $OutputBytes = $InputBytes
                    $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
                }
            }
    
        }
        else {
            # Because there is no BOM detected we will assume it's a normal UTF8 string without BOM
            Write-Verbose 'No BOM detected, file will be treated as Utf8'
            $OutputBytes = $InputBytes
            $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
        }
    } end {
        if ($OutputAsString) {
            Write-Verbose "Remove-ByteOrderMark: end: Returning output as string"
            return $OutputString
        }
        else {
            Write-Verbose "Remove-ByteOrderMark: end: Returning output as bytes"
            return $OutputBytes
        }
    }
}