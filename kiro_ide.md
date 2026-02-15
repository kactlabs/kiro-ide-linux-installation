# Kiro IDE Installation Script

## Overview

`kiro_ide.sh` is a secure installation script that clones the Kiro IDE installation repository and runs the installer. It includes comprehensive security hardening to protect against common attack vectors.


## Quick Start (Complete Installation)

If you encounter dependency issues, use this complete command sequence:

```bash
# Install dependencies
sudo apt update
sudo apt install -y jq

# Download and install Kiro
cd /tmp
rm -f kiro_ide.sh /tmp/test_kiro.sh
curl -fsSL "https://raw.githubusercontent.com/kactlabs/kiro-ide-linux-installation/refs/heads/main/kiro_ide.sh" -o kiro_ide.sh
cat kiro_ide.sh | grep -A1 "EXPECTED_SCRIPT_HASH="
chmod +x kiro_ide.sh
./kiro_ide.sh --user
```

**What each command does:**
- `sudo apt update` - Updates package lists
- `sudo apt install -y jq` - Installs jq dependency
- `cd /tmp` - Changes to temporary directory
- `rm -f kiro_ide.sh /tmp/test_kiro.sh` - Clears any cached versions
- `curl -fsSL ...` - Downloads the latest script
- `cat kiro_ide.sh | grep -A1 "EXPECTED_SCRIPT_HASH="` - Verifies hash configuration
- `chmod +x kiro_ide.sh` - Makes script executable
- `./kiro_ide.sh --user` - Runs the installation

## Usage

```
Usage: kiro_ide.sh [INSTALLER_OPTIONS]

This script clones the Kiro installation repository and runs the installer.
All arguments are passed directly to the installation script.

SECURITY NOTES:
  - This script validates the installer before execution
  - Temporary files are securely deleted after installation
  - For curl usage, always use --user flag to avoid sudo

Common installer options:
  --install     Install or update Kiro (default)
  --update      Same as --install
  --uninstall   Uninstall Kiro
  --user        Perform operation for current user only (recommended for curl)
  --force       Force reinstall even if same version exists
  --clean       Remove user data during uninstall
  --help        Display installer help

Examples:
  ./kiro_ide.sh                    # Clone repo and install Kiro
  ./kiro_ide.sh --user            # Clone repo and install for current user (no sudo)
  ./kiro_ide.sh --force           # Clone repo and force reinstall
  ./kiro_ide.sh --uninstall --user # Clone repo and uninstall user installation
```

