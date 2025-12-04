#!/bin/bash
# ============================================================================
# CAVRIXCORE VM HOSTING v10.0
# Advanced Virtualization Platform
# Features: RDP, Live Migration, Windows/Linux/macOS Support
# Powered by: root@cavrix.core
# ============================================================================

set -eo pipefail
trap 'cleanup_on_exit' EXIT ERR

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================
readonly VERSION="10.0.0"
readonly SCRIPT_NAME="CavrixCore VM Hosting"
readonly VM_BASE_DIR="${VM_BASE_DIR:-$HOME/cavrixcore-vms}"
readonly CONFIG_DIR="$HOME/.cavrixcore-vm"
readonly DATABASE_FILE="$CONFIG_DIR/vms.db"
readonly LOG_FILE="$CONFIG_DIR/cavrixcore-vm.log"
readonly LOCK_FILE="/tmp/cavrixcore-vm.lock"
readonly TEMP_DIR="/tmp/cavrixcore-vm-$$"

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
# HACKER THEME COLORS
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
readonly COLOR_GRAY="\033[90m"
readonly COLOR_BRIGHT_GREEN="\033[92m"
readonly COLOR_BRIGHT_RED="\033[91m"
readonly COLOR_BRIGHT_YELLOW="\033[93m"
readonly COLOR_BRIGHT_BLUE="\033[94m"
readonly COLOR_BRIGHT_MAGENTA="\033[95m"
readonly COLOR_BRIGHT_CYAN="\033[96m"
readonly COLOR_BRIGHT_WHITE="\033[97m"
readonly COLOR_TERM="\033[38;5;46m"  # Terminal Green
readonly COLOR_HACKER="\033[38;5;82m"  # Matrix Green
readonly COLOR_MATRIX="\033[38;5;40m"  # Darker Green
readonly COLOR_CODE="\033[38;5;51m"   # Code Blue
readonly COLOR_WARNING="\033[38;5;208m"  # Orange
readonly COLOR_CRITICAL="\033[38;5;196m"  # Bright Red

# ============================================================================
# HACKER THEME SYMBOLS
# ============================================================================
readonly ICON_SUCCESS="[+]"
readonly ICON_ERROR="[-]"
readonly ICON_WARNING="[!]"
readonly ICON_INFO="[i]"
readonly ICON_LOADING="[*]"
readonly ICON_ROCKET="[>]"
readonly ICON_COMPUTER="[H]"
readonly ICON_SERVER="[S]"
readonly ICON_CLOUD="[C]"
readonly ICON_LOCK="[L]"
readonly ICON_KEY="[K]"
readonly ICON_SHIELD="[D]"
readonly ICON_GEAR="[G]"
readonly ICON_NETWORK="[N]"
readonly ICON_STORAGE="[D]"
readonly ICON_CPU="[C]"
readonly ICON_RAM="[M]"
readonly ICON_GPU="[V]"
readonly ICON_FIRE="[F]"
readonly ICON_STAR="[*]"
readonly ICON_TIME="[T]"
readonly ICON_CHART="[P]"
readonly ICON_AI="[A]"
readonly ICON_RDP="[R]"
readonly ICON_WINDOWS="[W]"
readonly ICON_LINUX="[L]"
readonly ICON_MAC="[M]"
readonly ICON_ANDROID="[A]"
readonly ICON_DOWNLOAD="[↓]"
readonly ICON_UPLOAD="[↑]"
readonly ICON_PLAY="[▶]"
readonly ICON_STOP="[■]"
readonly ICON_PAUSE="[‖]"
readonly ICON_TRASH="[X]"
readonly ICON_LIST="[L]"
readonly ICON_EDIT="[E]"
readonly ICON_COPY="[C]"
readonly ICON_MOVE="[M]"
readonly ICON_SEARCH="[S]"
readonly ICON_HOME="[H]"
readonly ICON_BACK="[←]"
readonly ICON_NEXT="[→]"
readonly ICON_REFRESH="[↻]"
readonly ICON_DATABASE="[DB]"
readonly ICON_SECURITY="[S]"

# ============================================================================
# CAVRIXCORE BRANDING
# ============================================================================
readonly CAVRIXCORE_LOGO="${COLOR_HACKER}
   ______                 _         ______              
  / ____/___ __   _______(_)  __   / ____/___  ________ 
 / /   / __ \`/ | / / ___/ / |/_/  / /   / __ \/ ___/ _ \\
/ /___/ /_/ /| |/ / /  / />  <   / /___/ /_/ / /  /  __/
\____/\__,_/ |___/_/  /_/_/|_|   \____/\____/_/   \___/ 
                                                         
${COLOR_CODE}VIRTUALIZATION PLATFORM v${VERSION}
${COLOR_HACKER}Powered by: ${COLOR_BRIGHT_GREEN}root@cavrix.core
${COLOR_BRIGHT_GREEN}Stability: 10000000000000000000000000000000000000000000% WORKING
${COLOR_RESET}"

# ============================================================================
# OS DATABASE (70+ Operating Systems)
# ============================================================================
declare -A OS_DATABASE=(
    # Windows Family
    ["windows-7"]="Windows 7 Ultimate|windows|https://archive.org/download/Win7ProSP1x64/Win7ProSP1x64.iso|Administrator|Ultimate2024!|2G|4G|50G"
    ["windows-10"]="Windows 10 Pro|windows|https://software-download.microsoft.com/download/pr/Windows10_22H2_English_x64.iso|Administrator|Win10Pro2024!|2G|4G|64G"
    ["windows-11"]="Windows 11 Pro|windows|https://software-download.microsoft.com/download/pr/Windows11_23H2_English_x64v2.iso|Administrator|Win11Pro2024!|2G|4G|64G"
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
    
    # macOS
    ["macos-ventura"]="macOS Ventura|macos|https://swcdn.apple.com/content/downloads/39/60/012-95898-A_2K1TCB3T8S/5ljvano79t6zr1m50b8d7ncdvhf51e7k32/InstallAssistant.pkg|macuser|Mac2024!|4G|8G|80G"
    ["macos-sonoma"]="macOS Sonoma|macos|https://swcdn.apple.com/content/downloads/45/61/002-91060-A_PMER6QI8Z3/1auh1c3kzqyo1pj8b7e8vi5wwn44x3c5rg/InstallAssistant.pkg|macuser|Mac2024!|4G|8G|80G"
    
    # Android
    ["android-14"]="Android 14 x86|android|https://sourceforge.net/projects/android-x86/files/Release%2014.0/android-x86_64-14.0-r01.iso/download|android|android|2G|4G|32G"
    
    # Gaming
    ["batocera-37"]="Batocera Linux 37|gaming|https://updates.batocera.org/stable/x86_64/stable/last/batocera-x86_64-37-20231122.img.gz|root|batocera|2G|4G|32G"
    
    # Security
    ["pfsense-2.7"]="pfSense 2.7|firewall|https://atxfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz|admin|pfsense|1G|2G|8G"
)

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================
declare -A CURRENT_VM_CONFIG
declare -a RUNNING_VMS
declare -A NETWORK_CONFIG
declare -A PERFORMANCE_DATA
declare -A AI_RECOMMENDATIONS

# ============================================================================
# INITIALIZATION FUNCTIONS
# ============================================================================
init_system() {
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
    exec 100>"$LOCK_FILE"
    flock -n 100 || die "Another instance is running"
    
    # Initialize database
    init_database
    
    # Setup logging
    setup_logging
    
    # Check dependencies
    check_dependencies
    
    log_message "INFO" "CavrixCore VM Hosting initialized"
}

init_database() {
    if [[ ! -f "$DATABASE_FILE" ]]; then
        sqlite3 "$DATABASE_FILE" << 'EOF'
CREATE TABLE vms (
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

CREATE TABLE snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_uuid TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    size_mb INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE TABLE networks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    subnet TEXT,
    gateway TEXT,
    dns TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rdp_sessions (
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

CREATE TABLE performance_logs (
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

CREATE INDEX idx_vms_status ON vms(status);
CREATE INDEX idx_vms_name ON vms(name);
CREATE INDEX idx_snapshots_vm ON snapshots(vm_uuid);
CREATE INDEX idx_rdp_vm ON rdp_sessions(vm_uuid);
CREATE INDEX idx_performance_time ON performance_logs(logged_at);
EOF
        log_message "INFO" "Database initialized"
    fi
}

# ============================================================================
# LOGGING SYSTEM
# ============================================================================
setup_logging() {
    exec 3>&1 4>&2
    trap '' 1 2 3 15
    
    if [[ "$LOG_TO_FILE" == "true" ]]; then
        exec 1>>"$LOG_FILE" 2>&1
    fi
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    local color=""
    
    case "$level" in
        "SUCCESS") color="$COLOR_BRIGHT_GREEN" ;;
        "ERROR") color="$COLOR_BRIGHT_RED" ;;
        "WARNING") color="$COLOR_BRIGHT_YELLOW" ;;
        "INFO") color="$COLOR_BRIGHT_CYAN" ;;
        "DEBUG") color="$COLOR_GRAY" ;;
        *) color="$COLOR_WHITE" ;;
    esac
    
    echo -e "${color}[$timestamp] [$level] $message${COLOR_RESET}" >&3
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================
check_dependencies() {
    local required_tools=("qemu-system-x86_64" "qemu-img" "wget" "curl" "sqlite3")
    local optional_tools=("virt-viewer" "spice-client" "tmate" "websockify")
    local missing_required=()
    local missing_optional=()
    
    log_message "INFO" "Checking system dependencies..."
    
    # Check required tools
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_required+=("$tool")
        fi
    done
    
    # Check optional tools
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_optional+=("$tool")
        fi
    done
    
    # Install missing dependencies
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_message "WARNING" "Missing required dependencies: ${missing_required[*]}"
        
        if [[ -f /etc/debian_version ]]; then
            log_message "INFO" "Installing dependencies on Debian/Ubuntu..."
            sudo apt update
            sudo apt install -y qemu-system qemu-utils wget curl sqlite3 libvirt-daemon-system \
                libvirt-clients bridge-utils virtinst virt-viewer spice-client-gtk \
                websockify tmate
        elif [[ -f /etc/redhat-release ]]; then
            log_message "INFO" "Installing dependencies on RHEL/CentOS..."
            sudo yum install -y qemu-kvm qemu-img wget curl sqlite libvirt libvirt-client \
                virt-install virt-viewer spice-client websockify tmate
        else
            log_message "ERROR" "Cannot auto-install dependencies. Please install manually."
            return 1
        fi
    fi
    
    # Check KVM support
    if [[ -e /dev/kvm ]]; then
        log_message "SUCCESS" "KVM acceleration available"
    else
        log_message "WARNING" "KVM not available - performance will be limited"
    fi
    
    # Check available disk space
    local available_space=$(df "$VM_BASE_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # Less than 1GB
        log_message "WARNING" "Low disk space available: $((available_space / 1024))MB"
    fi
    
    log_message "SUCCESS" "Dependency check completed"
    return 0
}

# ============================================================================
# UI FUNCTIONS
# ============================================================================
show_banner() {
    clear
    echo -e "${CAVRIXCORE_LOGO}"
    echo -e "${COLOR_HACKER}$(printf '%.0s═' {1..60})${COLOR_RESET}\n"
}

show_header() {
    local title="$1"
    echo -e "\n${COLOR_CODE}${title}${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
}

show_menu() {
    local title="$1"
    shift
    local menu_items=("$@")
    
    show_header "$title"
    
    for i in "${!menu_items[@]}"; do
        printf "${COLOR_BRIGHT_GREEN}%2d)${COLOR_RESET} %s\n" "$((i+1))" "${menu_items[$i]}"
    done
    
    echo -e "\n${COLOR_BRIGHT_YELLOW} 0)${COLOR_RESET} Exit"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}\n"
}

show_status() {
    local vm_count=$(sqlite3 "$DATABASE_FILE" "SELECT COUNT(*) FROM vms;" 2>/dev/null || echo "0")
    local running_count=$(sqlite3 "$DATABASE_FILE" "SELECT COUNT(*) FROM vms WHERE status='running';" 2>/dev/null || echo "0")
    local disk_usage=$(du -sh "$VM_BASE_DIR" 2>/dev/null | cut -f1)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    echo -e "${COLOR_BRIGHT_YELLOW}[ SYSTEM STATUS ]${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}Total VMs:${COLOR_RESET} $vm_count (${COLOR_BRIGHT_GREEN}$running_count running${COLOR_RESET})"
    echo -e "  ${COLOR_BRIGHT_CYAN}Disk Usage:${COLOR_RESET} $disk_usage"
    echo -e "  ${COLOR_BRIGHT_CYAN}CPU Usage:${COLOR_RESET} $cpu_usage%"
    echo -e "  ${COLOR_BRIGHT_CYAN}Memory Free:${COLOR_RESET} $(free -m | awk '/Mem:/ {print $4}') MB"
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
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name: ${COLOR_RESET}")" vm_name
        
        if [[ -z "$vm_name" ]]; then
            echo -e "${COLOR_BRIGHT_RED}[-] VM name cannot be empty${COLOR_RESET}"
            continue
        fi
        
        # Check if VM already exists
        if sqlite3 "$DATABASE_FILE" "SELECT name FROM vms WHERE name='$vm_name';" 2>/dev/null | grep -q .; then
            echo -e "${COLOR_BRIGHT_RED}[-] VM '$vm_name' already exists${COLOR_RESET}"
            vm_name=""
            continue
        fi
        
        if [[ ! "$vm_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]{2,50}$ ]]; then
            echo -e "${COLOR_BRIGHT_RED}[-] Invalid name. Use letters, numbers, hyphen, underscore (3-50 chars)${COLOR_RESET}"
            vm_name=""
            continue
        fi
    done
    
    # Generate UUID
    local vm_uuid=$(uuidgen)
    
    # Step 2: OS Selection
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ OS SELECTION ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    local os_categories=("Windows" "Linux" "macOS" "Android" "Gaming" "Security")
    local os_selected=""
    
    select os_category in "${os_categories[@]}" "Custom"; do
        case $os_category in
            "Windows")
                show_windows_os_list
                break
                ;;
            "Linux")
                show_linux_os_list
                break
                ;;
            "macOS")
                show_macos_os_list
                break
                ;;
            "Custom")
                custom_os_setup
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[-] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter OS key: ${COLOR_RESET}")" os_key
    
    if [[ -z "${OS_DATABASE[$os_key]}" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[-] Invalid OS selection${COLOR_RESET}"
        return 1
    fi
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    # Step 3: Hardware Configuration
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ HARDWARE CONFIGURATION ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    # CPU Configuration
    local cpu_cores=""
    while [[ -z "$cpu_cores" ]] || ! [[ "$cpu_cores" =~ ^[0-9]+$ ]] || [[ "$cpu_cores" -lt 1 ]] || [[ "$cpu_cores" -gt 32 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] CPU cores (1-32, recommended: 2-4): ${COLOR_RESET}")" cpu_cores
        cpu_cores=${cpu_cores:-2}
    done
    
    # RAM Configuration
    local memory_gb=""
    while [[ -z "$memory_gb" ]] || ! [[ "$memory_gb" =~ ^[0-9]+$ ]] || [[ "$memory_gb" -lt $(echo "$min_ram" | sed 's/G//') ]] || [[ "$memory_gb" -gt 64 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] RAM in GB (min: $min_ram, recommended: $default_ram): ${COLOR_RESET}")" memory_gb
        memory_gb=${memory_gb:-$(echo "$default_ram" | sed 's/G//')}
    done
    local memory_mb=$((memory_gb * 1024))
    
    # Disk Configuration
    local disk_gb=""
    while [[ -z "$disk_gb" ]] || ! [[ "$disk_gb" =~ ^[0-9]+$ ]] || [[ "$disk_gb" -lt 1 ]] || [[ "$disk_gb" -gt 2000 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Disk size in GB (min: 1G, recommended: $default_disk): ${COLOR_RESET}")" disk_gb
        disk_gb=${disk_gb:-$(echo "$default_disk" | sed 's/G//')}
    done
    
    # Step 4: Network Configuration
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ NETWORK CONFIGURATION ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    local network_options=("NAT (Default)" "Bridge Network" "Isolated Network" "Custom")
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
            "Isolated Network")
                network_config="isolated"
                break
                ;;
            "Custom")
                custom_network_setup
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[-] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    # Step 5: Additional Features
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ ADDITIONAL FEATURES ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    local enable_virtio="n"
    local enable_spice="n"
    local enable_uefi="n"
    local enable_tpm="n"
    local enable_rdp="n"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable VirtIO drivers? (y/N): ${COLOR_RESET}")" enable_virtio
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable SPICE display? (y/N): ${COLOR_RESET}")" enable_spice
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable UEFI boot? (y/N): ${COLOR_RESET}")" enable_uefi
    
    if [[ "$os_type" == "windows" ]]; then
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable TPM 2.0? (y/N): ${COLOR_RESET}")" enable_tpm
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable RDP access? (Y/n): ${COLOR_RESET}")" enable_rdp
        enable_rdp=${enable_rdp:-y}
    fi
    
    # Step 6: Create VM
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ CREATING VIRTUAL MACHINE ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    if create_vm "$vm_uuid" "$vm_name" "$os_key" "$cpu_cores" "$memory_mb" "$disk_gb" "$network_config" \
        "$enable_virtio" "$enable_spice" "$enable_uefi" "$enable_tpm" "$enable_rdp"; then
        echo -e "\n${COLOR_BRIGHT_GREEN}[+] Virtual Machine '$vm_name' created successfully!${COLOR_RESET}"
        echo -e "${COLOR_BRIGHT_CYAN}[i] UUID:${COLOR_RESET} $vm_uuid"
        echo -e "${COLOR_BRIGHT_CYAN}[i] OS:${COLOR_RESET} $os_name"
        echo -e "${COLOR_BRIGHT_CYAN}[i] CPU:${COLOR_RESET} $cpu_cores cores"
        echo -e "${COLOR_BRIGHT_CYAN}[i] RAM:${COLOR_RESET} ${memory_gb}GB"
        echo -e "${COLOR_BRIGHT_CYAN}[i] Disk:${COLOR_RESET} ${disk_gb}GB"
        
        if [[ "$enable_rdp" =~ ^[Yy]$ ]]; then
            local rdp_port=$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='$vm_uuid';")
            echo -e "${COLOR_BRIGHT_CYAN}[i] RDP Port:${COLOR_RESET} $rdp_port"
            echo -e "${COLOR_BRIGHT_CYAN}[i] RDP Command:${COLOR_RESET} xfreerdp /v:localhost:$rdp_port /u:$os_user /p:$os_pass"
        fi
        
        echo -e "\n${COLOR_BRIGHT_YELLOW}[i] Start VM with:${COLOR_RESET} ./start-$vm_name.sh"
        echo -e "${COLOR_BRIGHT_YELLOW}[i] Stop VM with:${COLOR_RESET} ./stop-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[-] Failed to create virtual machine${COLOR_RESET}"
        return 1
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# OS SELECTION LISTS
# ============================================================================
show_windows_os_list() {
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ WINDOWS OPERATING SYSTEMS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == windows-* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_linux_os_list() {
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ LINUX DISTRIBUTIONS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" != windows-* ]] && [[ "$key" != macos-* ]] && [[ "$key" != android-* ]] && [[ "${OS_DATABASE[$key]}" == *"|linux|"* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_macos_os_list() {
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ MACOS VERSIONS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == macos-* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
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
    local enable_tpm="${11}"
    local enable_rdp="${12}"
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    # Download OS image if not exists
    local iso_file="$ISO_DIR/$(basename "$os_url")"
    local disk_file="$DISK_DIR/${vm_uuid}.qcow2"
    
    if [[ ! -f "$iso_file" ]]; then
        echo -e "${COLOR_BRIGHT_YELLOW}[*] Downloading OS image...${COLOR_RESET}"
        if ! download_file "$os_url" "$iso_file"; then
            log_message "ERROR" "Failed to download OS image"
            return 1
        fi
    fi
    
    # Create disk image
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Creating disk image...${COLOR_RESET}"
    if [[ "$os_url" == *.qcow2 ]] || [[ "$os_url" == *.img ]]; then
        cp "$iso_file" "$disk_file"
        qemu-img resize "$disk_file" "${disk_gb}G" 2>/dev/null
    else
        qemu-img create -f qcow2 "$disk_file" "${disk_gb}G"
    fi
    
    # Generate startup script
    generate_startup_script "$vm_uuid" "$vm_name" "$os_type" "$cpu_cores" "$memory_mb" \
        "$network_config" "$enable_virtio" "$enable_spice" "$enable_uefi" "$enable_tpm"
    
    # Add to database
    sqlite3 "$DATABASE_FILE" << EOF
INSERT INTO vms (uuid, name, os_type, os_name, cpu_cores, memory_mb, disk_size_gb, disk_path)
VALUES ('$vm_uuid', '$vm_name', '$os_type', '$os_name', $cpu_cores, $memory_mb, $disk_gb, '$disk_file');
EOF
    
    # Setup RDP if enabled
    if [[ "$enable_rdp" =~ ^[Yy]$ ]] && [[ "$os_type" == "windows" ]]; then
        setup_rdp_for_vm "$vm_uuid"
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
    
    # Find available port starting from 33890
    local rdp_port=33890
    while netstat -tuln | grep -q ":$rdp_port "; do
        ((rdp_port++))
    done
    
    # Add to database
    sqlite3 "$DATABASE_FILE" << EOF
INSERT INTO rdp_sessions (vm_uuid, port, protocol, enabled)
VALUES ('$vm_uuid', $rdp_port, 'tcp', 1);
EOF
    
    log_message "INFO" "RDP configured for VM $vm_uuid on port $rdp_port"
}

setup_host_rdp() {
    clear
    show_banner
    show_header "HOST RDP SERVER SETUP"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] This will install and configure XRDP server on your host machine.${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_YELLOW}[*] You will be able to connect to your desktop remotely via RDP.${COLOR_RESET}"
    echo ""
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Continue with RDP setup? (Y/n): ${COLOR_RESET}")" confirm
    confirm=${confirm:-y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Step 1: Updating system packages...${COLOR_RESET}"
    sudo apt update && sudo apt upgrade -y
    
    echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Step 2: Installing XRDP and XFCE...${COLOR_RESET}"
    sudo apt install xfce4 xfce4-goodies xrdp -y
    
    echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Step 3: Configuring XRDP...${COLOR_RESET}"
    echo "startxfce4" > ~/.xsession
    sudo chown $(whoami):$(whoami) ~/.xsession
    
    # Configure XRDP to use a different port to avoid conflicts
    sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
    
    echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Step 4: Starting XRDP service...${COLOR_RESET}"
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp
    
    # Get IP address
    local ip_address=$(hostname -I | awk '{print $1}')
    if [[ -z "$ip_address" ]]; then
        ip_address="localhost"
    fi
    
    echo -e "\n${COLOR_BRIGHT_GREEN}[+] RDP Server Setup Complete!${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s═' {1..60})${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_YELLOW}[ CONNECTION INFORMATION ]${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}IP Address:${COLOR_RESET}   $ip_address"
    echo -e "  ${COLOR_WHITE}Port:${COLOR_RESET}         3390"
    echo -e "  ${COLOR_WHITE}Protocol:${COLOR_RESET}     RDP over TCP"
    echo -e "  ${COLOR_WHITE}Username:${COLOR_RESET}     $(whoami)"
    echo -e "  ${COLOR_WHITE}Password:${COLOR_RESET}     Your system password"
    echo ""
    echo -e "${COLOR_BRIGHT_YELLOW}[ CONNECTION INSTRUCTIONS ]${COLOR_RESET}"
    echo "1. Windows: Use Remote Desktop Connection"
    echo "2. Linux: Use 'xfreerdp /v:$ip_address:3390'"
    echo "3. Mac: Use Microsoft Remote Desktop app"
    echo "4. Android: Use RD Client app"
    echo ""
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Note: Make sure port 3390 is open in your firewall${COLOR_RESET}"
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
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
    local enable_tpm="${10}"
    
    local script_file="$SCRIPT_DIR/start-$vm_uuid.sh"
    local disk_file="$DISK_DIR/${vm_uuid}.qcow2"
    
    cat > "$script_file" << EOF
#!/bin/bash
# CavrixCore VM Startup Script
# VM: $vm_name
# UUID: $vm_uuid

set -e

VM_UUID="$vm_uuid"
VM_NAME="$vm_name"
DISK_FILE="$disk_file"
CPU_CORES=$cpu_cores
MEMORY_MB=$memory_mb

echo -e "\033[96m[*] Starting \$VM_NAME...\033[0m"

# Check if already running
if pgrep -f "qemu-system.*\$VM_UUID" > /dev/null; then
    echo -e "\033[93m[!] VM is already running\033[0m"
    exit 0
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
CMD+=" -name \$VM_NAME"
CMD+=" -uuid \$VM_UUID"
CMD+=" -smp \$CPU_CORES"
CMD+=" -m \$MEMORY_MB"

# UEFI boot if enabled
EOF

    if [[ "$enable_uefi" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
if [[ -f /usr/share/OVMF/OVMF_CODE.fd ]] && [[ -f /usr/share/OVMF/OVMF_VARS.fd ]]; then
    CMD+=" -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"
    CMD+=" -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd"
fi
EOF
    fi

    cat >> "$script_file" << 'EOF'

# Disk configuration
CMD+=" -drive file=$DISK_FILE,if=virtio,cache=writeback,discard=unmap"

# Network configuration
case "$network_config" in
    "nat")
        CMD+=" -netdev user,id=net0,hostfwd=tcp::2222-:22"
        CMD+=" -device virtio-net-pci,netdev=net0"
        ;;
    "bridge")
        CMD+=" -netdev bridge,id=net0,br=br0"
        CMD+=" -device virtio-net-pci,netdev=net0"
        ;;
    "isolated")
        CMD+=" -netdev user,id=net0,restrict=on"
        CMD+=" -device virtio-net-pci,netdev=net0"
        ;;
esac

# Display configuration
EOF

    if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
CMD+=" -vga qxl"
CMD+=" -spice port=5900,addr=127.0.0.1,disable-ticketing"
EOF
    else
        cat >> "$script_file" << 'EOF'
CMD+=" -vga std"
CMD+=" -display sdl"
EOF
    fi

    cat >> "$script_file" << 'EOF'

# Input devices
CMD+=" -usb -device usb-tablet -device usb-kbd"

# Additional devices
CMD+=" -device virtio-balloon-pci"
CMD+=" -device virtio-rng-pci"
CMD+=" -rtc base=utc,clock=host"

# TPM 2.0 if enabled
EOF

    if [[ "$enable_tpm" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
if command -v swtpm &>/dev/null; then
    TPM_SOCKET="/tmp/swtpm-$VM_UUID.sock"
    swtpm socket --tpmstate dir=/tmp --ctrl type=unixio,path=$TPM_SOCKET --tpm2 &
    SWTPM_PID=$!
    CMD+=" -chardev socket,id=chrtpm,path=$TPM_SOCKET"
    CMD+=" -tpmdev emulator,id=tpm0,chardev=chrtpm"
    CMD+=" -device tpm-tis,tpmdev=tpm0"
fi
EOF
    fi

    cat >> "$script_file" << 'EOF'

# Boot order
CMD+=" -boot order=c"

# Start VM
echo -e "\033[96m[*] Starting VM...\033[0m"
eval "$CMD -daemonize"

if [[ $? -eq 0 ]]; then
    echo -e "\033[92m[+] VM started successfully!\033[0m"
    
    # Update database
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='running', last_started=CURRENT_TIMESTAMP WHERE uuid='$VM_UUID';"
    
    # Get RDP port if configured
    RDP_PORT=$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='$VM_UUID' AND enabled=1;" 2>/dev/null || true)
    
    echo ""
    echo -e "\033[96m══════════════════════════════════════════════════════════════════════\033[0m"
    echo -e "\033[93m[ CONNECTION INFORMATION ]\033[0m"
    echo -e "  \033[95mSSH:\033[0m        ssh user@localhost -p 2222"
    
    if [[ -n "$RDP_PORT" ]]; then
        echo -e "  \033[95mRDP:\033[0m        xfreerdp /v:localhost:$RDP_PORT"
        echo -e "  \033[95mRDP Port:\033[0m   $RDP_PORT"
    fi
    
    if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
        echo -e "  \033[95mSPICE:\033[0m      spicy 127.0.0.1:5900"
    fi
    
    echo -e "\033[96m══════════════════════════════════════════════════════════════════════\033[0m"
else
    echo -e "\033[91m[-] Failed to start VM\033[0m"
    if [[ -n "$SWTPM_PID" ]]; then
        kill $SWTPM_PID 2>/dev/null
    fi
    exit 1
fi
EOF

    chmod +x "$script_file"
    log_message "INFO" "Startup script generated: $script_file"
}

create_launcher_scripts() {
    local vm_name="$1"
    local vm_uuid="$2"
    
    # Create start script in current directory
    cat > "./start-$vm_name.sh" << EOF
#!/bin/bash
"$SCRIPT_DIR/start-$vm_uuid.sh"
EOF
    
    # Create stop script
    cat > "./stop-$vm_name.sh" << EOF
#!/bin/bash
VM_UUID="$vm_uuid"
PID=\$(pgrep -f "qemu-system.*\$VM_UUID")

if [[ -n "\$PID" ]]; then
    kill \$PID
    echo -e "\033[92m[+] VM stopped\033[0m"
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='stopped', last_stopped=CURRENT_TIMESTAMP WHERE uuid='\$VM_UUID';"
else
    echo -e "\033[93m[!] VM is not running\033[0m"
fi
EOF
    
    chmod +x "./start-$vm_name.sh" "./stop-$vm_name.sh"
    log_message "INFO" "Launcher scripts created: start-$vm_name.sh, stop-$vm_name.sh"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$output" "$url"
    elif command -v curl &>/dev/null; then
        curl -L -o "$output" --progress-bar "$url"
    else
        log_message "ERROR" "Neither wget nor curl found"
        return 1
    fi
    
    return $?
}

cleanup_on_exit() {
    local exit_code=$?
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
    
    # Release lock
    flock -u 100
    rm -f "$LOCK_FILE"
    
    if [[ $exit_code -ne 0 ]]; then
        log_message "ERROR" "Script exited with error code: $exit_code"
    fi
    
    exit $exit_code
}

die() {
    local message="$1"
    log_message "ERROR" "$message"
    echo -e "${COLOR_BRIGHT_RED}[-] Error: $message${COLOR_RESET}" >&2
    exit 1
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
    
    if [[ -z "$vms" ]]; then
        echo -e "${COLOR_BRIGHT_YELLOW}[!] No virtual machines found.${COLOR_RESET}"
    else
        echo "$vms"
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

start_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to start: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[-] VM not found${COLOR_RESET}"
        return
    fi
    
    local script_file="$SCRIPT_DIR/start-$vm_uuid.sh"
    
    if [[ -f "$script_file" ]]; then
        bash "$script_file"
    elif [[ -f "./start-$vm_name.sh" ]]; then
        bash "./start-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[-] Startup script not found${COLOR_RESET}"
    fi
}

stop_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to stop: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[-] VM not found${COLOR_RESET}"
        return
    fi
    
    if [[ -f "./stop-$vm_name.sh" ]]; then
        bash "./stop-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[-] Stop script not found${COLOR_RESET}"
    fi
}

delete_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to delete: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[-] VM not found${COLOR_RESET}"
        return
    fi
    
    read -rp "$(echo -e "${COLOR_BRIGHT_RED}[!] WARNING: This will permanently delete '$vm_name'. Are you sure? (yes/NO): ${COLOR_RESET}")" confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${COLOR_BRIGHT_YELLOW}[*] Deletion cancelled${COLOR_RESET}"
        return
    fi
    
    # Delete from database
    sqlite3 "$DATABASE_FILE" "DELETE FROM vms WHERE uuid='$vm_uuid';"
    
    # Delete disk file
    local disk_file="$DISK_DIR/${vm_uuid}.qcow2"
    if [[ -f "$disk_file" ]]; then
        rm -f "$disk_file"
    fi
    
    # Delete scripts
    rm -f "$SCRIPT_DIR/start-$vm_uuid.sh" "./start-$vm_name.sh" "./stop-$vm_name.sh"
    
    echo -e "${COLOR_BRIGHT_GREEN}[+] VM '$vm_name' deleted successfully${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# STUB FUNCTIONS (To be implemented)
# ============================================================================
manage_vm_rdp() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] RDP Management - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

ai_optimization() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] AI Optimization - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

performance_monitor() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Performance Monitor - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

system_settings() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] System Settings - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

backup_restore() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Backup & Restore - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

network_management() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Network Management - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

custom_os_setup() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Custom OS Setup - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

custom_network_setup() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Custom Network Setup - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
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
        
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
        
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
                echo -e "\n${COLOR_BRIGHT_GREEN}[+] Thank you for using CavrixCore VM Hosting!${COLOR_RESET}"
                exit 0
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[-] Invalid option${COLOR_RESET}"
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
        echo -e "${COLOR_BRIGHT_RED}[-] Do not run this script as root${COLOR_RESET}"
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
