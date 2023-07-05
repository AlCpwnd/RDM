#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering the default ItGlue entry
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$ItGlue = Get-RDMSession -Name 'IT Glue [To be configured]'

# Recovering existing credential entries
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$Folders = $Sessions | Where-Object{$_.ConnectionType -eq 'Group' -and $_.Name -eq $_.Group}

# Verifying if ItGlue credentials already exist
$ExistingCredentials = ($Sessions | Where-Object{$_.ConnectionType -eq 'Credential' -and $_.Credentials.ITGlueSafeApiKey}).Group
foreach($Folder in $Folders){
    $Test = $ExistingCredentials | Where-Object{$_ -match $Folder.Name}
    if(!$Test){
        # Creating the entry
        $ItGl = Copy-RDMSession $ItGlue
        $ItGl.Group = $Folder.Group
        # Adding mark in order to note further configuration
        $ItGl.Name = "$($Folder.Name) [To be configured]"
        Set-RDMSession $ItGl
        Write-Host "Session created for: $($Folder.Name)"
    }
}