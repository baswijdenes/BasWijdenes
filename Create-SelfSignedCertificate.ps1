<#
    Disclaimer (By BasW): This script is not created by Bas Wijdenes but by his dear colleague Maurice Lok-hin. The true scripting god ;-)
    This script generates a self-signed certificate which we can use to logon to AzureAD
    Script takes a certificateName as input and the path where you want to save the pfx and .cer file.
    The pfx contains the private key and is used on the "client" (Azure Automation) to authenticate.
    The cer file only contains the public key and should be uploaded to the app in AzureAD.
    Parameters:
    - CertificateName: The name/subject of the certificate
    - OutputFOlder: the folder where the pfx and cer files are stored
    - ExportPassword: the password set on the pfx file
    - ValidityInYears: how long is the certificate valid (defaults to 2 years)
#>
function Generate-LogonCertificate
{
[CmdletBinding()]
param(
[Parameter(Mandatory=$true,Position=0)]
[string]$CertificateName,
[Parameter(Mandatory=$true,Position=1)]
[string]$OutputFolder,
[Parameter(Mandatory=$true,Position=2)]
[string]$ExportPassword,
[Parameter(Mandatory=$false,Position=3)]
[int]$ValidityInYears = 2
)
begin {
    # Set the certificate parameters
    $CertificateParameters = @{
        Subject = "CN=$($CertificateName),C=Netherlands,L=Lijnden" # CertificateSubject
        CertStoreLocation = 'Cert:\currentuser\My' # Temporary store location
        KeyAlgorithm = 'RSA' # Algorithm
        KeyLength = 2048 # Length of private key
        KeyExportPolicy = 'Exportable'
        KeyProtection = 'None'
        Provider = 'Microsoft Enhanced RSA and AES Cryptographic Provider' # use this provider so we can use the private key
        NotBefore = [datetime]::Now
        NotAfter = [datetime]::Now.AddYears($ValidityInYears)
        }
    }
process {
        # Generate the certificate
        $NewCertificate = New-SelfSignedCertificate @CertificateParameters
        # Create the export files
        $ExportPfxFile = [System.IO.File]::Create("$($OutputFolder)\$($CertificateName).pfx")
        $ExportCerFile = [System.IO.File]::Create("$($OutputFolder)\$($CertificateName).cer")
        # Generate byte arrays for the pfx and cer files     
        $PfxBytes = $NewCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,$ExportPassword)
        $CerBytes = $NewCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        # Write the bytes
        $ExportPfxFile.Write($PfxBytes,0,$PfxBytes.Length)
        $ExportCerFile.Write($CerBytes,0,$CerBytes.Length)
        return $NewCertificate
        }
end {
    # remove the certificate from the certificate store
    Remove-Item $NewCertificate.PSPath
    # Close the file handles to the exported files
    $ExportPfxFile.Dispose()
    $ExportCerFile.Dispose()
    $PfxBytes = $null # null the private key bytes
    [gc]::Collect() # Garbage Collect so it's removed from memory
    }
}