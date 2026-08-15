@echo off
REM NeuroInsight-AutoHS Docker - Install Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" install %*
