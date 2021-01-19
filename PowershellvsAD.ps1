# Script intended to prep devices for reimaging by removing their entries in AD and SCCM, in that order.
# Thanks to Will and Justin for proofreading format
# BTW -match '^\d{6}$' is RegEx for PCC Number if necessary. Thanks Will!

# Credit to Kent DuBack for figuring out site config
try {

    # Site configuration
    $SiteCode = "PCC" # Site code
    $ProviderMachineName = "do-sccm.pcc-domain.pima.edu" # SMS Provider machine name
    
    # Import the ConfigurationManager.psd1 module
    if ((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
    }
    
    # Connect to the site's drive if it is not already present
    if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
    }
    
    # Set the current location to be the site code.
    Set-Location "$($SiteCode):\"
    
}
    
catch {
    Write-Host "SCCM is not installed on this machine or you don't have correct permissions, please install SCCM before running this script again"
    start-sleep 5
    exit
}

# Next section SPECIFICALLY for a Motorola Symbol CS3070 scanner
# Retrieves a list of numbers in the rightmost column
$DriveLetter = (Get-Volume -Friendlyname CS3070).DriveLetter + {:\}
$NumbersCol = (Import-CSV $DriveLetter'Scanned Barcodes\BARCODES.txt' -Header 'DateScanned', 'TimeScanned', 'Unknown', 'Barcode').Barcode
$PCCRegEx = '^\d{6}$'

# Ensure numbers are PCC numbers, then search AD and remove them
Import-Module ActiveDirectory
foreach ($Barcode in $NumbersCol) {
    if ($Barcode -match $PCCRegEx) {
        Get-ADComputer -Filter ('Name -Like "*' + $Barcode + '*"')  -Server PCC-Domain.pima.edu | Remove-ADComputer -WhatIf
        Get-ADComputer -Filter ('Name -Like "*' + $Barcode + '*"')  -Server EDU-Domain.pima.edu | Remove-ADComputer -WhatIf
        Get-CMDevice -Name $Barcode | Remove-CMDevice -WhatIf
    }
}