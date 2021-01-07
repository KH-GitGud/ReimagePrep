# Script intended to prep devices for reimaging by removing their entries in AD and SCCM, in that order.
# Thanks to Will and Justin for proofreading format
# BTW -match '^\d{6}$' is RegEx for PCC Number if necessary. Thanks Will!

# Imports first
# https://docs.microsoft.com/en-us/powershell/sccm/overview?view=sccm-ps
Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin'
Import-Module .\ConfigurationManager.psd1
    (Get-Module -Name ConfigurationManager).Version
    (Get-Module -Name ConfigurationManager).Path
Import-Module ActiveDirectory

# Retrieves full name from AD using PCC number, then removes
# AD Reference: https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
$PCC = Read-Host 'Enter a PCC Number'
$Domain = Read-Host 'Enter Domain (PCC or EDU)'
Get-ADComputer -Filter ('Name -Like "*' + $PCC + '*"')  -Server $Domain-Domain.pima.edu | Remove-ADComputer -Confirm -WhatIf

# SCCM Reference: https://docs.microsoft.com/en-us/powershell/module/configurationmanager/remove-cmdevice?view=sccm-ps
Get-CMDevice -Name $PCC | Remove-CMDevice -Confirm -WhatIf
# Should work IF site is configured, which it is currently not