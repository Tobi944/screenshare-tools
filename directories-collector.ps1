Write-Host @"
 _________  ________  ________  ___     
|\___   ___\\   __  \|\   __  \|\  \    
\|___ \  \_\ \  \|\  \ \  \|\  \ \  \   
     \ \  \ \ \  \\\  \ \   __  \ \  \  
      \ \  \ \ \  \\\  \ \  \|\  \ \  \ 
       \ \__\ \ \_______\ \_______\ \__\
        \|__|  \|_______|\|_______|\|__|
        
       [ Cryptographic Authenticode Auditor ]
       Engineered by TOBI // @124tobi1231   
"@ -ForegroundColor Cyan

$directories = @(
    "$env:windir\System32",
    "$env:windir\SysWOW64", 
    "$env:USERPROFILE\AppData\Local\Temp"
)

$outputDir = "C:\Screenshare"
$outputFile = "$outputDir\paths.txt"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Regex Context Class Rules
$microsoftRegex  = [regex]::new('Microsoft|Windows|Redmond', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
$trustedRegex    = [regex]::new('NVIDIA|Intel|AMD|Realtek|VIA|Qualcomm|Razer|Lenovo|Dolby|HP Inc|Dell Inc|ASUS|Acer|Logitech|Corsair', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
$knownCheatRegex = [regex]::new('manthe', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

$knownGoodFiles = @{
    'ntoskrnl.exe' = $true; 'kernel32.dll' = $true; 'user32.dll'   = $true; 'advapi32.dll' = $true
    'shell32.dll'  = $true; 'explorer.exe' = $true; 'svchost.exe'  = $true; 'services.exe' = $true
    'lsass.exe'    = $true; 'csrss.exe'    = $true; 'winlogon.exe' = $true; 'dwm.exe'      = $true
}

$signatureCache = @{}

# Advanced Authenticode Cryptographic Classifier Function
function Test-ShouldIncludeFile {
    param([System.IO.FileInfo]$FileInfo)
    
    try {
        $fileName = $FileInfo.Name
        if ($fileName -like "*.mui") { return $false }
        
        $extension = $FileInfo.Extension.ToLower()
        if ($extension -ne "") {
            $nonExecutableExtensions = @('.evtx', '.etl', '.dat', '.db', '.log', '.log1', '.log2', 
                                         '.regtrans-ms', '.blf', '.cab', '.rtf', '.inf', '.txt',
                                         '.tmp', '.bin', '.bak', '.btx', '.btr', '.wal', '.xml', '.db-wal')
            if ($nonExecutableExtensions -contains $extension) { return $false }
        }

        # Verify executable payload header matrix safely
        try {
            $stream = [System.IO.File]::OpenRead($FileInfo.FullName)
            $buffer = New-Object byte[] 2
            $bytesRead = $stream.Read($buffer, 0, 2)
            $stream.Close()
            if ($bytesRead -lt 2 -or $buffer[0] -ne 0x4D -or $buffer[1] -ne 0x5A) { return $false }
        }
        catch { return $false }

        if ($fileName -match '^(microsoft|windows|ms)') { return $false }
        if ($knownGoodFiles.ContainsKey($fileName.ToLower())) { return $false }

        $filePath = $FileInfo.FullName
        if ($signatureCache.ContainsKey($filePath)) { return $signatureCache[$filePath] }
        
        # Deep signature status analysis mapping logic
        $signature = Get-AuthenticodeSignature -FilePath $filePath -ErrorAction Stop
        $status = $signature.Status
        
        if ($status -eq "Valid" -and $signature.SignerCertificate) {
            $subject = $signature.SignerCertificate.Subject
            
            if ($knownCheatRegex.IsMatch($subject)) {
                $signatureCache[$filePath] = $true
                return $true
            }
            if ($microsoftRegex.IsMatch($subject) -or $trustedRegex.IsMatch($subject)) {
                $signatureCache[$filePath] = $false
                return $false
            }
        }
        elseif ($status -eq "HashMismatch" -or $status -eq "NotTrusted" -or $status -eq "IncompleteChain") {
            # Suspicious or broken chain state detected
            $signatureCache[$filePath] = $true
            return $true
        }

        # Secondary Metadata Fallback check
        try {
            $versionInfo = $FileInfo.VersionInfo
            if ($versionInfo.CompanyName) {
                if ($microsoftRegex.IsMatch($versionInfo.CompanyName) -or $trustedRegex.IsMatch($versionInfo.CompanyName)) {
                    return $false
                }
            }
        } catch {}
        
        return $true
    }
    catch { return $false }
}

if (Test-Path $outputFile) { Remove-Item $outputFile -Force }

Write-Host "Scanning for target data matching criteria..." -ForegroundColor Green
Write-Host "Output Allocation: $outputFile`n" -ForegroundColor Cyan

$startTime = Get-Date
$fileCount = 0
$totalFilesChecked = 0
$stringBuilder = [System.Text.StringBuilder]::new()

foreach ($directory in $directories) {
    if (-not (Test-Path $directory)) {
        Write-Host "Directory not found: $directory" -ForegroundColor Red
        continue
    }
    
    Write-Host "Scanning Node: $directory" -ForegroundColor Yellow
    $dirStartTime = Get-Date
    $dirFileCount = 0
    
    try {
        $files = Get-ChildItem -Path $directory -File -Recurse -Force -ErrorAction SilentlyContinue |
                 Where-Object { $_.Length -ge 300KB }
        
        foreach ($fileInfo in $files) {
            try {
                $totalFilesChecked++
                if ($totalFilesChecked % 500 -eq 0) {
                    Write-Host "   Checked: $totalFilesChecked | Found Unsigned/Flagged: $fileCount" -ForegroundColor Gray
                }
                
                if (Test-ShouldIncludeFile -FileInfo $fileInfo) {
                    [void]$stringBuilder.AppendLine($fileInfo.FullName)
                    $fileCount++
                    $dirFileCount++
                }
            } catch { continue }
        }
        
        $dirTime = (Get-Date) - $dirStartTime
        Write-Host "   Found: $dirFileCount targets in $([math]::Round($dirTime.TotalSeconds, 1))s" -ForegroundColor Green
    }
    catch { Write-Host "   Execution Error: $($_.Exception.Message)" -ForegroundColor Red }
}

# Flush memory collection stream to file storage node
[System.IO.File]::WriteAllText($outputFile, $stringBuilder.ToString(), [System.Text.UTF8Encoding]::new($false))
$totalTime = (Get-Date) - $startTime

Write-Host "`nScan Complete" -ForegroundColor Green
Write-Host "Time Elapsed: $([math]::Round($totalTime.TotalMinutes, 1)) minutes" -ForegroundColor White
Write-Host "Files Checked: $totalFilesChecked" -ForegroundColor White
Write-Host "Unsigned/Flagged Binaries Isolated: $fileCount" -ForegroundColor Cyan

# Clipboard Pipeline Delivery Mechanism (Cap threshold boundary: 10000)
if (Test-Path $outputFile) {
    $lines = Get-Content $outputFile -ErrorAction SilentlyContinue
    $lineCount = ($lines | Measure-Object).Count
    Write-Host "Paths Written to File Log: $lineCount" -ForegroundColor White

    if ($lineCount -gt 0) {
        if ($lineCount -le 10000) {
            $lines | Set-Clipboard
            Write-Host "[+] Clipboard Matrix Sync: All $lineCount paths mirrored to clipboard successfully." -ForegroundColor Green
        } else {
            # Cap the clip arrays exactly at 10,000 entries to prevent global thread locks
            $lines | Select-Object -First 10000 | Set-Clipboard
            Write-Host "[!] Clipboard Overload Boundary: Log file has $lineCount entries. First 10000 paths mirrored to clipboard." -ForegroundColor Yellow
        }

        # Print quick trace samples onto current display layout context
        Write-Host "`nSample Records Matrix:" -ForegroundColor Yellow
        $samplePaths = $lines | Select-Object -First 5
        foreach ($path in $samplePaths) {
            if (Test-Path $path) {
                $fileItem = Get-Item $path -ErrorAction SilentlyContinue
                if ($fileItem) {
                    $sizeMB = [math]::Round($fileItem.Length / 1MB, 2)
                    $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
                    if ($sig -and $sig.SignerCertificate -and ($sig.SignerCertificate.Subject -match 'manthe')) {
                        Write-Host "   [FLAGGED CHEAT] $path ($sizeMB MB)" -ForegroundColor Red
                    } else {
                        Write-Host "   $path ($sizeMB MB)" -ForegroundColor Green
                    }
                }
            }
        }
    }
} else {
    Write-Host "[-] Analysis terminal ended with zero isolated logs." -ForegroundColor Yellow
}

Write-Host "`nRun paths parser with YARA rules on '$outputFile'" -ForegroundColor Green
Write-Host "Pipeline tracking complete." -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray

Read-Host -Prompt "Press Enter to close pipeline window"