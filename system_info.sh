#!/bin/bash

# System Information Script - Works on macOS and Ubuntu
# Displays: OS info, version, CPU, memory, GPU, disk, swap

set -e

# Color codes for output
BOLD='\033[1m'
RESET='\033[0m'
BLUE='\033[34m'

print_section() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${RESET}"
}

print_info() {
    echo "$1: $2"
}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="Linux"
else
    OS_TYPE="Unknown"
fi

# ===== OS INFO =====
print_section "Operating System"
print_info "OS Type" "$OS_TYPE"

if [[ "$OS_TYPE" == "macOS" ]]; then
    OS_VERSION=$(sw_vers -productVersion)
    OS_BUILD=$(sw_vers -buildVersion)
    print_info "OS Version" "$OS_VERSION"
    print_info "Build" "$OS_BUILD"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "OS Version" "$PRETTY_NAME"
        print_info "Version ID" "$VERSION_ID"
    fi
fi

# ===== CPU INFO =====
print_section "CPU Information"

if [[ "$OS_TYPE" == "macOS" ]]; then
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
    CPU_CORES=$(sysctl -n hw.ncpu)
    CPU_FREQ=$(sysctl -n hw.cpufrequency_max | awk '{printf "%.2f GHz", $1/1000000000}')
    print_info "Model" "$CPU_MODEL"
    print_info "Cores" "$CPU_CORES"
    print_info "Max Frequency" "$CPU_FREQ"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
    CPU_FREQ=$(grep -m1 "cpu MHz" /proc/cpuinfo | cut -d: -f2 | xargs | awk '{printf "%.2f MHz", $1}')
    print_info "Model" "$CPU_MODEL"
    print_info "Cores" "$CPU_CORES"
    print_info "Frequency" "$CPU_FREQ"
fi

# ===== MEMORY INFO =====
print_section "Memory Information"

if [[ "$OS_TYPE" == "macOS" ]]; then
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{printf "%.2f GB", $1/1024/1024/1024}')
    USED_MEM=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.' | awk '{printf "%.2f GB", $1*4096/1024/1024/1024}')
    print_info "Total Memory" "$TOTAL_MEM"
    print_info "Used Memory" "$USED_MEM"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    TOTAL_MEM=$(free -h | grep "^Mem:" | awk '{print $2}')
    USED_MEM=$(free -h | grep "^Mem:" | awk '{print $3}')
    AVAILABLE_MEM=$(free -h | grep "^Mem:" | awk '{print $7}')
    print_info "Total Memory" "$TOTAL_MEM"
    print_info "Used Memory" "$USED_MEM"
    print_info "Available Memory" "$AVAILABLE_MEM"
fi

# ===== GPU INFO =====
print_section "GPU Information"

if [[ "$OS_TYPE" == "macOS" ]]; then
    GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs)
    if [ -z "$GPU_INFO" ]; then
        GPU_INFO="Integrated GPU (Apple Silicon or Intel)"
    fi
    print_info "GPU" "$GPU_INFO"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    if command -v lspci &> /dev/null; then
        GPU_INFO=$(lspci | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | xargs)
        if [ -z "$GPU_INFO" ]; then
            GPU_INFO="Not detected"
        fi
    else
        GPU_INFO="lspci not available"
    fi
    print_info "GPU" "$GPU_INFO"
fi

# ===== DISK INFO =====
print_section "Hard Disk Information"

if [[ "$OS_TYPE" == "macOS" ]]; then
    DISK_INFO=$(df / | tail -1 | awk '{print $1}')
    TOTAL_DISK=$(df -H / | tail -1 | awk '{print $2}')
    USED_DISK=$(df -H / | tail -1 | awk '{print $3}')
    FREE_DISK=$(df -H / | tail -1 | awk '{print $4}')
    print_info "Device" "$DISK_INFO"
    print_info "Total Size" "$TOTAL_DISK"
    print_info "Used Space" "$USED_DISK"
    print_info "Free Space" "$FREE_DISK"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    DISK_INFO=$(df -h / | tail -1 | awk '{print $1}')
    TOTAL_DISK=$(df -h / | tail -1 | awk '{print $2}')
    USED_DISK=$(df -h / | tail -1 | awk '{print $3}')
    FREE_DISK=$(df -h / | tail -1 | awk '{print $4}')
    print_info "Device" "$DISK_INFO"
    print_info "Total Size" "$TOTAL_DISK"
    print_info "Used Space" "$USED_DISK"
    print_info "Free Space" "$FREE_DISK"
fi

# ===== SWAP INFO =====
print_section "SWAP Memory Information"

if [[ "$OS_TYPE" == "macOS" ]]; then
    SWAP_INFO=$(sysctl -n vm.swapusage)
    print_info "SWAP Usage" "$SWAP_INFO"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    TOTAL_SWAP=$(free -h | grep "^Swap:" | awk '{print $2}')
    USED_SWAP=$(free -h | grep "^Swap:" | awk '{print $3}')
    FREE_SWAP=$(free -h | grep "^Swap:" | awk '{print $4}')
    print_info "Total SWAP" "$TOTAL_SWAP"
    print_info "Used SWAP" "$USED_SWAP"
    print_info "Free SWAP" "$FREE_SWAP"
fi

echo -e "\n"
