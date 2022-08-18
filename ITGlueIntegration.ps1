#Requires -Modules ITGlueAPI,RemoteDesktopManager

$Accounts = Get-ITGlueOrganizations -

$Companies = Get-RDMRepository

