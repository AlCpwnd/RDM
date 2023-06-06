#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$SessionsToBeCopied = $Sessions | Where-Object{$_.ConnectionType -ne "Group" -and $RootFolders -notcontains $_.Name}

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    $ToCopy = $SessionsToBeCopied | Where-Object{$_.Group -match "$RFolder\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        $Temp = Copy-RDMSession $Session
        $Temp.Group = $Temp.Group.Replace("$RFolder\",'')
        $Temp
    }

    # Moving to the vault.
    Set-RDMCurrentRepository $(Get-RDMRepository -Name $RFolder)

    # Creating the folder structure.
    $Copy | ForEach-Object{New-RDMSession $_}
    Write-Host "$($Copy.Count) sessions(s) created."
    Write-Host "Sessions copied for: $RFolder"
}