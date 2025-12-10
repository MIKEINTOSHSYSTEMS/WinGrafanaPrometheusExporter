# onetimefetch.ps1 - Self-elevating Prometheus Downloader with Progress Bar

# Check if we're running as Administrator, if not, relaunch as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as Administrator. Attempting to elevate..." -ForegroundColor Yellow
    
    # Get the script path
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptDirectory = Split-Path -Parent $scriptPath
    
    # Create a new PowerShell process with Administrator privileges
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""
    $psi.Verb = "runas"  # This triggers UAC elevation
    $psi.WorkingDirectory = $scriptDirectory
    
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        exit 0
    } catch {
        Write-Host "Failed to elevate. Please run this script as Administrator!" -ForegroundColor Red
        Write-Host "Right-click the script and select 'Run as Administrator'" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# ========== MAIN SCRIPT (runs as Administrator) ==========
Write-Host "=== Prometheus Binary Downloader ===" -ForegroundColor Cyan
Write-Host "Running as Administrator: YES" -ForegroundColor Green
Write-Host ""

# Paths
$targetDir = "Prometheus"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetPath = Join-Path $scriptDir $targetDir

# Check if files already exist
if ((Test-Path "$targetPath\prometheus.exe") -and (Test-Path "$targetPath\promtool.exe")) {
    # ASCII Art for files already exist
    Write-Host @"
    
    ╔══════════════════════════════════════════════════════════════╗
    ║                    FILES ALREADY EXIST                       ║
    ║                                                              ║
    ║   ███╗   ███╗██╗██╗  ██╗███████╗██╗███╗   ██╗████████╗       ║
    ║   ████╗ ████║██║██║ ██╔╝██╔════╝██║████╗  ██║╚══██╔══╝       ║
    ║   ██╔████╔██║██║█████╔╝ █████╗  ██║██╔██╗ ██║   ██║          ║
    ║   ██║╚██╔╝██║██║██╔═██╗ ██╔══╝  ██║██║╚██╗██║   ██║          ║
    ║   ██║ ╚═╝ ██║██║██║  ██╗███████╗██║██║ ╚████║   ██║          ║
    ║   ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝          ║
    ║                      MIKEINTOSH SYSTEMS                      ║
    ║           Prometheus binaries already downloaded!            ║
    ║                                                              ║
    ║               Please run 'start.bat' instead.                ║
    ╚══════════════════════════════════════════════════════════════╝
    
"@ -ForegroundColor Yellow
    
    Write-Host "Files already exist. Run start.bat instead." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: Run 'start.bat' to begin monitoring installation." -ForegroundColor Cyan
    Write-Host ""
    pause
    exit 0
}

# Download with Progress Bar
Write-Host "Downloading Prometheus 3.8.0..." -ForegroundColor Yellow
Write-Host "Please Do NOT Close This Window Until Downloads Are Completed!" -ForegroundColor Red
$url = "https://github.com/prometheus/prometheus/releases/download/v3.8.0/prometheus-3.8.0.windows-amd64.zip"
$zipPath = "$env:TEMP\prometheus.zip"

try {
    # Function to show progress bar
    function Show-Progress {
        param(
            [Parameter(Mandatory=$true)]
            [int]$PercentComplete,
            [Parameter(Mandatory=$false)]
            [string]$Activity = "Downloading",
            [Parameter(Mandatory=$false)]
            [string]$Status = "Progress"
        )
        
        $width = 50
        $filled = [math]::Round($width * ($PercentComplete / 100))
        $empty = $width - $filled
        
        # Build progress bar
        $progressBar = "[" + ("#" * $filled) + ("-" * $empty) + "]"
        
        # Update the same line
        Write-Host "`r$Activity $progressBar $PercentComplete% " -NoNewline -ForegroundColor Cyan
    }
    
    # Get file size for progress calculation
    Write-Host "Getting file size..." -ForegroundColor Gray
    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.Method = "HEAD"
    $response = $request.GetResponse()
    $fileSize = $response.ContentLength
    $response.Close()
    
    if ($fileSize -gt 0) {
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Host "File size: $fileSizeMB MB" -ForegroundColor Gray
    }
    
    # Download with progress tracking
    $client = New-Object System.Net.WebClient
    $global:downloadPercent = 0
    
    # Register event for download progress
    Register-ObjectEvent -InputObject $client -EventName DownloadProgressChanged -Action {
        $global:downloadPercent = $args[1].ProgressPercentage
    } | Out-Null
    
    # Start download in background
    Write-Host "`nStarting download..." -ForegroundColor Yellow
    $downloadTask = $client.DownloadFileTaskAsync($url, $zipPath)
    
    # Show progress while downloading
    while (-not $downloadTask.IsCompleted) {
        if ($global:downloadPercent -ne 0) {
            Show-Progress -PercentComplete $global:downloadPercent -Activity "Downloading"
        }
        Start-Sleep -Milliseconds 100
    }
    
    # Clear progress line and show completion
    Write-Host "`r" -NoNewline
    Write-Host (" " * 70) -NoNewline
    Write-Host "`r" -NoNewline
    
    Write-Host "`r[##################################################] 100%" -ForegroundColor Green
    Write-Host "Download complete!" -ForegroundColor Green
    
    # Unregister event
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $client } | Unregister-Event
    $client.Dispose()
    
} catch {
    Write-Host "`nDownload failed: $_" -ForegroundColor Red
    pause
    exit 1
}

# Extract
Write-Host "`nExtracting files..." -ForegroundColor Yellow
$extractPath = "$env:TEMP\prometheus_extract"
try {
    # Show extraction progress
    Write-Host "Extracting ZIP file..." -NoNewline
    
    # Check if 7zip is available for better progress, otherwise use default
    $sevenZipPath = "$env:ProgramFiles\7-Zip\7z.exe"
    if (Test-Path $sevenZipPath) {
        # Use 7zip for better extraction with progress
        & $sevenZipPath x "$zipPath" "-o$extractPath" -y | Out-Null
    } else {
        # Use PowerShell's Expand-Archive
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    }
    
    Write-Host "`rExtracting ZIP file... [DONE]" -ForegroundColor Green
} catch {
    Write-Host "`rExtracting ZIP file... [FAILED]" -ForegroundColor Red
    Write-Host "Extraction failed: $_" -ForegroundColor Red
    pause
    exit 1
}

# Find the extracted folder
Write-Host "Locating extracted files..." -NoNewline
$prometheusFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
Write-Host "`rLocating extracted files... [DONE]" -ForegroundColor Green

if (-not $prometheusFolder) {
    Write-Host "ERROR: Could not find extracted Prometheus folder!" -ForegroundColor Red
    Write-Host "Please check the ZIP file at: $zipPath" -ForegroundColor Yellow
    pause
    exit 1
}

# Copy files
Write-Host "`nCopying files to $targetDir..." -ForegroundColor Yellow

# Create target directory if it doesn't exist
if (-not (Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    Write-Host "Created directory: $targetDir" -ForegroundColor Gray
}

# Copy required files with progress
$files = @("prometheus.exe", "promtool.exe", "LICENSE", "NOTICE")
$totalFiles = $files.Count
$currentFile = 0

foreach ($file in $files) {
    $currentFile++
    $source = Join-Path $prometheusFolder.FullName $file
    $destination = Join-Path $targetPath $file
    
    # Show copy progress
    $percent = [math]::Round(($currentFile / $totalFiles) * 100)
    $progressBar = "[" + ("#" * [math]::Round($percent / 2)) + ("-" * (50 - [math]::Round($percent / 2))) + "]"
    Write-Host "`rCopying files... $progressBar $percent% " -NoNewline -ForegroundColor Cyan
    
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $destination -Force
    } elseif ($file -in @("prometheus.exe", "promtool.exe")) {
        Write-Host "`nERROR: $file not found in extracted files!" -ForegroundColor Red
        pause
        exit 1
    }
    
    Start-Sleep -Milliseconds 100  # Small delay for visual effect
}

# Clear progress line and show completion
Write-Host "`r" -NoNewline
Write-Host (" " * 70) -NoNewline
Write-Host "`r" -NoNewline
Write-Host "`rCopying files... [##################################################] 100%" -ForegroundColor Green
Write-Host "All files copied successfully!" -ForegroundColor Green

# Cleanup
Write-Host "`nCleaning up temporary files..." -NoNewline
Remove-Item -Path $zipPath -ErrorAction SilentlyContinue
Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`rCleaning up temporary files... [DONE]" -ForegroundColor Green

# Success Message with ASCII Art
Write-Host @"

    ╔══════════════════════════════════════════════════════════════╗
    ║                      DOWNLOAD COMPLETE!                      ║
    ║                                                              ║
    ║   ███╗   ███╗██╗██╗  ██╗███████╗██╗███╗   ██╗████████╗       ║
    ║   ████╗ ████║██║██║ ██╔╝██╔════╝██║████╗  ██║╚══██╔══╝       ║
    ║   ██╔████╔██║██║█████╔╝ █████╗  ██║██╔██╗ ██║   ██║          ║
    ║   ██║╚██╔╝██║██║██╔═██╗ ██╔══╝  ██║██║╚██╗██║   ██║          ║
    ║   ██║ ╚═╝ ██║██║██║  ██╗███████╗██║██║ ╚████║   ██║          ║
    ║   ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝          ║
    ║                      MIKEINTOSH SYSTEMS                      ║
    ║                  Prometheus 3.8.0 Installed!                 ║
    ╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Show file sizes
$prometheusSize = [math]::Round((Get-Item "$targetPath\prometheus.exe").Length / 1MB, 2)
$promtoolSize = [math]::Round((Get-Item "$targetPath\promtool.exe").Length / 1MB, 2)
Write-Host "File sizes:" -ForegroundColor Cyan
Write-Host "  • prometheus.exe: $prometheusSize MB" -ForegroundColor White
Write-Host "  • promtool.exe: $promtoolSize MB" -ForegroundColor White

# Show verification
Write-Host "`nVerification:" -ForegroundColor Cyan
if (Test-Path "$targetPath\prometheus.exe") {
    Write-Host "  ✓ prometheus.exe verified" -ForegroundColor Green
} else {
    Write-Host "  ✗ prometheus.exe missing!" -ForegroundColor Red
}

if (Test-Path "$targetPath\promtool.exe") {
    Write-Host "  ✓ promtool.exe verified" -ForegroundColor Green
} else {
    Write-Host "  ✗ promtool.exe missing!" -ForegroundColor Red
}

Write-Host "`n" + ("-"*60) -ForegroundColor Gray
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Run 'start.bat' to install the monitoring stack" -ForegroundColor White
Write-Host "2. Access Grafana at: http://localhost:3000" -ForegroundColor White
Write-Host "3. Login with admin/admin" -ForegroundColor White
Write-Host "4. Import Dashboard ID: 24390" -ForegroundColor White
Write-Host ("-"*60) -ForegroundColor Gray

# Wait for key press
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")