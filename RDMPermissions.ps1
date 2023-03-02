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
$TVSessions = Get-RDMSession | Where-Object{$_.ConnectionType -eq "Group"}
$Exceptions = $TemplateVaultInfo

show-info "Recovering target vault(s) information"
if($Select){
    $TargetVaults = foreach($Vault in $Select){
        try{
            Get-RDMRepository -Name $Vault -ErrorAction Stop
        }catch{
            show-error "Invalid selection."
            show-error "Couldn't find vault: $Vault"
            show-error "Exiting script"
            return
        }
    }
}else{
    $TargetVaults = Get-RDMRepository
    if($Exceptions){
        show-info "Recovering exception vault(s) information"
        $ExceptionVaults += foreach($Vault in $Exceptions){
            try{
                Get-RDMRepository -Name $Vault -ErrorAction Stop
            }catch{
                show-error "Invalid selection."
                show-error "Couldn't find vault exception: $Vault"
                show-error "Exiting script"
                return
            }
        }
    }
}

foreach($Vault in $TargetVaults){
    if($ExceptionVaults -contains $Vault){
        Continue
    }
    Set-RDMCurrentRepository -Repository $Vault
    # Defining root folder permissions
    $RootSession = Get-RDMRootSession
    $RootSession.Security.PSobject.Properties.Name | ForEach-Object{$RootSession.Security.$_ = $TVRootSession.Security.$_}
    Set-RDMRootSession $RootSession
    # Defining other folders permissions
    $Sessions = Get-RDMSession | Where-Object{$_.ConnectionType -eq "Group"}
    foreach($Session in $Sessions){
        if($Session.Group -eq $Session.Name){ # First level folders
            if($TVSessions.Name -contains $Session.Name){ # Corresponding template folder
                $Index = $TVSessions.Name.IndexOf($($Session.Name))
                $TVSessions[$Index].Security.PSobject.Properties.Name | ForEach-Object{$Session.Security.$_ = $TVSession[$Index].Security.$_}
            }
        }
    }
}