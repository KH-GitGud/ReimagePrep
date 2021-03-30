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

# For later: rig up a section for plain old input - this should cover scanners without storage.

# Ensure numbers are PCC numbers, then search AD and remove them
Import-Module ActiveDirectory
foreach ($Barcode in $NumbersCol) {
    if ($Barcode -match $PCCRegEx) {
        Get-ADComputer -Filter ('Name -Like "*' + $Barcode + '*"')  -Server PCC-Domain.pima.edu | Remove-ADComputer -WhatIf
        Get-ADComputer -Filter ('Name -Like "*' + $Barcode + '*"')  -Server EDU-Domain.pima.edu | Remove-ADComputer -WhatIf
        #Remove-CMDevice -IResultObject $Barcode -WhatIf
    }
}
# Correctly removes computers from AD. However, SCCM removal attempt shows (with $Barcode underlined):
#   Remove-CMDevice -InputObject $Barcode -WhatIf
#   + CategoryInfo          : InvalidArgument: (:) [Remove-CMDevice], ParameterBindingException
#   + FullyQualifiedErrorId : CannotConvertArgumentNoMessage,Microsoft.ConfigurationManagement.Cmdlets.Collections.Commands.RemoveDeviceCommand

# Next attempt: -InputObject and -IResultObject show same error, does NOT like $Barcode.
# Get-CMDevice -Name 'FullComputerName' | Remove-CMDevice
#       ^ works.
# Get-ADComputer -Filter ('Name -Like "*' + '132825' + '*"') | select Name
#       ^ returns '@{Name=WC-R011132825SC}'
# Get-CMDevice (Get-ADComputer -Filter ('Name -Like "*' + '132825' + '*"') | select Name)
#       ^ needs JUST the name string and it can be piped to Remove-CMDevice
#         -replace won't work as-is, this is not a string, it just returns one.
