# 🚀 Windows Server Monitoring - One-Click Installation

## 📋 Overview
A complete, automated Windows Server monitoring solution using Prometheus, windows_exporter, and Grafana. Clone, run one batch file, and get a full monitoring dashboard in minutes!

## 📁 Repository Structure
```
WinGrafanaPrometheusExporter/
├── Grafana/
│   └── docker-compose.yml
├── Prometheus/
│   ├── prometheus.exe        (will be downloaded)
│   ├── prometheus.yml
│   ├── promtool.exe          (will be downloaded)
│   ├── LICENSE               (optional copy)
│   └── NOTICE                (optional copy)
├── windows_exporter/
│   ├── windows_exporter.exe
│   ├── config.yaml
│   └── textfile_inputs/
├── onetimefetch.bat          (new - download Prometheus binaries)
├── onetimefetch.ps1          (optional PowerShell version)
├── start.bat
├── stop.bat
├── restart.bat
├── status.bat
├── uninstall.bat
└── README.md
```


# 📋 Prerequisites

Before running the monitoring stack, ensure your Windows Server meets the following requirements:

## **1. Operating System Requirements**
- **Windows Server 2016** or later
- **Windows 10/11** (for desktop Windows monitoring)
- **Administrator privileges** (required for service installation)

## **2. Docker Requirements**

### **Option A: Docker Desktop (Recommended)**
- **Download:** [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **Minimum Version:** Docker Desktop 4.0+
- **Requirements:**
  - Windows 10/11 Pro, Enterprise, or Education (64-bit)
  - Windows Server 2016+ (with Windows Server containers)
  - WSL 2 backend (Windows 10/11)
  - Hyper-V enabled (for older Windows versions)
  - Virtualization enabled in BIOS

### **Option B: Docker Engine Only**
- **For Windows Server Core:** Use Docker Engine without Desktop UI
- **Install via PowerShell:**
  ```powershell
  # Install Docker Engine
  Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
  Install-Package -Name docker -ProviderName DockerMsftProvider -Force
  Start-Service docker
  ```

### **Option C: Docker Compose Standalone**
If Docker Desktop is not available, install Docker Compose separately:
```powershell
# Download Docker Compose
Invoke-WebRequest "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-windows-x86_64.exe" -UseBasicParsing -OutFile "C:\Program Files\Docker\Docker\resources\bin\docker-compose.exe"
```

## **3. System Resources**
- **RAM:** Minimum 4GB (8GB recommended)
- **CPU:** 2 cores minimum (4 cores recommended)
- **Disk Space:** 2GB free space for containers and metrics storage

## **4. Network Requirements**
- **Ports that will be used:**
  - `3000` - Grafana web interface
  - `9090` - Prometheus web interface
  - `9182` - windows_exporter metrics endpoint
- **Firewall:** Administrator access to configure Windows Firewall rules
- **Network connectivity:** For downloading Docker images from Docker Hub

## **5. Required Windows Features**

### **Enable Containers Feature (Windows Server)**
```powershell
# Install Containers feature
Install-WindowsFeature -Name Containers
Restart-Computer -Force
```

### **Enable Hyper-V (if needed)**
```powershell
# For Windows 10/11 Pro/Enterprise
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### **Enable WSL 2 (Windows 10/11 with Docker Desktop)**
```powershell
# Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Set WSL 2 as default
wsl --set-default-version 2
```

## **6. PowerShell Requirements**
- **PowerShell 5.1** or later
- **Execution Policy** allowing script execution:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## **7. Git (Optional but Recommended)**
For cloning the repository:
```powershell
# Install Git for Windows
# Download from: https://git-scm.com/download/win

# Or using winget (Windows 11)
winget install --id Git.Git -e --source winget
```

## **8. Verification Checklist**

Before proceeding, verify all prerequisites:

### **Run Prerequisites Check Script:**
Create `check-prereqs.ps1`:
```powershell
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
```

Run the check:
```powershell
powershell -ExecutionPolicy Bypass -File check-prereqs.ps1
```

## **9. Quick Fixes for Common Issues**

### **Docker not starting?**
```powershell
# Check Docker service
Get-Service docker

# Start Docker service
Start-Service docker

# For Docker Desktop, ensure it's running from system tray
```

### **Ports already in use?**
```powershell
# Find process using port
netstat -ano | findstr :3000
# Kill process if needed (replace PID)
taskkill /F /PID <PID>
```

### **Hyper-V not enabled?**
```powershell
# Enable via PowerShell (requires restart)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### **WSL 2 not installed?**
```powershell
# Install WSL 2
wsl --install
```

## **10. Alternative: Using Windows Server Core**

For Windows Server Core (no GUI), minimal requirements:
- Docker Engine installed via PowerShell
- PowerShell 5.1+
- Network access to download images
- Command-line access only

## **⚠️ Important Notes**

1. **Containers vs Hyper-V Containers:**
   - Windows Server 2016+: Use Windows containers
   - Windows 10/11: Use WSL 2 with Linux containers (recommended)

2. **Anti-Virus Software:**
   - Some AV software may block Docker
   - Add exceptions for Docker processes

3. **Corporate Environment:**
   - May require proxy configuration
   - May need firewall exceptions
   - Docker Hub access might be restricted

4. **Storage Location:**
   - Docker Desktop defaults to `C:\Users\<user>\AppData\Local\Docker`
   - Ensure sufficient space on system drive

## **🎯 Ready to Proceed?**

Once all prerequisites are met, you can:
1. Clone the repository
2. Run `start.bat` as Administrator
3. Access Grafana at `http://localhost:3000`

If any prerequisite fails, fix it before proceeding with the installation.

---

**Next Step:** Once prerequisites are verified, proceed to [Installation Instructions](#one-click-installation).


---

## 🎯 <a id="one-click-installation"></a>One-Click Installation

### **Step 1: Clone and Navigate**
```cmd
cd C:\
git clone https://github.com/MIKEINTOSHSYSTEMS/WinGrafanaPrometheusExporter.git
cd WinGrafanaPrometheusExporter
```

### **Step 2: Run the Installation**

Start fetching the Prometheus services (Double Click on it or run it as Admin)

```cmd
.\run-onetimefetch.bat
```
or Individual alternatives below

Option 1: Run onetimefetch.bat as Administrator by Rightclicking and Click on Run As Administrator:

```cmd
.\onetimefetch.bat
```

OR

Option 2: Run the onetimefetcher In Powershell where the file exists:
```powershell
powershell -ExecutionPolicy Bypass -File onetimefetch.ps1
```

Then

```cmd
start.bat
```
**OR** Simply double-click `start.bat` in File Explorer

## 📦 What the Installation Does

The `start.bat` script will:

1. ✅ **Install windows_exporter as a Windows Service**
2. ✅ **Install Prometheus as a Windows Service**
3. ✅ **Start Grafana using Docker**
4. ✅ **Configure Windows Firewall rules**
5. ✅ **Verify all components are running**
6. ✅ **Provide access URLs**

## 🔧 Manual Installation (Alternative)

If you prefer manual steps:

### **1. Install as Services**
Run these commands **as Administrator**:

```cmd
# Navigate to repository
cd C:\WinGrafanaPrometheusExporter

# Install windows_exporter service
sc create windows_exporter binpath="C:\WinGrafanaPrometheusExporter\windows_exporter\windows_exporter.exe" start=auto
sc start windows_exporter

# Install Prometheus service
sc create Prometheus binpath="C:\WinGrafanaPrometheusExporter\Prometheus\prometheus.exe --config.file=C:\WinGrafanaPrometheusExporter\Prometheus\prometheus.yml" start=auto
sc start Prometheus

# Start Grafana
cd Grafana
docker-compose up -d
```

### **2. Configure Grafana**
1. Open browser to: `http://localhost:3000`
2. Login: `admin` / `admin`
3. Add Prometheus data source:
   - URL: `http://host.docker.internal:9090`
4. Import Dashboard:
   - Click "+" → "Import"
   - Enter ID: `24390`
   - Select Prometheus data source
   - Click "Import"

## 📊 Dashboard Preview

Dashboard ID **24390** provides:
- ✅ **Real-time CPU monitoring** (overall and per-core)
- ✅ **Memory usage** (used, cached, available)
- ✅ **Disk I/O** per volume
- ✅ **Network traffic** per interface
- ✅ **System uptime** and processes
- ✅ **Service status** monitoring
- ✅ **Hardware metrics** (temperature, power if available)

## 🛠️ Management Scripts

### **`start.bat`** - Start all services
```batch
@echo off
echo Starting Windows Monitoring Stack...
sc start windows_exporter
sc start Prometheus
cd /d "%~dp0Grafana"
docker-compose up -d
echo.
echo All services started!
echo Access Grafana at: http://localhost:3000
pause
```

### **`stop.bat`** - Stop all services
```batch
@echo off
echo Stopping Windows Monitoring Stack...
sc stop windows_exporter
sc stop Prometheus
cd /d "%~dp0Grafana"
docker-compose down
echo All services stopped!
pause
```

### **`restart.bat`** - Restart all services
```batch
@echo off
echo Restarting Windows Monitoring Stack...
call stop.bat
timeout /t 5 /nobreak >nul
call start.bat
```

### **`status.bat`** - Check service status
```batch
@echo off
echo === Windows Monitoring Stack Status ===
echo.
echo Windows Services:
sc query windows_exporter | findstr "STATE"
sc query Prometheus | findstr "STATE"
echo.
echo Docker Containers:
docker ps --filter "name=grafana"
echo.
echo Port Check:
echo - windows_exporter (9182): 
powershell -command "Test-NetConnection -ComputerName localhost -Port 9182 -WarningAction SilentlyContinue | Select-Object -Property TcpTestSucceeded"
echo - Prometheus (9090): 
powershell -command "Test-NetConnection -ComputerName localhost -Port 9090 -WarningAction SilentlyContinue | Select-Object -Property TcpTestSucceeded"
echo - Grafana (3000): 
powershell -command "Test-NetConnection -ComputerName localhost -Port 3000 -WarningAction SilentlyContinue | Select-Object -Property TcpTestSucceeded"
echo.
pause
```

### **`uninstall.bat`** - Remove all services
```batch
@echo off
echo Uninstalling Windows Monitoring Stack...
sc stop windows_exporter 2>nul
sc delete windows_exporter 2>nul
sc stop Prometheus 2>nul
sc delete Prometheus 2>nul
cd /d "%~dp0Grafana"
docker-compose down -v 2>nul
echo.
echo All services removed!
echo Note: Configuration files are preserved.
pause
```

## 🚨 Troubleshooting

### **Issue: "Access Denied" when running scripts**
**Solution:** Run as Administrator
- Right-click batch file → "Run as administrator"

### **Issue: Docker not running**
**Solution:**
```cmd
# Start Docker Desktop
# Or check if Docker service is running
sc query docker
```

### **Issue: Port already in use**
**Solution:** Check what's using the ports
```cmd
netstat -ano | findstr :3000
netstat -ano | findstr :9090
netstat -ano | findstr :9182
```

### **Issue: Grafana shows "No data"**
**Solution:**
1. Wait 2-3 minutes for data collection
2. Check Prometheus targets: `http://localhost:9090/targets`
3. Verify data source URL in Grafana is: `http://host.docker.internal:9090`

## 🔒 Security Notes

1. **Change default Grafana password** after first login
2. **The setup is for local monitoring only** by default
3. **Expose to network only** if properly secured
4. **Regularly update components**:
   ```cmd
   # Update Grafana
   cd Grafana
   docker-compose pull
   docker-compose up -d
   ```

## 📈 Customization

### **Edit Prometheus Configuration**
Edit `Prometheus\prometheus.yml` to:
- Add more Windows servers
- Change scrape intervals
- Add alerting rules

### **Customize windows_exporter**
Edit `windows_exporter\config.yaml` to:
- Enable/disable specific collectors
- Configure service filters
- Add custom metrics

### **Add Custom Metrics**
Place `.prom` files in `windows_exporter\textfile_inputs\`:
```prom
# Example: custom_server_info.prom
windows_server_info{server_name="my-server", role="web"} 1
```

## 🆘 Quick Help

### **All Services Down?**
```cmd
restart.bat
```

### **Check Everything is Working**
```cmd
status.bat
```

### **Reset Everything**
```cmd
uninstall.bat
# Then run again:
start.bat
```

### **View Logs**
```cmd
# Grafana logs
docker logs grafana

# Windows services logs
eventvwr.msc
```

## 🎯 Verification Checklist

After running `start.bat`:

1. ✅ Open `http://localhost:9182/metrics` (should show metrics)
2. ✅ Open `http://localhost:9090/targets` (both targets should be UP)
3. ✅ Open `http://localhost:3000` (Grafana login)
4. ✅ Login with `admin`/`admin`
5. ✅ Import Dashboard ID `24390`
6. ✅ See real-time monitoring data

## 📞 Support

If you encounter issues:

1. Check the GitHub repository for updates
2. Verify Docker is running
3. Run `status.bat` to check all components
4. Check Windows Event Viewer for service errors

---

## 🚀 **Quick Start Summary**

```cmd
# 1. Clone repository
cd C:\
git clone https://github.com/MIKEINTOSHSYSTEMS/WinGrafanaPrometheusExporter.git

# 2. Navigate to folder
cd WinGrafanaPrometheusExporter

# 3. Run installation (as Administrator)
start.bat

# 4. Access your dashboard
#    Grafana: http://localhost:3000
#    Dashboard ID: 24390
```

**Enjoy your Windows Server monitoring dashboard!** 🎉

---

*Note: This setup uses Dashboard ID 24390 - "Windows Exporter Dashboard 2025", specifically designed for comprehensive Windows Server monitoring with windows_exporter.*

