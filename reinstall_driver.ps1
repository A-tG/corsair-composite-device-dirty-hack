$IS_64BIT = [Environment]::Is64BitOperatingSystem;
$FIRST_DRIVER = 'CorsairVBusDriver.inf'
$SECOND_DRIVER = 'CorsairVBusDriver.inf'
$DRIVERS_SUBPATH = 'drivers\hid'
$DEFAULT_DRIVER_PATH = ${Env:ProgramFiles}
if ($IS_64BIT)
{
    $DEFAULT_DRIVER_PATH = ${Env:ProgramFiles(x86)}
}
$DEFAULT_DRIVER_PATH = Join-Path $DEFAULT_DRIVER_PATH 'Corsair\CORSAIR iCUE Software' | 
    Join-Path -ChildPath $DRIVERS_SUBPATH

Function GetOemNameFromOriginal
{
    Param ([String]$originalName)
    pnputil /enum-drivers | Select-String -Context 1 ('Original Name:\s+' + $originalName) | 
        ForEach-Object { ($_.Context.PreContext[0] -split ':\s+')[1] }
}

$corsairCompositeDevInfo = pnputil /enum-devices |
    Select-String -Context 2, 4 ('Device Description:\s+' + 'Corsair composite virtual input device')
$isStopped = $corsairCompositeDevInfo.ToString() | Select-String -Context 1 ('Status:\s+' + 'Stopped')
$isDisconnected = $corsairCompositeDevInfo.ToString() | Select-String -Context 1 ('Status:\s+' + 'Disconnected')
If (!($isStopped -or $isDisconnected))
{
    Write-Host "No actions needed"
    exit 0
}

$driversFolder = $DEFAULT_DRIVER_PATH
$registryInstallPaths = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
if ($IS_64BIT)
{
    $registryInstallPaths = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'    
}
$corsairInstallRegistry = Get-ChildItem $registryInstallPaths |
    Where-Object {$_.GetValue('DisplayName') -match "ICUE"}
if ($corsairInstallRegistry)
{
    $driversFolder = Join-Path $corsairInstallRegistry.GetValue('InstallLocation') $DRIVERS_SUBPATH
} else
{
    Write-Host "Unable to find ICUE install location"
    Write-Host "Trying default path"
}

$fullFirstDriverPath = Join-Path $driversFolder $FIRST_DRIVER
$fullSecondtDriverPath = Join-Path $driversFolder $SECOND_DRIVER
$isDriversExist = (Test-Path $fullFirstDriverPath) -and (Test-Path $fullSecondtDriverPath)
if (!($isDriversExist))
{
    Write-Host "Unable to find drivers"
    exit 1
}

Write-Host "Corsair Composite Virtual Input Device is disabled"
Write-Host "Reinstalling drivers"
pnputil /delete-driver (GetOemNameFromOriginal $FIRST_DRIVER) /uninstall /force
pnputil /delete-driver (GetOemNameFromOriginal $SECOND_DRIVER) /uninstall /force
pnputil /add-driver (Join-Path $driversFolder CorsairVBusDriver.inf) /install
pnputil /add-driver (Join-Path $driversFolder CorsairVHidDriver.inf) /install
