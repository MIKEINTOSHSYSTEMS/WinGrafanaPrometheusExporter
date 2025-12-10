Write-Host "=== Prerequisites Check ===" -ForegroundColor Cyan

# Check OS
$OS = Get-WmiObject -Class Win32_OperatingSystem
Write-Host "OS: $($OS.Caption)" -ForegroundColor $(if ($OS.Caption -like "*Server*" -or $OS.Caption -like "*Windows 10*" -or $OS.Caption -like "*Windows 11*") {"Green"} else {"Red"})

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Running as Admin: $isAdmin" -ForegroundColor $(if ($isAdmin) {"Green"} else {"Red"})

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    Write-Host "Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker: NOT FOUND" -ForegroundColor Red
}

# Check Docker Compose
try {
    $composeVersion = docker-compose --version 2>$null
    Write-Host "Docker Compose: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker Compose: NOT FOUND" -ForegroundColor Red
}

# Check ports availability
$ports = @(3000, 9090, 9182)
foreach ($port in $ports) {
    $test = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    Write-Host "Port $port available: $($test.TcpTestSucceeded -eq $false)" -ForegroundColor $(if ($test.TcpTestSucceeded -eq $false) {"Green"} else {"Red"})
}

# Check virtualization
try {
    $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    Write-Host "Hyper-V: $($hyperv.State)" -ForegroundColor $(if ($hyperv.State -eq "Enabled") {"Green"} else {"Yellow"})
} catch {
    Write-Host "Hyper-V: N/A" -ForegroundColor Yellow
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "If any checks show RED, please fix before proceeding." -ForegroundColor Yellow