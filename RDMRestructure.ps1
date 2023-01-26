#Requires -Modules RemoteDesktopManager

<#=============================#>
<#==========Functions==========#>
<#=============================#>

function show-info{
    Param([Parameter(Mandatory,Position=0)][String]$txt)
    $Date = Get-Date -Format HH:mm:ss
    $Msg = "> $Date | $txt"
    if(!$Silent){Write-Host $Msg}
    if(!$DisableLogging){Add-Content -Path $LogPath -Value $Msg}
}

function show-error{
    Param([Parameter(Mandatory,Position=0)][String]$txt)
    $Inverted = @{
        ForegroundColor = $Host.UI.RawUI.BackgroundColor
        BackgroundColor = $Host.UI.RawUI.ForegroundColor
    }
    $Date = Get-Date -Format HH:mm:ss
    $Msg = "> $Date |ERROR| $txt"
    if(!$Silent){Write-Host $Msg @Inverted}
    if(!$DisableLogging){Add-Content -Path $LogPath -Value $Msg}
}

function show-banner{
    param(
        [Parameter(Mandatory)][String]$Title
    )
    $h,$v,$tlc,$trc,$blc,$brc = "═","║","╔","╗","╚","╝"
    $TitleLength = $Title.Length +2
    $Banner = @()
    $Banner += ''
    $Banner += "`t$tlc$($h * $TitleLength)$trc"
    $Banner += "`t$v $Title $v"
    $Banner += "`t$blc$($h * $TitleLength)$brc"
    $Banner += ''
    $Banner | ForEach-Object{Write-Host $_}
    $Banner | Out-File -FilePath $LogFile
}

function Test-Vault{
    param(
        [Parameter(Mandatory)][String]$Vault
    )
    try{
        $VaultInfo = Get-RDMVault -Name $Vault -ErrorAction Stop
        show-info "Data recovered for: $Vault"
    }catch{
        $VaultInfo = $false
    }
    return $VaultInfo
}

function DrawMenu{
    param($menuItems, $menuPosition, $Multiselect, $selection)
    $l = $menuItems.length
    for($i = 0; $i -le $l;$i++){
		if($null -ne $menuItems[$i]){
			$item = $menuItems[$i]
			if($Multiselect)
			{
				if($selection -contains $i){
					$item = '[x] ' + $item
				}
				else{
					$item = '[ ] ' + $item
				}
			}
			if($i -eq $menuPosition){
				Write-Host "> $($item)" -ForegroundColor Green
			}else{
				Write-Host "  $($item)"
			}
		}
    }
}

function Toggle-Selection{
	param($pos, [array]$selection)
	if($selection -contains $pos){ 
		$result = $selection | Where-Object{$_ -ne $pos}
	}
	else{
		$selection += $pos
		$result = $selection
	}
	$result
}

function Menu{
    param([array]$menuItems, [switch]$ReturnIndex=$false, [switch]$Multiselect)
    $vkeycode = 0
    $pos = 0
    $selection = @()
    if($menuItems.Length -gt 0)
	{
		try{
			[console]::CursorVisible=$false #prevents cursor flickering
			DrawMenu $menuItems $pos $Multiselect $selection
			While($vkeycode -ne 13 -and $vkeycode -ne 27){
				$press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
				$vkeycode = $press.virtualkeycode
				If($vkeycode -eq 38 -or $press.Character -eq 'k'){$pos--}
				If($vkeycode -eq 40 -or $press.Character -eq 'j'){$pos++}
				If($vkeycode -eq 36){ $pos = 0 }
				If($vkeycode -eq 35){ $pos = $menuItems.length - 1 }
				If($press.Character -eq ' '){ $selection = Toggle-Selection $pos $selection }
				if($pos -lt 0){$pos = 0}
				If($vkeycode -eq 27){$pos = $null }
				if($pos -ge $menuItems.length){$pos = $menuItems.length -1}
				if($vkeycode -ne 27)
				{
					$startPos = [System.Console]::CursorTop - $menuItems.Length
					[System.Console]::SetCursorPosition(0, $startPos)
					DrawMenu $menuItems $pos $Multiselect $selection
				}
			}
		}
		finally{
			[System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
			[console]::CursorVisible = $true
		}
	}
	else{
		$pos = $null
	}

    if($ReturnIndex -eq $false -and $null -ne $pos)
	{
		if($Multiselect){
			return $menuItems[$selection]
		}
		else{
			return $menuItems[$pos]
		}
	}
	else 
	{
		if($Multiselect){
			return $selection
		}
		else{
			return $pos
		}
	}
}

<#=============================#>
<#===========Script============#>
<#=============================#>

$LogFile = "$(Get-Date -Format yyyyMMdd)_RDMMigrate_Logs.txt"
$LogPath = "$PSScriptRoot\$LogFile"

show-info "Script intiating..."
show-info "Logfile: $LogPath"
Write-host ''
show-info "Recovering vaults."
try{
    $Vaults = Get-RDMRepository -ErrorAction Stop
}catch{
    show-error "Couldn't recover the existing vaults. Exiting"
    return
}

$SVInfo = $false

while(!$SVInfo){
	switch(menu "List existing vaults","Enter the vault Name from the source vault","/!\Quit"){
		"List existing vaults"{$Vaults.Name}
		"Enter the vault Name from the source vault"{$SourceVault = Read-Host -Prompt "Vault Name:"}
		"/!\Quit" {return}
	}
	$SVInfo = Test-Vault -Vault $SourceVault
}

