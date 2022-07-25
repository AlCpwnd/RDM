# RDM
Remote Desktop Manger scripting tests

## Disclaimer
***This is a work in progress, use the script at your own risk and make sure to backup your database prior to running it!***

## Goal
The goal would be to create a script that splits a single DB into multiple ones based on the names of the first level of folders, moving all childitems into their respective DB.

## Description
The script will go over the contents of a vault and attempt to create a a new vault for each first degree subfolder, moving it's contents to the newly created folder.

## Requiirements
- Requires de the **RemoteDesktopManager** PowerShell module.
- You'll be expected to have the rights to create vaults and edit/move folders.

## Parameters
### MainVault
Vault from which the script will recover the subfolders and create vaults accordingly.