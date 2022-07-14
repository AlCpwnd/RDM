#Requires -Module RemoteDesktopManager

# Connects to the Database configuration
Start-RDMInstance

# Recovers all existing cesisons
$Sessions = Get-RDMSession 
# Recovers all groups
$Groups = $Sessions | Where-Object{$_.Group -notmatch "\\"} | Select-Object Group -Unique 
# Recovers all existing repositories
$Repositories = Get-RDMRepository