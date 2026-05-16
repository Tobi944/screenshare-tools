$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║           ADMINISTRATOR PRIVILEGES REQUIRED       ║" -ForegroundColor Red
    Write-Host "║     Please run this script as Administrator!      ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Red
    exit
}

Clear-Host
Write-Host "╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║               TOBI'S SYSTEM DIAGNOSTIC CORE v2.5                ║" -ForegroundColor Cyan
Write-Host "║                    [ Environment Analysis ]                     ║" -ForegroundColor Cyan
Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────────────────────────
Write-Host " [▶] SYSTEM BOOT & UPTIME" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Host ("  Last Boot : {0}" -f $bootTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    Write-Host ("  Uptime    : {0} days, {1:D2}:{2:D2}:{3:D2}" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor White
} catch {
    Write-Host "  [-] Unable to retrieve boot time information" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────
$drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Host "`n [▶] CONNECTED STORAGE DRIVES" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    foreach ($drive in $drives) {
        Write-Host ("  Drive {0,-3} File System: {1}" -f $drive.DeviceID, $drive.FileSystem) -ForegroundColor Green
    }
}

# ─────────────────────────────────────────────────────────────────
Write-Host "`n [▶] SECURITY: WINDOWS DEFENDER STATUS" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
try {
    $pref = Get-MpPreference -ErrorAction SilentlyContinue
    if ($pref) {
        $rtm = if ($pref.DisableRealtimeMonitoring) { "DISABLED" } else { "Active" }
        $ioav = if ($pref.DisableIOAVProtection) { "DISABLED" } else { "Active" }
        $bafs = if ($pref.DisableBehaviorMonitoring) { "DISABLED" } else { "Active" }
        
        Write-Host "  Realtime Monitoring : " -NoNewline -ForegroundColor White
        if ($rtm -eq "DISABLED") { Write-Host $rtm -ForegroundColor Red } else { Write-Host $rtm -ForegroundColor Green }
        
        Write-Host "  IOAV Protection     : " -NoNewline -ForegroundColor White
        if ($ioav -eq "DISABLED") { Write-Host $ioav -ForegroundColor Red } else { Write-Host $ioav -ForegroundColor Green }

        Write-Host "  Behavior Monitoring : " -NoNewline -ForegroundColor White
        if ($bafs -eq "DISABLED") { Write-Host $bafs -ForegroundColor Red } else { Write-Host $bafs -ForegroundColor Green }
    } else {
        Write-Host "  [!] Could not query Defender security preferences." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [-] Error checking Windows Defender configuration" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────
Write-Host "`n [▶] CORE SYSTEM SERVICES" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray

$services = @(
    @{Name = "SysMain"; DisplayName = "SysMain"},
    @{Name = "PcaSvc"; DisplayName = "Program Compatibility Assistant"},
    @{Name = "DPS"; DisplayName = "Diagnostic Policy Service"},
    @{Name = "EventLog"; DisplayName = "Windows Event Log"},
    @{Name = "Schedule"; DisplayName = "Task Scheduler"},
    @{Name = "Bam"; DisplayName = "Background Activity Moderator"},
    @{Name = "Dusmsvc"; DisplayName = "Data Usage Service"},
    @{Name = "Appinfo"; DisplayName = "Application Information"},
    @{Name = "CDPSvc"; DisplayName = "Connected Devices Platform"},
    @{Name = "DcomLaunch"; DisplayName = "DCOM Server Process Launcher"},
    @{Name = "PlugPlay"; DisplayName = "Plug and Play"},
    @{Name = "wsearch"; DisplayName = "Windows Search"}
)

foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service) {
        $displayName = $svc.DisplayName
        if ($displayName.Length -gt 35) { $displayName = $displayName.Substring(0, 32) + "..." }
        
        if ($service.Status -eq "Running") {
            Write-Host ("  {0,-12} │ {1,-35} │ " -f $svc.Name, $displayName) -ForegroundColor White -NoNewline
            
            if ($svc.Name -eq "Bam") {
                Write-Host "Running (Enabled)" -ForegroundColor Green
            } else {
                try {
                    $process = Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" | Select-Object ProcessId
                    if ($process.ProcessId -gt 0) {
                        $proc = Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue
                        if ($proc) {
                            Write-Host ("Up since: {0}" -f $proc.StartTime.ToString("HH:mm:ss")) -ForegroundColor Green
                        } else {
                            Write-Host "Running" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "Running" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "Running" -ForegroundColor Green
                }
            }
        } else {
            Write-Host ("  {0,-12} │ {1,-35} │ " -f $svc.Name, $displayName) -ForegroundColor Gray -NoNewline
            Write-Host "STOPPED" -ForegroundColor Red
        }
    } else {
        Write-Host ("  {0,-12} │ {1,-35} │ NOT FOUND" -f $svc.Name, "Missing Service") -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────────────────────────
Write-Host "`n [▶] CRITICAL REGISTRY POLICIES" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray

$settings = @(
    @{ Name = "CMD Access Restrictions"; Path = "HKCU:\Software\Policies\Microsoft\Windows\System"; Key = "DisableCMD"; Warning = "Disabled"; Safe = "Default (Available)" },
    @{ Name = "PowerShell Script Block Logging"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"; Key = "EnableScriptBlockLogging"; Warning = "Disabled"; Safe = "Enabled" },
    @{ Name = "User Activity Feed Cache"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "EnableActivityFeed"; Warning = "Disabled"; Safe = "Enabled" },
    @{ Name = "Windows Prefetch Engine"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher"; Warning = "Disabled"; Safe = "Enabled" }
)

foreach ($s in $settings) {
    $status = Get-ItemProperty -Path $s.Path -Name $s.Key -ErrorAction SilentlyContinue
    Write-Host ("  {0,-35} : " -f $s.Name) -NoNewline -ForegroundColor White
    if ($status -and $status.$($s.Key) -eq 0) {
        Write-Host "$($s.Warning)" -ForegroundColor Red
    } else {
        Write-Host "$($s.Safe)" -ForegroundColor Green
    }
}

# ─────────────────────────────────────────────────────────────────
Write-Host "`n [▶] REGISTRY STARTUP PERSISTENCE" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
$runPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)
$foundStartup = $false
foreach ($path in $runPaths) {
    if (Test-Path $path) {
        $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $values = $props.psobject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') }
        if ($values) {
            $foundStartup = $true
            Write-Host "  Hive Location: $path" -ForegroundColor Gray
            foreach ($val in $values) {
                Write-Host ("    └─ {0} -> {1}" -f $val.Name, $val.Value) -ForegroundColor Yellow
            }
        }
    }
}
if (-not $foundStartup) {
    Write-Host "  [+] Registry startup paths are clear." -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────────
Write-Host "`n [▶] SECURITY & AUDIT EVENT LOGS" -ForegroundColor Cyan
Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray

function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    Write-Host ("  {0,-35} : " -f $message) -NoNewline -ForegroundColor White
    if ($event) {
        Write-Host ("Triggered at {0}" -f $event.TimeCreated.ToString("MM/dd HH:mm")) -ForegroundColor Yellow
    } else {
        Write-Host "No anomalies recorded" -ForegroundColor Green
    }
}

function Check-RecentEventLog {
    param ($logName, $eventIDs, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$($eventIDs -join ' or EventID=')]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    Write-Host ("  {0,-35} : " -f $message) -NoNewline -ForegroundColor White
    if ($event) {
        Write-Host ("Cleared/Modified at {0} (ID: {1})" -f $event.TimeCreated.ToString("MM/dd HH:mm"), $event.Id) -ForegroundColor Red
    } else {
        Write-Host "No clear logs detected" -ForegroundColor Green
    }
}

function Check-DeviceDeleted {
    Write-Host ("  {0,-35} : " -f "Hardware Device Removals") -NoNewline -ForegroundColor White
    try {
        $event = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -FilterXPath "*[System[EventID=400]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            Write-Host ("PnP Config Change: {0}" -f $event.TimeCreated.ToString("MM/dd HH:mm")) -ForegroundColor Yellow
            return
        }
    } catch {}

    try {
        $event = Get-WinEvent -FilterHashtable @{LogName="System"; ID=225} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            Write-Host ("Device Ejected: {0}" -f $event.TimeCreated.ToString("MM/dd HH:mm")) -ForegroundColor Yellow
            return
        }
    } catch {}

    Write-Host "Clean" -ForegroundColor Green
}

Check-EventLog "Application" 3079 "USN Journal Clear Event"
Check-RecentEventLog "System" @(104, 1102) "Log Wipe Detection"
Check-EventLog "System" 1074 "Last System Shutdown Timestamp"
Check-EventLog "Security" 4616 "System Time Sync Modifications"
Check-EventLog "System" 6005 "Event Log Subsystem Boot"
Check-DeviceDeleted

# ─────────────────────────────────────────────────────────────────
$prefetchPath = "$env:SystemRoot\Prefetch"
if (Test-Path $prefetchPath) {
    Write-Host "`n [▶] PREFETCH STORAGE INTEGRITY" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    $files = Get-ChildItem -Path $prefetchPath -Filter *.pf -Force -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-Host "  [!] Prefetch directory layout is empty or unreadable." -ForegroundColor Yellow
    } else {
        $hashTable = @{}
        $suspiciousFiles = @{}
        $totalFiles = $files.Count
        $hiddenFiles = @()
        $readOnlyFiles = @()
        $hiddenAndReadOnlyFiles = @()

        foreach ($file in $files) {
            try {
                $isHidden = $file.Attributes -band [System.IO.FileAttributes]::Hidden
                $isReadOnly = $file.Attributes -band [System.IO.FileAttributes]::ReadOnly
                
                if ($isHidden -and $isReadOnly) {
                    $hiddenAndReadOnlyFiles += $file
                    $suspiciousFiles[$file.Name] = "Hidden + Read-only Attribute Mod"
                } elseif ($isHidden) {
                    $hiddenFiles += $file
                    $suspiciousFiles[$file.Name] = "Hidden Attribute Mod"
                } elseif ($isReadOnly) {
                    $readOnlyFiles += $file
                    $suspiciousFiles[$file.Name] = "Read-only Attribute Mod"
                }

                $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($hash) {
                    if ($hashTable.ContainsKey($hash.Hash)) {
                        $hashTable[$hash.Hash].Add($file.Name)
                    } else {
                        $hashTable[$hash.Hash] = [System.Collections.Generic.List[string]]::new()
                        $hashTable[$hash.Hash].Add($file.Name)
                    }
                }
            } catch {}
        }

        Write-Host ("  Total Executable Footprints : {0}" -f $totalFiles) -ForegroundColor White
        
        if ($hiddenAndReadOnlyFiles.Count -gt 0) { Write-Host ("  [!] Stealth Attributes      : {0} files flags found" -f $hiddenAndReadOnlyFiles.Count) -ForegroundColor Red }
        if ($hiddenFiles.Count -gt 0) { Write-Host ("  [!] Hidden Files Found      : {0} modified items" -f $hiddenFiles.Count) -ForegroundColor Yellow }
        
        $repeatedHashes = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($repeatedHashes) {
            Write-Host ("  [!] Duplicate Binary Hashes : {0} matching sets discovered" -f ($repeatedHashes | Measure-Object).Count) -ForegroundColor Yellow
        }

        if ($suspiciousFiles.Count -gt 0) {
            Write-Host "`n  [➔] FLAG SUMMARY:" -ForegroundColor Yellow
            foreach ($entry in $suspiciousFiles.GetEnumerator() | Sort-Object Key) {
                Write-Host ("      ↳ {0} -> {1}" -f $entry.Key, $entry.Value) -ForegroundColor White
            }
        } else {
            Write-Host "  [+] Hash & attribute checks verified clean." -ForegroundColor Green
        }
    }
}

# ─────────────────────────────────────────────────────────────────
try {
    $recycleBinPath = "$env:SystemDrive" + '\$Recycle.Bin'
    Write-Host "`n [▶] FILE RECOVERY SYSTEM (RECYCLE BIN)" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray

    if (Test-Path $recycleBinPath) {
        $recycleBinFolder = Get-Item -LiteralPath $recycleBinPath -Force
        $userFolders = Get-ChildItem -LiteralPath $recycleBinPath -Directory -Force -ErrorAction SilentlyContinue
        
        if ($userFolders) {
            $allDeletedItems = @()
            $latestModTime = $recycleBinFolder.LastWriteTime
            
            foreach ($userFolder in $userFolders) {
                if ($userFolder.LastWriteTime -gt $latestModTime) { $latestModTime = $userFolder.LastWriteTime }
                $userItems = Get-ChildItem -LiteralPath $userFolder.FullName -File -Force -ErrorAction SilentlyContinue
                if ($userItems) {
                    $allDeletedItems += $userItems
                    $latestFile = $userItems | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                    if ($latestFile -and $latestFile.LastWriteTime -gt $latestModTime) { $latestModTime = $latestFile.LastWriteTime }
                }
            }
            
            Write-Host ("  Last Modification Time : {0}" -f $latestModTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
            Write-Host ("  Cached Retained Items  : {0}" -f $allDeletedItems.Count) -ForegroundColor White
        } else {
            Write-Host "  Status                 : Empty Directory Structure" -ForegroundColor Green
        }
    }

    # ─────────────────────────────────────────────────────────────────
    Write-Host "`n [▶] NETWORK PATHS: HOSTS FILE INTEGRITY" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        $lines = Get-Content -Path $hostsPath | Where-Object { $_.Trim() -and -not $_.StartsWith("#") }
        if ($lines) {
            Write-Host "  [!] Manual Network Routing Intercepts Discovered:" -ForegroundColor Yellow
            foreach ($line in $lines) { Write-Host "      → $line" -ForegroundColor White }
        } else {
            Write-Host "  [+] DNS routing tables standard (No overrides)" -ForegroundColor Green
        }
    }

    # ─────────────────────────────────────────────────────────────────
    $consoleHistoryPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    Write-Host "`n [▶] CONSOLE TERMINAL FOOTPRINT" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    if (Test-Path $consoleHistoryPath) {
        $historyFile = Get-Item -Path $consoleHistoryPath -Force
        Write-Host ("  History Buffer Mod Time : {0}" -f $historyFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        Write-Host ("  Log Buffer Footprint    : {0} KB" -f [math]::Round($historyFile.Length/1024, 2)) -ForegroundColor White
    } else {
        Write-Host "  [-] Operational logging history file not found." -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    Write-Host "`n [▶] RECENT OS ACCESS SHORTCUTS" -ForegroundColor Cyan
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    $recentPath = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        $recentFiles = Get-ChildItem -Path $recentPath -File -ErrorAction SilentlyContinue
        Write-Host ("  Stored Shortcut Links   : {0}" -f $recentFiles.Count) -ForegroundColor White
    }
} catch {
    Write-Host "  [-] Secondary trace validation error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  Scan Complete. Your environment is solid. Keep up the high standard. " -ForegroundColor Green
Write-Host "  For custom operational adjustments, ping the dev: @124tobi1231" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Gray