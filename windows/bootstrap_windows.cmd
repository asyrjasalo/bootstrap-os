@echo off

rem PowerShell -Command "& {Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression '%~dp0\bootstrap_windows.ps1 -All'}"
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/asyrjasalo/bootstrap-os/master/windows/bootstrap_windows.ps1'))}"

pause