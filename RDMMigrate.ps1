param(
    [Parameter(Mandatory,ParameterSetName="Logging")][Parameter(Mandatory,ParameterSetName="Default")][String]$MainVault,
    [Parameter(Mandatory,ParameterSetName="Logging")][Switch]$Log,
    [Parameter(ParameterSetName="Logging")][String]$Path,
    [Parameter(ParameterSetName="Default")][Parameter(ParameterSetName="Loggin")][Switch]$Silent
)

#Requires -Module RemoteDesktopManager

$Global:LogBuffer = @()

#===========#
# Functions #
#===========#

function Show-Status{
    param(
        [Parameter(Mandatory,Position=0)][ValidateSet("info","error","warning")]$Type,
        [Parameter(Mandatory,Position=1)][String]$Message
    )
    $Date = Get-Date -Format HH:mm:ss
    switch($Type){
        "info" {$Parameters = @{Object = "$Date (i) $Message"}}
        "warning" {$Parameters = @{Object = "$Date /!\ $Message";ForegroundColor = "Yellow"}}
        "error" {$Parameters = @{Object = "$Date [!] $Message";ForegroundColor = "Red"}}
    }
    if($Log){
        if(!$LogPath){
            $Global:LogBuffer += $Parameters.Object
        }else{
            Add-Content -Path $LogPath -Value $Parameters.Object -ErrorAction SilentlyContinue
        }
    }
    if(!$Silent){Write-Host @Parameters}
}


#=================#
# Security Checks #
#=================#

Show-Status info "Initiating script"
Show-Status info "Verifying parameters"

if($Log){
    if($Path){
        if(Test-Path -Path $Path -PathType Container){
            $Path += "\$(Get-Date -Format yyyyMMdd)_RDMMigrate_Logs.txt"
            $LogPath = $Path.Replace("\\","\")
        }elseif(Test-Path -Path $Path -PathType Leaf){
            $LogPath = $Path
        }else{
            Show-Status error "Invalid log path: $Path"
            return
        }
    }else{
        $LogPath = "$PSScriptRoot\$(Get-Date -Format yyyyMMdd)_RDMMigrate_Logs.txt"
    }
    Show-Status info "Loggin enabled"
    Show-Status info "Logfile path: $LogPath"
    if($LogBuffer){
        $LogBuffer | ForEach-Object{Add-Content -Path $LogPath -Value $_}
    }
}

Show-Status info "Verifying variables"

# Verifies the parameter
try{
    $MVInfo = Get-RDMVault -Name $MainVault
    Show-Status info "Main Vault defined as : $($MVInfo.Name)"
}catch{
    Show-Status error "Invalid Main Vault : $MainVault"
    return
}

# Sets current location within the $MainVault
Set-RDMCurrentVault $MVInfo


#=====================#
# Variable Definition #
#=====================#

# Verifies if the Remote Desktop Manager client is running
if(Get-Process | Where-Object{$_.Name -match "RemoteDesktopManager"}){$ClientRunning = $true}

# Recovers all existing sessions
$Entries = Get-RDMSession
Show-Status info "$($Entries.Count) Entries found."

# Seperates the main groups
$MainGroups = ($Entries | Where-Object{$_.Group -eq $_.Name -and $_.ConnectionType -eq "Group"} | Select-Object Group -Unique).Group
Show-Status info "$($MainGroups.Count) MainGroups found."

# Lists all the subfolders
$Folders = $Entries | Where-Object{$_.ConnectionType -eq "Group" -and $_.Group -match "\\"} | Sort-Object Group

# Lists all the remaining sessions
$Sessions = $Entries | Where-Object{$_.ConnectionType -ne "Group"} | Sort-Object Group

# Recovers all existing repositories
$Repositories = Get-RDMVault


#========#
# Script #
#========#

# Start Vault check/creation
foreach($Group in $MainGroups){
    if($Repositories.Name -contains $Group){
        Show-Status warning "Existing vault found for : $Group _Skipping_"
        Continue
    }
    $Parameters = @{Name = $Group}
    $Vault = New-RDMVault @Parameters
    Set-RDMVault $Vault
    Show-Status info "Created vault : $Group"
}
# End Vault check/creation

if($ClientRunning){Update-RDMUI}

# Update vaults after creation
$Repositories = Get-RDMRepository

# Start folder ceation
foreach($MGroup in $MainGroups){
    Show-Status info "Attempting to recreate folder structure for : $MGroup"
    $GroupFolders = $Folders | Where-Object{$_.Group -like "$MGroup\*"}
    $FolderCreation = foreach($Folder in $GroupFolders){
        $Copy = Copy-RDMSession $Folder -IncludePasswordHistory -IncludeSubConnections
        $Copy.Group = $Copy.Group.Replace("$MGroup\","") # New vault doesn't have the first folder level structure
        $Copy
    }
    Show-Status info "$($FolderCreation.Count) folder(s) found"
    Show-Status info "Moving to vault: $MGroup"
    Set-RDMCurrentRepository (Get-RDMRepository -Name $MGroup)
    $ExistingFolders = Get-RDMSession -ErrorAction SilentlyContinue | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}
    foreach($Folder in $FolderCreation){
        $Test = $ExistingFolders | Where-Object{$Folder.Name -eq $_.Name -and $Folder.Group -eq $_.Group}
        if($Test){
            Show-Status warning "Existing corresponding entry found for folder: $($Folder.Name) _Skipping_"
            continue
        }
        Set-RDMSession $Folder
        Show-Status info "Created folder: $($Folder.Name)"
    }
    Show-Status info "Folders created for: $MGroup"
    Set-RDMCurrentRepository $MVInfo
}
# End folder creation

if($ClientRunning){Update-RDMUI}

# Start session creation
foreach($MGroup in $MainGroups){
    Show-Status info "Attempting to recreate sessions for : $MGroup"
    $GroupSessions = $Sessions | Where-Object{$_.Group -cmatch "$MGroup"}
    $SessionCreation = foreach($Session in $GroupSessions){
        $Copy = Copy-RDMSession $Session -IncludePasswordHistory -IncludeSubConnections
        if($Copy.Group -eq $MGroup){
            $Copy.Group = ""
        }else{
            $Copy.Group = $Copy.Group.Replace("$MGroup\","") # New vault doesn't have the first folder level structure
        }
        $Copy
    }
    Show-Status info "$($SessionCreation.Count) session(s) to be created"
    Set-RDMCurrentRepository (Get-RDMRepository -Name $MGroup)
    Show-Status info "Moving to vault: $MGroup"
    $ExistingSessions = Get-RDMSession -ErrorAction SilentlyContinue | Where-Object{$_.ConnectionType -ne "Group"}
    foreach($Session in $SessionCreation){
        $Test = $ExistingSessions | Where-Object{$Session.Name -eq $_.Name -and $Session.Group -eq $_.Group}
        if($Test){
            Show-Status warning "Existing corresponding entry found for session: $($Session.Name) _Skipping_"
            continue
        }
        Set-RDMSession $Session
        Show-Status info "Created session: $($Session.Name)"
    }
    Show-Status info "Sessions created for : $MGroup"
    Set-RDMCurrentRepository $MVInfo
}
# End session creation

if($ClientRunning){Update-RDMUI}