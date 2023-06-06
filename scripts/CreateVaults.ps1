#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering clients from the Default vault.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$RootFolders = (Get-RDMSession | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name

# Creating the Vaults.
foreach($RFolder in $RootFolders){
    $Repository = New-RDMRepository -Name $RFolder.Name
    Set-RDMRepository $Repository
    Write-Host "Created: $($RFoldere.Namee)"
}