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

$FolderCopy = foreach($Folder in $Folders){
    $Copy = Copy-RDMSession -PSConnection $Folder -IncludePasswordHistory -IncludeSubConnections
    $Copy.Name = $Copy.Name.Replace($Copy.Group.Split("\")[0]
    $Copy.Group = $Copy.Group.Replace("Amazon","Amazon - copy")
    $Copy
}

$Report | ForEach-Object{Set-RDMSession $_}

$Entries = $Sessions | Where-Object{$_.ConnectionType -ne "Group" -and $_.Group -match "Amazon"}

$SessionsReport = foreach($Entry in $Entries){
    $Copy = Copy-RDMSession -PSConnection $Entry -IncludePasswordHistory -IncludeSubConnections
    $Copy.Group = $Copy.Group.Replace("Amazon","Amazon - copy")
    $Copy
}

$SessionsReport | ForEach-Object{Set-RDMSession $_}
