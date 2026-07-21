@echo off
setlocal
set "ROOT=%~dp0"
start "Second Lianzha Web Server" powershell -NoExit -ExecutionPolicy Bypass -File "%ROOT%backend\server.ps1" -Port 8091
timeout /t 2 >nul
start "" http://127.0.0.1:8091/
echo Second Lianzha B/S prototype is opening at http://127.0.0.1:8091/
endlocal
