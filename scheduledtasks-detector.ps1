Start-Sleep -Seconds 1
Clear-Host

Write-Host @"
 _________  ________  ________  ___     
|\___   ___\\   __  \|\   __  \|\  \    
\|___ \  \_\ \  \|\  \ \  \|\  \ \  \   
     \ \  \ \ \  \\\  \ \   __  \ \  \  
      \ \  \ \ \  \\\  \ \  \|\  \ \  \ 
       \ \__\ \ \_______\ \_______\ \__\
        \|__|  \|_______|\|_______|\|__|
        
       [ Persistence & Task Scheduler Auditor ]
       Engineered by TOBI // @124tobi1231   
"@ -ForegroundColor Cyan

Write-Host "`n[➔] Extracting scheduling objects and auditing execution targets..." -ForegroundColor Gray

# Hardcoded absolute directory paths to prevent ERR_FILE_NOT_FOUND browser drops
$outputDir  = "C:\Screenshare"
$outputFile = "$outputDir\ScheduledTaskResults.html"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Deep Authenticode Cryptographic Analyzer
function Test-ExtendedSignature {
    param ([string]$filePath)
    
    if ([string]::IsNullOrWhiteSpace($filePath) -or -not (Test-Path -LiteralPath $filePath -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{ Status = "❌ Missing / Invalid Path"; Class = "status-invalid"; Subject = "N/A" }
    }

    try {
        $sig = Get-AuthenticodeSignature -FilePath $filePath -ErrorAction Stop
        $status = $sig.Status
        $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { "No Signer Context" }
        
        switch ($status) {
            "Valid" {
                return [PSCustomObject]@{ Status = "✅ Valid Signature"; Class = "status-valid"; Subject = $subject }
            }
            "HashMismatch" {
                return [PSCustomObject]@{ Status = "❌ Hash Mismatch (Modified)"; Class = "status-invalid"; Subject = $subject }
            }
            "NotSigned" {
                return [PSCustomObject]@{ Status = "⚠ Unsigned Binary"; Class = "status-unsigned"; Subject = "N/A" }
            }
            "NotTrusted" {
                return [PSCustomObject]@{ Status = "❌ Untrusted Root / Chain"; Class = "status-invalid"; Subject = $subject }
            }
            "IncompleteChain" {
                return [PSCustomObject]@{ Status = "❌ Incomplete Chain"; Class = "status-invalid"; Subject = $subject }
            }
            "UnknownError" {
                if ($sig.StatusMessage -like "*expired*") {
                    return [PSCustomObject]@{ Status = "⏳ Expired Certificate"; Class = "status-warning"; Subject = $subject }
                }
                return [PSCustomObject]@{ Status = "❌ Revoked / Malformed"; Class = "status-invalid"; Subject = $subject }
            }
            Default {
                return [PSCustomObject]@{ Status = "❌ Error ($status)"; Class = "status-invalid"; Subject = $subject }
            }
        }
    } catch {
        return [PSCustomObject]@{ Status = "⚠ Execution Blocked"; Class = "status-unsigned"; Subject = "N/A" }
    }
}

function Get-FullPath {
    param([string]$ExePath)
    if ([string]::IsNullOrWhiteSpace($ExePath)) { return $null }
    
    $ExePath = $ExePath.Trim('"').Trim()
    if (Test-Path -LiteralPath $ExePath -ErrorAction SilentlyContinue) { return $ExePath }
    
    if ($ExePath -notmatch '\\') {
        $whereResult = Get-Command $ExePath -ErrorAction SilentlyContinue
        if ($whereResult) { return $whereResult.Path }
    }
    
    try {
        $expandedPath = [Environment]::ExpandEnvironmentVariables($ExePath)
        if ($expandedPath -ne $ExePath -and (Test-Path -LiteralPath $expandedPath -ErrorAction SilentlyContinue)) {
            return $expandedPath
        }
    } catch {}
    
    return $null
}

$suspectPrograms = @("cmd.exe", "powershell.exe", "powershell_ise.exe", "rundll32.exe", "regsvr32.exe", "taskmgr.exe", "LaunchTM.exe", "WinRAR.exe")

$allTasks = Get-ScheduledTask
$tableRowsHTML = ""

# Telemetry Counter Blocks
$totalAuditedTasks = 0
$flaggedCount      = 0
$unsignedTaskCount = 0
$invalidPathCount  = 0
$validSignedCount  = 0

foreach ($task in $allTasks) {
    try {
        if ($task.Actions -and $task.Actions.Count -gt 0) {
            foreach ($action in $task.Actions) {
                if ($action.Execute -and $action.Execute.Trim()) {
                    $totalAuditedTasks++
                    
                    $exeName = [System.IO.Path]::GetFileName($action.Execute.Trim('"'))
                    $exePath = Get-FullPath -ExePath $action.Execute
                    
                    $isSuspicious = $suspectPrograms -contains $exeName.ToLower()
                    $sigAnalysis  = Test-ExtendedSignature -filePath $exePath
                    
                    if ($isSuspicious) { $flaggedCount++ }
                    if ($sigAnalysis.Class -eq "status-unsigned") { $unsignedTaskCount++ }
                    if ($sigAnalysis.Status -like "*Missing*") { $invalidPathCount++ }
                    if ($sigAnalysis.Class -eq "status-valid") { $validSignedCount++ }

                    if ($isSuspicious -or $sigAnalysis.Class -ne "status-valid") {
                        
                        $taskName    = $task.TaskName
                        $taskPath    = $task.TaskPath
                        $execCommand = $action.Execute
                        $arguments   = if ($action.Arguments) { $action.Arguments } else { "None" }
                        $resolved    = if ($exePath) { $exePath } else { "Unresolved" }
                        $suspBadge   = if ($isSuspicious) { "<span class='badge status-invalid'>High Risk Shell</span>" } else { "<span class='badge status-unsigned'>Standard</span>" }
                        $certSigner  = $sigAnalysis.Subject

                        $escapedTaskName = $taskName.Replace("\", "\\").Replace("'", "\'")

                        $tableRowsHTML += @"
                        <tr onclick="copyToClipboard('$escapedTaskName')">
                            <td class="file-name">$taskName</td>
                            <td class="text-muted text-monospace">$taskPath</td>
                            <td class="text-monospace" style="color: var(--accent-cyan); font-weight: 600;">$execCommand</td>
                            <td class="text-muted text-monospace ellipsis" title="$arguments">$arguments</td>
                            <td class="text-muted text-monospace ellipsis" title="$resolved">$resolved</td>
                            <td>$suspBadge</td>
                            <td><span class="badge $($sigAnalysis.Class)">$($sigAnalysis.Status)</span></td>
                            <td class="text-muted ellipsis" title="$certSigner">$certSigner</td>
                        </tr>
"@
                    }
                }
            }
        }
    }
    catch {
        Write-Host "Error parsing context parameters on: $($task.TaskName)" -ForegroundColor Red
    }
}

# Modern Dark UI Framework Layout Engine Document Template
$htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>TOBI // Task Scheduler Security Dashboard</title>
    <style>
        :root {
            --bg-dark: #121212;
            --bg-panel: #1e1e1e;
            --bg-input: #2d2d2d;
            --text-white: #f5f5f5;
            --text-gray: #a0a0a0;
            --accent-cyan: #00b4d8;
            --accent-blue: #0077b6;
            --stat-green: #2ec4b6;
            --stat-red: #e63946;
            --stat-yellow: #ffb703;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: var(--bg-dark);
            color: var(--text-white);
            margin: 0;
            padding: 30px;
        }

        .header {
            margin-bottom: 30px;
            border-bottom: 1px solid var(--bg-input);
            padding-bottom: 20px;
        }

        .header h1 {
            margin: 0 0 5px 0;
            color: var(--accent-cyan);
            font-size: 28px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }

        .header .subtitle {
            color: var(--text-gray);
            font-size: 14px;
            font-style: italic;
        }

        .analytics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }

        .card {
            background-color: var(--bg-panel);
            padding: 15px 20px;
            border-radius: 6px;
            border-left: 4px solid var(--bg-input);
        }

        .card.total      { border-left-color: var(--text-white); }
        .card.suspicious { border-left-color: var(--stat-red); }
        .card.unsigned   { border-left-color: var(--stat-yellow); }
        .card.missing    { border-left-color: #560bad; }
        .card.signed     { border-left-color: var(--stat-green); }

        .card-label {
            font-size: 11px;
            text-transform: uppercase;
            color: var(--text-gray);
            font-weight: bold;
            letter-spacing: 0.5px;
        }

        .card-value {
            font-size: 24px;
            font-weight: bold;
            margin-top: 5px;
        }

        .controls-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            background-color: var(--bg-panel);
            padding: 12px 20px;
            border-radius: 6px;
        }

        .search-container input {
            background-color: var(--bg-input);
            border: 1px solid #404040;
            padding: 8px 15px;
            color: var(--text-white);
            border-radius: 4px;
            width: 320px;
            font-size: 14px;
            outline: none;
            transition: border-color 0.2s;
        }

        .search-container input:focus {
            border-color: var(--accent-cyan);
        }

        .table-container {
            background-color: var(--bg-panel);
            border-radius: 6px;
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 14px;
        }

        th {
            background-color: #252525;
            color: var(--accent-cyan);
            padding: 12px 15px;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
            border-bottom: 2px solid var(--bg-input);
        }

        td {
            padding: 12px 15px;
            border-bottom: 1px solid var(--bg-input);
            max-width: 260px;
            overflow: hidden;
        }

        tr {
            cursor: pointer;
            transition: background-color 0.15s ease;
        }

        tr:hover {
            background-color: #262626;
        }

        .file-name {
            font-weight: 600;
            color: var(--text-white);
        }

        .text-muted { color: var(--text-gray); }
        .text-monospace { font-family: 'Consolas', 'Courier New', monospace; font-size: 13px; }
        
        .ellipsis {
            white-space: nowrap;
            text-overflow: ellipsis;
        }

        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        .status-valid { background-color: rgba(46, 196, 182, 0.15); color: var(--stat-green); }
        .status-invalid { background-color: rgba(230, 57, 70, 0.15); color: var(--stat-red); }
        .status-unsigned { background-color: rgba(160, 160, 160, 0.15); color: var(--text-gray); }
        .status-warning { background-color: rgba(255, 183, 3, 0.15); color: var(--stat-yellow); }

        #toast {
            position: fixed;
            bottom: 30px;
            right: 30px;
            background-color: var(--accent-blue);
            color: var(--text-white);
            padding: 10px 20px;
            border-radius: 4px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(0,0,0,0.5);
            display: none;
            z-index: 1000;
        }
    </style>
    <script>
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(function() {
                var toast = document.getElementById('toast');
                toast.style.display = 'block';
                setTimeout(function() { toast.style.display = 'none'; }, 2000);
            });
        }

        function filterGrid() {
            var input = document.getElementById("searchBox").value.toLowerCase();
            var rows = document.getElementById("mainTableBody").getElementsByTagName("tr");
            for (var i = 0; i < rows.length; i++) {
                var match = false;
                var cells = rows[i].getElementsByTagName("td");
                for (var j = 0; j < cells.length; j++) {
                    if (cells[j].textContent.toLowerCase().includes(input)) {
                        match = true;
                        break;
                    }
                }
                rows[i].style.display = match ? "" : "none";
            }
        }
    </script>
</head>
<body>

    <div class="header">
        <h1>Task Scheduler Security & Persistence Auditor</h1>
        <div class="subtitle">Engineered by TOBI // @124tobi1231</div>
    </div>

    <div class="analytics-grid">
        <div class="card total">
            <div class="card-label">Total Actions Audited</div>
            <div class="card-value">$totalAuditedTasks</div>
        </div>
        <div class="card suspicious">
            <div class="card-label">Shell / Script Enclaves</div>
            <div class="card-value" style="color: var(--stat-red);">$flaggedCount</div>
        </div>
        <div class="card unsigned">
            <div class="card-label">Unsigned Binaries</div>
            <div class="card-value" style="color: var(--stat-yellow);">$unsignedTaskCount</div>
        </div>
        <div class="card missing">
            <div class="card-label">Broken / Invalid Paths</div>
            <div class="card-value" style="color: #b5179e;">$invalidPathCount</div>
        </div>
        <div class="card signed">
            <div class="card-label">Verified Valid Targets</div>
            <div class="card-value" style="color: var(--stat-green);">$validSignedCount</div>
        </div>
    </div>

    <div class="controls-bar">
        <div class="search-container">
            <input type="text" id="searchBox" onkeyup="filterGrid()" placeholder="Filter flagged tasks by keyword metadata...">
        </div>
        <div class="text-muted" style="font-size: 13px;">Click a record row to clone the Task Name directly to your clipboard.</div>
    </div>

    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Task Identity Context</th>
                    <th>Node Group Path</th>
                    <th>Assigned Executable</th>
                    <th>Runtime Arguments</th>
                    <th>Resolved Location</th>
                    <th>Risk Class</th>
                    <th>Signature Diagnostics</th>
                    <th>Certificate Signer Context</th>
                </tr>
            </thead>
            <tbody id="mainTableBody">
                $tableRowsHTML
            </tbody>
        </table>
    </div>

    <div id="toast">Task Name node identifier mirrored to clipboard.</div>

</body>
</html>
"@

# Write matrix layout template out to storage log asset
$htmlTemplate | Out-File -Encoding UTF8 $outputFile
Start-Process $outputFile

Write-Host "`n[+] Audit verified. Output compiled to: $outputFile" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray

Read-Host -Prompt "Press Enter to safely exit the pipeline console window"