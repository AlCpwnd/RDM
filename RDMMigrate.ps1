param(
    [Parameter(Mandatory)][String]$MainVault
)

#Requires -Module RemoteDesktopManager

#===========#
# Functions #
#===========#

function Show-Info{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t=i=`t$Msg"}
function Show-Error{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t/!\`t$Msg" -ForegroundColor Red}


#=================#
# Security Checks #
#=================#

# Verifies the parameter
$MVInfo = Get-RDMVault -Name $MainVault
Show-Info "Main Vault defined as : $($MVInfo.Name)"
if(!$MVInfo){
    Show-Error "Invalid Main Vault : $MainVault"
    return
}

# Sets current location within the $MainVault
Set-RDMCurrentVault $MVInfo


#=====================#
# Variable Definition #
#=====================#

# Recovers all existing sessions
$Entries = Get-RDMSession
Show-Info "$($Entries.Count) Entries found."

# Seperates the main groups
$MainGroups = ($Entries | Where-Object{$_.Group -notmatch "\\|Test"} | Select-Object Group -Unique).Group
Show-Info "$($MainGroups.Count) MainGroups found."

# Lists all the subfolders
$Folders = $Entries | Where-Object{$_.ConnectionType -eq "Group" -and $_.Group -match "\\"} | Sort-Object Group

# Lists all the remaining sessions
$Sessions = $Entries | Where-Object{$_.ConnectionType -ne "Group" -and $_.Group -match "\\"} | Sort-Object Group

# Recovers all existing repositories
$Repositories = Get-RDMVault


#========#
# Script #
#========#

# Start Vault check/creation
foreach($Group in $MainGroups){
    if($Repositories.Name -contains $Group){
        Show-Info "Existing vault found for : $Group .Skipping."
        Continue
    }
    $Parameters = @{Name = $Group}
    $Vault = New-RDMVault @Parameters
    Set-RDMVault $Vault
    Show-Info "Created vault : $Group"
}
# End Vault check/creation

Update-RDMUI

# Update vaults after creation
$Repositories = Get-RDMRepository

# Start folder ceation
foreach($MGroup in $MainGroups){
    $GroupFolders = $Folders | Where-Object{$_.Group -like "$MGroup\*"}
    $FolderCreation = foreach($Folder in $GroupFolders){
        $Copy = Copy-RDMSession $Folder -IncludePasswordHistory -IncludeSubConnections
        $Copy.Group = $Copy.Group.Replace("$MGroup\","") # New vault doesn't have the first folder level structure
        $Copy
    }
    $Repo = $Repositories[$Repositories.Name.IndexOf($MGroup)]
    Set-RDMRepository $Repo
    $FolderCreation | ForEach-Object{Set-RDMSession $_}
    Set-RDMCurrentRepository $MVInfo
}
# End folder creation

Update-RDMUI

# Start session creation
foreach($MGroup in $MainGroups){
    $GroupSessions = $Sessions | Where-Object{$_.Group -like "$MGroup\*"}
    $SessionCreation = foreach($Folder in $GroupSessions){
        $Copy = Copy-RDMSession $Folder -IncludePasswordHistory -IncludeSubConnections
        $Copy.Group = $Copy.Group.Replace("$MGroup\","") # New vault doesn't have the first folder level structure
        $Copy
    }
    Set-RDMRepository (Get-RDMRepository -Name $MGroup)
    $SessionCreation | ForEach-Object{Set-RDMSession $_}
    Set-RDMCurrentRepository $MVInfo
}
# End session creation

Update-RDMUI