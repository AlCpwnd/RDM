#Requires -Modules @{ModuleName="Devolutions.PowerShell"; ModuleVersion="2023.2.0.1"} -Version 7

#   BKM-Orange
#   JAAL - 06/06/2023

# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$SessionsToBeCopied = $Sessions | Where-Object{$_.ConnectionType -ne "Group"}

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    $ToCopy = $SessionsToBeCopied | Where-Object{$_.Group -like "$RFolder*" -and $_.Group -notlike "*\$RFolder*"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        $Temp = Copy-RDMSession $Session -DontChangeID -IncludePasswordHistory -IncludeSubConnections
        if($Temp.Group -eq $RFolder){
            $Temp.Group = ""
        }else{
            $Temp.Group = $Temp.Group.Replace("$RFolder\",'')
        }
        $Temp
    }

    # Moving to the vault.
    Set-RDMCurrentRepository $(Get-RDMRepository -Name $RFolder)

    # Creating the folder structure.
    $Copy | ForEach-Object{Set-RDMSession $_}
    Write-Host "$($Copy.Count) sessions(s) created."
    Write-Host "Sessions copied for: $RFolder"
}