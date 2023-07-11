#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$RootTemplate = Get-RDMRootSession
$Properties = $RootTemplate.Security.PSObject.Properties

# Recovering existing vaults.
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    # Moving to the concerned vault.
    Set-RDMCurrentRepository $Vault

    # Applying the permissions on the root folder.
    $RootFolder = Get-RDMRootSession
    $Properties | ForEach-Object{$RootFolder.Security.$($_.Name) = $_.Value}
    Set-RDMRootSession $RootFolder
    Write-Host "Rooltfolder permissions defined for $($Vault.Name)"
}