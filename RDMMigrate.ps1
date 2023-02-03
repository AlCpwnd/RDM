param(
    [String]$SourceVault,
    [Array]$Folders,
    [Array]$Excaptions
)

#Requires -Modules RemoteDesktopManager

$LogFile = $PSCommandPath.Replace("ps1","txt")

# Functions #####################################

show-info{
    param(
        [String]$Txt
    )
    $Time = Get-Date -Format HH:MM:ss
    $Message = "$Time`t$Txt"
    Write-Host $Message
    Add-Content $LogFile -Value $Message
}

show-error{
    param(
        [String]$Txt
    )
    $Time = Get-Date -Format HH:MM:ss
    $Message = "$Time`t[ERROR]$Txt"
    Write-Host $Message
    Add-Content $LogFile -Value $Message
}

# Script ########################################

show-info "Initiating script"
try{
    $SourceVaultInfo = Get-RDMVault -Name $SourceVault -ErrorAction Stop
    show-info "Source vault defined: $($SourceVaultInfo.Name)"
}catch{
    show-error "Invalid source vault: $SourceVault"
    show-info "Exiting script"
    return
}

$Sessions = Get-RDMSession
show-info "$($Sessions.Count) sessions found"
$RootFolders = $Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}
show-info "$($RootFolders.Count) rootfolders found"

$ExistingVaults = Get-RDMVault

# Vault creation
$NewVaults = (Compare-Object -ReferenceObject $ExistingVaults.Name -DifferenceObject $RootFolders.Name | Where-Object{$_.SideIndicator -eq "=>"}).InputObject
show-info "$($NewVaults.Count) new vaults to be created"
foreach($NewVault in $NewVaults){
    try{
        New-RDMVault -Name $NewVault -IsAllowedOffline $true -SetRepository -ErrorAction Stop
        show-info "Created vault: $NewVault"
    }catch{
        show-error "Failed to create vault: $NewVault"
    }
}

