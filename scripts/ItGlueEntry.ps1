#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering the default ItGlue entry
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$ItGlue = Get-Session -Name 'It Glue'

# Recreating the entry in each repository
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    Set-RDMCurrentRepository $Vault
    $Test = Get-RDMSession | Where-Object{$_.Credentials.ITGlueSafeApiKey -ne $null -and $_.ConnectionType -eq  'Credential'}
    if(!Test){
        $CredEntry = Copy-RDMSession $ItGlue
        Set-RDMSession $CredEntry
        Write-Host "Created ItGlue entry $($Vault.Name)"
    }else{
        Write-Host "Present for $($Vault.Name)"
    }
}