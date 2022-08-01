#Requires -Module RemoteDesktopManager

#:Safety Net:#################################################
##############################################################
$OpenPoints = (
    "Have yet to verify if connexion permissions are preserved when copying and/or moving sessions.",
    "Have yet to verify what permission are given to the vaults by default."
)    

function Show-Disclaimer{
    param([Parameter(Mandatory,Position=0)][Array]$Points)
    Write-Host "`n`t[!] Open points/notes found:`n" -ForegroundColor Red
    $Points | ForEach-Object{Write-Host "`t- $_" -ForegroundColor Red}
    Write-Host ""
    do{
        Write-Host "`t[!] Do you wish to continue execution knowing this? y/n (N)" -ForegroundColor Red -NoNewline
        $Choice = Read-Host
    }until($Choice -match "y|n" -or !$Choice)
    Write-Host ""
    switch ($Choice) {
        y {return $true}
        Default {return $false}
    }
}

if($OpenPoints){
    if(!(Show-Disclaimer $OpenPoints)){
        return
    }
}
##############################################################
##############################################################

param(
    [Parameter(Mandatory)][String]$MainVault
)

# Functions:
function Show-Info{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t=i=`t$Msg"}
function Show-Error{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t/!\`t$Msg" -ForegroundColor Yellow}

# Verifies the parameter
$MVInfo = Get-RDMVault -Name $MainVault
if(!$MVInfo){
    Show-Error "Invalid Main Vault : $MainVault"
    return
}

# Sets current location within the $MainVault
Set-RDMCurrntVault $MVInfo

# Recovers all existing cesisons
$Sessions = Get-RDMSession 
# Recovers all groups
$Groups = $Sessions | Where-Object{$_.Group -notmatch "\\"} | Select-Object Group -Unique 
# Recovers all existing repositories
$Repositories = Get-RDMVault

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
    Set-RDMCurrntVault $MVInfo
    try{
        # Recovers the information of the current cession
        # -DontChangeID  -->  Will move instead of copy the cession
        $Move = Copy-RDMSession -DontChangeID -IncludePasswordHistory -IncludeSubConnections -ErrorAction Stop
        # Recovers the new location's information based on the cession's name
        $NewVault = Get-RDMVault -Name $Session.Split("\")[0]
        # Moves into the new vault        
        Set-RDMCurrntVault $NewVault
        # Copies the cession over
        Set-RDMCession $Move
    }catch{
        Show-Error "Failed to move : $($Session.Group)"
    }
}

# Update the Remote desktop manager UI in order to show the changes
Update-RDMUI