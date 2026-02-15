#!/usr/bin/env bash

# Kiro Clone and Install Script
# This script clones the Kiro installation repo and runs the installer

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository information
REPO_URL="https://github.com/kactlabs/kiro-ide-linux-installation"
INSTALL_SCRIPT="install-kiro.sh"

# Expected script hash (SHA256) - update this after verifying the legitimate script
# This prevents tampering with the installer
# Generate with: sha256sum install-kiro.sh
EXPECTED_SCRIPT_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"  # Update with actual hash

# Create secure temporary directory using mktemp
TEMP_DIR=$(mktemp -d) || {
    echo -e "${RED}Error: Failed to create temporary directory${NC}"
    exit 1
}

# Restrict permissions on temp directory
chmod 700 "$TEMP_DIR" || {
    echo -e "${RED}Error: Failed to set temp directory permissions${NC}"
    exit 1
}

print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}    Kiro Clone & Install Script      ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
}

cleanup() {
    local exit_code=$?
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        # Use secure deletion with shred if available, otherwise rm
        if command -v shred &> /dev/null; then
            find "$TEMP_DIR" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
        fi
        rm -rf "$TEMP_DIR"
    fi
    return $exit_code
}

# Set up cleanup on exit
trap cleanup EXIT

check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local deps=("git" "bash" "sha256sum")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Please install the missing dependencies and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies satisfied.${NC}"
}

clone_repo() {
    echo -e "${YELLOW}Cloning repository to temporary directory...${NC}"
    echo -e "${BLUE}Repository: $REPO_URL${NC}"
    echo -e "${BLUE}Temporary directory: $TEMP_DIR${NC}"
    
    # Validate URL format before cloning
    # Only allow HTTPS GitHub URLs with valid org/repo names
    if [[ ! "$REPO_URL" =~ ^https://github\.com/[a-zA-Z0-9]([a-zA-Z0-9_-]{0,38}[a-zA-Z0-9])?/[a-zA-Z0-9._-]+/?$ ]]; then
        echo -e "${RED}Error: Invalid repository URL format${NC}"
        exit 1
    fi
    
    # Additional check: ensure no suspicious characters that could be git injection vectors
    if [[ "$REPO_URL" =~ [\;\$\`\|\&\<\>\(\)\{\}\[\]] ]]; then
        echo -e "${RED}Error: Repository URL contains suspicious characters${NC}"
        exit 1
    fi
    
    # Verify HTTPS is being used (no HTTP fallback)
    if [[ ! "$REPO_URL" =~ ^https:// ]]; then
        echo -e "${RED}Error: Repository URL must use HTTPS protocol${NC}"
        exit 1
    fi
    
    # Clone with depth=1 for faster cloning and reduced attack surface
    if ! git clone --depth=1 "$REPO_URL" "$TEMP_DIR"; then
        echo -e "${RED}Error: Failed to clone repository${NC}"
        exit 1
    fi
    
    # Verify the cloned repository's remote URL matches expectations
    local cloned_remote
    if ! cloned_remote=$(cd "$TEMP_DIR" && git config --get remote.origin.url 2>/dev/null); then
        echo -e "${RED}Error: Failed to verify cloned repository remote${NC}"
        exit 1
    fi
    
    if [ "$cloned_remote" != "$REPO_URL" ]; then
        echo -e "${RED}Error: Cloned repository remote URL mismatch!${NC}"
        echo -e "${RED}Expected: $REPO_URL${NC}"
        echo -e "${RED}Got:      $cloned_remote${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Repository cloned successfully.${NC}"
}

verify_install_script() {
    local script_path="$TEMP_DIR/$INSTALL_SCRIPT"
    
    echo -e "${YELLOW}Verifying installation script...${NC}"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}Error: Installation script not found at $script_path${NC}"
        echo -e "${YELLOW}Available files in repository:${NC}"
        ls -la "$TEMP_DIR"
        exit 1
    fi
    
    # Verify script is a regular file and readable
    if [ ! -r "$script_path" ]; then
        echo -e "${RED}Error: Installation script is not readable${NC}"
        exit 1
    fi
    
    # Verify it's not a symlink (prevent symlink attacks)
    if [ -L "$script_path" ]; then
        echo -e "${RED}Error: Installation script is a symlink (security risk)${NC}"
        exit 1
    fi
    
    # Check script size is reasonable (between 1KB and 1MB)
    local script_size
    if script_size=$(stat -f%z "$script_path" 2>/dev/null); then
        :  # macOS stat succeeded
    elif script_size=$(stat -c%s "$script_path" 2>/dev/null); then
        :  # Linux stat succeeded
    else
        echo -e "${RED}Error: Failed to determine script size${NC}"
        exit 1
    fi
    
    if [ "$script_size" -lt 1024 ] || [ "$script_size" -gt 1048576 ]; then
        echo -e "${RED}Error: Installation script size is suspicious (${script_size} bytes)${NC}"
        exit 1
    fi
    
    # Verify script starts with shebang (basic sanity check)
    if ! head -n1 "$script_path" | grep -q '^#!'; then
        echo -e "${RED}Error: Installation script missing shebang${NC}"
        exit 1
    fi
    
    # Verify file permissions are safe (not world-writable or group-writable)
    local perms
    if perms=$(stat -f%OLp "$script_path" 2>/dev/null); then
        :  # macOS format
    elif perms=$(stat -c%a "$script_path" 2>/dev/null); then
        :  # Linux format
    else
        echo -e "${RED}Error: Failed to determine script permissions${NC}"
        exit 1
    fi
    
    # Check for world-writable (last digit 2 or 7) or group-writable (middle digit 2 or 7)
    if [[ "$perms" =~ [27]$ ]] || [[ "$perms" =~ ^.[27] ]]; then
        echo -e "${RED}Error: Installation script has unsafe permissions: $perms${NC}"
        exit 1
    fi
    
    # Verify SHA256 hash if EXPECTED_SCRIPT_HASH is set
    if [ -n "$EXPECTED_SCRIPT_HASH" ]; then
        local actual_hash=$(sha256sum "$script_path" | awk '{print $1}')
        if [ "$actual_hash" != "$EXPECTED_SCRIPT_HASH" ]; then
            echo -e "${RED}Error: Script hash mismatch!${NC}"
            echo -e "${RED}Expected: $EXPECTED_SCRIPT_HASH${NC}"
            echo -e "${RED}Actual:   $actual_hash${NC}"
            echo -e "${YELLOW}This may indicate the script has been tampered with.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Script hash verified.${NC}"
    fi
    
    if [ ! -x "$script_path" ]; then
        echo -e "${YELLOW}Making installation script executable...${NC}"
        chmod 755 "$script_path"
    fi
    
    echo -e "${GREEN}Installation script verified.${NC}"
}

run_installer() {
    local script_path="$TEMP_DIR/$INSTALL_SCRIPT"
    
    echo -e "${YELLOW}Running Kiro installation script...${NC}"
    echo -e "${BLUE}Script location: $script_path${NC}"
    
    # Check if running in pipe and no --user flag provided
    if [ ! -t 0 ]; then
        case "$@" in
            *--user*)
                ;;
            *)
                echo -e "${BLUE}Note: Running via pipe (curl). System-wide installation will proceed with sudo.${NC}"
                echo -e "${BLUE}Use --user flag if you prefer user-only installation (no sudo required).${NC}"
                echo
                ;;
        esac
    fi
    
    # Validate that script_path is within TEMP_DIR (prevent directory traversal)
    # Use pwd -P for robust path resolution
    local resolved_path
    local resolved_temp
    
    if ! resolved_path=$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P && echo "/$(basename "$script_path")"); then
        echo -e "${RED}Error: Failed to resolve script path${NC}"
        exit 1
    fi
    resolved_path="${resolved_path%/}"  # Remove trailing slash if present
    
    if ! resolved_temp=$(cd "$TEMP_DIR" 2>/dev/null && pwd -P); then
        echo -e "${RED}Error: Failed to resolve temp directory path${NC}"
        exit 1
    fi
    resolved_temp="${resolved_temp%/}"  # Remove trailing slash if present
    
    # Check if resolved_path starts with resolved_temp
    if [[ "$resolved_path" != "$resolved_temp"* ]]; then
        echo -e "${RED}Error: Script path validation failed (security check)${NC}"
        exit 1
    fi
    
    # Run installer while maintaining safety checks
    # Note: We keep set -u enabled to catch unset variable errors
    
    # Pass all arguments to the installation script
    if [ $# -gt 0 ]; then
        echo -e "${BLUE}Arguments passed to installer: $@${NC}"
        # Use explicit path to prevent PATH hijacking
        bash "$script_path" "$@" || {
            local exit_code=$?
            echo -e "${RED}Installation script exited with code: $exit_code${NC}"
            return $exit_code
        }
    else
        bash "$script_path" || {
            local exit_code=$?
            echo -e "${RED}Installation script exited with code: $exit_code${NC}"
            return $exit_code
        }
    fi
}

print_usage() {
    echo "Usage: $0 [INSTALLER_OPTIONS]"
    echo ""
    echo "This script clones the Kiro installation repository and runs the installer."
    echo "All arguments are passed directly to the installation script."
    echo ""
    echo "SECURITY NOTES:"
    echo "  - This script validates the installer before execution"
    echo "  - Temporary files are securely deleted after installation"
    echo "  - For curl usage, always use --user flag to avoid sudo"
    echo ""
    echo "Common installer options:"
    echo "  --install     Install or update Kiro (default)"
    echo "  --update      Same as --install"
    echo "  --uninstall   Uninstall Kiro"
    echo "  --user        Perform operation for current user only (recommended for curl)"
    echo "  --force       Force reinstall even if same version exists"
    echo "  --clean       Remove user data during uninstall"
    echo "  --help        Display installer help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Clone repo and install Kiro"
    echo "  $0 --user            # Clone repo and install for current user (no sudo)"
    echo "  $0 --force           # Clone repo and force reinstall"
    echo "  $0 --uninstall --user # Clone repo and uninstall user installation"
    echo ""
    echo "For curl usage:"
    echo "  curl -fsSL https://raw.githubusercontent.com/.../clone-and-install-kiro.sh | bash -s -- --user"
    echo ""
}

# Main script execution
print_header

# Validate script is running from a safe location
if [ "${0#/}" != "$0" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Warn if running from world-writable directory
if [ -w "$SCRIPT_DIR" ]; then
    local script_owner
    local current_user
    
    if script_owner=$(stat -f%u "$SCRIPT_DIR" 2>/dev/null); then
        :  # macOS format
    elif script_owner=$(stat -c%U "$SCRIPT_DIR" 2>/dev/null); then
        :  # Linux format (returns username)
        script_owner=$(id -u "$script_owner" 2>/dev/null || echo "unknown")
    else
        script_owner="unknown"
    fi
    
    current_user=$(id -u)
    
    if [ "$script_owner" != "$current_user" ] && [ "$script_owner" != "unknown" ]; then
        echo -e "${YELLOW}Warning: Script is in a world-writable directory. Consider moving it to a secure location.${NC}"
    fi
fi

# Check for help flag
for arg in "$@"; do
    case $arg in
        --help | -h)
            print_usage
            exit 0
            ;;
    esac
done

# Execute main workflow
check_dependencies
clone_repo
verify_install_script
run_installer "$@"

echo -e "${GREEN}Script execution completed!${NC}"
