param(
    [Parameter(ParameterSetName='All',Mandatory)]
    [Parameter(ParameterSetName='Select',Mandatory)]
    [String]$TemplateVault,

    [Parameter(ParameterSetName='Select',Mandatory)]
    [Array]$Vaults,

    [Parameter(ParameterSetName='All',Mandatory)]
    [Switch]$All,

    [Parameter(ParameterSetName='All')]
    [Array]$Exceptions
)

#Requires -Modules @{ModuleName="RemoteDesktopManager"; ModuleVersion="2022.3.1.2"} -Version 7

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

try{
    show-info "Recovering template vault"
    $TemplateVaultInfo = Get-RDMRepository -Name $TemplateVault -ErrorAction Stop
}catch{
    show-error "Failed to recover vault information for $TemplateVault"
    show-error "Exiting script."
    return
}

show-info "Recovering template vault contents"
Set-RDMCurrentRepository -Repository $TemplateVaultInfo

# From this point on template vault variables will 
# be '$TV<Variable' as to improve readability.

$TVRootSession = Get-RDMRootSession
$TVSessions = Get-RDMSession

