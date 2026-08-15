@echo off
REM NeuroInsight-AutoHS Docker - Stop Command
powershell.exe -ExecutionPolicy Bypass -File "%~dp0neuroinsight-autohs-docker.ps1" stop %*
