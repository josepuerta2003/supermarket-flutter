@echo off
REM Compilador automatico de SuperMarket - doble clic para generar el APK
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1"
