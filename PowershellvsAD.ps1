# Script intended to prep devices for reimaging by removing their entries in AD and SCCM, in that order - AD is easier to search.

#Import AD first
Import-Module ActiveDirectory

# Ask for PCC Number, ideally pipe to AD to retrieve full computer name and use that as our variable
$PCC = Read-Host "Enter a PCC Number:" | Get-ADComputer -Filter {Name -like $PCC}

# How to enter large amounts of PCC numbers at once? Manual type? CSV? JSON array?

# AD Reference: https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
Remove-ADComputer -Identity -Confirm -WhatIf $PCC

# Imports SCCM to PowerShell: https://docs.microsoft.com/en-us/powershell/sccm/overview?view=sccm-ps
Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin'
Import-Module .\ConfigurationManager.psd1
(Get-Module -Name ConfigurationManager).Version
(Get-Module -Name ConfigurationManager).Path

# SCCM Reference: https://docs.microsoft.com/en-us/powershell/module/configurationmanager/remove-cmdevice?view=sccm-ps
Get-CMDevice -Name $PCC | Remove-CMDevice -Confirm -WhatIf