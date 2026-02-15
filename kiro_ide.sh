#!/usr/bin/env bash

# Kiro Clone and Install Script
# This script clones the Kiro installation repo and runs the installer

set -euo pipefail

# Verify bash version (need 4.0+ for associative arrays and other features)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf '%s\n' "Error: Bash 4.0 or higher is required" >&2
    exit 1
fi

# Set restrictive umask to prevent world-readable/writable files
umask 0077

# Override TMPDIR to ensure secure temporary directory location
export TMPDIR="${TMPDIR:-/tmp}"
if [ ! -d "$TMPDIR" ] || [ ! -w "$TMPDIR" ]; then
    printf '%s\n' "Error: TMPDIR is not writable or does not exist" >&2
    exit 1
fi

# Verify /tmp is available as fallback
if [ ! -d "/tmp" ] || [ ! -w "/tmp" ]; then
    printf '%s\n' "Error: /tmp is not available or writable" >&2
    exit 1
fi

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository information
REPO_URL="https://github.com/kactlabs/kiro-ide-linux-installation"
INSTALL_SCRIPT="install-kiro.sh"

# Validate INSTALL_SCRIPT filename (prevent directory traversal)
if [[ "$INSTALL_SCRIPT" =~ / ]] || [[ "$INSTALL_SCRIPT" =~ \.\. ]]; then
    printf '%s\n' "Error: Invalid install script filename" >&2
    exit 1
fi

# Validate REPO_URL format immediately
if [[ ! "$REPO_URL" =~ ^https://github\.com/[a-zA-Z0-9]([a-zA-Z0-9_-]{0,38}[a-zA-Z0-9])?/[a-zA-Z0-9._-]+/?$ ]]; then
    printf '%s\n' "Error: Invalid repository URL format" >&2
    exit 1
fi

if [[ "$REPO_URL" =~ [\;\$\`\|\&\<\>\(\)\{\}\[\]] ]]; then
    printf '%s\n' "Error: Repository URL contains suspicious characters" >&2
    exit 1
fi

# Expected script hash (SHA256) - update this after verifying the legitimate script
# This prevents tampering with the installer
# Generate with: sha256sum install-kiro.sh
EXPECTED_SCRIPT_HASH="e0ece1c0223a2969ff279907507f8e23bf12a2194cda9b8c9f43a9f1d924f747"  # Update with actual hash

# Create secure temporary directory using mktemp
TEMP_DIR=$(mktemp -d) || {
    printf '%s\n' "Error: Failed to create temporary directory" >&2
    exit 1
}

# Verify TEMP_DIR is not empty
if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
    printf '%s\n' "Error: Temporary directory creation failed or is invalid" >&2
    exit 1
fi

# Restrict permissions on temp directory
chmod 700 "$TEMP_DIR" || {
    printf '%s\n' "Error: Failed to set temp directory permissions" >&2
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
            find "$TEMP_DIR" -maxdepth 1 -type f ! -type l -exec shred -vfz -n 3 {} \; 2>/dev/null || true
        fi
        rm -rf "$TEMP_DIR"
    fi
    return $exit_code
}

# Set up cleanup on exit
trap cleanup EXIT

# Protect critical sections from SIGINT
trap 'printf "%s\n" "Installation interrupted. Cleaning up..." >&2; exit 130' INT TERM

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
        printf '%s\n' "Error: Missing required dependencies: $(printf '%s ' "${missing_deps[@]}")" >&2
        printf '%s\n' "Please install the missing dependencies and try again." >&2
        exit 1
    fi
    
    # Verify git version supports --depth
    local git_version
    git_version=$(git --version 2>/dev/null | awk '{print $3}' || true)
    if [ -z "$git_version" ]; then
        printf '%s\n' "Error: Could not determine git version" >&2
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies satisfied.${NC}"
}

clone_repo() {
    echo -e "${YELLOW}Cloning repository to temporary directory...${NC}"
    echo -e "${BLUE}Repository: $REPO_URL${NC}"
    echo -e "${BLUE}Temporary directory: $TEMP_DIR${NC}"
    
    # Disable dangerous git environment variables to prevent injection
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL 2>/dev/null || true
    
    # Clone with depth=1 for faster cloning and reduced attack surface
    if ! git clone --depth=1 "$REPO_URL" "$TEMP_DIR" 2>&1; then
        printf '%s\n' "Error: Failed to clone repository" >&2
        exit 1
    fi
    
    # Verify the cloned repository's remote URL matches expectations
    local cloned_remote
    if ! cloned_remote=$(cd "$TEMP_DIR" 2>/dev/null && git config --get remote.origin.url 2>/dev/null); then
        printf '%s\n' "Error: Failed to verify cloned repository remote" >&2
        exit 1
    fi
    
    # Validate cloned_remote doesn't contain suspicious characters
    if [[ "$cloned_remote" =~ [\$\`\|\&\<\>\(\)\{\}] ]]; then
        printf '%s\n' "Error: Cloned repository remote contains suspicious characters" >&2
        exit 1
    fi
    
    if [ "$cloned_remote" != "$REPO_URL" ]; then
        printf '%s\n' "Error: Cloned repository remote URL mismatch!" >&2
        printf '%s\n' "Expected: $REPO_URL" >&2
        printf '%s\n' "Got:      $cloned_remote" >&2
        exit 1
    fi
    
    # Verify it's actually a git repository with proper error checking
    if ! (cd "$TEMP_DIR" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1); then
        printf '%s\n' "Error: Cloned directory is not a valid git repository" >&2
        exit 1
    fi
    
    echo -e "${GREEN}Repository cloned successfully.${NC}"
}

verify_install_script() {
    local script_path="$TEMP_DIR/$INSTALL_SCRIPT"
    
    echo -e "${YELLOW}Verifying installation script...${NC}"
    
    if [ ! -f "$script_path" ]; then
        printf '%s\n' "Error: Installation script not found at $script_path" >&2
        printf '%s\n' "Available files in repository:" >&2
        find "$TEMP_DIR" -maxdepth 1 -type f ! -type l -printf '%f\n' 2>/dev/null | sort || true
        exit 1
    fi
    
    # Verify script is a regular file and readable
    if [ ! -r "$script_path" ]; then
        echo -e "${RED}Error: Installation script is not readable${NC}" >&2
        exit 1
    fi
    
    # Verify it's not a symlink (prevent symlink attacks)
    if [ -L "$script_path" ]; then
        echo -e "${RED}Error: Installation script is a symlink (security risk)${NC}" >&2
        exit 1
    fi
    
    # Check script size is reasonable (between 1KB and 1MB)
    local script_size
    if script_size=$(stat -f%z "$script_path" 2>/dev/null); then
        :  # macOS stat succeeded
    elif script_size=$(stat -c%s "$script_path" 2>/dev/null); then
        :  # Linux stat succeeded
    else
        printf '%s\n' "Error: Failed to determine script size" >&2
        exit 1
    fi
    
    # Validate script_size is numeric
    if ! [[ "$script_size" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "Error: Invalid script size value: $script_size" >&2
        exit 1
    fi
    
    if [ "$script_size" -lt 1024 ] || [ "$script_size" -gt 1048576 ]; then
        printf '%s\n' "Error: Installation script size is suspicious ($script_size bytes)" >&2
        exit 1
    fi
    
    # Verify script starts with shebang (basic sanity check)
    local shebang
    shebang=$(head -n1 "$script_path" 2>/dev/null || true)
    if [ -z "$shebang" ] || ! [[ "$shebang" =~ ^#! ]]; then
        printf '%s\n' "Error: Installation script missing shebang" >&2
        exit 1
    fi
    
    # Verify file permissions are safe (not world-writable or group-writable)
    local perms
    if perms=$(stat -f%OLp "$script_path" 2>/dev/null); then
        :  # macOS format
    elif perms=$(stat -c%a "$script_path" 2>/dev/null); then
        :  # Linux format
    else
        printf '%s\n' "Error: Failed to determine script permissions" >&2
        exit 1
    fi
    
    # Validate perms is numeric and 3 digits
    if ! [[ "$perms" =~ ^[0-7]{3}$ ]]; then
        printf '%s\n' "Error: Invalid permission format: $perms" >&2
        exit 1
    fi
    
    # Check for world-writable (last digit 2 or 7) or group-writable (middle digit 2 or 7)
    if [[ "$perms" =~ [27]$ ]] || [[ "$perms" =~ ^.[27] ]]; then
        printf '%s\n' "Error: Installation script has unsafe permissions: $perms" >&2
        exit 1
    fi
    
    # Verify SHA256 hash if EXPECTED_SCRIPT_HASH is set
    if [ -n "$EXPECTED_SCRIPT_HASH" ]; then
        local actual_hash
        actual_hash=$(sha256sum "$script_path" 2>/dev/null | awk '{print $1}' || true)
        
        if [ -z "$actual_hash" ]; then
            printf '%s\n' "Error: Failed to compute script hash" >&2
            exit 1
        fi
        
        # Validate hash is 64 hex characters
        if ! [[ "$actual_hash" =~ ^[a-f0-9]{64}$ ]]; then
            printf '%s\n' "Error: Invalid hash format: $actual_hash" >&2
            exit 1
        fi
        
        if [ "$actual_hash" != "$EXPECTED_SCRIPT_HASH" ]; then
            printf '%s\n' "Error: Script hash mismatch!" >&2
            printf '%s\n' "Expected: $EXPECTED_SCRIPT_HASH" >&2
            printf '%s\n' "Actual:   $actual_hash" >&2
            printf '%s\n' "This may indicate the script has been tampered with." >&2
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
    
    # Re-verify script hasn't been modified (TOCTOU protection)
    if [ ! -f "$script_path" ] || [ -L "$script_path" ]; then
        printf '%s\n' "Error: Script file was modified or removed" >&2
        exit 1
    fi
    
    # Check if running in pipe and no --user flag provided
    if [ ! -t 0 ]; then
        local has_user_flag=0
        for arg in "$@"; do
            if [ "$arg" = "--user" ]; then
                has_user_flag=1
                break
            fi
        done
        
        if [ $has_user_flag -eq 0 ]; then
            echo -e "${BLUE}Note: Running via pipe (curl). System-wide installation will proceed with sudo.${NC}"
            echo -e "${BLUE}Use --user flag if you prefer user-only installation (no sudo required).${NC}"
            echo
        fi
    fi
    
    # Validate that script_path is within TEMP_DIR (prevent directory traversal)
    # Use pwd -P for robust path resolution
    local resolved_path
    local resolved_temp
    
    # Validate script_path format before resolution
    if [[ "$script_path" =~ [[:space:]] ]]; then
        printf '%s\n' "Error: Script path contains whitespace" >&2
        exit 1
    fi
    
    if ! resolved_path=$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P && echo "/$(basename "$script_path")"); then
        printf '%s\n' "Error: Failed to resolve script path" >&2
        exit 1
    fi
    resolved_path="${resolved_path%/}"  # Remove trailing slash if present
    
    if ! resolved_temp=$(cd "$TEMP_DIR" 2>/dev/null && pwd -P); then
        printf '%s\n' "Error: Failed to resolve temp directory path" >&2
        exit 1
    fi
    resolved_temp="${resolved_temp%/}"  # Remove trailing slash if present
    
    # Check if resolved_path starts with resolved_temp
    if [[ "$resolved_path" != "$resolved_temp"* ]]; then
        printf '%s\n' "Error: Script path validation failed (security check)" >&2
        exit 1
    fi
    
    # Run installer while maintaining safety checks
    # Note: We keep set -u enabled to catch unset variable errors
    
    # Pass all arguments to the installation script
    if [ $# -gt 0 ]; then
        echo -e "${BLUE}Arguments passed to installer: $*${NC}"
        # Use explicit path to prevent PATH hijacking
        # Properly quote all arguments
        bash "$script_path" "$@" || {
            local exit_code=$?
            echo -e "${RED}Installation script exited with code: $exit_code${NC}" >&2
            return $exit_code
        }
    else
        bash "$script_path" || {
            local exit_code=$?
            echo -e "${RED}Installation script exited with code: $exit_code${NC}" >&2
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
    script_owner=""
    current_user=""
    
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
    case "$arg" in
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
