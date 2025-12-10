@echo off
echo Stopping Windows Monitoring Stack...
sc stop windows_exporter
sc stop Prometheus
cd /d "%~dp0Grafana"
docker-compose down
echo All services stopped!
pause