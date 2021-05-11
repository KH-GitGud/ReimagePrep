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

# Needed here: ask user if barcode data is coming from a csv file or direct input (scanner/keyboard)
# Currently runs with CSVs SPECIFICALLY from a Motorola Symbol CS3070 scanner, working on Direct Scan
# Later: generalize the CSV input. Other things aside from this specific scanner use them.
$InputType = Read-Host "Are you loading from a file (CSV) or scanning PCC numbers directly (Scan)?"
switch ($InputType) {
    CSV {
        # ORIGINAL, FUNCTIONING CODE STARTS HERE... 
        # Retrieves a list of numbers in the rightmost column
        $DriveLetter = (Get-Volume -Friendlyname CS3070).DriveLetter + { :\ }
        $NumbersCol = (Import-CSV $DriveLetter'Scanned Barcodes\BARCODES.txt' -Header 'DateScanned', 'TimeScanned', 'Unknown', 'Barcode').Barcode
        $PCCRegEx = '^\d{6}$'
            
        # Ensure numbers are PCC numbers, then search AD and remove them
        # Does this work without the $NumberCol variable? If so, move this chunk to after the switch, the same process must happen regardless of $InputType
        Import-Module ActiveDirectory
        foreach ($Barcode in $NumbersCol) {
            if ($Barcode -match $PCCRegEx) {
                $WildBars = 'Name -Like "*' + $Barcode + '*"'
                (Get-CMDevice -Name *$Barcode*).name
                Get-ADComputer -Filter ($WildBars) -Server PCC-Domain.pima.edu | Remove-ADComputer -Confirm
                Get-ADComputer -Filter ($WildBars) -Server EDU-Domain.pima.edu | Remove-ADComputer -Confirm
            }
        } 
    }
    Scan { $Barcode = Read-Host }
    default { "Input not recognized. Please enter either 'CSV' or 'Scan' to proceed." }
}



