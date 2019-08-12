[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') 

$file_content = get-content "C:\Windows\Temp\domainjoin\config.ini"
$file_content = $file_content -join [Environment]::NewLine
$configuration = ConvertFrom-StringData($file_content)

$previous_domain = $configuration.'previous_domain'
$new_domain = $configuration.'new_domain'
$organizational_prefix = $configuration.'organizational_prefix'
$laptop_prefix = $configuration.'laptop_prefix'
$desktop_prefix = $configuration.'desktop_prefix'
$temp_admpasswd = $configuration.'temp_admpasswd'
$mobile_ou_path = $configuration.'mobile_ou_path'
$static_ou_path = $configuration.'static_ou_path'

$remove = $false
$restart = $false
$computername = $env:COMPUTERNAME
$begin = $false
$finduseroverride = $false
$isLaptop = $false
$status = 0
$serialIsNull = $true
$macAddressIsNull = $true
$verifyExecute = $false
$add = $false

$serial = (get-wmiobject win32_BIOS).SerialNumber
$macAddress = (get-wmiobject win32_networkadapter | where {($_.netconnectionid -match "Anslutning till lokalt" -or $_.netconnectionid -match "Local Area Connection" -or $_.netconnectionid -match "Ethernet" -or $_.netconnectionid -match "Gigabit") -and ($_.name -match "Ethernet" -or $_.name -match "Gigabit")}).macaddress
$macAddress = $macAddress -replace ":",""


function stringIsNullOrWhitespace([string] $string){
    if ($string -ne $null) { $string = $string.Trim() }
    return [string]::IsNullOrEmpty($string)
}

$serialIsNull = stringIsNullOrWhitespace($serial)
$macAddressIsNull = stringIsNullOrWhitespace($macAddress)

function remove{
	
	$begin = [Microsoft.VisualBasic.Interaction]::MsgBox("Resetting Local Administrator Password and removing domain. Continue?" ,'YesNo', "Unjoin") 
	
	if($begin -eq "Yes"){
		if(& net users | select-string "Administrator"){
			([ADSI] "WinNT://$computername/Administrator,user").SetPassword("$temp_admpasswd")
		}
		elseif(& net users | select-string "Administratör"){
			([ADSI] "WinNT://$computername/Administratör,user").SetPassword("$temp_admpasswd")
		}
		else{
			$finduseroverride = [Microsoft.VisualBasic.Interaction]::MsgBox("Can't find Local Admin user, make sure you have a local account before continuing! Continue?" ,'YesNo', "Missing User") 
			if($finduseroverride -eq "No"){
				cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
				Exit
			}
		}

		$remove = Remove-Computer -UnjoinDomainCredential $previous_domain\ -Force -PassThru
		
		if ($remove.HasSucceeded -eq $True){
			[Microsoft.VisualBasic.Interaction]::MsgBox("Unjoin Successful, restarting" ,'OKOnly', "Success") 
			Restart-Computer
		}
		else{
			[Microsoft.VisualBasic.Interaction]::MsgBox("Domain Unjoin Failed!" ,'OKOnly', "Faliure")
			cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
			Exit 
		}
	}
	else{
		cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
		Exit
	}
}

function join{
	if((get-wmiobject -Class win32_battery | ? { $_.Description -match "Internal" })) { 
		$isLaptop = $true 
	}


	if(($isLaptop -eq $true) -And ($serialIsNull -eq $false)) {
		$hostname = "$organizational_prefix-$laptop_prefix$serial"
		$status = 1
	}
	elseif(($isLaptop -eq $false) -And ($serialIsNull -eq $false)) {
		$hostname = "$organizational_prefix-$desktop_prefix$serial"
		$status = 2
	}
	elseif(($isLaptop -eq $true) -And ($serialIsNull -eq $true) -And ($macAddressIsNull -eq $false)) {
		$hostname = "$organizational_prefix$laptop_prefix$macAddress"
		$status = 3
	}
	elseif(($isLaptop -eq $false) -And ($serialIsNull -eq $true) -And ($macAddressIsNull -eq $false)) {
		$hostname = "$organizational_prefix$desktop_prefix$macAddress"
		$status = 4
	}
	else{
		$hostname = [Microsoft.VisualBasic.Interaction]::InputBox('Enter computer name', 'Computer Name') 
	}

	$verifyExecute = [Microsoft.VisualBasic.Interaction]::MsgBox("Computer name:    $hostname `n `n Serial:    $serial `n MAC:    $macAddress `n Laptop:    $isLaptop `n `n Continue?" ,'YesNo', "Verify Execution") 


	if(($verifyExecute -eq "Yes") -and ($isLaptop -eq $true)){
		
		$addmobile = Add-Computer -DomainName $new_domain -Credential $new_domain\ -NewName $hostname -Force -OUPath "$mobile_ou_path" -PassThru
    
		if ($addmobile.HasSucceeded -eq $True){
			$restart = [Microsoft.VisualBasic.Interaction]::MsgBox("Domain Join Successful! Restarting" ,'OKOnly', "Success") 
				Restart-Computer
		}
		else{
			[Microsoft.VisualBasic.Interaction]::MsgBox("Domain Join Failed!" ,'OKOnly', "Faliure")
			cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
			Exit 
		}
	}
	elseif(($verifyExecute -eq "Yes") -and ($isLaptop -eq $false)){
		$adddesktop = Add-Computer -DomainName $new_domain -Credential $new_domain\ -NewName $hostname -Force -OUPath "$static_ou_path" -PassThru
    
		if ($adddesktop.HasSucceeded -eq $True){
			[Microsoft.VisualBasic.Interaction]::MsgBox("Domain Join Successful! Restarting" ,'OKOnly', "Success") 
			Restart-Computer
		}
		else{
			[Microsoft.VisualBasic.Interaction]::MsgBox("Domain Join Failed!" ,'OKOnly', "Faliure")
			cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
			Exit 
		}
	}
}

function check{
	if((get-childitem cert:\LocalMachine\My | where {$_.Issuer -match "CN=Karolinska Institutet AD CA, DC=user, DC=ki, DC=se"}).Thumbprint){
		[Microsoft.VisualBasic.Interaction]::MsgBox("Computer certificate installed correctly" ,'OKOnly', "Computer Certificate") 
		cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
		Exit 
	}
	else{
		[Microsoft.VisualBasic.Interaction]::MsgBox("Computer certificate not installed" ,'OKOnly', "Computer Certificate") 
		cmd.exe /c "REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f"
		Exit 
	}
}

function finish{
	remove-item C:\Windows\Temp\domainjoin -recurse
	cmd.exe /c "gpupdate /force /boot"
}