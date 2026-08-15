@echo off
REM NeuroInsight-AutoHS Docker - Logs Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" logs %*
