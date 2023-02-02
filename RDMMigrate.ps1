param(
    [String]$SourceVault,
    [String]$TemplateVault
)

#Requires -Modules RemoteDesktopManager

$LogFile = $PSCommandPath.Replace("ps1","txt")

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

show-info "Initiating script"
try{
    $SourceVaultInfo = Get-RDMVault -Name $SourceVault -ErrorAction Stop
    show-info "Source vault defined: $($SourceVaultInfo.Name)"
}catch{
    show-error "Invalid source vault: $SourceVault"
    show-info "Exiting script"
    return
}

try{
    $TemplateVaultInfo = Get-RDMVault -Name $TemplateVault -ErrorAction Stop
    show-info "Template vault defined: $($TemplateVaultInfo.Name)"
}catch{
    show-error "Invalid template vault: $TemplateVault"
    show-info "Exiting script"
    return
}

show-info "Recovering template information"
Set-RDMCurrentVault $TemplateVaultInfo
$TemplateSessions = Get-RDMSession
$TemplateRootFolders = $TemplateSessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}

$Sessions = Get-RDMSession
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

