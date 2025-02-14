#<
# Author       : Robert Magasi
# Usage        : Set DNS Suffix Search List
#>

#######################################
#     Set DNS Suffix Search List      #
#######################################

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set DNS Suffix Search List Start -  $((Get-Date).ToUniversalTime()) "

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$registryKey = "SearchList"
$registryType = "String"
$registryValue = "reddog.microsoft.com,ads.ktag.ch,ktag.ch,ag.ch"

IF(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

try {
    New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType $registryType -Force -ErrorAction Stop
}
catch {
     Write-Host "*** AVD AIB CUSTOMIZER PHASE *** Set DNS Suffix Search List - Cannot add the registry key $registryKey *** : [$($_.Exception.Message)]"
     Write-Host "Message: [$($_.Exception.Message)"]
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set DNS Suffix Search List - Exit Code: $LASTEXITCODE ***"
Write-Host "*** Ending AVD AIB CUSTOMIZER PHASE: Set DNS Suffix Search List - Time taken: $elapsedTime "

#############
#    END    #
#############