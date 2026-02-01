# Hibernate on Charger Unplug

Automatically hibernate your Windows laptop when you unplug the charger. Perfect for quickly securing your device when moving away from your desk.

## ⚡ Features

- **fast response**: Hibernates within seconds of unplugging
- **Lightweight**: Minimal CPU/memory usage (500ms polling interval)
- **Reliable**: Runs as a system service, auto-restarts on failure
- **Clean**: Easy install/uninstall, no residual files

## 🚀 Quick Install

Run this command in PowerShell **as Administrator**:

```powershell
irm https://raw.githubusercontent.com/kunshakolime/HibernateOnUnplug/main/HibernateOnUnplug.ps1 -OutFile "$env:TEMP\HibernateOnUnplug.ps1"
powershell.exe -ExecutionPolicy Bypass -File "$env:TEMP\HibernateOnUnplug.ps1"
```
Or:

```powershell
irm https://raw.githubusercontent.com/kunshakolime/HibernateOnUnplug/main/HibernateOnUnplug.ps1 | iex
```


## 📋 Manual Usage

1. Download `HibernateOnUnplug.ps1`
2. Right-click → "Run with PowerShell" (as Administrator)
3. Choose **Install** or **Uninstall**

Or run with parameters:

```powershell
.\HibernateOnUnplug.ps1 -Action Install
.\HibernateOnUnplug.ps1 -Action Uninstall
```

## 🧪 Testing

After installation:
1. Wait a few seconds for the service to initialize
2. Unplug your charger
3. Your PC should hibernate within ~0.5 seconds

Check the log for activity:
```
C:\PowerWatcher\log.txt
```

## 🔧 How It Works

1. **Monitors AC power** every 500ms using WMI (`Win32_Battery`)
2. **Detects unplug event** by comparing current vs. previous AC status
3. **Triggers hibernate** using `shutdown.exe /h /f`
4. **Runs as scheduled task** under SYSTEM account, starts at boot

## ⚙️ Optimization Details

This version is optimized for speed:
- **500ms polling interval** (down from 2000ms) for near-instant response
- **Removed unnecessary logging** during normal operation
- **Streamlined battery status check** with minimal overhead
- **Direct shutdown command** without delays

## 📁 Files Created

- `C:\PowerWatcher\HibernateOnUnplug.ps1` - Monitor script
- `C:\PowerWatcher\log.txt` - Activity log
- Scheduled Task: `HibernateOnChargerUnplug`

## 🗑️ Uninstall

Run the script again and choose **Uninstall**, or:

```powershell
irm https://raw.githubusercontent.com/kunshakolime/HibernateOnUnplug/main/HibernateOnUnplug.ps1 | iex
# Then select option 2
```

Uninstalling removes:
- Scheduled task
- Watcher script
- Log file
- Base folder (if empty)

## 📝 Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges
- Laptop with battery

## ⚠️ Notes

- Hibernation must be supported by your hardware
- Only triggers on **actual unplug events** (not on startup)
- Desktop PCs without batteries are safely ignored
- Does not interfere with manual hibernate/sleep

## 🐛 Troubleshooting

**Not hibernating?**
- Check Task Scheduler: `HibernateOnChargerUnplug` should be running
- Verify hibernation is enabled: `powercfg /a`
- Check log: `C:\PowerWatcher\log.txt`

**Hibernates on startup?**
- Fixed in this version - initializes AC status before monitoring

**Want slower/faster response?**
- Edit `C:\PowerWatcher\HibernateOnUnplug.ps1`
- Change `Start-Sleep -Milliseconds 500` to desired value
- Restart task or reboot

## 📄 License

MIT License - Feel free to use and modify

## 🤝 Contributing

Issues and pull requests welcome!

---

**⚠️ Remember**: Always run PowerShell scripts from trusted sources. Review the code before executing!
