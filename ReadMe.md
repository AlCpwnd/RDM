# RDM Migration

This document goes over the various steps needed to split up the current RDM 'Default' vault. As well as a few requests in order to better find information within the new infrastructure.

> Scripts containing the code snippets below as well as the required run parameters van be found in the [scripts](/scripts/).

## Requests:
1. [ ] ItGlue integration: make an ItGlue credential entry within each new vault.
2. [ ] Exact ID integration: reference the internal Exact ID for all clients.

## Migration

### Preperation
Put all existing 'Credential' folders in read only. This should push users towards using the ItGlue link.
[CredentialsReadOnlye.ps1](/scripts/CredentialsReadOnly.ps1)

```ps
# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Name 'Template_Vault')
$TemplateCred = Get-RDMSession -Name Credentials
# Recovering existing Credentials folders.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Name 'Default')
$CredentialFolders = Get-RDMSession -Name Credentials | Where-Object{$_.ConnectionType -eq 'Group'}

# Replacing permissions with the template one.
$Properties = $TemplateCred.Security.PSObject.Properties
foreach($Folder in $CredentialFolders){
    $Properties | foreach{$Folder.Security.$($_.Name) = $_.Value}
    Set-RDMSession $Folder
    Write-Host "Done: $($Folder.Group)"
}
```

### Execution

#### Vault Creation
Creates a vault for each client.
[CreateVaults.ps1](/scripts/CreateVaults.ps1)

```ps
# Recovering clients from the Default vault.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$RootFolders = (Get-RDMSession | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name

# Creating the Vaults.
foreach($RFolder in $RootFolders){
    $Repository = New-RDMRepository -Name $RFolder.Name
    Set-RDMRepository $Repository
    Write-Host "Created: $($RFoldere.Name)"
}
```

#### Defining Root folder permissions
Recovers the rootfolder permissions and applies it to the folders.
[RootFolderPermissions.ps1](/scripts/RootFolderPermission.ps1)

```ps
# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$RootTemplate = Get-RDMRootSession

# Recovering existing vaults.
$Properties = $RootTemplate.Security.PSObject.Properties
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    Set-RDMCurrentRepository $Vault
    $RootFolder = Get-RDMRootSession
    $Properties | foreach{$RootFolder.Security.$($_.Name) = $_.Value}
    Set-RDMRootSession $RootFolder
    Write-Host "Rooltfolder permissions defined for $($Vault.Name)"
}
```

#### Recreating folder structure
Recreates the existing folder structure in the newly created ones.
[CopyFolderStructure.ps1](/scripts/CopyFolderStructure.ps1)

```ps
# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$Folders = $Sessions | Where-Object{$_.ConnectionType -eq "Group" -and $RootFolders -notcontains $_.Name}

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    $ToCopy = $Folders | Where-Object{$_.Group -match "$RFolder\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        $Temp = Copy-RDMSession $Session
        $Temp.Group = $Temp.Group.Replace("$RFolder\",'')
        $Temp
    }

    # Moving to the vault.
    Set-RDMCurrentRepository $(Get-RDMRepository -Name $RFolder)

    # Creating the folder structure.
    $Copy | Foreach{New-RDMSession $_}
    Write-Host "$($Copy.Count) folder(s) created."
    Write-Host "Folders copied for: $RFolder"
}
```

#### Copying over the sessions
It is highly recommended that all users leave the application prior to running the code below. If a user has one of the sessions open or is editing the sessions while it's being copied, it might abort the operation for the session in question.
[CopySessions.ps1](/scripts/CopySessions.ps1)

```ps
# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$SessionsToBeCopied = $Sessions | Where-Object{$_.ConnectionType -ne "Group" -and $RootFolders -notcontains $_.Name}

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    $ToCopy = $SessionsToBeCopied | Where-Object{$_.Group -match "$RFolder\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        $Temp = Copy-RDMSession $Session
        $Temp.Group = $Temp.Group.Replace("$RFolder\",'')
        $Temp
    }

    # Moving to the vault.
    Set-RDMCurrentRepository $(Get-RDMRepository -Name $RFolder)

    # Creating the folder structure.
    $Copy | ForEach-Object{New-RDMSession $_}
    Write-Host "$($Copy.Count) sessions(s) created."
    Write-Host "Sessions copied for: $RFolder"
}
```