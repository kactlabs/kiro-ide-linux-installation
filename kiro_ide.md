# Kiro IDE Installation Script

## Overview

`kiro_ide.sh` is a secure installation script that clones the Kiro IDE installation repository and runs the installer. It includes comprehensive security hardening to protect against common attack vectors.

## Shell Compatibility

### Execution Method
- **Shebang:** `#!/usr/bin/env bash`
- **Always runs in:** Bash (regardless of user's default shell)
- **Works from:** Bash, Zsh, or any POSIX shell

### Important Notes

The script uses `#!/usr/bin/env bash` which means:
- When executed as a file, it always runs in bash
- The shebang is respected by the OS, not by the shell
- Your default shell (zsh, bash, etc.) doesn't matter

## Installation Methods

### Method 1: Direct Execution (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/kactlabs/kiro-ide-linux-installation/main/kiro_ide.sh -o kiro_ide.sh
chmod +x kiro_ide.sh
./kiro_ide.sh --user
```

**Why this is best:**
- Shebang is respected
- Always runs in bash
- Works from any shell (bash, zsh, fish, etc.)
- Allows you to review the script before execution

### Method 2: Pipe to Bash
```bash
curl -fsSL https://raw.githubusercontent.com/kactlabs/kiro-ide-linux-installation/main/kiro_ide.sh | bash
```

**Important:** Always pipe to `bash`, NOT `zsh`
- ❌ `curl ... | zsh` - Will fail
- ✅ `curl ... | bash` - Works correctly

### Method 3: With Arguments
```bash
./kiro_ide.sh --user --force
```

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

### Verification & Validation
- ✅ URL format validation before cloning
- ✅ Shallow clone (`--depth=1`) to reduce attack surface
- ✅ Symlink attack prevention
- ✅ File permission validation
- ✅ Shebang verification
- ✅ File size sanity checks (1KB - 1MB)
- ✅ SHA256 hash verification (optional)

### Secure Execution
- ✅ Secure temporary directory creation with `mktemp`
- ✅ Restricted permissions (700) on temp directory
- ✅ Directory traversal prevention
- ✅ PATH hijacking prevention (explicit bash invocation)
- ✅ Secure file deletion with `shred` (if available)

### Error Handling
- ✅ Strict mode: `set -euo pipefail`
- ✅ Exit code capture and reporting
- ✅ Automatic cleanup on exit
- ✅ World-writable directory warnings


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

## Requirements

- `git` - For cloning the repository
- `bash` - For script execution
- `sha256sum` - For hash verification

## Troubleshooting

### Script fails with "Permission denied"
```bash
chmod +x kiro_ide.sh
```

### "Failed to clone repository"
- Check your internet connection
- Verify the repository URL is accessible
- Check if git is installed: `which git`

### "Installation script not found"
- The repository structure may have changed
- Check available files: `ls -la /tmp/kiro_installer_*`

### "Script hash mismatch"
- The installer has been modified or tampered with
- Verify the expected hash is correct
- Re-download the script

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

- The script validates the installer before execution
- Temporary files are stored in a secure directory with restricted permissions
- Files are securely deleted after installation (using `shred` if available)
- The script prevents common attack vectors (symlink attacks, directory traversal, PATH hijacking)
- Always download from the official repository URL

## Support

For issues or questions, visit the [Kiro IDE repository](https://github.com/kactlabs/kiro-ide-linux-installation)
