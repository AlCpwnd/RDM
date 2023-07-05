#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$RootTemplate = Get-RDMRootSession

# Recovering existing vaults.
$Properties = $RootTemplate.Security.PSObject.Properties
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    Set-RDMCurrentRepository $Vault
    $RootFolder = Get-RDMRootSession
    $Properties | ForEach-Object{$RootFolder.Security.$($_.Name) = $_.Value}
    Set-RDMRootSession $RootFolder
    Write-Host "Rooltfolder permissions defined for $($Vault.Name)"
}