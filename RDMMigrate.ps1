#Requires -Module RemoteDesktopManager

# Functions:
function Show-Info{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t=i=`t$Msg"}
function Show-Error{param([String]$Msg)Write-host "$(Get-Date -f HH:mm:ss)`t/!\`t$Msg" -ForegroundColor Yellow}


# Connects to the Database configuration
Start-RDMInstance

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