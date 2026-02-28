param()

$BaseDir = "C:\PowerWatcher"
$WatcherScript = "$BaseDir\HibernateOnUnplug.ps1"
$TaskName = "HibernateOnChargerUnplug"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."; exit 1
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

# UNINSTALL if already installed
if ($task) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Remove-Item $BaseDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Uninstalled." -ForegroundColor Cyan
    exit
}

# INSTALL
powercfg /hibernate on
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

@'
function Write-Log { param($m); "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') - $m" | Out-File "C:\PowerWatcher\log.txt" -Append }
Write-Log "Watcher started"

# WMI event fires the instant Windows detects BatteryStatus change - zero polling delay
$query = "SELECT * FROM __InstanceModificationEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Battery' AND TargetInstance.BatteryStatus <> PreviousInstance.BatteryStatus"
$watcher = New-Object System.Management.ManagementEventWatcher $query
$watcher.Options.Timeout = [System.Management.ManagementOptions]::InfiniteTimeout

while ($true) {
    $event = $watcher.WaitForNextEvent()
    $wasAC = $event.PreviousInstance.BatteryStatus -in 2,3
    $nowAC = $event.TargetInstance.BatteryStatus -in 2,3
    if ($wasAC -and -not $nowAC) {
        Write-Log "Unplugged - hibernating"
        shutdown.exe /h /f
    }
}
'@ | Set-Content $WatcherScript -Encoding UTF8

$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatcherScript`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "Installed. Log: $BaseDir\log.txt" -ForegroundColor Green
