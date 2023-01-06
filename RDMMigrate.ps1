param(
    [Parameter(Mandatory)]
    [String]$SourceVault,

    [Parameter()]
    [String]$TemplateVault,

    [ValidateRange(1, [int]::MaxValue)]
    [Parameter()]
    [Int]$BatchSize,

    [Parameter()]
    [Array]$Exceptions,

    [Parameter()]
    [Switch]$Silent,

    [Parameter()]
    [Switch]$DisableLogging
)

#Requires -Module RemoteDesktopManager

<#=============================#>
<#==========Functions==========#>
<#=============================#>

function show-info{
    Param([Parameter(Mandatory,Position=0)][String]$txt)
    $Date = Get-Date -Format HH:mm:ss
    $Msg = "> $Date | $txt"
    if(!$Silent){Write-Host $Msg}
    if(!$DisableLogging){Add-Content -Path $LogPath -Value $Msg}
}

$Inverted = @(
    ForegroundColor = $Host.UI.RawUI.BackgroundColor
    BackgroundColor = $Host.UI.RawUI.ForegroundColor
)

function show-error{
    Param([Parameter(Mandatory,Position=0)][String]$txt)
    $Date = Get-Date -Format HH:mm:ss
    if(!$Silent){Write-Host "> $Date | $txt" @Inverted}
    if(!$DisableLogging){Add-Content -Path $LogPath -Value $Msg}
}

function show-banner{
    $Banner = @()
    $Banner += ''
    $Banner += "`tRDMMigrate.ps1"
    $Banner += ''
    $Banner += "`tParameters:"
    $Banner += "`t> SourceVault : $($MVInfo.Name)"
    $Banner += "`t> LogFile : $LogPath"
    $Banner += "`t> Silent Mode : $(if($Silent){"Enabled"}else{"Disabled"})"
}

function Test-Vault{
    param(
        [Parameter(Mandatory)][String]$Vault
    )
    try{
        $VaultInfo = Get-RDMVault -Name "$Vault" -ErrorAction Stop
        show-info ""
    }catch{
        $VaultInfo = $false
    }
    return $VaultInfo
}

<#=============================#>
<#====Variable verification====#>
<#=============================#>

$LogFile = "$(Get-Date -Format yyyyMMdd)_RDMMigrate_Logs.txt"
$LogPath = "$PSScriptRoot\$LogFile"

# Verifies the source vault
$MVInfo = Test-Vault $SourceVault
if(!$MVInfo){
    show-error "Invalid source vault. Aborting script"
    return
}

# Verifies the template vault if given
if($TemplateVault){
    $TVInfo = Test-Vault $TemplateVault
    show-info "Template vault : $($TVInfo.Name)"
    if(!$TVInfo){
        show-error "Invalid template vault. Aborting script"
        return
    }
}

# Verifies the exceptions
if($Exceptions){
    $EXCVault = foreach($Exc in $Exceptions){
        $test = Test-Vault $Exc
        if(!$test){
            show-error "Invalid exception : $Exc . Aborting script"
            return
        }else{
            $i
        }        
    }
}

# Verifies if the Remote Desktop Manager client is running
if(Get-Process | Where-Object{$_.Name -match "RemoteDesktopManager"}){$ClientRunning = $true}

<#==============================#>
<#=====Variable Definition======#>
<#==============================#>

# Recovers all existing sessions
Set-RDMCurrentRepository $MVInfo
if($Exception){
    $Entries = Get-RDMSession | Where-Object{$_.Group -notmatch ($EXCVault.Name -join '|')}
    show-info "$($EXCVault.Count) Exceptions given."
    show-info "$($Entries.Count) Entries found."
}else{
    $Entries = Get-RDMSession
    show-info "$($Entries.Count) Entries found."
}

# Seperates the main groups
$MainGroups = ($Entries | Where-Object{$_.Group -eq $_.Name -and $_.ConnectionType -eq "Group"} | Select-Object Group -Unique).Group
show-info "$($MainGroups.Count) MainGroups found."

# Lists all the subfolders
$Folders = $Entries | Where-Object{$_.ConnectionType -eq "Group" -and $_.Group -match "\\"} | Sort-Object Group

# Lists all the remaining sessions
$Sessions = $Entries | Where-Object{$_.ConnectionType -ne "Group"} | Sort-Object Group

# Recovers all existing repositories
$Repositories = Get-RDMVault


<#==============================#>
<#============Script============#>
<#==============================#>

# Start Vault check/creation
foreach($Group in $MainGroups){
    if($Repositories.Name -contains $Group){
        Show-Status warning "Existing vault found for : $Group _Skipping_"
        Continue
    }
    $Parameters = @{Name = $Group}
    $Vault = New-RDMVault @Parameters
    Set-RDMVault $Vault
    show-info "Created vault : $Group"
}
# End Vault check/creation

if($ClientRunning){Update-RDMUI}

# Update vaultsafter creation
$Repositories = Get-RDMRepository

# Start folder ceation
foreach($MGroup in $MainGroups){
    show-info "Attempting to recreate folder structure for : $MGroup"
    $GroupFolders = $Folders | Where-Object{$_.Group -like "$MGroup\*"}
    $FolderCreation = foreach($Folder in $GroupFolders){
        $Copy = Copy-RDMSession $Folder -IncludePasswordHistory -IncludeSubConnections
        $Copy.Group = $Copy.Group.Replace("$MGroup\","") # New vault doesn't have the first folder level structure
        $Copy
    }
    show-info "$($FolderCreation.Count) folder(s) found"
    show-info "Moving to vault: $MGroup"
    Set-RDMCurrentRepository (Get-RDMRepository -Name $MGroup)
    $ExistingFolders = Get-RDMSession -ErrorAction SilentlyContinue | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}
    foreach($Folder in $FolderCreation){
        $Test = $ExistingFolders | Where-Object{$Folder.Name -eq $_.Name -and $Folder.Group -eq $_.Group}
        if($Test){
            Show-Status warning "Existing corresponding entry found for folder: $($Folder.Name) _Skipping_"
            continue
        }
        Set-RDMSession $Folder
        show-info "Created folder: $($Folder.Name)"
    }
    show-info "Folders created for: $MGroup"
    Set-RDMCurrentRepository $MVInfo
}
# End folder creation

if($ClientRunning){Update-RDMUI}

# Start session creation
foreach($MGroup in $MainGroups){
    show-info "Attempting to recreate sessions for : $MGroup"
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
    show-info "$($SessionCreation.Count) session(s) to be created"
    Set-RDMCurrentRepository (Get-RDMRepository -Name $MGroup)
    show-info "Moving to vault: $MGroup"
    $ExistingSessions = Get-RDMSession -ErrorAction SilentlyContinue | Where-Object{$_.ConnectionType -ne "Group"}
    foreach($Session in $SessionCreation){
        $Test = $ExistingSessions | Where-Object{$Session.Name -eq $_.Name -and $Session.Group -eq $_.Group}
        if($Test){
            Show-Status warning "Existing corresponding entry found for session: $($Session.Name) _Skipping_"
            continue
        }
        Set-RDMSession $Session
        show-info "Created session: $($Session.Name)"
    }
    show-info "Sessions created for : $MGroup"
    Set-RDMCurrentRepository $MVInfo
}
# End session creation

if($ClientRunning){Update-RDMUI}
