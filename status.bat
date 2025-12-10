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