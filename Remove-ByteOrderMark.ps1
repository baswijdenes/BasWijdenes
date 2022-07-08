function Remove-M8Bom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$InputBytes,
    
        [Parameter(Mandatory = $false)]
        [switch]$OutputAsString
    )
    
    # startBytes of the BOMs
    $BomStart = @{
        [byte]0xEF = 'UTF8'
        [byte]0xFE = 'UTF16BE'
        [byte]0xFF = 'UTF16LE'
    }
    
    # first we check the first byte to see if it's a possible BOM
    $PossibleBOMType = $BomStart[$InputBytes[0]]
    
    
    if ($null -ne $PossibleBOMType) {
        # if the first byte matches, check the next byte
    
        switch ($PossibleBOMType) {
            'UTF8' {
                # check byte 2 and 3 for UTF8
                if (($InputBytes[1]) -eq 0xBB -and ($InputBytes[2] -eq 0xBF)) {
                    Write-Verbose 'UTF8 BOM detected'
                    $OutputBytes = $InputBytes[3..$InputBytes.Length]
                    $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
                }
            }
            'UTF16BE' {
                # check byte 2
                if ($InputBytes[1] -eq 0xFF) {
                    Write-Verbose 'UTF16BE BOM detected'
                    $OutputBytes = $InputBytes[2..$InputBytes.Length]
                    $OutputString = [System.Text.Encoding]::Unicode.GetString($OutputBytes)
                }
            }
            'UTF16LE' {
                if ($InputBytes[1] -eq 0xFE) {
                    Write-Verbose 'UTF16LE BOM detected'
                    $OutputBytes = $InputBytes[2..$InputBytes.Length]
                    $OutputString = [System.Text.Encoding]::Unicode.GetString($OutputBytes)
                }
            }
            default {
                # assume the data is UTF8 without a BOM
                Write-Verbose 'No BOM detected, file will be treated as Utf8'
                $OutputBytes = $InputBytes
                $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
            } # no other BOM bytes detected
        }
    
    } else {
         # assume the data is UTF8 without a BOM
         Write-Verbose 'No BOM detected, file will be treated as Utf8'
         $OutputBytes = $InputBytes
         $OutputString = [System.Text.Encoding]::UTF8.GetString($OutputBytes)
    }
    if ($OutputAsString) {
        Write-Output $OutputString
    }
    else {
        Write-Output $OutputBytes
    }
        
}