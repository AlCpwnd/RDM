#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 05/06/2023

# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$Folders = $Sessions | Where-Object{$_.ConnectionType -eq "Group" -and $RootFolders -notcontains $_.Name}

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    $ToCopy = $Folders | Where-Object{$_.Group -match "$RFolder\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        $Temp = Copy-RDMSession -PSConnection $Session -IncludePasswordHistory
        $Temp.Group = $Temp.Group.Replace("$RFolder\",'')
        $Temp
    }

    # Moving to the vault.
    Set-RDMCurrentRepository $(Get-RDMRepository -Name $RFolder)

    # Creating the folder structure.
    $Copy | ForEach-Object{Set-RDMSession $_}
    Write-Host "$($Copy.Count) folder(s) created."
    Write-Host "Folders copied for: $RFolder"
}