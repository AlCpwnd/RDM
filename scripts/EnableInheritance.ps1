#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

#   BKM-Orange
#   JAAL - 07/06/2023

# Recovering sessions who don't have inheritance enabled
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession | Where-Object{$_.Security.RoleOverride -ne 'Default'}

# Enabling inheritance on the found sessions
foreach($Session in $Sessions){
    $Session.Security.RoleOverride = 'Default'
    Set-RDMSession $Session
    Write-Host "Done: $($Session.group)"
}