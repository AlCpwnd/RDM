param(
    [Parameter(ParameterSetName='All',Mandatory)]
    [Parameter(ParameterSetName='Select',Mandatory)]
    [String]$SourceVault,

    [Parameter(ParameterSetName='Select',Mandatory)]
    [Array]$Folders,

    [Parameter(ParameterSetName='All',Mandatory)]
    [Switch]$All,

    [Parameter(ParameterSetName='All')]
    [Array]$Exceptions
)

#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

$LogFile = $PSCommandPath.Replace("ps1","txt")

# Functions #####################################

function show-info{
    param(
        [String]$Txt
    )
    $Time = Get-Date -Format HH:MM:ss
    $Message = "$Time`t$Txt"
    Write-Host $Message
    Add-Content $LogFile -Value $Message
}

function show-error{
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
    Set-RDMCurrentRepository $SourceVaultInfo
    Show-info "Moving to source vault"
}catch{
    show-error "Invalid source vault: $SourceVault"
    show-info "Exiting script"
    return
}

$Sessions = Get-RDMSession
show-info "$($Sessions.Count) sessions found"
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
if(!$All){
    $Selection = Compare-Object -ReferenceObject $RootFolders -DifferenceObject $Folders -IncludeEqual -ExcludeDifferent
    if(!$Selection){
        show-error "No corresponding folder found"
        show-info "Exiting script"
        return
    }
}
show-info "$($RootFolders.Count) rootfolders found"

$ExistingVaults = Get-RDMVault

# Vault creation
$NewVaults = (Compare-Object -ReferenceObject $ExistingVaults.Name -DifferenceObject $RootFolders | Where-Object{$_.SideIndicator -eq "=>"}).InputObject
show-info "$($NewVaults.Count) new vaults to be created"
foreach($NewVault in $NewVaults){
    try{
        New-RDMVault -Name $NewVault -IsAllowedOffline $true -SetRepository -ErrorAction Stop
        show-info "Created vault: $NewVault"
    }catch{
        show-error "Failed to create vault: $NewVault"
    }
}

# Sessions copy
show-info "Initiating session copy"
$i = 0
$iMax = $RootFolder.Count
foreach($RootFolder in $RootFolders){
    Write-Progress -Activity "Copying folders" -Status $RootFolder -Id 0 -PercentComplete (($i/$iMax)*100)
    $SubSessions = $Sessions | Where-Object{$_.Group -match $RootFolder}
    $j = 0
    $jMax = $SubSessions.Count
    try{
        $Copies = foreach($SubSession in $SubSessions){
            Write-Progress -Activity "Generating copies" -Status $SubSession.Name -Id 1 -PercentComplete (($j/$jMax)*100) -ParentId 0
            if($SubSession -eq $RootFolder){Continue}
            $Temp = Copy-RDMSession -PSConnection $SubSession -IncludePasswordHistory -ErrorAction Stop
            $Temp.Group = $Temp.Group.Replace($RootFolder,"")
            $Temp
        }
        $NewVaultInfo = Get-RDMRepository -Name $RootFolder
        Set-RDMCurrentRepository $NewVaultInfo -ErrorAction Stop
    }catch{
        show-error "Failed to copy sessions for $RootFolder"
        Continue
    }
    try{
        $Copies | ForEach-Object{New-RDMSession $_ -ErrorAction Stop}
    }catch{
        show-error "Failed to create copied sessions for $RootFolder"
        Continue
    }
}