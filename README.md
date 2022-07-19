# RDM
Remote Desktop Manger scripting tests

## Disclaimer
**This is a work in progress, use the script at your own risk and make sure to backup your database prior to running it!**

## Goal
The goal would be to create a script that splits a single DB into multiple ones based on the names of the first level of folders, moving all childitems into their respective DB.

## Todo:
1. Need to verify how `Get-RDMCurrentRepository` works when no RMD Instance is started. 
    - Might be able to remove line 20 completely
2. Verify the difference between `Set-RDMCurrentRepository` and `Set-RDMCurrentVault`
    - Update the script accordingly