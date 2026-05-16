Write-Host @"
 _________  ________  ________  ___     
|\___   ___\\   __  \|\   __  \|\  \    
\|___ \  \_\ \  \|\  \ \  \|\  \ \  \   
     \ \  \ \ \  \\\  \ \   __  \ \  \  
      \ \  \ \ \  \\\  \ \  \|\  \ \  \ 
       \ \__\ \ \_______\ \_______\ \__\
        \|__|  \|_______|\|_______|\|__|
        
       [ Service Control Environment ]
       Engineered by TOBI // @124tobi1231                                 
"@ -ForegroundColor Cyan

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Extended Service Target Array ---
$servicesToCheck = @(
    "SysMain","PcaSvc","DPS","EventLog","Schedule","Bam","wsearch",
    "Appinfo","SSDPSRV","CDPSvc","DcomLaunch","PlugPlay",
    "DiagTrack","DusmSvc","WerSvc","WbioSrvc","Spooler",
    "CryptSvc","Dhcp","Dnscache","BFE"
)

# --- Service Functional Descriptions ---
$serviceDescriptions = @{
    "SysMain"    = "Prefetch engine for application acceleration"
    "PcaSvc"     = "Program Compatibility Assistant tracking"
    "DPS"        = "Diagnostic Policy troubleshooting framework"
    "EventLog"   = "Centralized systemic event logging core"
    "Schedule"   = "Task Scheduler automation routing subsystem"
    "Bam"        = "Background Activity Moderator processing control"
    "wsearch"    = "Windows Search indexing and tracking index"
    "Appinfo"    = "Application Information facilitating UAC execution"
    "SSDPSRV"    = "SSDP local network device discovery"
    "CDPSvc"     = "Connected Devices Platform synchronization"
    "DcomLaunch" = "DCOM Object Server infrastructure execution"
    "PlugPlay"   = "Plug and Play hardware device abstraction manager"
    "DiagTrack"  = "Connected User Experiences / Telemetry pipelines"
    "DusmSvc"    = "Data Usage network capacity and packet metrics"
    "WerSvc"     = "Windows Error Reporting infrastructure execution"
    "WbioSrvc"   = "Windows Biometric credential tracking pipeline"
    "Spooler"    = "Print Spooler print management background routing"
    "CryptSvc"   = "Cryptographic Services catalog and file signature verification"
    "Dhcp"       = "DHCP Client network registration and auto-config"
    "Dnscache"   = "DNS Client name resolution caching and storage"
    "BFE"        = "Base Filtering Engine security policy enforcement"
}

# --- Design Language Palette ---
$bgDark      = [System.Drawing.Color]::FromArgb(20, 20, 20)
$bgPanel     = [System.Drawing.Color]::FromArgb(30, 30, 30)
$bgInput     = [System.Drawing.Color]::FromArgb(40, 40, 40)
$textWhite   = [System.Drawing.Color]::FromArgb(245, 245, 245)
$textGray    = [System.Drawing.Color]::FromArgb(150, 150, 150)
$accentCyan  = [System.Drawing.Color]::FromArgb(0, 180, 216)
$accentBlue  = [System.Drawing.Color]::FromArgb(0, 119, 182)
$statGreen   = [System.Drawing.Color]::FromArgb(46, 196, 182)
$statRed     = [System.Drawing.Color]::FromArgb(230, 57, 70)

# --- Main Window Configuration ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "TOBI // Advanced Service Architecture Interface"
$form.Size = New-Object System.Drawing.Size(740, 640)
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false
$form.FormBorderStyle = "FixedDialog"
$form.BackColor = $bgDark

# --- Real-Time Analytics Dashboard Panel ---
$statsPanel = New-Object System.Windows.Forms.Panel
$statsPanel.Size = New-Object System.Drawing.Size(680, 55)
$statsPanel.Location = New-Object System.Drawing.Point(20, 20)
$statsPanel.BackColor = $bgPanel

$lblTotal = New-Object System.Windows.Forms.Label
$lblTotal.Size = New-Object System.Drawing.Size(180, 35)
$lblTotal.Location = New-Object System.Drawing.Point(20, 12)
$lblTotal.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblTotal.ForeColor = $textWhite

$lblRunning = New-Object System.Windows.Forms.Label
$lblRunning.Size = New-Object System.Drawing.Size(180, 35)
$lblRunning.Location = New-Object System.Drawing.Point(240, 12)
$lblRunning.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblRunning.ForeColor = $statGreen

$lblStopped = New-Object System.Windows.Forms.Label
$lblStopped.Size = New-Object System.Drawing.Size(180, 35)
$lblStopped.Location = New-Object System.Drawing.Point(460, 12)
$lblStopped.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblStopped.ForeColor = $statRed

$statsPanel.Controls.AddRange(@($lblTotal, $lblRunning, $lblStopped))
$form.Controls.Add($statsPanel)

# --- Service Execution Grid View ---
$listView = New-Object System.Windows.Forms.ListView
$listView.Size = New-Object System.Drawing.Size(680, 400)
$listView.Location = New-Object System.Drawing.Point(20, 90)
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.GridLines = $false
$listView.MultiSelect = $true
$listView.CheckBoxes = $true
$listView.BorderStyle = "None"
$listView.BackColor = $bgInput
$listView.ForeColor = $textWhite
$listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$listView.Columns.Add("State", 50) | Out-Null
$listView.Columns.Add("Service Identifier", 130) | Out-Null
$listView.Columns.Add("Status", 85) | Out-Null
$listView.Columns.Add("Startup Type", 100) | Out-Null
$listView.Columns.Add("Functional Operational Scope", 290) | Out-Null

$form.Controls.Add($listView)

# --- Control Execution Action Panel ---
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Size = New-Object System.Drawing.Size(680, 50)
$buttonPanel.Location = New-Object System.Drawing.Point(20, 505)
$buttonPanel.BackColor = $bgPanel

$selectAllBox = New-Object System.Windows.Forms.CheckBox
$selectAllBox.Text = "Toggle All"
$selectAllBox.Size = New-Object System.Drawing.Size(110, 25)
$selectAllBox.Location = New-Object System.Drawing.Point(15, 12)
$selectAllBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$selectAllBox.ForeColor = $textWhite
$selectAllBox.Add_CheckedChanged({
    foreach ($item in $listView.Items) {
        $item.Checked = $selectAllBox.Checked
    }
})
$buttonPanel.Controls.Add($selectAllBox)

$buttonEnable = New-Object System.Windows.Forms.Button
$buttonEnable.Text = "Optimize & Run"
$buttonEnable.Size = New-Object System.Drawing.Size(160, 32)
$buttonEnable.Location = New-Object System.Drawing.Point(330, 9)
$buttonEnable.FlatStyle = "Flat"
$buttonEnable.FlatAppearance.BorderSize = 0
$buttonEnable.BackColor = $accentBlue
$buttonEnable.ForeColor = $textWhite
$buttonEnable.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$buttonPanel.Controls.Add($buttonEnable)

$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Text = "Refresh Grid"
$buttonRefresh.Size = New-Object System.Drawing.Size(150, 32)
$buttonRefresh.Location = New-Object System.Drawing.Point(510, 9)
$buttonRefresh.FlatStyle = "Flat"
$buttonRefresh.FlatAppearance.BorderSize = 1
$buttonRefresh.FlatAppearance.BorderColor = $accentCyan
$buttonRefresh.BackColor = $bgDark
$buttonRefresh.ForeColor = $accentCyan
$buttonRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$buttonPanel.Controls.Add($buttonRefresh)

$form.Controls.Add($buttonPanel)

# --- Footer Metric & Status Tracker ---
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready // Standing by for compilation targets..."
$statusLabel.Size = New-Object System.Drawing.Size(680, 25)
$statusLabel.Location = New-Object System.Drawing.Point(20, 565)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$statusLabel.ForeColor = $textGray
$statusLabel.TextAlign = "MiddleLeft"
$form.Controls.Add($statusLabel)

# --- Operational Logic Processing Functions ---
function Refresh-Services {
    $listView.Items.Clear()
    $runCount = 0
    $stopCount = 0
    
    foreach ($serviceName in $servicesToCheck) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        $description = $serviceDescriptions[$serviceName]
        
        if ($service) {
            $status = $service.Status.ToString()
            $startupObj = Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue
            $startup = if ($startupObj) { $startupObj.StartMode } else { "Unknown" }
            
            $item = New-Object System.Windows.Forms.ListViewItem("")
            $item.Checked = $false
            $item.SubItems.Add($serviceName) | Out-Null
            $item.SubItems.Add($status) | Out-Null
            $item.SubItems.Add($startup) | Out-Null
            $item.SubItems.Add($description) | Out-Null
            
            if ($status -eq "Running") {
                $item.BackColor = [System.Drawing.Color]::FromArgb(35, 55, 40)
                $runCount++
            } else {
                $item.BackColor = [System.Drawing.Color]::FromArgb(60, 35, 35)
                $stopCount++
            }
            $listView.Items.Add($item) | Out-Null
        } else {
            $item = New-Object System.Windows.Forms.ListViewItem("")
            $item.Checked = $false
            $item.SubItems.Add($serviceName) | Out-Null
            $item.SubItems.Add("Not Found") | Out-Null
            $item.SubItems.Add("N/A") | Out-Null
            $item.SubItems.Add($description) | Out-Null
            $item.BackColor = [System.Drawing.Color]::FromArgb(50, 45, 30)
            $stopCount++
            $listView.Items.Add($item) | Out-Null
        }
    }
    
    # Update Top Analytics Panel Data dynamically
    $lblTotal.Text   = "TOTAL TARGETS: $($servicesToCheck.Count)"
    $lblRunning.Text = "RUNNING: $runCount"
    $lblStopped.Text = "STOPPED / INACTIVE: $stopCount"
}

$buttonEnable.Add_Click({
    $selectedCount = 0
    $successCount = 0
    
    foreach ($item in $listView.Items) {
        if ($item.Checked) {
            $selectedCount++
            $serviceName = $item.SubItems[1].Text
            
            try {
                Set-Service -Name $serviceName -StartupType Automatic -ErrorAction SilentlyContinue
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -ne 'Running') {
                    Start-Service -Name $serviceName -ErrorAction SilentlyContinue
                }
                $successCount++
            } catch {}
        }
    }
    
    Refresh-Services
    
    if ($selectedCount -eq 0) {
        $statusLabel.Text = "Aborted: Choose target service nodes before execution."
        $statusLabel.ForeColor = [System.Drawing.Color]::OrangeRed
    } else {
        $statusLabel.Text = "Execution Complete: Successfully authorized and started $successCount of $selectedCount services."
        $statusLabel.ForeColor = [System.Drawing.Color]::LightGreen
    }
})

$buttonRefresh.Add_Click({
    Refresh-Services
    $statusLabel.Text = "Environment registry matrix successfully synchronized and parsed."
    $statusLabel.ForeColor = $textGray
})

# Initial System Diagnostics Generation
Refresh-Services
[void]$form.ShowDialog()