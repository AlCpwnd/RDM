# RDM Migration

This document goes over the various steps needed to split up the current RDM 'Default' vault. As well as a few requests in order to better find information within the new infrastructure.

> Scripts containing the code snippets below as well as the required run parameters van be found in the [scripts](/scripts/).


## Migration

### Preperation

#### Verify that existing folders have permission inheritance enabled
Going over the cessions within a vault and verifying that no folders have custom permissions.

[EnableInheritance.ps1](/scripts/EnableInheritance.ps1)

```ps
# Recovering sessions who don't have inheritance enabled
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession | Where-Object{$_.Security.RoleOverride -ne 'Default'}

# Enabling inheritance on the found sessions
foreach($Session in $Sessions){
    $Session.Security.RoleOverride = 'Default'
    Set-RDMSession $Session
    Write-Host "Done: $($Session.group)"
}
```

#### Set existing credental folders to Read Only
Put all existing 'Credential' folders in read only. This should push users towards using the ItGlue link.

[CredentialsReadOnlye.ps1](/scripts/CredentialsReadOnly.ps1)

```ps
# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$TemplateCred = Get-RDMSession -Name Credentials

# Recovering existing Credentials folders.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$CredentialFolders = Get-RDMSession -Name Credentials | Where-Object{$_.ConnectionType -eq 'Group'}

# Replacing permissions with the template one.
$Properties = $TemplateCred.Security.PSObject.Properties
foreach($Folder in $CredentialFolders){
    $Properties | ForEach-Object{$Folder.Security.$($_.Name) = $_.Value}
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
    $Repository = New-RDMRepository -Name $RFolder
    Set-RDMRepository $Repository
    Write-Host "Created: $RFolder"
}
```

#### Defining Root folder permissions
Recovers the rootfolder permissions and applies it to the folders.

[RootFolderPermissions.ps1](/scripts/RootFolderPermission.ps1)

```ps
# Recovering the template's permissions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$RootTemplate = Get-RDMRootSession
$Properties = $RootTemplate.Security.PSObject.Properties

# Recovering existing vaults.
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    # Moving to the concerned vault.
    Set-RDMCurrentRepository $Vault

    # Applying the permissions on the root folder.
    $RootFolder = Get-RDMRootSession
    $Properties | ForEach-Object{$RootFolder.Security.$($_.Name) = $_.Value}
    Set-RDMRootSession $RootFolder
    Write-Host "Rooltfolder permissions defined for $($Vault.Name)"
}
```

#### Recreating folder structure (**Deprecated**)
> This script has been moved to the 'Old' folder. It has been totally replaced with the `Move-RDMSession` command.

Recreates the existing folder structure in the newly created ones.

[CopyFolderStructure.ps1](/scripts/Old/CopyFolderStructure.ps1)

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
    $Copy | Foreach{Set-RDMSession $_}
    Write-Host "$($Copy.Count) folder(s) created."
    Write-Host "Folders copied for: $RFolder"
}
```

#### Copying over the sessions
It is highly recommended that all users leave the application prior to running the code below. If a user has one of the sessions open or is editing the sessions while it's being copied, it might abort the operation for the session in question.
> During testing moving entries to 300 different vaults caused the database to become unresponsive and no longer allow authentication. This was resolved by restarting the host and no changes were lost. But if you're planning a big migration of 250+ vaults, I would recommend splitting it up.

[CopySessions.ps1](/scripts/CopySessions.ps1)

```ps
# Recovering sessions.
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$RootFolders = ($Sessions | Where-Object{$_.Name -eq $_.Group -and $_.ConnectionType -eq "Group"}).Name
$ToBeCopied = $Sessions | Where-Object{$RootFolders -notcontains $_.Name -or $_.ConnectionType -ne 'Group'}

$i = 0
$iMax = $RootFolders.Count

# Sorting through the folders.
foreach($RFolder in $RootFolders){
    Write-Progress -Activity "Moving sessions [$i/$iMax]" -Status $RFolder -PercentComplete (($i/$iMax)*100)
    $ToCopy = $ToBeCopied | Where-Object{($_.Group -like "$RFolder\*" -or $_.Group -eq $RFolder) -and $_.Group -notmatch "$RFolder\\.+\\"}

    # Preparing the sessions for copy.
    $Copy = foreach($Session in $ToCopy){
        if($Session.Group -eq $RFolder){
            $Session.Group = ""
            $Session
        }elseif($Session.ConnectionType -eq 'Group'){
            $Session.Group = $Session.Group.Replace("$RFolder\",'')
            $Session
        }
    }

    # Recovering the destination vault
    $Vault = Get-RDMRepository -Name $RFolder

    # Moving entries to the vault
    $Copy | ForEach-Object{Move-RDMSession -InputObject $_ -ToVaultID $Vault.ID}
    Write-Host "$($ToCopy.Count) sessions(s) moved."
    Write-Host "Sessions moved for: $RFolder"
    $i++
}
```

## Requests

### ItGlue entry creation

#### Within each vault
Creates a copy of an existing ItGlue entry into each vault.

[ItGlueEntry.ps1](/scripts/ItGlueEntry_Vaults.ps1)

```ps
# Recovering the default ItGlue entry
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$ItGlue = Get-Session -Name 'It Glue'

# Recreating the entry in each repository
$Vaults = Get-RDMRepository
foreach($Vault in $Vaults){
    Set-RDMCurrentRepository $Vault
    $Test = Get-RDMSession | Where-Object{$_.Credentials.ITGlueSafeApiKey -ne $null -and $_.ConnectionType -eq  'Credential'}
    if(!$Test){
        $CredEntry = Copy-RDMSession $ItGlue
        Set-RDMSession $CredEntry
        Write-Host "Created ItGlue entry $($Vault.Name)"
    }else{
        Write-Host "Present for $($Vault.Name)"
    }
}
```

#### Within each existing folder
Create an ItGlue entry within each 'subfolder'.
[ItGLueEntry_Folder.ps1](/scripts/ItGlueEntry_Folder.ps1)

```ps
# Recovering the default ItGlue entry
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Template_Vault')
$ItGlue = Get-RDMSession -Name 'IT Glue [To be configured]'

# Recovering existing credential entries
Set-RDMCurrentRepository (Get-RDMRepository -Name 'Default')
$Sessions = Get-RDMSession
$Folders = $Sessions | Where-Object{$_.ConnectionType -eq 'Group' -and $_.Name -eq $_.Group}

# Verifying if ItGlue credentials already exist
$ExistingCredentials = ($Sessions | Where-Object{$_.ConnectionType -eq 'Credential' -and $_.Credentials.ITGlueSafeApiKey}).Group
foreach($Folder in $Folders){
    $Test = $ExistingCredentials | Where-Object{$_ -match $Folder.Name}
    if(!$Test){
        # Creating the entry
        $ItGl = Copy-RDMSession $ItGlue
        $ItGl.Group = $Folder.Group
        # Adding mark in order to note further configuration
        $ItGl.Name = "$($Folder.Name) [To be configured]"
        Set-RDMSession $ItGl
        Write-Host "Session created for: $($Folder.Name)"
    }
}
```

## Reporting
Creates a reort of existing vauls and their description.
[VaultReport.ps1](/scripts/VaultReport.ps1)

```ps
# Recovering existing vaults
$Vaults = Get-RDMRepository | Select-Object ID,Name,Description

# Preparing filename for report
$Date = Get-Date -Format 'yyyyMMdd'
$FileName = "$PSScriptRoot\$Date`_VaultReport.csv"

# File Export
$Vaults | Export-Csv -Path $FileName -Delimiter ';' -NoTypeInformation -Encoding unicode
Write-Host "File generated: $FileName"
```