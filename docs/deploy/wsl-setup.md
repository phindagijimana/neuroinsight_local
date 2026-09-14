# WSL setup (Windows)

← [NeuroInsight-AutoHS User Guide](../USER_GUIDE.md)

## WSL Setup (Windows Users)

If you're using Windows, you can run NeuroInsight-AutoHS using Windows Subsystem for Linux (WSL). Here's how to set it up:

### Enable WSL Feature

1. **Open PowerShell as Administrator**:
   - Press `Win + X` and select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Enable WSL feature**:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

3. **Enable Virtual Machine Platform** (required for WSL 2):
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

4. **Restart your computer** when prompted.

### Install WSL and Ubuntu

1. **Open PowerShell/Terminal as Administrator** again after restart.

2. **Set WSL 2 as default version**:
   ```powershell
   wsl --set-default-version 2
   ```

3. **Install Ubuntu distribution**:
   ```powershell
   wsl --install -d Ubuntu
   ```

4. **Set up Ubuntu**:
   - The Ubuntu installation will start automatically
   - Create a username and password when prompted
   - Wait for installation to complete

### Verify WSL Installation

1. **Open Ubuntu from Start Menu** or run `wsl` in PowerShell/Terminal.

2. **Update Ubuntu packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Verify WSL version**:
   ```bash
   wsl --version
   ```

### Important WSL Notes

- **File Access**: Windows files are accessible at `/mnt/c/` from WSL
- **Performance**: Keep project files inside WSL for better Docker performance
- **Memory**: WSL may need memory allocation adjustments in `.wslconfig`
- **Integration**: Docker Desktop integrates with WSL for container operations

Once WSL is set up, continue with the Docker installation instructions below.

