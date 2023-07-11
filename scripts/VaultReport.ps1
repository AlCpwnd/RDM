#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering existing vaults
$Vaults = Get-RDMRepository | Select-Object ID,Name,Description

# Preparing filename for report
$Date = Get-Date -Format 'yyyyMMdd'
$FileName = "$PSScriptRoot\$Date`_VaultReport.csv"

# File Export
$Vaults | Export-Csv -Path $FileName -Delimiter ';' -NoTypeInformation -Encoding unicode
Write-Host "File generated: $FileName"