$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║           ADMINISTRATOR PRIVILEGES REQUIRED       ║" -ForegroundColor Red
    Write-Host "║     Please run this script as Administrator!      ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Red
    exit
}

Clear-Host
Write-Host @"
 _________  ________  ________  ___     
|\___   ___\\   __  \|\   __  \|\  \    
\|___ \  \_\ \  \|\  \ \  \|\  \ \  \   
     \ \  \ \ \  \\\  \ \   __  \ \  \  
      \ \  \ \ \  \\\  \ \  \|\  \ \  \ 
       \ \__\ \ \_______\ \_______\ \__\
        \|__|  \|_______|\|_______|\|__|
        
       [ Device Connection History & Scan ]
       Engineered by TOBI // @124tobi1231                                 
"@ -ForegroundColor Cyan

Write-Host "`n[➔] Scanning USB Storage History..." -ForegroundColor Gray
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray

$logName = "Microsoft-Windows-Partition/Diagnostic"
try {
    $usbEvents = Get-WinEvent -LogName $logName -FilterHashtable @{LogName=$logName; Id=@(1006, 1007)} -ErrorAction SilentlyContinue | 
                 Sort-Object TimeCreated

    if ($usbEvents) {
        foreach ($event in $usbEvents) {
            $time = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            $xml = [xml]$event.ToXml()
            $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
            $ns.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)
            
            $capacityBytes = $xml.SelectSingleNode("//ns:Data[@Name='Capacity']", $ns).'#text'
            $sizeStr = ""
            if ($capacityBytes) {
                $sizeStr = "($([math]::Round([int64]$capacityBytes / 1GB, 2)) GB)"
            }

            if ($event.Id -eq 1006) {
                Write-Host "  [$time]" -NoNewline -ForegroundColor Gray
                Write-Host " [PLUGGED IN]  " -NoNewline -ForegroundColor Green
                Write-Host "USB Storage Device Connected $sizeStr" -ForegroundColor White
            } else {
                Write-Host "  [$time]" -NoNewline -ForegroundColor Gray
                Write-Host " [REMOVED]     " -NoNewline -ForegroundColor Red
                Write-Host "USB Storage Device Disconnected" -ForegroundColor White
            }
        }
    } else {
        Write-Host "  [!] No USB storage connection log entries found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [-] Error reading partition log database." -ForegroundColor Red
}

Write-Host "`n[➔] Scanning All Currently Connected Hardware..." -ForegroundColor Gray
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray

$pnpDevices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue | 
              Where-Object { $_.Status -eq "OK" } | 
              Group-Object PNPClass | 
              Sort-Object Name

if ($pnpDevices) {
    foreach ($group in $pnpDevices) {
        $className = if ($group.Name) { $group.Name.ToUpper() } else { "UNKNOWN CLASS" }
        Write-Host " [$className] ($($group.Count) Devices)" -ForegroundColor Yellow
        
        foreach ($device in $group.Group) {
            $manufacturer = if ($device.Manufacturer) { "[$($device.Manufacturer)]" } else { "" }
            Write-Host "   ➔ $($device.Name) " -NoNewline -ForegroundColor White
            Write-Host $manufacturer -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "  [-] Error: Could not query PnP hardware list." -ForegroundColor Red
}