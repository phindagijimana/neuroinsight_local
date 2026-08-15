@echo off
REM NeuroInsight-AutoHS Docker - Status Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" status %*
