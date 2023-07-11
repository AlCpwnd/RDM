#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$ToBeCopied = $Sessions | Where-Object{$RootFolders -notcontains $_.Name -or $_.ConnectionType -ne 'Group'}

$i = 0
$iMax = $RootFolders.Count

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    Write-Progress -Activity "Moving sessions [$i/$iMax]" -Status $RFolder -PercentComplete (($i/$iMax)*100)
    $ToCopy = $ToBeCopied | Where-Object{($_.Group -like "$RFolder\*" -or $_.Group -eq $RFolder) -and $_.Group -notmatch "$RFolder\\.+\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        if($Session.Group -eq $RFolder){
            $Session.Group = ""
            $Session
        }elseif($Session.ConnectionType -eq 'Group'){
            $Session.Group = $Session.Group.Replace("$RFolder\",'')
            $Session
        }
    }

    # Recovering the destination vault
    $Vault = Get-RDMRepository -Name $RFolder

    # Moving entries to the vault
    $Copy | ForEach-Object{Move-RDMSession -InputObject $_ -ToVaultID $Vault.ID}
    Write-Host "$($ToCopy.Count) sessions(s) moved."
    Write-Host "Sessions moved for: $RFolder"
    $i++
}