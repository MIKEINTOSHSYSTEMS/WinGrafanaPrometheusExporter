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