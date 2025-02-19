<# Image preparation script for Provisioned Citrix servers

#>
 
if($PSVersionTable.PSVersion.Major - 5)
{
#throw "your powershell version needs to be updated to execute this script properly"
write-host -foregroundcolor red "your powershell version needs to be updated to execute this script properly"
start-process iexplore.exe -ArgumentList "https://www.microsoft.com/en-us/download/details.aspx?id=54616"
throw "Reastart the script after WMF installation"
}
 
function Sync-Time
{
$TimeService = Get-Service -Name W32Time -ErrorAction SilentlyContinue
#Write-Host -ForegroundColor Yellow "$($MyInvocation.MyCommand) - Time sync started..."
 
if ($TimeService.Status -eq 'Stopped')
{
Write-Host -ForegroundColor yellow "$($MyInvocation.MyCommand) - W32Time not running. Starting now.."
$TimeService.Start()
$TimeService.WaitForStatus('Running')
}
#Write-Host -ForegroundColor Yellow "$($MyInvocation.MyCommand) - Time sync started..."
try
{
Start-Process w32tm.exe -ArgumentList "/config /update" -Wait
Start-Process w32tm.exe -ArgumentList "/resync" -Wait
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - Time sync completed."
}
catch
{
$ErrorMsg = $Error[0].Exception
Write-host -ForegroundColor Red "$($ErrorMsg)"
}
}
function Start-GPUpdate
{
#Write-Host -ForegroundColor Yellow "$($MyInvocation.MyCommand) - GPUpdate started..."
try
{
Start-Process gpupdate.exe -Wait -WindowStyle Hidden
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - GPUpdate successfully completed."
}
catch
{
$ErrorMsg = $Error[0].Exception
Write-host -ForegroundColor Red "$($ErrorMsg)"
}
}
function Clear-ArpCache
{
#Write-Host -ForegroundColor Yellow "$($MyInvocation.MyCommand) - Clearing ARP cache..."
try
{
Start-Process arp.exe -ArgumentList "-d" -Wait
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - ARP cache successfully cleared."
}
catch
{
$ErrorMsg = $Error[0].Exception
Write-host -ForegroundColor Red "$($ErrorMsg)"
}
}
function Clear-AllEventLogs
{
#Write-Host -ForegroundColor Yellow "$($MyInvocation.MyCommand) - Clearing all event logs..."
try
{
Get-EventLog -List | ForEach-Object {Clear-EventLog -LogName $_.Log}
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - All event logs successfully cleared."
}
catch
{
$ErrorMsg = $Error[0].Exception
Write-host -ForegroundColor Red "$($ErrorMsg)"
}
}
function Clear-DNSCache
{
$OSVersion = [version](Get-WmiObject win32_operatingsystem).version
$OSVerReq = [version]::new("6.2.0") # version at least reaquired (here windows 8 or Server 2012)
 
if ($OSVersion -ge $OSVerReq)
{
try
{
Clear-DnsClientCache
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - DNS cache successfully cleared."
}
catch
{
$ErrorMsg = $Error[0].Exception
Write-host -ForegroundColor Red "$($ErrorMsg)"
}
}
else
{
Start-Process ipconfig.exe -ArgumentList "/flushdns"
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - cleared DNS cache successfully."
}
 
}
function Clear-Temp
{
 
# remove files
$filesToRemove = @(
"$($env:TMP)\*",
"$($env:TEMP)\*",
"$($env:Windir)\Temp\*"
)
 
Foreach ($file in $filesToRemove)
{
if (Test-Path $file)
{
Remove-Item $file -Recurse -ErrorAction SilentlyContinue
 
}
else
{
Write-Host "$($file) not found"
}
}
Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - Successfully removed Temp files."
}

Function Stop-WEM {
	if (Get-Service "WemAgentSvc" -ErrorAction SilentlyContinue) {
		"NETLOGON","WemAgentSvc" | Stop-Service -ErrorAction SilentlyContinue
		
		$a =Get-Service "WemAgentSvc" |select-Object Status
		
		if($a -eq "stopped"){
			Write-Host -ForegroundColor Green "$($MyInvocation.MyCommand) - Successfully stopped the Citrix WEM Agent Host Service and netlogon Services."
		}
		Else {
			Write-host -foregroundcolor Green "There was an issue while stopping the Citrix WEM Agent Host Service service"
		}
		Else{
			Write-Host -ForegroundColor yellow "$($MyInvocation.MyCommand) - Citrix WEM Agent Host Service not present on this Image"
		}
	}
}
 
function Test-Regkey
{
 
param (
[parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]$Path,
[parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]$Name
)
 
try
{
Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Name -ErrorAction Stop | Out-Null
return $true
}
catch
{
return $false
}
 
}
function Reset-Java
{
#region remove javaupdate
$JavaRegkeyPath = "hklm:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
$javaregkeyname = "SunJavaUpdateSched"
if(test-regkey -path $JavaRegkeyPath -name $javaregkeyname)
{
Remove-ItemProperty -path $JavaRegkeyPath -Name $javaregkeyname
Write-Host -ForegroundColor green `n "Reset-Java - Java update key has been successfully removed"
}
else
{
Write-Host -ForegroundColor yellow "Reset-Java - Javaupdate key not found"
}
}
Function ShutDown-computer
{
$oReturn = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"),
[System.Windows.Forms.MessageBox]::Show("Please check the results. If all is good press OK to shutdown the computer","Sealing the Image",
[System.Windows.Forms.MessageBoxButtons]::OKCancel,
[System.Windows.Forms.MessageBoxIcon]::information)
 
switch ($oReturn)
{
"OK"
{
write-host -foregroundcolor Green "This image will be sealed now, and the server shutdown"
Start-Sleep -Seconds 5
#stop-computer
& shutdown.exe -s -t 00
}
 
"Cancel"
{
write-host -foregroundcolor yellow "You have cancelled the shutdown to check the errors"
}
 
}
}
 
 
$iMax = 7
$i = 0
Write-Progress -Activity "Synchronise time on the server" -Status "In Progress" -PercentComplete $($i * 100 / $iMax)
Sync-Time
 
$i++
Write-Progress -Activity "Update GPO's" -Status "This might take some minutes. Please be patient..." -PercentComplete $($i * 100 / $iMax)
Start-GPUpdate
 
$i++
Write-Progress -Activity "Clear DNS cache" -Status "In Progress" -PercentComplete $($i * 100 / $iMax)
Clear-DNSCache
 
$i++
Write-Progress -Activity "Clear ARP Cache" -Status "In Progress" -PercentComplete $($i * 100 / $iMax)
Clear-ArpCache
 
$i++
Write-Progress -Activity "Clear temporary olders and files" -Status "In Progress" -PercentComplete $($i * 100 / $iMax)
Clear-Temp
 
$i++
Write-Progress -Activity "Stop Norscale service" -Status "In Progress" -PercentComplete $($i * 100 / $iMax)
Stop-WEM
 
$i++
Write-Progress -Activity "Turn off Java Update" -Status "This might take some minutes. Please be patient..." -PercentComplete $($i * 100 / $iMax)
reset-java
 
$i++
Write-Progress -Activity "Shutdown-computer" -Status "Have there been errors in the script then click Cancel. Other wise OK to shutdown the image..." -PercentComplete $($i * 100 / $iMax)
ShutDown-computer