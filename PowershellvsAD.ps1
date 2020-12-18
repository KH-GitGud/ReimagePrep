# Script intended to prep devices for reimaging by removing their entries in AD and SCCM, in that order - AD is easier to search.
# Need to import module first: https://docs.microsoft.com/en-us/powershell/sccm/overview?view=sccm-ps
# Run from SCCM console?

# Ask for PCC Number, ideally pipe to AD to retrieve full computer name and use that as our variable
$PCC = Read-Host "Please enter the PCC Number of the computer to be removed" | Get-ADComputer -Filter # Ask Justin?

# How to enter large amounts of PCC numbers at once? Manual type? CSV?

# AD Reference: https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
Remove-ADComputer -Identity -Confirm -WhatIf $PCC

# SCCM Reference: https://docs.microsoft.com/en-us/powershell/module/configurationmanager/remove-cmdevice?view=sccm-ps
Get-CMDevice -Name $PCC | Remove-CMDevice -Confirm -WhatIf