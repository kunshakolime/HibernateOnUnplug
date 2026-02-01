# ===============================
# Hibernate on Charger Unplug
# Combined Install/Uninstall Script
# ===============================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install', 'Uninstall')]
    [string]$Action
)

# --- Config ---
$BaseDir = "C:\PowerWatcher"
$WatcherScript = "$BaseDir\HibernateOnUnplug.ps1"
$TaskName = "HibernateOnChargerUnplug"

# --- Ensure admin ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Error "⚠️  Run this script as Administrator."
    exit 1
}

# --- Prompt for action if not specified ---
if (-not $Action) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Hibernate on Charger Unplug" -ForegroundColor White
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Choose an action:" -ForegroundColor Yellow
    Write-Host "  [1] Install" -ForegroundColor Green
    Write-Host "  [2] Uninstall" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1 or 2)"
    
    switch ($choice) {
        "1" { $Action = "Install" }
        "2" { $Action = "Uninstall" }
        default {
            Write-Error "Invalid choice. Exiting."
            exit 1
        }
    }
}

# ===============================
# INSTALL
# ===============================
if ($Action -eq "Install") {
    Write-Host ""
    Write-Host "Installing Hibernate-on-Unplug..." -ForegroundColor Cyan
    Write-Host ""

    # --- Enable hibernation ---
    Write-Host "Enabling hibernation..." -ForegroundColor Yellow
    powercfg /hibernate on
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
    Write-Host "✔ Hibernate enabled" -ForegroundColor Green
    Write-Host ""

    # --- Create directory ---
    if (-not (Test-Path $BaseDir)) {
        New-Item -ItemType Directory -Path $BaseDir | Out-Null
    }

    # --- Create optimized watcher script (500ms polling for faster response) ---
    @'
# Optimized AC power monitor with fast response

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File "C:\PowerWatcher\log.txt" -Append
}

Write-Log "Watcher started"

# Initialize AC status
$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if ($battery) {
    $lastACStatus = ($battery.BatteryStatus -eq 2) -or ($battery.BatteryStatus -eq 3)
} else {
    $lastACStatus = $true
}

while ($true) {
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $onAC = ($battery.BatteryStatus -eq 2) -or ($battery.BatteryStatus -eq 3)

        # Hibernate on unplug
        if ($lastACStatus -and -not $onAC) {
            Write-Log "AC unplugged - hibernating"
            shutdown.exe /h /f
        }

        $lastACStatus = $onAC
    }

    Start-Sleep -Milliseconds 500
}
'@ | Set-Content -Path $WatcherScript -Encoding UTF8

    # --- Remove existing task ---
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # --- Create scheduled task ---
    $taskAction = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatcherScript`""

    $trigger = New-ScheduledTaskTrigger -AtStartup

    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Days 0) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $taskAction `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings | Out-Null

    Write-Host "✔ Installed successfully" -ForegroundColor Green
    Write-Host "✔ Starting service..." -ForegroundColor Green
    Start-ScheduledTask -TaskName $TaskName

    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Testing:" -ForegroundColor Yellow
    Write-Host "1. Wait a few seconds" -ForegroundColor White
    Write-Host "2. Unplug your charger" -ForegroundColor White
    Write-Host "3. PC hibernates in ~2 seconds" -ForegroundColor White
    Write-Host ""
    Write-Host "Log: C:\PowerWatcher\log.txt" -ForegroundColor White
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
}

# ===============================
# UNINSTALL
# ===============================
if ($Action -eq "Uninstall") {
    Write-Host ""
    Write-Host "Uninstalling Hibernate-on-Unplug..." -ForegroundColor Cyan
    Write-Host ""

    # --- Stop and remove task ---
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Removing scheduled task..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "✔ Task removed" -ForegroundColor Green
    } else {
        Write-Host "No task found" -ForegroundColor White
    }

    # --- Delete files ---
    if (Test-Path $WatcherScript) {
        Remove-Item $WatcherScript -Force
        Write-Host "✔ Watcher script deleted" -ForegroundColor Green
    }

    $logFile = "$BaseDir\log.txt"
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
        Write-Host "✔ Log deleted" -ForegroundColor Green
    }

    # --- Remove folder if empty ---
    if (Test-Path $BaseDir) {
        $contents = Get-ChildItem $BaseDir -Force
        if ($contents.Count -eq 0) {
            Remove-Item $BaseDir -Force
            Write-Host "✔ Folder removed" -ForegroundColor Green
        } else {
            Write-Host "Folder not empty, left intact" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "✔ Uninstalled successfully" -ForegroundColor Cyan
}
