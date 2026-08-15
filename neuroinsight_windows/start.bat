@echo off
REM NeuroInsight-AutoHS Docker - Start Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" start %*
