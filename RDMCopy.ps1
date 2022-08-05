param(
    [String]$MainRepository = "Old BKM",
    [String]$Company
)

if(!$MainRepository){$MainRepository = "Old BKM"}

$MRInfo = Get-RDMRepository -Name $MainRepository

# Verifies we're in the MainRepository
if((Get-RDMCurrentRepository) -ne $MRInfo){Set-RDMCurrentRepository $MRInfo}

# Lists the sessions depending if a Company was mentionned
if($Company){
    $Sessions = Get-RDMSession | Where-Object{$_.Group -like "$Company\*"}
}else{
    $Sessions = Get-RDMSession
}

$Folders = $Sessions | Where-Object{$_.ConnectionType -eq "Group"}

# Generates the folder information that need to be copied over
$FolderCopy = foreach($Folder in $Folders){
    $Copy = Copy-RDMSession -PSConnection $Folder -IncludePasswordHistory -IncludeSubConnections
    $Copy.Group = $Copy.Group.Replace("$($Copy.Group.Split("\")[0])\","")
    $Copy
}
# Moves over to the requested vault and creates the folders
$DestinationVault = Get-RDMRepository -Name $Company
Set-RDMCurrentRepository $DestinationVault
$FolderCopy | ForEach-Object{Set-RDMSession $_}

# Updates the UI to reflect the changes
Update-RDMUI

# Returns to the main vault
Set-RDMCurrentRepository $MRInfo

$Entries = $Sessions | Where-Object{$_.ConnectionType -ne "Group" -and $_.Group -match "Amazon\\"}

$SessionsReport = foreach($Entry in $Entries){
    $Copy = Copy-RDMSession -PSConnection $Entry -IncludePasswordHistory -IncludeSubConnections
    $Copy.Group = $Copy.Group.Replace("Amazon\","")
    $Copy
}

$SessionsReport | ForEach-Object{Set-RDMSession $_}
