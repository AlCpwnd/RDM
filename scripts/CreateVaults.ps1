#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering clients from the Default vault.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$RootFolders = (Get-RDMSession | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name

# Creating the Vaults.
foreach($RFolder in $RootFolders){
    $Repository = New-RDMRepository -Name $RFolder
    Set-RDMRepository $Repository
    Write-Host "Created: $RFolder"
}