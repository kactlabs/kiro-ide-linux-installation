# Kiro Troubleshooting Guide

## Installation Script Troubleshooting

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

## Kiro Application Troubleshooting

### Kiro hangs or is slow to start on first launch
- First launch can take 1-2 minutes as it initializes components
- Wait at least 2-3 minutes before force-closing

### Check if Kiro is actually running
```bash
ps aux | grep kiro
```

### Run Kiro with verbose output to see errors
```bash
kiro --verbose
```
or
```bash
~/.local/bin/kiro --verbose
```

### Clear cache and restart
```bash
rm -rf ~/.config/kiro ~/.cache/kiro
kiro
```

### Check system resources
```bash
free -h
df -h
```
Ensure you have enough RAM and disk space available.

### Check Kiro logs
```bash
cat ~/.local/share/kiro/logs/* 2>/dev/null | tail -50
```

### Force kill and restart Kiro
```bash
pkill -9 kiro
sleep 2
kiro
```

### Kiro window is unresponsive
- Try moving or resizing the window to check if it's responsive
- If responsive, it's likely still loading
- If unresponsive, force kill and restart:
```bash
pkill -9 kiro
kiro
```
