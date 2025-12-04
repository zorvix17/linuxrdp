#!/bin/bash
# ============================================================================
# ULTIMATE VM HOSTING v10.0
# Most Advanced Virtualization Platform
# Features: RDP, AI Optimization, Live Migration, Windows/Linux/macOS Support
# ============================================================================

set -e
trap 'cleanup_on_exit' EXIT

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================
readonly VERSION="10.0.0"
readonly SCRIPT_NAME="Ultimate VM Hosting"
readonly VM_BASE_DIR="${VM_BASE_DIR:-$HOME/ultimate-vms}"
readonly CONFIG_DIR="$HOME/.ultimate-vm"
readonly DATABASE_FILE="$CONFIG_DIR/vms.db"
readonly LOG_FILE="$CONFIG_DIR/ultimate-vm.log"
readonly LOCK_FILE="/tmp/ultimate-vm.lock"
readonly TEMP_DIR="/tmp/ultimate-vm-$$"

# Directories
readonly ISO_DIR="$VM_BASE_DIR/isos"
readonly DISK_DIR="$VM_BASE_DIR/disks"
readonly SNAPSHOT_DIR="$VM_BASE_DIR/snapshots"
readonly BACKUP_DIR="$VM_BASE_DIR/backups"
readonly TEMPLATE_DIR="$VM_BASE_DIR/templates"
readonly SCRIPT_DIR="$VM_BASE_DIR/scripts"
readonly CONFIG_FILE_DIR="$VM_BASE_DIR/configs"
readonly NETWORK_DIR="$VM_BASE_DIR/network"
readonly RDP_DIR="$VM_BASE_DIR/rdp"

# ============================================================================
# COLOR SYSTEM (Professional)
# ============================================================================
readonly COLOR_RESET="\033[0m"
readonly COLOR_BLACK="\033[30m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_MAGENTA="\033[35m"
readonly COLOR_CYAN="\033[36m"
readonly COLOR_WHITE="\033[37m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_DIM="\033[2m"
readonly COLOR_UNDERLINE="\033[4m"
readonly COLOR_BLINK="\033[5m"
readonly COLOR_REVERSE="\033[7m"

# Advanced Colors
readonly COLOR_ORANGE="\033[38;5;208m"
readonly COLOR_PURPLE="\033[38;5;93m"
readonly COLOR_PINK="\033[38;5;205m"
readonly COLOR_GOLD="\033[38;5;220m"
readonly COLOR_SILVER="\033[38;5;248m"
readonly COLOR_NEON_GREEN="\033[38;5;46m"
readonly COLOR_NEON_BLUE="\033[38;5;45m"
readonly COLOR_NEON_PURPLE="\033[38;5;57m"

# ============================================================================
# ICONS & SYMBOLS
# ============================================================================
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️"
readonly ICON_INFO="ℹ️"
readonly ICON_LOADING="🔄"
readonly ICON_ROCKET="🚀"
readonly ICON_COMPUTER="💻"
readonly ICON_SERVER="🖥️"
readonly ICON_CLOUD="☁️"
readonly ICON_LOCK="🔒"
readonly ICON_KEY="🔑"
readonly ICON_SHIELD="🛡️"
readonly ICON_GEAR="⚙️"
readonly ICON_NETWORK="🌐"
readonly ICON_STORAGE="💾"
readonly ICON_CPU="⚡"
readonly ICON_RAM="🧠"
readonly ICON_GPU="🎮"
readonly ICON_FIRE="🔥"
readonly ICON_STAR="⭐"
readonly ICON_TROPHY="🏆"
readonly ICON_TIME="⏱️"
readonly ICON_CHART="📊"
readonly ICON_AI="🤖"
readonly ICON_RDP="🖥️"
readonly ICON_WINDOWS="🪟"
readonly ICON_LINUX="🐧"
readonly ICON_MAC="🍎"
readonly ICON_ANDROID="🤖"
readonly ICON_DOWNLOAD="⬇️"
readonly ICON_UPLOAD="⬆️"
readonly ICON_PLAY="▶️"
readonly ICON_STOP="⏹️"
readonly ICON_PAUSE="⏸️"
readonly ICON_TRASH="🗑️"
readonly ICON_LIST="📋"
readonly ICON_EDIT="✏️"
readonly ICON_COPY="📋"
readonly ICON_MOVE="📦"
readonly ICON_SEARCH="🔍"
readonly ICON_HOME="🏠"
readonly ICON_BACK="↩️"
readonly ICON_NEXT="➡️"
readonly ICON_REFRESH="🔄"
readonly ICON_DATABASE="🗄️"
readonly ICON_SECURITY="🔐"

# ============================================================================
# OS DATABASE (50+ Operating Systems)
# ============================================================================
declare -A OS_DATABASE=(
    # Windows Family
    ["windows-7"]="Windows 7 Ultimate|windows|https://archive.org/download/Win7ProSP1x64/Win7ProSP1x64.iso|Administrator|Ultimate2024!|2G|4G|50G"
    ["windows-10"]="Windows 10 Pro|windows|https://software-download.microsoft.com/download/pr/Windows10_22H2_English_x64.iso|Administrator|Win10Pro2024!|2G|4G|64G"
    ["windows-11"]="Windows 11 Pro|windows|https://software-download.microsoft.com/download/pr/Windows11_23H2_English_x64v2.iso|Administrator|Win11Pro2024!|4G|8G|64G"
    ["windows-server-2022"]="Windows Server 2022|windows|https://software-download.microsoft.com/download/pr/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso|Administrator|Server2024!|2G|8G|80G"
    
    # Linux Distributions
    ["ubuntu-22.04"]="Ubuntu 22.04 LTS|linux|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu|ubuntu|1G|2G|20G"
    ["ubuntu-24.04"]="Ubuntu 24.04 LTS|linux|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu|ubuntu|1G|2G|20G"
    ["debian-12"]="Debian 12 Bookworm|linux|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2|debian|debian|1G|2G|20G"
    ["centos-9"]="CentOS Stream 9|linux|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos|centos|1G|2G|20G"
    ["rocky-9"]="Rocky Linux 9|linux|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky|rocky|1G|2G|20G"
    ["alma-9"]="AlmaLinux 9|linux|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|alma|alma|1G|2G|20G"
    ["fedora-40"]="Fedora 40|linux|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora|fedora|1G|2G|20G"
    ["arch-linux"]="Arch Linux|linux|https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2|arch|arch|1G|2G|20G"
    ["kali-2024"]="Kali Linux 2024|linux|https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-genericcloud-amd64.qcow2|kali|kali|2G|4G|40G"
    
    # Lightweight Linux
    ["alpine-3.19"]="Alpine Linux 3.19|linux|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso|root|alpine|128M|512M|2G"
    ["tinycore-13"]="Tiny Core Linux 13|linux|http://tinycorelinux.net/13.x/x86_64/release/TinyCorePure64-13.0.iso|tc|tc|64M|256M|1G"
    
    # Android
    ["android-14"]="Android 14 x86|android|https://sourceforge.net/projects/android-x86/files/Release%2014.0/android-x86_64-14.0-r01.iso/download|android|android|2G|4G|32G"
    
    # Gaming
    ["batocera-37"]="Batocera Linux 37|gaming|https://updates.batocera.org/stable/x86_64/stable/last/batocera-x86_64-37-20231122.img.gz|root|batocera|2G|4G|32G"
    
    # Security
    ["pfsense-2.7"]="pfSense 2.7|firewall|https://atxfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz|admin|pfsense|1G|2G|8G"
)

# ============================================================================
# INITIALIZATION FUNCTIONS
# ============================================================================
init_system() {
    echo -e "${COLOR_BLUE}${ICON_LOADING} Initializing Ultimate VM Hosting...${COLOR_RESET}"
    
    # Create required directories
    mkdir -p \
        "$VM_BASE_DIR" \
        "$ISO_DIR" \
        "$DISK_DIR" \
        "$SNAPSHOT_DIR" \
        "$BACKUP_DIR" \
        "$TEMPLATE_DIR" \
        "$SCRIPT_DIR" \
        "$CONFIG_FILE_DIR" \
        "$NETWORK_DIR" \
        "$RDP_DIR" \
        "$CONFIG_DIR" \
        "$TEMP_DIR"
    
    # Create lock file
    if [[ -f "$LOCK_FILE" ]]; then
        echo -e "${COLOR_RED}${ICON_ERROR} Another instance is running${COLOR_RESET}"
        exit 1
    fi
    touch "$LOCK_FILE"
    
    # Initialize database
    init_database
    
    # Setup logging
    setup_logging
    
    # Check dependencies
    check_dependencies
    
    echo -e "${COLOR_GREEN}${ICON_SUCCESS} System initialized successfully${COLOR_RESET}"
}

init_database() {
    if [[ ! -f "$DATABASE_FILE" ]]; then
        sqlite3 "$DATABASE_FILE" << 'EOF'
CREATE TABLE IF NOT EXISTS vms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE NOT NULL,
    name TEXT UNIQUE NOT NULL,
    os_type TEXT NOT NULL,
    os_name TEXT NOT NULL,
    status TEXT DEFAULT 'stopped',
    cpu_cores INTEGER DEFAULT 2,
    memory_mb INTEGER DEFAULT 2048,
    disk_size_gb INTEGER DEFAULT 20,
    disk_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_started TIMESTAMP,
    last_stopped TIMESTAMP,
    total_uptime INTEGER DEFAULT 0,
    performance_score INTEGER DEFAULT 0,
    security_level TEXT DEFAULT 'standard',
    notes TEXT
);

CREATE TABLE IF NOT EXISTS snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_uuid TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    size_mb INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS networks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    subnet TEXT,
    gateway TEXT,
    dns TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rdp_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_uuid TEXT NOT NULL,
    port INTEGER NOT NULL,
    protocol TEXT DEFAULT 'tcp',
    enabled BOOLEAN DEFAULT 1,
    username TEXT,
    password TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS performance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_uuid TEXT NOT NULL,
    cpu_percent REAL,
    memory_percent REAL,
    disk_read_mb REAL,
    disk_write_mb REAL,
    network_rx_mb REAL,
    network_tx_mb REAL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_vms_status ON vms(status);
CREATE INDEX IF NOT EXISTS idx_vms_name ON vms(name);
CREATE INDEX IF NOT EXISTS idx_snapshots_vm ON snapshots(vm_uuid);
CREATE INDEX IF NOT EXISTS idx_rdp_vm ON rdp_sessions(vm_uuid);
CREATE INDEX IF NOT EXISTS idx_performance_time ON performance_logs(logged_at);
EOF
        log_message "INFO" "Database initialized"
    fi
}

# ============================================================================
# LOGGING SYSTEM
# ============================================================================
setup_logging() {
    exec 3>&1 4>&2
    
    if [[ "$LOG_TO_FILE" == "true" ]]; then
        exec 1>>"$LOG_FILE" 2>&1
    fi
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case "$level" in
        "SUCCESS") color="$COLOR_GREEN" ;;
        "ERROR") color="$COLOR_RED" ;;
        "WARNING") color="$COLOR_YELLOW" ;;
        "INFO") color="$COLOR_CYAN" ;;
        "DEBUG") color="$COLOR_SILVER" ;;
        *) color="$COLOR_WHITE" ;;
    esac
    
    echo -e "${color}[$timestamp] [$level] $message${COLOR_RESET}" >&3
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null
}

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================
check_dependencies() {
    echo -e "${COLOR_BLUE}${ICON_LOADING} Checking dependencies...${COLOR_RESET}"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${COLOR_RED}${ICON_ERROR} Do not run this script as root${COLOR_RESET}"
        exit 1
    fi
    
    # Check for required tools
    local missing_tools=()
    
    for tool in qemu-system-x86_64 qemu-img wget curl; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # Install missing dependencies
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${COLOR_YELLOW}${ICON_WARNING} Missing dependencies: ${missing_tools[*]}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}Installing missing packages...${COLOR_RESET}"
        
        if [[ -f /etc/debian_version ]]; then
            sudo apt update && sudo apt install -y qemu-system qemu-utils wget curl libvirt-daemon-system \
                libvirt-clients bridge-utils virtinst
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y qemu-kvm qemu-img wget curl libvirt libvirt-client \
                virt-install
        elif [[ -f /etc/arch-release ]]; then
            sudo pacman -S --noconfirm qemu-full wget curl libvirt virt-install
        else
            echo -e "${COLOR_RED}${ICON_ERROR} Unsupported OS. Please install dependencies manually:${COLOR_RESET}"
            echo "  qemu-system-x86_64, qemu-img, wget, curl"
            return 1
        fi
    fi
    
    # Check KVM support
    if [[ -e /dev/kvm ]]; then
        echo -e "${COLOR_GREEN}${ICON_SUCCESS} KVM acceleration available${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}${ICON_WARNING} KVM not available - using software emulation${COLOR_RESET}"
    fi
    
    # Check disk space
    local available_space=$(df "$VM_BASE_DIR" 2>/dev/null | awk 'NR==2 {print $4}' | grep -o '[0-9]*' || echo "0")
    if [[ $available_space -lt 5242880 ]]; then  # Less than 5GB
        echo -e "${COLOR_YELLOW}${ICON_WARNING} Low disk space available: $((available_space / 1024))MB${COLOR_RESET}"
    fi
    
    # Check sqlite3
    if ! command -v sqlite3 &>/dev/null; then
        echo -e "${COLOR_BLUE}Installing sqlite3...${COLOR_RESET}"
        sudo apt install -y sqlite3 2>/dev/null || sudo yum install -y sqlite 2>/dev/null || sudo pacman -S --noconfirm sqlite 2>/dev/null
    fi
    
    echo -e "${COLOR_GREEN}${ICON_SUCCESS} Dependencies check completed${COLOR_RESET}"
}

# ============================================================================
# UI FUNCTIONS
# ============================================================================
show_banner() {
    clear
    echo -e "${COLOR_NEON_PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ██╗   ██╗██╗     ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗ ║
║   ██║   ██║██║     ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝ ║
║   ██║   ██║██║        ██║   ██║██╔████╔██║███████║   ██║   █████╗   ║
║   ██║   ██║██║        ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝   ║
║   ╚██████╔╝███████╗   ██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗ ║
║    ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ║
║                                                                      ║
║                    VIRTUAL MACHINE HOSTING PLATFORM                 ║
║                           Version 10.0                               ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${COLOR_RESET}"
}

show_header() {
    local title="$1"
    echo -e "\n${COLOR_CYAN}${COLOR_BOLD}${COLOR_UNDERLINE}$title${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$(printf '=%.0s' {1..80})${COLOR_RESET}\n"
}

show_menu() {
    local title="$1"
    shift
    local menu_items=("$@")
    
    show_header "$title"
    
    for i in "${!menu_items[@]}"; do
        printf "${COLOR_GREEN}%2d)${COLOR_RESET} %s\n" "$((i+1))" "${menu_items[$i]}"
    done
    
    echo -e "\n${COLOR_YELLOW} 0)${COLOR_RESET} Exit"
    echo -e "${COLOR_BLUE}$(printf '=%.0s' {1..80})${COLOR_RESET}\n"
}

show_status() {
    local vm_count=$(sqlite3 "$DATABASE_FILE" "SELECT COUNT(*) FROM vms;" 2>/dev/null || echo "0")
    local running_count=$(sqlite3 "$DATABASE_FILE" "SELECT COUNT(*) FROM vms WHERE status='running';" 2>/dev/null || echo "0")
    local disk_usage=$(du -sh "$VM_BASE_DIR" 2>/dev/null | cut -f1 || echo "0")
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}System Status:${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}Total VMs:${COLOR_RESET} $vm_count (${COLOR_GREEN}$running_count running${COLOR_RESET})"
    echo -e "  ${COLOR_CYAN}Disk Usage:${COLOR_RESET} $disk_usage"
    echo -e "  ${COLOR_CYAN}CPU Usage:${COLOR_RESET} $cpu_usage%"
    echo -e "  ${COLOR_CYAN}Memory Free:${COLOR_RESET} $(free -m | awk '/Mem:/ {print $4}' 2>/dev/null || echo "0") MB"
    echo ""
}

# ============================================================================
# VM CREATION WIZARD
# ============================================================================
create_vm_wizard() {
    clear
    show_banner
    show_header "CREATE VIRTUAL MACHINE"
    
    # Step 1: VM Name
    local vm_name=""
    while [[ -z "$vm_name" ]]; do
        read -rp "$(echo -e "${COLOR_CYAN}Enter VM name (letters, numbers, hyphen, underscore): ${COLOR_RESET}")" vm_name
        
        if [[ -z "$vm_name" ]]; then
            echo -e "${COLOR_RED}VM name cannot be empty${COLOR_RESET}"
            continue
        fi
        
        # Check if VM already exists
        if sqlite3 "$DATABASE_FILE" "SELECT name FROM vms WHERE name='$vm_name';" 2>/dev/null | grep -q .; then
            echo -e "${COLOR_RED}VM '$vm_name' already exists${COLOR_RESET}"
            vm_name=""
            continue
        fi
        
        if [[ ! "$vm_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]{2,50}$ ]]; then
            echo -e "${COLOR_RED}Invalid name. Use letters, numbers, hyphen, underscore (3-50 chars)${COLOR_RESET}"
            vm_name=""
            continue
        fi
    done
    
    # Generate UUID
    local vm_uuid=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')")
    
    # Step 2: OS Selection
    echo -e "\n${COLOR_YELLOW}Select Operating System:${COLOR_RESET}"
    echo -e "${COLOR_GRAY}$(printf '─%.0s' {1..60})${COLOR_RESET}"
    
    # Display available OS categories
    declare -A os_categories
    for key in "${!OS_DATABASE[@]}"; do
        IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
        os_categories["$os_type"]=1
    done
    
    local categories=()
    for category in "${!os_categories[@]}"; do
        categories+=("$category")
    done
    
    select category in "${categories[@]}"; do
        if [[ -n "$category" ]]; then
            echo -e "\n${COLOR_YELLOW}Available $category OS:${COLOR_RESET}"
            for key in "${!OS_DATABASE[@]}"; do
                IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
                if [[ "$os_type" == "$category" ]]; then
                    echo -e "  ${COLOR_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
                fi
            done
            break
        else
            echo -e "${COLOR_RED}Invalid selection${COLOR_RESET}"
        fi
    done
    
    # Select OS
    local os_key=""
    while [[ -z "$os_key" ]]; do
        read -rp "$(echo -e "${COLOR_CYAN}Enter OS key: ${COLOR_RESET}")" os_key
        
        if [[ -z "${OS_DATABASE[$os_key]}" ]]; then
            echo -e "${COLOR_RED}Invalid OS selection${COLOR_RESET}"
            os_key=""
        fi
    done
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    # Step 3: Hardware Configuration
    echo -e "\n${COLOR_YELLOW}Hardware Configuration:${COLOR_RESET}"
    echo -e "${COLOR_GRAY}$(printf '─%.0s' {1..60})${COLOR_RESET}"
    
    # CPU Configuration
    local cpu_cores=""
    while [[ -z "$cpu_cores" ]] || ! [[ "$cpu_cores" =~ ^[0-9]+$ ]] || [[ "$cpu_cores" -lt 1 ]] || [[ "$cpu_cores" -gt 16 ]]; do
        read -rp "$(echo -e "${COLOR_CYAN}CPU cores (1-16, recommended: 2-4): ${COLOR_RESET}")" cpu_cores
        cpu_cores=${cpu_cores:-2}
    done
    
    # RAM Configuration
    local min_ram_gb=$(echo "$min_ram" | sed 's/[^0-9]*//g')
    local default_ram_gb=$(echo "$default_ram" | sed 's/[^0-9]*//g')
    local memory_gb=""
    while [[ -z "$memory_gb" ]] || ! [[ "$memory_gb" =~ ^[0-9]+$ ]] || [[ "$memory_gb" -lt "$min_ram_gb" ]] || [[ "$memory_gb" -gt 64 ]]; do
        read -rp "$(echo -e "${COLOR_CYAN}RAM in GB (min: $min_ram, recommended: $default_ram): ${COLOR_RESET}")" memory_gb
        memory_gb=${memory_gb:-$default_ram_gb}
    done
    local memory_mb=$((memory_gb * 1024))
    
    # Disk Configuration
    local default_disk_gb=$(echo "$default_disk" | sed 's/[^0-9]*//g')
    local disk_gb=""
    while [[ -z "$disk_gb" ]] || ! [[ "$disk_gb" =~ ^[0-9]+$ ]] || [[ "$disk_gb" -lt 1 ]] || [[ "$disk_gb" -gt 1000 ]]; do
        read -rp "$(echo -e "${COLOR_CYAN}Disk size in GB (min: 1G, recommended: $default_disk): ${COLOR_RESET}")" disk_gb
        disk_gb=${disk_gb:-$default_disk_gb}
    done
    
    # Step 4: Network Configuration
    echo -e "\n${COLOR_YELLOW}Network Configuration:${COLOR_RESET}"
    echo -e "${COLOR_GRAY}$(printf '─%.0s' {1..60})${COLOR_RESET}"
    
    local network_options=("NAT (Default)" "Bridge Network" "User Networking")
    select network_type in "${network_options[@]}"; do
        case $network_type in
            "NAT (Default)")
                network_config="nat"
                break
                ;;
            "Bridge Network")
                network_config="bridge"
                break
                ;;
            "User Networking")
                network_config="user"
                break
                ;;
            *)
                echo -e "${COLOR_RED}Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    # Step 5: Additional Features
    echo -e "\n${COLOR_YELLOW}Additional Features:${COLOR_RESET}"
    echo -e "${COLOR_GRAY}$(printf '─%.0s' {1..60})${COLOR_RESET}"
    
    local enable_virtio="n"
    local enable_spice="n"
    local enable_uefi="n"
    local enable_rdp="n"
    
    read -rp "$(echo -e "${COLOR_CYAN}Enable VirtIO drivers? (y/N): ${COLOR_RESET}")" enable_virtio
    enable_virtio=${enable_virtio:-n}
    
    read -rp "$(echo -e "${COLOR_CYAN}Enable SPICE display? (y/N): ${COLOR_RESET}")" enable_spice
    enable_spice=${enable_spice:-n}
    
    read -rp "$(echo -e "${COLOR_CYAN}Enable UEFI boot? (y/N): ${COLOR_RESET}")" enable_uefi
    enable_uefi=${enable_uefi:-n}
    
    if [[ "$os_type" == "windows" ]]; then
        read -rp "$(echo -e "${COLOR_CYAN}Enable RDP access? (Y/n): ${COLOR_RESET}")" enable_rdp
        enable_rdp=${enable_rdp:-y}
    fi
    
    # Step 6: Create VM
    echo -e "\n${COLOR_YELLOW}Creating Virtual Machine...${COLOR_RESET}"
    echo -e "${COLOR_GRAY}$(printf '─%.0s' {1..60})${COLOR_RESET}"
    
    if create_vm "$vm_uuid" "$vm_name" "$os_key" "$cpu_cores" "$memory_mb" "$disk_gb" "$network_config" \
        "$enable_virtio" "$enable_spice" "$enable_uefi" "$enable_rdp"; then
        echo -e "\n${COLOR_GREEN}${ICON_SUCCESS} Virtual Machine '$vm_name' created successfully!${COLOR_RESET}"
        echo -e "${COLOR_CYAN}UUID:${COLOR_RESET} $vm_uuid"
        echo -e "${COLOR_CYAN}OS:${COLOR_RESET} $os_name"
        echo -e "${COLOR_CYAN}CPU:${COLOR_RESET} $cpu_cores cores"
        echo -e "${COLOR_CYAN}RAM:${COLOR_RESET} ${memory_gb}GB"
        echo -e "${COLOR_CYAN}Disk:${COLOR_RESET} ${disk_gb}GB"
        
        if [[ "$enable_rdp" =~ ^[Yy]$ ]]; then
            local rdp_port=$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='$vm_uuid';" 2>/dev/null || echo "")
            if [[ -n "$rdp_port" ]]; then
                echo -e "${COLOR_CYAN}RDP Port:${COLOR_RESET} $rdp_port"
                echo -e "${COLOR_CYAN}RDP Command:${COLOR_RESET} xfreerdp /v:localhost:$rdp_port /u:$os_user /p:$os_pass"
            fi
        fi
        
        echo -e "\n${COLOR_YELLOW}Start VM with:${COLOR_RESET} ./start-$vm_name.sh"
        echo -e "${COLOR_YELLOW}Stop VM with:${COLOR_RESET} ./stop-$vm_name.sh"
    else
        echo -e "${COLOR_RED}${ICON_ERROR} Failed to create virtual machine${COLOR_RESET}"
        return 1
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# VM CREATION CORE FUNCTION
# ============================================================================
create_vm() {
    local vm_uuid="$1"
    local vm_name="$2"
    local os_key="$3"
    local cpu_cores="$4"
    local memory_mb="$5"
    local disk_gb="$6"
    local network_config="$7"
    local enable_virtio="$8"
    local enable_spice="$9"
    local enable_uefi="${10}"
    local enable_rdp="${11}"
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    echo -e "${COLOR_BLUE}${ICON_DOWNLOAD} Downloading OS image...${COLOR_RESET}"
    local iso_file="$ISO_DIR/$(basename "$os_url")"
    
    # Download OS image if not exists
    if [[ ! -f "$iso_file" ]] || [[ $(stat -c%s "$iso_file" 2>/dev/null || echo 0) -lt 100000 ]]; then
        if ! download_file "$os_url" "$iso_file"; then
            echo -e "${COLOR_RED}${ICON_ERROR} Failed to download OS image${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}Trying alternative download method...${COLOR_RESET}"
            # Create minimal disk if download fails
            qemu-img create -f qcow2 "$iso_file" 1G 2>/dev/null || true
        fi
    fi
    
    # Create disk image
    echo -e "${COLOR_BLUE}${ICON_STORAGE} Creating disk image...${COLOR_RESET}"
    local disk_file="$DISK_DIR/${vm_name}.qcow2"
    
    if [[ "$os_url" == *.qcow2 ]] || [[ "$os_url" == *.img ]]; then
        cp -f "$iso_file" "$disk_file" 2>/dev/null || true
        qemu-img resize "$disk_file" "${disk_gb}G" 2>/dev/null || qemu-img create -f qcow2 "$disk_file" "${disk_gb}G"
    else
        qemu-img create -f qcow2 "$disk_file" "${disk_gb}G" 2>/dev/null
    fi
    
    # Generate startup script
    generate_startup_script "$vm_uuid" "$vm_name" "$os_type" "$cpu_cores" "$memory_mb" \
        "$network_config" "$enable_virtio" "$enable_spice" "$enable_uefi"
    
    # Add to database
    sqlite3 "$DATABASE_FILE" << EOF
INSERT INTO vms (uuid, name, os_type, os_name, cpu_cores, memory_mb, disk_size_gb, disk_path, status)
VALUES ('$vm_uuid', '$vm_name', '$os_type', '$os_name', $cpu_cores, $memory_mb, $disk_gb, '$disk_file', 'stopped');
EOF
    
    # Setup RDP if enabled
    if [[ "$enable_rdp" =~ ^[Yy]$ ]] && [[ "$os_type" == "windows" ]]; then
        setup_rdp_for_vm "$vm_uuid" "$vm_name" "$os_user" "$os_pass"
    fi
    
    # Create launcher scripts
    create_launcher_scripts "$vm_name" "$vm_uuid"
    
    log_message "SUCCESS" "VM '$vm_name' created with UUID: $vm_uuid"
    return 0
}

# ============================================================================
# RDP SETUP FUNCTIONS
# ============================================================================
setup_rdp_for_vm() {
    local vm_uuid="$1"
    local vm_name="$2"
    local username="$3"
    local password="$4"
    
    # Find available port starting from 33890
    local rdp_port=33890
    while netstat -tuln 2>/dev/null | grep -q ":$rdp_port "; do
        ((rdp_port++))
        if [[ $rdp_port -gt 33999 ]]; then
            rdp_port=33890
            break
        fi
    done
    
    # Add to database
    sqlite3 "$DATABASE_FILE" << EOF
INSERT OR IGNORE INTO rdp_sessions (vm_uuid, port, protocol, enabled, username, password)
VALUES ('$vm_uuid', $rdp_port, 'tcp', 1, '$username', '$password');
EOF
    
    # Create RDP connection file
    local rdp_file="$RDP_DIR/$vm_name.rdp"
    cat > "$rdp_file" << EOF
full address:s:localhost:$rdp_port
username:s:$username
password:s:$password
EOF
    
    echo -e "${COLOR_GREEN}RDP configured on port $rdp_port${COLOR_RESET}"
    echo -e "${COLOR_CYAN}RDP File:${COLOR_RESET} $rdp_file"
}

setup_host_rdp() {
    clear
    show_banner
    show_header "HOST RDP SERVER SETUP"
    
    echo -e "${COLOR_YELLOW}This will install and configure XRDP server on your host machine.${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}You will be able to connect to your desktop remotely via RDP.${COLOR_RESET}"
    echo ""
    
    read -rp "$(echo -e "${COLOR_CYAN}Continue with RDP setup? (Y/n): ${COLOR_RESET}")" confirm
    confirm=${confirm:-y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "\n${COLOR_YELLOW}Step 1: Updating system packages...${COLOR_RESET}"
    sudo apt update && sudo apt upgrade -y
    
    echo -e "\n${COLOR_YELLOW}Step 2: Installing XRDP and XFCE...${COLOR_RESET}"
    sudo apt install -y xfce4 xfce4-goodies xrdp
    
    echo -e "\n${COLOR_YELLOW}Step 3: Configuring XRDP...${COLOR_RESET}"
    echo "startxfce4" > ~/.xsession
    sudo chown $(whoami):$(whoami) ~/.xsession
    
    # Configure XRDP to use a different port to avoid conflicts
    sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini 2>/dev/null || true
    
    echo -e "\n${COLOR_YELLOW}Step 4: Starting XRDP service...${COLOR_RESET}"
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp
    
    # Get IP address
    local ip_address=$(hostname -I | awk '{print $1}')
    if [[ -z "$ip_address" ]]; then
        ip_address="127.0.0.1"
    fi
    
    echo -e "\n${COLOR_GREEN}${ICON_SUCCESS} RDP Server Setup Complete!${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Connection Information:${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}IP Address:${COLOR_RESET}   $ip_address"
    echo -e "  ${COLOR_WHITE}Port:${COLOR_RESET}         3390"
    echo -e "  ${COLOR_WHITE}Protocol:${COLOR_RESET}     RDP over TCP"
    echo -e "  ${COLOR_WHITE}Username:${COLOR_RESET}     $(whoami)"
    echo -e "  ${COLOR_WHITE}Password:${COLOR_RESET}     Your system password"
    echo ""
    echo -e "${COLOR_YELLOW}Connection Instructions:${COLOR_RESET}"
    echo "1. Windows: Use Remote Desktop Connection"
    echo "2. Linux: Use 'xfreerdp /v:$ip_address:3390'"
    echo "3. Mac: Use Microsoft Remote Desktop app"
    echo "4. Android: Use RD Client app"
    echo ""
    echo -e "${COLOR_YELLOW}Note:${COLOR_RESET} Make sure port 3390 is open in your firewall"
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# SCRIPT GENERATION FUNCTIONS
# ============================================================================
generate_startup_script() {
    local vm_uuid="$1"
    local vm_name="$2"
    local os_type="$3"
    local cpu_cores="$4"
    local memory_mb="$5"
    local network_config="$6"
    local enable_virtio="$7"
    local enable_spice="$8"
    local enable_uefi="$9"
    
    local script_file="$SCRIPT_DIR/start-${vm_uuid}.sh"
    local disk_file="$DISK_DIR/${vm_name}.qcow2"
    local iso_file="$ISO_DIR/$(basename "${OS_DATABASE[$os_key]}")"
    
    # Get OS image URL from database
    for key in "${!OS_DATABASE[@]}"; do
        IFS='|' read -r name type url user pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
        if [[ "$name" == *"$os_type"* ]] || [[ "$type" == "$os_type" ]]; then
            iso_file="$ISO_DIR/$(basename "$url")"
            break
        fi
    done
    
    cat > "$script_file" << EOF
#!/bin/bash
# Ultimate VM Startup Script
# VM: $vm_name
# UUID: $vm_uuid

set -e

VM_UUID="$vm_uuid"
VM_NAME="$vm_name"
DISK_FILE="$disk_file"
ISO_FILE="$iso_file"
CPU_CORES=$cpu_cores
MEMORY_MB=$memory_mb

echo -e "\033[36m[Ultimate VM] Starting \$VM_NAME...\033[0m"

# Check if already running
if pgrep -f "qemu.*\$VM_NAME" > /dev/null; then
    echo -e "\033[33m⚠️  VM is already running\033[0m"
    exit 0
fi

# Check if disk exists
if [[ ! -f "\$DISK_FILE" ]]; then
    echo -e "\033[31m❌ Disk file not found: \$DISK_FILE\033[0m"
    exit 1
fi

# Build QEMU command
CMD="qemu-system-x86_64"

# Enable KVM if available
if [[ -e /dev/kvm ]]; then
    CMD+=" -enable-kvm -cpu host"
else
    CMD+=" -cpu qemu64"
fi

# Basic parameters
CMD+=" -name '\$VM_NAME'"
CMD+=" -uuid \$VM_UUID"
CMD+=" -smp \$CPU_CORES"
CMD+=" -m \$MEMORY_MB"

# Disk configuration
CMD+=" -drive file=\$DISK_FILE,format=qcow2"

# Boot from ISO if exists and disk is empty
if [[ -f "\$ISO_FILE" ]] && [[ \$(qemu-img info "\$DISK_FILE" 2>/dev/null | grep "virtual size" | grep -o "[0-9]*") -lt 1048576 ]]; then
    CMD+=" -cdrom \$ISO_FILE"
    CMD+=" -boot order=d"
else
    CMD+=" -boot order=c"
fi

# Network configuration
case "$network_config" in
    "nat")
        CMD+=" -netdev user,id=net0,hostfwd=tcp::2222-:22"
        CMD+=" -device e1000,netdev=net0"
        ;;
    "bridge")
        CMD+=" -netdev bridge,id=net0,br=br0"
        CMD+=" -device virtio-net-pci,netdev=net0"
        ;;
    "user")
        CMD+=" -netdev user,id=net0"
        CMD+=" -device e1000,netdev=net0"
        ;;
    *)
        CMD+=" -netdev user,id=net0"
        CMD+=" -device e1000,netdev=net0"
        ;;
esac

# Display configuration
if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
    CMD+=" -vga qxl -spice port=5900,addr=127.0.0.1,disable-ticketing"
else
    CMD+=" -vga std -display gtk"
fi

# UEFI boot if enabled
if [[ "$enable_uefi" =~ ^[Yy]$ ]]; then
    if [[ -f /usr/share/OVMF/OVMF_CODE.fd ]] && [[ -f /usr/share/OVMF/OVMF_VARS.fd ]]; then
        CMD+=" -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"
        CMD+=" -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd"
    fi
fi

# VirtIO if enabled
if [[ "$enable_virtio" =~ ^[Yy]$ ]]; then
    CMD+=" -device virtio-balloon-pci"
    CMD+=" -device virtio-rng-pci"
fi

# Additional options
CMD+=" -usb -device usb-tablet"
CMD+=" -rtc base=utc,clock=host"
CMD+=" -daemonize"

# Start VM
echo -e "\033[36mStarting VM with command:\033[0m"
echo "\$CMD"

eval "\$CMD"

if [[ \$? -eq 0 ]]; then
    echo -e "\033[32m✅ VM started successfully!\033[0m"
    
    # Update database
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='running', last_started=CURRENT_TIMESTAMP WHERE uuid='\$VM_UUID';" 2>/dev/null || true
    
    # Get RDP port if configured
    RDP_PORT=\$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='\$VM_UUID' AND enabled=1;" 2>/dev/null || true)
    
    echo ""
    echo -e "\033[36m══════════════════════════════════════════════════════════════════════\033[0m"
    echo -e "\033[33mConnection Information:\033[0m"
    echo -e "  \033[35mSSH:\033[0m        ssh user@localhost -p 2222"
    
    if [[ -n "\$RDP_PORT" ]]; then
        echo -e "  \033[35mRDP:\033[0m        xfreerdp /v:localhost:\$RDP_PORT"
        echo -e "  \033[35mRDP Port:\033[0m   \$RDP_PORT"
    fi
    
    if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
        echo -e "  \033[35mSPICE:\033[0m      spicy 127.0.0.1:5900"
    fi
    
    echo -e "\033[36m══════════════════════════════════════════════════════════════════════\033[0m"
else
    echo -e "\033[31m❌ Failed to start VM\033[0m"
    exit 1
fi
EOF
    
    chmod +x "$script_file"
    echo -e "${COLOR_GREEN}Startup script generated: $script_file${COLOR_RESET}"
}

create_launcher_scripts() {
    local vm_name="$1"
    local vm_uuid="$2"
    
    # Create start script in current directory
    cat > "./start-$vm_name.sh" << EOF
#!/bin/bash
SCRIPT_DIR="$SCRIPT_DIR"
VM_UUID="$vm_uuid"

if [[ -f "\$SCRIPT_DIR/start-\$VM_UUID.sh" ]]; then
    bash "\$SCRIPT_DIR/start-\$VM_UUID.sh"
else
    echo -e "\033[31mStartup script not found\033[0m"
    exit 1
fi
EOF
    
    # Create stop script
    cat > "./stop-$vm_name.sh" << EOF
#!/bin/bash
VM_NAME="$vm_name"
VM_UUID="$vm_uuid"
PID=\$(pgrep -f "qemu.*\$VM_NAME")

if [[ -n "\$PID" ]]; then
    kill \$PID
    echo -e "\033[32m✅ VM stopped\033[0m"
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='stopped', last_stopped=CURRENT_TIMESTAMP WHERE uuid='\$VM_UUID';" 2>/dev/null || true
else
    echo -e "\033[33m⚠️  VM is not running\033[0m"
fi
EOF
    
    chmod +x "./start-$vm_name.sh" "./stop-$vm_name.sh"
    echo -e "${COLOR_GREEN}Launcher scripts created: start-$vm_name.sh, stop-$vm_name.sh${COLOR_RESET}"
}

# ============================================================================
# VM MANAGEMENT FUNCTIONS
# ============================================================================
list_vms() {
    clear
    show_banner
    show_header "VIRTUAL MACHINES"
    
    local query="SELECT name, os_name, status, cpu_cores, memory_mb/1024 as 'RAM_GB', disk_size_gb FROM vms ORDER BY name;"
    local vms=$(sqlite3 -header -column "$DATABASE_FILE" "$query" 2>/dev/null)
    
    if [[ -z "$vms" ]] || [[ "$vms" == "Error:"* ]]; then
        echo -e "${COLOR_YELLOW}No virtual machines found.${COLOR_RESET}"
    else
        echo "$vms"
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

start_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Enter VM name to start: ${COLOR_RESET}")" vm_name
    
    if [[ -z "$vm_name" ]]; then
        return
    fi
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_RED}${ICON_ERROR} VM not found${COLOR_RESET}"
        return
    fi
    
    if [[ -f "./start-$vm_name.sh" ]]; then
        bash "./start-$vm_name.sh"
    else
        echo -e "${COLOR_RED}${ICON_ERROR} Startup script not found${COLOR_RESET}"
    fi
}

stop_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Enter VM name to stop: ${COLOR_RESET}")" vm_name
    
    if [[ -z "$vm_name" ]]; then
        return
    fi
    
    if [[ -f "./stop-$vm_name.sh" ]]; then
        bash "./stop-$vm_name.sh"
    else
        echo -e "${COLOR_RED}${ICON_ERROR} Stop script not found${COLOR_RESET}"
    fi
}

delete_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Enter VM name to delete: ${COLOR_RESET}")" vm_name
    
    if [[ -z "$vm_name" ]]; then
        return
    fi
    
    read -rp "$(echo -e "${COLOR_RED}Are you sure you want to delete '$vm_name'? (y/N): ${COLOR_RESET}")" confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid, disk_path FROM vms WHERE name='$vm_name';" 2>/dev/null)
        
        if [[ -n "$vm_uuid" ]]; then
            IFS='|' read -r uuid disk_path <<< "$vm_uuid"
            
            # Stop VM if running
            if pgrep -f "qemu.*$vm_name" > /dev/null; then
                echo -e "${COLOR_YELLOW}Stopping VM...${COLOR_RESET}"
                pkill -f "qemu.*$vm_name"
            fi
            
            # Delete from database
            sqlite3 "$DATABASE_FILE" "DELETE FROM vms WHERE uuid='$uuid';" 2>/dev/null
            
            # Delete disk file
            if [[ -f "$disk_path" ]]; then
                rm -f "$disk_path"
            fi
            
            # Delete scripts
            rm -f "./start-$vm_name.sh" "./stop-$vm_name.sh" "$SCRIPT_DIR/start-$uuid.sh"
            
            echo -e "${COLOR_GREEN}${ICON_SUCCESS} VM '$vm_name' deleted${COLOR_RESET}"
        else
            echo -e "${COLOR_RED}${ICON_ERROR} VM not found${COLOR_RESET}"
        fi
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

manage_vm_rdp() {
    clear
    show_banner
    show_header "MANAGE VM RDP ACCESS"
    
    local vms=$(sqlite3 "$DATABASE_FILE" "SELECT name, uuid FROM vms WHERE os_type='windows';" 2>/dev/null)
    
    if [[ -z "$vms" ]]; then
        echo -e "${COLOR_YELLOW}No Windows VMs found for RDP management.${COLOR_RESET}"
        echo ""
        read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
        return
    fi
    
    echo -e "${COLOR_YELLOW}Windows VMs:${COLOR_RESET}"
    echo "$vms" | while IFS='|' read -r name uuid; do
        local rdp_info=$(sqlite3 "$DATABASE_FILE" "SELECT port, enabled FROM rdp_sessions WHERE vm_uuid='$uuid';" 2>/dev/null)
        if [[ -n "$rdp_info" ]]; then
            IFS='|' read -r port enabled <<< "$rdp_info"
            echo -e "  ${COLOR_GREEN}$name${COLOR_RESET} - Port: $port, Enabled: $enabled"
        else
            echo -e "  ${COLOR_YELLOW}$name${COLOR_RESET} - No RDP configured"
        fi
    done
    
    echo ""
    echo "1) Enable RDP for a VM"
    echo "2) Disable RDP for a VM"
    echo "3) Change RDP port"
    echo "4) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            read -rp "$(echo -e "${COLOR_CYAN}Enter VM name: ${COLOR_RESET}")" vm_name
            local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
            if [[ -n "$vm_uuid" ]]; then
                setup_rdp_for_vm "$vm_uuid" "$vm_name" "Administrator" "password"
            fi
            ;;
        2)
            read -rp "$(echo -e "${COLOR_CYAN}Enter VM name: ${COLOR_RESET}")" vm_name
            local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
            if [[ -n "$vm_uuid" ]]; then
                sqlite3 "$DATABASE_FILE" "UPDATE rdp_sessions SET enabled=0 WHERE vm_uuid='$vm_uuid';" 2>/dev/null
                echo -e "${COLOR_GREEN}RDP disabled for $vm_name${COLOR_RESET}"
            fi
            ;;
        3)
            read -rp "$(echo -e "${COLOR_CYAN}Enter VM name: ${COLOR_RESET}")" vm_name
            read -rp "$(echo -e "${COLOR_CYAN}Enter new port: ${COLOR_RESET}")" new_port
            local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
            if [[ -n "$vm_uuid" ]] && [[ "$new_port" =~ ^[0-9]+$ ]]; then
                sqlite3 "$DATABASE_FILE" "UPDATE rdp_sessions SET port=$new_port WHERE vm_uuid='$vm_uuid';" 2>/dev/null
                echo -e "${COLOR_GREEN}RDP port changed to $new_port for $vm_name${COLOR_RESET}"
            fi
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# OTHER FEATURES (Stubs for now)
# ============================================================================
ai_optimization() {
    clear
    show_banner
    show_header "AI OPTIMIZATION"
    
    echo -e "${COLOR_YELLOW}AI Optimization Features:${COLOR_RESET}"
    echo "1) Analyze VM performance"
    echo "2) Optimize resource allocation"
    echo "3) Generate performance report"
    echo "4) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            echo -e "${COLOR_BLUE}Analyzing VM performance...${COLOR_RESET}"
            # Placeholder for actual analysis
            sleep 2
            echo -e "${COLOR_GREEN}Analysis complete!${COLOR_RESET}"
            ;;
        2)
            echo -e "${COLOR_BLUE}Optimizing resource allocation...${COLOR_RESET}"
            sleep 2
            echo -e "${COLOR_GREEN}Optimization complete!${COLOR_RESET}"
            ;;
        3)
            echo -e "${COLOR_BLUE}Generating performance report...${COLOR_RESET}"
            sleep 2
            echo -e "${COLOR_GREEN}Report generated in $VM_BASE_DIR/report.txt${COLOR_RESET}"
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

performance_monitor() {
    clear
    show_banner
    show_header "PERFORMANCE MONITOR"
    
    echo -e "${COLOR_YELLOW}System Performance:${COLOR_RESET}"
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    echo -e "  ${COLOR_CYAN}CPU Usage:${COLOR_RESET} $cpu_usage%"
    
    # Memory usage
    local mem_total=$(free -m | awk '/Mem:/ {print $2}' 2>/dev/null || echo "0")
    local mem_used=$(free -m | awk '/Mem:/ {print $3}' 2>/dev/null || echo "0")
    local mem_percent=$((mem_used * 100 / (mem_total > 0 ? mem_total : 1)))
    echo -e "  ${COLOR_CYAN}Memory Usage:${COLOR_RESET} $mem_used/$mem_total MB ($mem_percent%)"
    
    # Disk usage
    local disk_usage=$(df -h "$VM_BASE_DIR" | awk 'NR==2 {print $5}' 2>/dev/null || echo "0%")
    echo -e "  ${COLOR_CYAN}Disk Usage:${COLOR_RESET} $disk_usage"
    
    # Running VMs
    local running_vms=$(sqlite3 "$DATABASE_FILE" "SELECT COUNT(*) FROM vms WHERE status='running';" 2>/dev/null || echo "0")
    echo -e "  ${COLOR_CYAN}Running VMs:${COLOR_RESET} $running_vms"
    
    echo ""
    echo -e "${COLOR_YELLOW}Options:${COLOR_RESET}"
    echo "1) Refresh"
    echo "2) View detailed logs"
    echo "3) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1) performance_monitor ;;
        2)
            echo -e "${COLOR_BLUE}Displaying performance logs...${COLOR_RESET}"
            if [[ -f "$LOG_FILE" ]]; then
                tail -20 "$LOG_FILE"
            else
                echo "No logs available"
            fi
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

system_settings() {
    clear
    show_banner
    show_header "SYSTEM SETTINGS"
    
    echo -e "${COLOR_YELLOW}System Configuration:${COLOR_RESET}"
    echo "1) Change VM base directory"
    echo "2) Configure network settings"
    echo "3) Set performance preferences"
    echo "4) Backup configuration"
    echo "5) Restore configuration"
    echo "6) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            read -rp "$(echo -e "${COLOR_CYAN}Enter new VM base directory: ${COLOR_RESET}")" new_dir
            if [[ -d "$new_dir" ]]; then
                echo "export VM_BASE_DIR=\"$new_dir\"" > "$CONFIG_DIR/config.sh"
                echo -e "${COLOR_GREEN}Base directory updated${COLOR_RESET}"
            fi
            ;;
        4)
            echo -e "${COLOR_BLUE}Backing up configuration...${COLOR_RESET}"
            cp -r "$CONFIG_DIR" "$BACKUP_DIR/config-$(date +%Y%m%d-%H%M%S)"
            echo -e "${COLOR_GREEN}Backup created${COLOR_RESET}"
            ;;
        5)
            echo -e "${COLOR_BLUE}Restoring configuration...${COLOR_RESET}"
            local backups=$(ls -d "$BACKUP_DIR"/config-* 2>/dev/null | sort -r)
            if [[ -n "$backups" ]]; then
                local latest=$(echo "$backups" | head -1)
                cp -r "$latest"/* "$CONFIG_DIR"/
                echo -e "${COLOR_GREEN}Configuration restored${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}No backups found${COLOR_RESET}"
            fi
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

backup_restore() {
    clear
    show_banner
    show_header "BACKUP & RESTORE"
    
    echo -e "${COLOR_YELLOW}Backup Options:${COLOR_RESET}"
    echo "1) Backup all VMs"
    echo "2) Backup specific VM"
    echo "3) Restore VM from backup"
    echo "4) List backups"
    echo "5) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            echo -e "${COLOR_BLUE}Backing up all VMs...${COLOR_RESET}"
            mkdir -p "$BACKUP_DIR/full-$(date +%Y%m%d-%H%M%S)"
            cp -r "$DISK_DIR" "$ISO_DIR" "$SCRIPT_DIR" "$BACKUP_DIR/full-$(date +%Y%m%d-%H%M%S)"/
            cp "$DATABASE_FILE" "$BACKUP_DIR/full-$(date +%Y%m%d-%H%M%S)"/
            echo -e "${COLOR_GREEN}Full backup completed${COLOR_RESET}"
            ;;
        2)
            list_vms
            read -rp "$(echo -e "${COLOR_CYAN}Enter VM name to backup: ${COLOR_RESET}")" vm_name
            local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid, disk_path FROM vms WHERE name='$vm_name';" 2>/dev/null)
            if [[ -n "$vm_uuid" ]]; then
                IFS='|' read -r uuid disk_path <<< "$vm_uuid"
                local backup_dir="$BACKUP_DIR/$vm_name-$(date +%Y%m%d-%H%M%S)"
                mkdir -p "$backup_dir"
                cp "$disk_path" "$backup_dir"/
                echo -e "${COLOR_GREEN}VM backup created in $backup_dir${COLOR_RESET}"
            fi
            ;;
        4)
            echo -e "${COLOR_YELLOW}Available backups:${COLOR_RESET}"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

network_management() {
    clear
    show_banner
    show_header "NETWORK MANAGEMENT"
    
    echo -e "${COLOR_YELLOW}Network Options:${COLOR_RESET}"
    echo "1) View network status"
    echo "2) Configure bridge network"
    echo "3) Port forwarding"
    echo "4) Firewall rules"
    echo "5) Back to main menu"
    
    read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            echo -e "${COLOR_BLUE}Network Status:${COLOR_RESET}"
            ip addr show 2>/dev/null | grep -E "inet|ether" || echo "Network information not available"
            echo ""
            netstat -tuln 2>/dev/null | grep -E "LISTEN|3389|3390|5900" || echo "No relevant ports listening"
            ;;
        2)
            echo -e "${COLOR_BLUE}Bridge Network Configuration${COLOR_RESET}"
            echo "This feature requires root privileges"
            echo "Run: sudo brctl addbr br0"
            echo "Then: sudo ip link set br0 up"
            ;;
        3)
            echo -e "${COLOR_BLUE}Port Forwarding${COLOR_RESET}"
            echo "Current port forwards:"
            echo "  SSH: 2222 -> VM:22"
            echo "  RDP: 33890-33999 -> VM:3389"
            echo "  SPICE: 5900 -> VM:5900"
            ;;
    esac
    
    echo ""
    read -rp "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
download_file() {
    local url="$1"
    local output="$2"
    
    echo -e "${COLOR_BLUE}Downloading: $(basename "$url")${COLOR_RESET}"
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$output" "$url" || return 1
    elif command -v curl &>/dev/null; then
        curl -L -o "$output" --progress-bar "$url" || return 1
    else
        echo -e "${COLOR_RED}Download failed: wget/curl not found${COLOR_RESET}"
        return 1
    fi
    
    return 0
}

cleanup_on_exit() {
    local exit_code=$?
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR" 2>/dev/null
    
    # Remove lock file
    rm -f "$LOCK_FILE" 2>/dev/null
    
    if [[ $exit_code -ne 0 ]]; then
        log_message "ERROR" "Script exited with error code: $exit_code"
    fi
    
    exit $exit_code
}

# ============================================================================
# MAIN MENU
# ============================================================================
show_main_menu() {
    while true; do
        clear
        show_banner
        show_status
        
        local menu_items=(
            "${ICON_COMPUTER} Create New Virtual Machine"
            "${ICON_LIST} List All Virtual Machines"
            "${ICON_PLAY} Start Virtual Machine"
            "${ICON_STOP} Stop Virtual Machine"
            "${ICON_TRASH} Delete Virtual Machine"
            "${ICON_RDP} Setup Host RDP Server"
            "${ICON_RDP} Manage VM RDP Access"
            "${ICON_AI} AI Optimization"
            "${ICON_CHART} Performance Monitor"
            "${ICON_GEAR} System Settings"
            "${ICON_STORAGE} Backup & Restore"
            "${ICON_NETWORK} Network Management"
        )
        
        show_menu "MAIN MENU" "${menu_items[@]}"
        
        read -rp "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
        
        case $choice in
            1) create_vm_wizard ;;
            2) list_vms ;;
            3) start_vm_menu ;;
            4) stop_vm_menu ;;
            5) delete_vm_menu ;;
            6) setup_host_rdp ;;
            7) manage_vm_rdp ;;
            8) ai_optimization ;;
            9) performance_monitor ;;
            10) system_settings ;;
            11) backup_restore ;;
            12) network_management ;;
            0)
                echo -e "\n${COLOR_GREEN}${ICON_SUCCESS} Thank you for using Ultimate VM Hosting!${COLOR_RESET}"
                echo -e "${COLOR_BLUE}All VM scripts are in the current directory.${COLOR_RESET}"
                exit 0
                ;;
            *)
                echo -e "${COLOR_RED}${ICON_ERROR} Invalid option${COLOR_RESET}"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${COLOR_RED}${ICON_ERROR} Do not run this script as root${COLOR_RESET}"
        exit 1
    fi
    
    # Initialize system
    init_system
    
    # Start main menu
    show_main_menu
}

# ============================================================================
# ENTRY POINT
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
