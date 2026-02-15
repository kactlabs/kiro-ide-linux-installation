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

## Security Features

### Input Validation & Sanitization
- ✅ URL format validation with regex and injection character detection
- ✅ Filename validation (prevent directory traversal)
- ✅ Script path whitespace validation
- ✅ Git output validation (check for suspicious characters)
- ✅ Hash format validation (64 hex characters)
- ✅ Permission format validation (3 octal digits)
- ✅ Script size validation (numeric check + range 1KB-1MB)
- ✅ Shebang verification with safe parsing

### Verification & Validation
- ✅ Shallow clone (`--depth=1`) to reduce attack surface
- ✅ Git repository integrity verification
- ✅ Cloned remote URL verification
- ✅ Symlink attack prevention (multiple checks)
- ✅ File permission validation (no world/group-writable)
- ✅ SHA256 hash verification with format validation
- ✅ TOCTOU (Time-of-Check-Time-of-Use) protection

### Secure Execution
- ✅ Secure temporary directory creation with `mktemp`
- ✅ Restricted permissions (700) on temp directory
- ✅ TMPDIR override for secure location
- ✅ Directory traversal prevention with `pwd -P`
- ✅ PATH hijacking prevention (explicit bash invocation)
- ✅ Secure file deletion with `shred` (if available)
- ✅ Symlink exclusion from cleanup operations

### Environment Protection
- ✅ Dangerous git environment variables disabled (GIT_AUTHOR_*, GIT_COMMITTER_*)
- ✅ Restrictive umask (0077) set at startup
- ✅ TMPDIR validation and verification
- ✅ /tmp availability check

### Error Handling & Safety
- ✅ Strict mode: `set -euo pipefail`
- ✅ Bash 4.0+ version check
- ✅ Git version verification
- ✅ Exit code capture and reporting
- ✅ Automatic cleanup on exit
- ✅ SIGINT/TERM signal protection
- ✅ World-writable directory warnings
- ✅ Proper stderr redirection for all errors


## Configuration

### Optional: SHA256 Hash Verification

To enable hash verification, set the `EXPECTED_SCRIPT_HASH` variable in the script:

1. Get the hash of the legitimate installer:
```bash
sha256sum install-kiro.sh
```

2. Update the script:
```bash
EXPECTED_SCRIPT_HASH="<hash-from-step-1>"
```

This prevents tampering with the installer script.

## Security Hardening Details

### 32 Security Fixes Implemented

The script includes comprehensive security hardening with 32 distinct security fixes:

**Input Validation (8 fixes)**
1. URL format validation with regex
2. URL injection character detection
3. Filename validation (prevent directory traversal)
4. Script path whitespace validation
5. Git output validation
6. Hash format validation (64 hex characters)
7. Permission format validation (3 octal digits)
8. Script size numeric validation

**Verification & Integrity (7 fixes)**
9. Shallow clone to reduce attack surface
10. Git repository integrity verification
11. Cloned remote URL verification
12. Symlink attack prevention (file check)
13. Symlink attack prevention (cleanup)
14. Symlink attack prevention (file listing)
15. TOCTOU protection (re-verify before execution)

**Secure Execution (6 fixes)**
16. Secure temporary directory with mktemp
17. Restrictive umask (0077)
18. TMPDIR override for secure location
19. /tmp availability verification
20. Directory traversal prevention with pwd -P
21. PATH hijacking prevention

**Environment Protection (4 fixes)**
22. Disable dangerous git environment variables
23. Bash version check (4.0+)
24. Git version verification
25. TMPDIR validation

**Error Handling & Safety (7 fixes)**
26. Strict mode (set -euo pipefail)
27. SIGINT/TERM signal protection
28. Proper stderr redirection
29. Safe array expansion in printf
30. Validate TEMP_DIR not empty
31. Proper cd error checking
32. Validate awk output

## Requirements

- `bash` 4.0+ - For script execution with security features
- `git` - For cloning the repository
- `sha256sum` - For hash verification
- Writable `/tmp` directory - For secure temporary files

## Troubleshooting

### Script fails with "Permission denied"
```bash
chmod +x kiro_ide.sh
```

### "Bash 4.0 or higher is required"
- Update bash to version 4.0 or later
- Check version: `bash --version`

### "TMPDIR is not writable or does not exist"
- Ensure `/tmp` is writable: `touch /tmp/test && rm /tmp/test`
- Check disk space: `df -h /tmp`

### "Failed to clone repository"
- Check your internet connection
- Verify the repository URL is accessible
- Check if git is installed: `which git`
- Verify git version: `git --version`

### "Installation script not found"
- The repository structure may have changed
- Check available files in temp directory
- Verify the repository contains `install-kiro.sh`

### "Script hash mismatch"
- The installer has been modified or tampered with
- Verify the expected hash is correct
- Re-download the script from the official repository
- Check for man-in-the-middle attacks

### "Installation script has unsafe permissions"
- The cloned script has incorrect permissions
- This is a security check to prevent tampering
- Verify the repository is not compromised

### "Script path validation failed"
- The temporary directory path is invalid
- This is a security check to prevent directory traversal
- Ensure `/tmp` is properly configured

### "Failed to install jq" or "jq dependency missing"
- The installer needs `jq` for JSON processing
- Install it manually:
```bash
sudo apt update
sudo apt install -y jq
```
- Then re-run the installation:
```bash
./kiro_ide.sh --user
```

### APT repository errors (GPG key issues, 404 errors)
- These are system configuration issues, not related to Kiro
- Fix your apt sources:
```bash
sudo apt update
```
- Remove problematic PPAs if needed:
```bash
sudo add-apt-repository --remove ppa:problematic/ppa
```
- Then retry the installation

## Best Practices

1. **Always use `--user` flag with curl:**
   ```bash
   curl -fsSL https://... | bash -s -- --user
   ```

2. **Review the script before execution:**
   ```bash
   curl -fsSL https://... -o kiro_ide.sh
   cat kiro_ide.sh  # Review the code
   bash kiro_ide.sh --user
   ```

3. **Use explicit bash, not zsh:**
   ```bash
   # ✅ Correct
   curl -fsSL https://... | bash
   
   # ❌ Wrong
   curl -fsSL https://... | zsh
   ```

4. **Keep the script updated:**
   - Periodically re-download to get security updates
   - Check the repository for new versions

## Security Considerations

### Attack Vectors Mitigated

**Injection Attacks**
- URL injection prevention with character validation
- Git environment variable injection prevention
- Format string protection with printf

**File System Attacks**
- Symlink attacks prevented with multiple checks
- Directory traversal prevention with path validation
- World-writable directory detection and warnings

**Execution Attacks**
- PATH hijacking prevention with explicit bash invocation
- TOCTOU (Time-of-Check-Time-of-Use) race condition prevention
- Signal handling for graceful interruption

**Tampering Detection**
- SHA256 hash verification with format validation
- File permission validation
- File size sanity checks
- Shebang verification
- Git repository integrity checks

### Best Practices for Users

1. **Always verify the script before execution:**
   ```bash
   curl -fsSL https://... -o kiro_ide.sh
   cat kiro_ide.sh  # Review the code
   bash kiro_ide.sh --user
   ```

2. **Use HTTPS only:**
   - Always download from `https://` URLs
   - Never use `http://` for installation scripts

3. **Keep the script updated:**
   - Periodically re-download to get security updates
   - Check the repository for new versions

4. **Use `--user` flag with curl:**
   ```bash
   curl -fsSL https://... | bash -s -- --user
   ```

5. **Verify hash after download:**
   ```bash
   sha256sum kiro_ide.sh
   # Compare with official hash from repository
   ```

### What This Script Does NOT Do

- Does not require root/sudo for user installation
- Does not modify system files without explicit permission
- Does not collect or transmit user data
- Does not install telemetry or tracking
- Does not modify shell configuration files automatically

## Support

For issues or questions, visit the [Kiro IDE repository](https://github.com/kactlabs/kiro-ide-linux-installation)
