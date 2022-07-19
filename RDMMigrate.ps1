#Requires -Module RemoteDesktopManager

param(
    [Parameter(Mandatory)][String]$MainVault
)

# Functions:
function Show-Info{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t=i=`t$Msg"}
function Show-Error{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t/!\`t$Msg" -ForegroundColor Yellow}

# Verifies the parameter
$MVInfo = Get-RDMRepository -Name $MainVault
if(!$MVInfo){
    Show-Error "Invalid Main Vault : $MainVault"
    return
}

# Connects to the Database configuration
# Start-RDMInstance # => Might not be needed

# Sets current location within the $MainVault
Set-RDMCurrentRepository $MVInfo

# Recovers all existing cesisons
$Sessions = Get-RDMSession 
# Recovers all groups
$Groups = $Sessions | Where-Object{$_.Group -notmatch "\\"} | Select-Object Group -Unique 
# Recovers all existing repositories
$Repositories = Get-RDMRepository

# Creates a Vault for each group and skips in case it already exists
foreach($Group in $Groups){
    if($Repositories.Name -contains $Group){
        Show-Info "Existing vault found for : $Group .Skipping."
        Continue
    }
    try{
        $Vault = New-RDMVault -Name $Group
        Set-RDMVault $Vault -ErrorAction Stop
    }catch{
        Show-Error "Failed to create a vault for : $Group"
    }
}

# Update the Remote desktop manager UI in order to show the changes
Update-RDMUI

# 
foreach($Session in $Sessions){
    # Verifies if the current cession isn't one of the $Groups
    if($Session -notmatch "\\"){
        Continue
    }
    # Moves to the $MainVault
    Set-RDMCurrentRepository $MVInfo
    try{
        # Recovers the information of the current cession
        # -DontChangeID  -->  Will move instead of copy the cession
        $Move = Copy-RDMSession -DontChangeID -IncludePasswordHistory -IncludeSubConnections -ErrorAction Stop
        # Recovers the new location's information based on the cession's name
        $NewVault = Get-RDMVault -Name $Session.Split("\")[0]
        # Moves into the new vault        
        Set-RDMCurrentRepository $NewVault
        # Copies the cession over
        Set-RDMCession $Move
    }catch{
        Show-Error "Failed to move : $Session"
    }
}

# Update the Remote desktop manager UI in order to show the changes
Update-RDMUI