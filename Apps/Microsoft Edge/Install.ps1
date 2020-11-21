Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

$Vendor = "Microsoft"
$Product = "Edge Enterprise x64"
$PackageName = "MicrosoftEdgeEnterpriseX64"
$Evergreen = Get-MicrosoftEdge | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Platform -eq "Windows" }
$Evergreen = $Evergreen | Sort-Object -Property Version -Descending | Select-Object -First 1
$Version = $Evergreen.Version
$URL = $Evergreen.uri
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /norestart /qn /liewa $LogApp"
#$prefurl = "https://github.com/rmagasi/Lab/blob/main/master_preferences"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}

CD $Version

If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source
    #Invoke-WebRequest -UseBasicParsing -Uri $prefurl -OutFile master_preferences
}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Copy Preferences File" -Verbose
Copy-Item -Path "C:\_SRC\MicrosoftEdge\master_preferences" -Destination "C:\Program Files (x86)\Microsoft\Edge\Application\master_preferences" -Recurse -Force

Write-Verbose "Stop and Disable Microsoft Edge Services" -Verbose
$Services = "edgeupdatem","edgeupdate","MicrosoftEdgeElevationService"
ForEach ($Service in $Services)
{
If ((Get-Service -Name $Service).Status -eq "Stopped")
{
Set-Service -Name $Service -StartupType Disabled
}
else
{
Stop-Service -Name $Service -Force -Verbose
Set-Service -Name $Service -StartupType Disabled
}
}

Write-Verbose "Delete Microsoft Edge Scheduled Tasks" -Verbose
$EdgeScheduledTasks = "MicrosoftEdgeUpdateTaskMachineCore","MicrosoftEdgeUpdateTaskMachineUA"
ForEach ($Task in $EdgeScheduledTasks)
{
Unregister-ScheduledTask -TaskName $Task -Confirm:$false
}

If ((Test-Path -Path HKLM:SYSTEM\CurrentControlSet\services\CtxUvi)) {
    Write-Verbose "Fix Citrix API Hook" -Verbose
    $RegPath = "HKLM:SYSTEM\CurrentControlSet\services\CtxUvi"
    $RegName = "UviProcessExcludes"
    $EdgeRegvalue = "msedge.exe"

    # Get current values in UviProcessExcludes
    $CurrentValues = Get-ItemProperty -Path $RegPath | Select-Object -ExpandProperty $RegName | Out-Null
    # Add the msedge.exe value to existing values in UviProcessExcludes
    Set-ItemProperty -Path $RegPath -Name $RegName -Value "$CurrentValues$EdgeRegvalue;" | Out-Null
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
