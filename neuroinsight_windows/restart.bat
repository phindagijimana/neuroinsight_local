@echo off
REM NeuroInsight-AutoHS Docker - Restart Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" restart %*
