$FIRST_DRIVER = 'CorsairVBusDriver.inf'
$SECOND_DRIVER = 'CorsairVBusDriver.inf'
$DEFAULT_DRIVER_PATH = "${Env:ProgramFiles(x86)}\Corsair\CORSAIR iCUE Software\driver\hid"

Function GetOemNameFromOriginal
{
    Param ([String]$originalName)
    pnputil /enum-drivers | Select-String -Context 1 ('Original Name:\s+' + $originalName) | 
        ForEach-Object { ($_.Context.PreContext[0] -split ':\s+')[1] }
}

$driversFolder = $DEFAULT_DRIVER_PATH
$corsairInstallRegistry = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
    Where-Object {$_.GetValue('DisplayName') -match "ICUE"}
if ($corsairInstallRegistry)
{
    $driversFolder = Join-Path $corsairInstallRegistry.GetValue('InstallLocation') $DRIVER_SUB_PATH
} else
{
    Write-Host "Unable to find ICUE install location"
    Write-Host "Trying default path"
}

$fullFirstDriverPath = Join-Path $DEFAULT_DRIVER_PATH $FIRST_DRIVER
$fullSecondtDriverPath = Join-Path $DEFAULT_DRIVER_PATH $SECOND_DRIVER
$isDriversExist = (Test-Path $fullFirstDriverPath) -and (Test-Path $fullSecondtDriverPath)
if (!($isDriversExist))
{
    Write-Host "Unable to find drivers"
    exit 1
}

$corsairCompositeDevInfo = pnputil /enum-devices |
    Select-String -Context 2, 4 ('Device Description:\s+' + 'Corsair composite virtual input device')
$isStopped = $corsairCompositeDevInfo.ToString() | Select-String -Context 1 ('Status:\s+' + 'Stopped')
If ($isStopped)
{
    Write-Host "Corsair Composite Device is disabled"
    Write-Host "Reinstalling drivers"
    pnputil /delete-driver (GetOemNameFromOriginal $FIRST_DRIVER) /uninstall /force
    pnputil /delete-driver (GetOemNameFromOriginal $SECOND_DRIVER) /uninstall /force
    pnputil /add-driver (Join-Path $driversFolder CorsairVBusDriver.inf) /install
    pnputil /add-driver (Join-Path $driversFolder CorsairVHidDriver.inf) /install
} else 
{
    Write-Host "No actions required"
}
