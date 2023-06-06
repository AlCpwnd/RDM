#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$TemplateCred = Get-RDMSession -Name Credentials

# Recovering existing Credentials folders.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$CredentialFolders = Get-RDMSession -Name Credentials | Where-Object{$_.ConnectionType -eq 'Group'}

# Replacing permissions with the template one.
$Properties = $TemplateCred.Security.PSObject.Properties
foreach($Folder in $CredentialFolders){
    $Properties | ForEach-Object{$Folder.Security.$($_.Name) = $_.Value}
    Set-RDMSession $Folder
    Write-Host "Done: $($Folder.Group)"
}