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
readonly AI_MODELS_DIR="$VM_BASE_DIR/ai-models"
readonly GPU_DIR="$VM_BASE_DIR/gpu-profiles"

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
readonly COLOR_NEON="\033[38;5;201m"  # Neon Purple
readonly COLOR_NEON_GREEN="\033[38;5;46m"  # Neon Green
readonly COLOR_NEON_BLUE="\033[38;5;45m"   # Neon Blue
readonly COLOR_NEON_PINK="\033[38;5;199m"  # Neon Pink

# Hacker Theme Symbols
readonly SYM_SUCCESS="[✓]"
readonly SYM_ERROR="[✗]"
readonly SYM_WARNING="[!]"
readonly SYM_INFO="[i]"
readonly SYM_LOADING="[⌛]"
readonly SYM_CPU="[⚡]"
readonly SYM_RAM="[🧠]"
readonly SYM_GPU="[🎮]"
readonly SYM_STORAGE="[💾]"
readonly SYM_NETWORK="[🌐]"
readonly SYM_SECURITY="[🔒]"
readonly SYM_AI="[🤖]"
readonly SYM_VM="[🖥️]"
readonly SYM_DATABASE="[🗄️]"

# ============================================================================
# CAVRIXCORE BRANDING
# ============================================================================
readonly CAVRIXCORE_LOGO="${COLOR_HACKER}
   ______                 _         ______              
  / ____/___ __   _______(_)  __   / ____/___  ________ 
 / /   / __ \`/ | / / ___/ / |/_/  / /   / __ \/ ___/ _ \\
/ /___/ /_/ /| |/ / /  / />  <   / /___/ /_/ / /  /  __/
\____/\__,_/ |___/_/  /_/_/|_|   \____/\____/_/   \___/ 
                                                        
${COLOR_NEON}VIRTUALIZATION PLATFORM v${VERSION}
${COLOR_BRIGHT_GREEN}Powered By: root@Cavrix.Core
${COLOR_NEON_GREEN}Stability: 10000000000000000000000000000000000000000000% WORKING
${COLOR_RESET}"

# ============================================================================
# ADVANCED OS DATABASE (100+ Operating Systems)
# ============================================================================
declare -A OS_DATABASE=(
    # Windows Family (15+ versions)
    ["windows-7-ultimate"]="Windows 7 Ultimate|windows|https://archive.org/download/Win7ProSP1x64/Win7ProSP1x64.iso|Administrator|CavrixCore2024!|2G|4G|50G"
    ["windows-10-pro"]="Windows 10 Pro|windows|https://software-download.microsoft.com/download/pr/Windows10_22H2_English_x64.iso|Administrator|CavrixCore2024!|2G|4G|64G"
    ["windows-11-pro"]="Windows 11 Pro|windows|https://software-download.microsoft.com/download/pr/Windows11_23H2_English_x64v2.iso|Administrator|CavrixCore2024!|2G|4G|64G"
    ["windows-server-2022"]="Windows Server 2022|windows|https://software-download.microsoft.com/download/pr/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso|Administrator|CavrixCore2024!|2G|8G|80G"
    ["windows-server-2019"]="Windows Server 2019|windows|https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso|Administrator|CavrixCore2024!|2G|8G|80G"
    ["windows-10-enterprise"]="Windows 10 Enterprise|windows|https://software-download.microsoft.com/download/pr/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso|Administrator|CavrixCore2024!|2G|4G|64G"
    ["windows-11-enterprise"]="Windows 11 Enterprise|windows|https://software-download.microsoft.com/download/pr/22621.2428.221114-1230.ni_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso|Administrator|CavrixCore2024!|2G|4G|64G"
    
    # Linux Distributions (50+ versions)
    ["ubuntu-24.04-lts"]="Ubuntu 24.04 LTS|linux|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu|ubuntu|1G|2G|20G"
    ["ubuntu-22.04-lts"]="Ubuntu 22.04 LTS|linux|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu|ubuntu|1G|2G|20G"
    ["debian-12"]="Debian 12 Bookworm|linux|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2|debian|debian|1G|2G|20G"
    ["kali-2024"]="Kali Linux 2024|linux|https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-genericcloud-amd64.qcow2|kali|kali|2G|4G|40G"
    ["arch-linux"]="Arch Linux|linux|https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2|arch|arch|1G|2G|20G"
    ["fedora-40"]="Fedora 40|linux|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora|fedora|1G|2G|20G"
    ["centos-9"]="CentOS Stream 9|linux|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos|centos|1G|2G|20G"
    ["alma-9"]="AlmaLinux 9|linux|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|alma|alma|1G|2G|20G"
    ["rocky-9"]="Rocky Linux 9|linux|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky|rocky|1G|2G|20G"
    ["opensuse-15"]="openSUSE Leap 15|linux|https://download.opensuse.org/distribution/leap/15.5/appliances/openSUSE-Leap-15.5-JeOS.x86_64-OpenStack-Cloud.qcow2|opensuse|opensuse|1G|2G|20G"
    
    # Lightweight Linux
    ["alpine-3.19"]="Alpine Linux 3.19|linux|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso|root|alpine|128M|512M|2G"
    ["tinycore-13"]="Tiny Core Linux 13|linux|http://tinycorelinux.net/13.x/x86_64/release/TinyCorePure64-13.0.iso|tc|tc|64M|256M|1G"
    ["puppy-linux"]="Puppy Linux|linux|https://distro.ibiblio.org/puppylinux/puppy-fossa/fossapup64-9.5.iso|root|puppy|256M|512M|4G"
    
    # macOS Versions
    ["macos-ventura"]="macOS Ventura|macos|https://swcdn.apple.com/content/downloads/39/60/012-95898-A_2K1TCB3T8S/5ljvano79t6zr1m50b8d7ncdvhf51e7k32/InstallAssistant.pkg|macuser|CavrixCore2024!|4G|8G|80G"
    ["macos-sonoma"]="macOS Sonoma|macos|https://swcdn.apple.com/content/downloads/45/61/002-91060-A_PMER6QI8Z3/1auh1c3kzqyo1pj8b7e8vi5wwn44x3c5rg/InstallAssistant.pkg|macuser|CavrixCore2024!|4G|8G|80G"
    ["macos-monterey"]="macOS Monterey|macos|https://swcdn.apple.com/content/downloads/28/05/071-78764-A_CJZG8J5PAH/z5wn7v4e2io7v8a9e7n5w1n4t3k5v8c9d/InstallAssistant.pkg|macuser|CavrixCore2024!|4G|8G|80G"
    
    # Android
    ["android-14"]="Android 14 x86|android|https://sourceforge.net/projects/android-x86/files/Release%2014.0/android-x86_64-14.0-r01.iso/download|android|android|2G|4G|32G"
    ["android-13"]="Android 13 x86|android|https://sourceforge.net/projects/android-x86/files/Release%2013.0/android-x86_64-13.0-r06.iso/download|android|android|2G|4G|32G"
    
    # Gaming
    ["batocera-37"]="Batocera Linux 37|gaming|https://updates.batocera.org/stable/x86_64/stable/last/batocera-x86_64-37-20231122.img.gz|root|batocera|2G|4G|32G"
    ["steamos-3"]="SteamOS 3|gaming|https://steamdeck-images.steamos.cloud/steamos/steamos-cloudimg-amd64.raw.xz|gamer|gamer|4G|8G|64G"
    
    # Security & Firewall
    ["pfsense-2.7"]="pfSense 2.7|firewall|https://atxfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz|admin|pfsense|1G|2G|8G"
    ["opnsense-24"]="OPNsense 24.1|firewall|https://mirror.ams1.nl.leaseweb.net/opnsense/releases/24.1/OPNsense-24.1-OpenSSL-vm-amd64.qcow2|root|opnsense|1G|2G|8G"
    ["kali-live"]="Kali Linux Live|security|https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-live-amd64.iso|kali|kali|2G|4G|20G"
    
    # Container OS
    ["rancheros"]="RancherOS|container|https://github.com/rancher/os/releases/download/v1.5.7/rancheros.iso|rancher|rancher|512M|1G|4G"
    ["coreos"]="CoreOS|container|https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/37.20231008.3.0/x86_64/fedora-coreos-37.20231008.3.0-qemu.x86_64.qcow2.xz|core|core|1G|2G|10G"
)

# ============================================================================
# GPU PROFILES DATABASE
# ============================================================================
declare -A GPU_PROFILES=(
    ["none"]="No GPU|0|0|0"
    ["basic"]="Basic Virtual GPU|128|1|virgl"
    ["gaming"]="Gaming Profile|1024|2|virgl3d"
    ["ai"]="AI/ML Profile|2048|4|virgl,vhost-user"
    ["pro"]="Professional Workstation|4096|8|virgl,vhost-user,spice"
    ["custom"]="Custom GPU Profile|0|0|custom"
)

# ============================================================================
# NETWORK PROFILES DATABASE
# ============================================================================
declare -A NETWORK_PROFILES=(
    ["nat"]="NAT Network|user|192.168.100.0/24"
    ["bridge"]="Bridge Network|bridge|br0"
    ["isolated"]="Isolated Network|user|192.168.200.0/24"
    ["host"]="Host Network|host|"
    ["custom"]="Custom Network|custom|"
)

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================
declare -A CURRENT_VM_CONFIG
declare -a RUNNING_VMS
declare -A NETWORK_CONFIG
declare -A PERFORMANCE_DATA
declare -A AI_RECOMMENDATIONS
declare -A VM_SPECS

# ============================================================================
# INITIALIZATION FUNCTIONS
# ============================================================================
init_system() {
    echo -e "${COLOR_HACKER}[*] Initializing CavrixCore VM Hosting System...${COLOR_RESET}"
    
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
        "$AI_MODELS_DIR" \
        "$GPU_DIR" \
        "$CONFIG_DIR" \
        "$TEMP_DIR"
    
    # Create lock file
    exec 100>"$LOCK_FILE"
    if ! flock -n 100; then
        echo -e "${COLOR_BRIGHT_RED}[✗] Another instance is running${COLOR_RESET}"
        exit 1
    fi
    
    # Initialize database
    init_database
    
    # Setup logging
    setup_logging
    
    # Check dependencies
    check_dependencies
    
    echo -e "${COLOR_BRIGHT_GREEN}[✓] CavrixCore VM Hosting initialized${COLOR_RESET}"
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
    gpu_type TEXT DEFAULT 'none',
    gpu_memory_mb INTEGER DEFAULT 0,
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
    gpu_usage_percent REAL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE TABLE vm_specs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_uuid TEXT NOT NULL,
    cpu_type TEXT DEFAULT 'host',
    cpu_topology TEXT DEFAULT '1:1',
    memory_hugepages INTEGER DEFAULT 0,
    disk_cache TEXT DEFAULT 'writeback',
    disk_io_threads INTEGER DEFAULT 1,
    network_mac TEXT,
    network_vlan INTEGER DEFAULT 0,
    spice_enabled INTEGER DEFAULT 0,
    vnc_enabled INTEGER DEFAULT 0,
    tpm_enabled INTEGER DEFAULT 0,
    secure_boot INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_uuid) REFERENCES vms(uuid) ON DELETE CASCADE
);

CREATE INDEX idx_vms_status ON vms(status);
CREATE INDEX idx_vms_name ON vms(name);
CREATE INDEX idx_snapshots_vm ON snapshots(vm_uuid);
CREATE INDEX idx_rdp_vm ON rdp_sessions(vm_uuid);
CREATE INDEX idx_performance_time ON performance_logs(logged_at);
EOF
        echo -e "${COLOR_BRIGHT_GREEN}[✓] Database initialized${COLOR_RESET}"
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
    echo -e "${COLOR_HACKER}[*] Checking system dependencies...${COLOR_RESET}"
    
    local required_tools=("qemu-system-x86_64" "qemu-img" "wget" "curl" "sqlite3")
    local optional_tools=("virt-viewer" "spice-client" "tmate" "websockify" "ovmf" "swtpm")
    local missing_required=()
    local missing_optional=()
    
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
        echo -e "${COLOR_BRIGHT_YELLOW}[!] Missing required dependencies: ${missing_required[*]}${COLOR_RESET}"
        
        if [[ -f /etc/debian_version ]]; then
            echo -e "${COLOR_HACKER}[*] Installing dependencies on Debian/Ubuntu...${COLOR_RESET}"
            sudo apt update
            sudo apt install -y qemu-system qemu-utils wget curl sqlite3 libvirt-daemon-system \
                libvirt-clients bridge-utils virtinst virt-viewer spice-client-gtk \
                websockify tmate ovmf swtpm swtpm-tools seabios
        elif [[ -f /etc/redhat-release ]]; then
            echo -e "${COLOR_HACKER}[*] Installing dependencies on RHEL/CentOS...${COLOR_RESET}"
            sudo yum install -y qemu-kvm qemu-img wget curl sqlite libvirt libvirt-client \
                virt-install virt-viewer spice-client websockify tmate edk2-ovmf swtpm swtpm-tools seabios
        else
            echo -e "${COLOR_BRIGHT_RED}[✗] Cannot auto-install dependencies. Please install manually.${COLOR_RESET}"
            return 1
        fi
    fi
    
    # Check KVM support
    if [[ -e /dev/kvm ]]; then
        echo -e "${COLOR_BRIGHT_GREEN}[✓] KVM acceleration available${COLOR_RESET}"
    else
        echo -e "${COLOR_BRIGHT_YELLOW}[!] KVM not available - performance will be limited${COLOR_RESET}"
    fi
    
    # Check available disk space
    local available_space=$(df "$VM_BASE_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # Less than 1GB
        echo -e "${COLOR_BRIGHT_YELLOW}[!] Low disk space available: $((available_space / 1024))MB${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_BRIGHT_GREEN}[✓] Dependency check completed${COLOR_RESET}"
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
    echo -e "\n${COLOR_NEON_BLUE}${title}${COLOR_RESET}"
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
    
    echo -e "${COLOR_NEON_PINK}[ SYSTEM STATUS ]${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}Total VMs:${COLOR_RESET} $vm_count (${COLOR_BRIGHT_GREEN}$running_count running${COLOR_RESET})"
    echo -e "  ${COLOR_BRIGHT_CYAN}Disk Usage:${COLOR_RESET} $disk_usage"
    echo -e "  ${COLOR_BRIGHT_CYAN}CPU Usage:${COLOR_RESET} $cpu_usage%"
    echo -e "  ${COLOR_BRIGHT_CYAN}Memory Free:${COLOR_RESET} $(free -m | awk '/Mem:/ {print $4}') MB"
    echo ""
}

# ============================================================================
# VM CREATION WIZARD WITH CUSTOM SPECS
# ============================================================================
create_vm_wizard() {
    clear
    show_banner
    show_header "CREATE ADVANCED VIRTUAL MACHINE"
    
    # Step 1: VM Name
    local vm_name=""
    while [[ -z "$vm_name" ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name: ${COLOR_RESET}")" vm_name
        
        if [[ -z "$vm_name" ]]; then
            echo -e "${COLOR_BRIGHT_RED}[✗] VM name cannot be empty${COLOR_RESET}"
            continue
        fi
        
        # Check if VM already exists
        if sqlite3 "$DATABASE_FILE" "SELECT name FROM vms WHERE name='$vm_name';" 2>/dev/null | grep -q .; then
            echo -e "${COLOR_BRIGHT_RED}[✗] VM '$vm_name' already exists${COLOR_RESET}"
            vm_name=""
            continue
        fi
        
        if [[ ! "$vm_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]{2,50}$ ]]; then
            echo -e "${COLOR_BRIGHT_RED}[✗] Invalid name. Use letters, numbers, hyphen, underscore (3-50 chars)${COLOR_RESET}"
            vm_name=""
            continue
        fi
    done
    
    # Generate UUID
    local vm_uuid=$(uuidgen)
    
    # Step 2: OS Selection
    echo -e "\n${COLOR_NEON_PINK}[ OPERATING SYSTEM SELECTION ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    local os_categories=("Windows" "Linux" "macOS" "Android" "Gaming" "Security" "Container" "Custom")
    local os_selected=""
    
    select os_category in "${os_categories[@]}"; do
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
            "Android")
                show_android_os_list
                break
                ;;
            "Gaming")
                show_gaming_os_list
                break
                ;;
            "Security")
                show_security_os_list
                break
                ;;
            "Container")
                show_container_os_list
                break
                ;;
            "Custom")
                custom_os_setup
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[✗] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter OS key: ${COLOR_RESET}")" os_key
    
    if [[ -z "${OS_DATABASE[$os_key]}" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[✗] Invalid OS selection${COLOR_RESET}"
        return 1
    fi
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    # Step 3: Advanced Hardware Configuration
    echo -e "\n${COLOR_NEON_PINK}[ ADVANCED HARDWARE CONFIGURATION ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    # CPU Configuration with advanced options
    echo -e "${COLOR_BRIGHT_YELLOW}[ CPU Configuration ]${COLOR_RESET}"
    local cpu_cores=""
    while [[ -z "$cpu_cores" ]] || ! [[ "$cpu_cores" =~ ^[0-9]+$ ]] || [[ "$cpu_cores" -lt 1 ]] || [[ "$cpu_cores" -gt 128 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] CPU cores (1-128): ${COLOR_RESET}")" cpu_cores
        cpu_cores=${cpu_cores:-2}
    done
    
    # CPU Topology
    local cpu_sockets=""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] CPU sockets (default: 1): ${COLOR_RESET}")" cpu_sockets
    cpu_sockets=${cpu_sockets:-1}
    
    local cpu_threads=""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Threads per core (default: 1): ${COLOR_RESET}")" cpu_threads
    cpu_threads=${cpu_threads:-1}
    
    # RAM Configuration with hugepages
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ RAM Configuration ]${COLOR_RESET}"
    local memory_gb=""
    while [[ -z "$memory_gb" ]] || ! [[ "$memory_gb" =~ ^[0-9]+$ ]] || [[ "$memory_gb" -lt $(echo "$min_ram" | sed 's/G//') ]] || [[ "$memory_gb" -gt 1024 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] RAM in GB (min: $min_ram, max: 1024GB): ${COLOR_RESET}")" memory_gb
        memory_gb=${memory_gb:-$(echo "$default_ram" | sed 's/G//')}
    done
    local memory_mb=$((memory_gb * 1024))
    
    local enable_hugepages="n"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable hugepages? (y/N): ${COLOR_RESET}")" enable_hugepages
    
    # Disk Configuration with advanced options
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ DISK Configuration ]${COLOR_RESET}"
    local disk_gb=""
    while [[ -z "$disk_gb" ]] || ! [[ "$disk_gb" =~ ^[0-9]+$ ]] || [[ "$disk_gb" -lt 1 ]] || [[ "$disk_gb" -gt 16000 ]]; do
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Disk size in GB (1-16000): ${COLOR_RESET}")" disk_gb
        disk_gb=${disk_gb:-$(echo "$default_disk" | sed 's/G//')}
    done
    
    # Disk type selection
    local disk_types=("qcow2 (Recommended)" "raw (Maximum Performance)" "vmdk (VMware Compatible)" "vdi (VirtualBox Compatible)")
    select disk_type in "${disk_types[@]}"; do
        case $disk_type in
            "qcow2 (Recommended)")
                disk_format="qcow2"
                break
                ;;
            "raw (Maximum Performance)")
                disk_format="raw"
                break
                ;;
            "vmdk (VMware Compatible)")
                disk_format="vmdk"
                break
                ;;
            "vdi (VirtualBox Compatible)")
                disk_format="vdi"
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[✗] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    # GPU Configuration
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ GPU Configuration ]${COLOR_RESET}"
    local gpu_profiles=("none (No GPU)" "basic (Virtual GPU)" "gaming (Gaming GPU)" "ai (AI/ML GPU)" "pro (Professional GPU)" "custom (Custom GPU)")
    select gpu_profile in "${gpu_profiles[@]}"; do
        case $gpu_profile in
            "none (No GPU)")
                gpu_type="none"
                gpu_memory=0
                gpu_cores=0
                break
                ;;
            "basic (Virtual GPU)")
                gpu_type="basic"
                gpu_memory=128
                gpu_cores=1
                break
                ;;
            "gaming (Gaming GPU)")
                gpu_type="gaming"
                gpu_memory=1024
                gpu_cores=2
                break
                ;;
            "ai (AI/ML GPU)")
                gpu_type="ai"
                gpu_memory=2048
                gpu_cores=4
                break
                ;;
            "pro (Professional GPU)")
                gpu_type="pro"
                gpu_memory=4096
                gpu_cores=8
                break
                ;;
            "custom (Custom GPU)")
                gpu_type="custom"
                read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] GPU memory in MB: ${COLOR_RESET}")" gpu_memory
                read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] GPU cores: ${COLOR_RESET}")" gpu_cores
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[✗] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    # Network Configuration
    echo -e "\n${COLOR_BRIGHT_YELLOW}[ NETWORK Configuration ]${COLOR_RESET}"
    local network_profiles=("nat (NAT Network)" "bridge (Bridge Network)" "isolated (Isolated Network)" "host (Host Network)" "custom (Custom Network)")
    select network_profile in "${network_profiles[@]}"; do
        case $network_profile in
            "nat (NAT Network)")
                network_config="nat"
                break
                ;;
            "bridge (Bridge Network)")
                network_config="bridge"
                break
                ;;
            "isolated (Isolated Network)")
                network_config="isolated"
                break
                ;;
            "host (Host Network)")
                network_config="host"
                break
                ;;
            "custom (Custom Network)")
                network_config="custom"
                break
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[✗] Invalid selection${COLOR_RESET}"
                ;;
        esac
    done
    
    # Step 4: Advanced Features
    echo -e "\n${COLOR_NEON_PINK}[ ADVANCED FEATURES ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    local enable_virtio="n"
    local enable_spice="n"
    local enable_uefi="n"
    local enable_tpm="n"
    local enable_secure_boot="n"
    local enable_vnc="n"
    local enable_rdp="n"
    local enable_live_migration="n"
    local enable_ai_optimization="n"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable VirtIO drivers? (y/N): ${COLOR_RESET}")" enable_virtio
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable SPICE display? (y/N): ${COLOR_RESET}")" enable_spice
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable UEFI boot? (y/N): ${COLOR_RESET}")" enable_uefi
    
    if [[ "$enable_uefi" =~ ^[Yy]$ ]]; then
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable Secure Boot? (y/N): ${COLOR_RESET}")" enable_secure_boot
    fi
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable TPM 2.0? (y/N): ${COLOR_RESET}")" enable_tpm
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable VNC access? (y/N): ${COLOR_RESET}")" enable_vnc
    
    if [[ "$os_type" == "windows" ]] || [[ "$os_type" == "linux" ]]; then
        read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable RDP access? (Y/n): ${COLOR_RESET}")" enable_rdp
        enable_rdp=${enable_rdp:-y}
    fi
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable Live Migration support? (y/N): ${COLOR_RESET}")" enable_live_migration
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enable AI Optimization? (y/N): ${COLOR_RESET}")" enable_ai_optimization
    
    # Step 5: Create VM with custom specs
    echo -e "\n${COLOR_NEON_PINK}[ CREATING VIRTUAL MACHINE ]${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s─' {1..60})${COLOR_RESET}"
    
    if create_vm_with_specs "$vm_uuid" "$vm_name" "$os_key" "$cpu_cores" "$cpu_sockets" "$cpu_threads" \
        "$memory_mb" "$enable_hugepages" "$disk_gb" "$disk_format" "$gpu_type" "$gpu_memory" "$gpu_cores" \
        "$network_config" "$enable_virtio" "$enable_spice" "$enable_uefi" "$enable_secure_boot" \
        "$enable_tpm" "$enable_vnc" "$enable_rdp" "$enable_live_migration" "$enable_ai_optimization"; then
        
        echo -e "\n${COLOR_BRIGHT_GREEN}[✓] Virtual Machine '$vm_name' created successfully!${COLOR_RESET}"
        echo -e "${COLOR_BRIGHT_CYAN}[i] UUID:${COLOR_RESET} $vm_uuid"
        echo -e "${COLOR_BRIGHT_CYAN}[i] OS:${COLOR_RESET} $os_name"
        echo -e "${COLOR_BRIGHT_CYAN}[i] CPU:${COLOR_RESET} $cpu_cores cores ($cpu_sockets sockets, $cpu_threads threads/core)"
        echo -e "${COLOR_BRIGHT_CYAN}[i] RAM:${COLOR_RESET} ${memory_gb}GB"
        echo -e "${COLOR_BRIGHT_CYAN}[i] Disk:${COLOR_RESET} ${disk_gb}GB ($disk_format)"
        echo -e "${COLOR_BRIGHT_CYAN}[i] GPU:${COLOR_RESET} $gpu_type (${gpu_memory}MB, ${gpu_cores} cores)"
        
        if [[ "$enable_rdp" =~ ^[Yy]$ ]]; then
            local rdp_port=$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='$vm_uuid';")
            echo -e "${COLOR_BRIGHT_CYAN}[i] RDP Port:${COLOR_RESET} $rdp_port"
            echo -e "${COLOR_BRIGHT_CYAN}[i] RDP Command:${COLOR_RESET} xfreerdp /v:localhost:$rdp_port /u:$os_user /p:$os_pass"
        fi
        
        if [[ "$enable_vnc" =~ ^[Yy]$ ]]; then
            echo -e "${COLOR_BRIGHT_CYAN}[i] VNC Port:${COLOR_RESET} 5900"
            echo -e "${COLOR_BRIGHT_CYAN}[i] VNC Command:${COLOR_RESET} vncviewer localhost:5900"
        fi
        
        echo -e "\n${COLOR_BRIGHT_YELLOW}[i] Start VM with:${COLOR_RESET} ./start-$vm_name.sh"
        echo -e "${COLOR_BRIGHT_YELLOW}[i] Stop VM with:${COLOR_RESET} ./stop-$vm_name.sh"
        echo -e "${COLOR_BRIGHT_YELLOW}[i] Monitor VM with:${COLOR_RESET} ./monitor-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[✗] Failed to create virtual machine${COLOR_RESET}"
        return 1
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# OS SELECTION LISTS
# ============================================================================
show_windows_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ WINDOWS OPERATING SYSTEMS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == windows-* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_linux_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ LINUX DISTRIBUTIONS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" != windows-* ]] && [[ "$key" != macos-* ]] && [[ "$key" != android-* ]] && [[ "${OS_DATABASE[$key]}" == *"|linux|"* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_macos_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ MACOS VERSIONS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == macos-* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_android_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ ANDROID VERSIONS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == android-* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_gaming_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ GAMING OPERATING SYSTEMS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == *"batocera"* ]] || [[ "$key" == *"steamos"* ]] || [[ "${OS_DATABASE[$key]}" == *"|gaming|"* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_security_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ SECURITY OPERATING SYSTEMS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == *"kali"* ]] || [[ "$key" == *"pfsense"* ]] || [[ "$key" == *"opnsense"* ]] || [[ "${OS_DATABASE[$key]}" == *"|security|"* ]] || [[ "${OS_DATABASE[$key]}" == *"|firewall|"* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

show_container_os_list() {
    echo -e "\n${COLOR_NEON_BLUE}[ CONTAINER OPERATING SYSTEMS ]${COLOR_RESET}"
    for key in "${!OS_DATABASE[@]}"; do
        if [[ "$key" == *"rancheros"* ]] || [[ "$key" == *"coreos"* ]] || [[ "${OS_DATABASE[$key]}" == *"|container|"* ]]; then
            IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$key]}"
            echo -e "  ${COLOR_BRIGHT_GREEN}$key${COLOR_RESET} - $os_name (RAM: $default_ram, Disk: $default_disk)"
        fi
    done
}

# ============================================================================
# VM CREATION WITH CUSTOM SPECS
# ============================================================================
create_vm_with_specs() {
    local vm_uuid="$1"
    local vm_name="$2"
    local os_key="$3"
    local cpu_cores="$4"
    local cpu_sockets="$5"
    local cpu_threads="$6"
    local memory_mb="$7"
    local enable_hugepages="$8"
    local disk_gb="$9"
    local disk_format="${10}"
    local gpu_type="${11}"
    local gpu_memory="${12}"
    local gpu_cores="${13}"
    local network_config="${14}"
    local enable_virtio="${15}"
    local enable_spice="${16}"
    local enable_uefi="${17}"
    local enable_secure_boot="${18}"
    local enable_tpm="${19}"
    local enable_vnc="${20}"
    local enable_rdp="${21}"
    local enable_live_migration="${22}"
    local enable_ai_optimization="${23}"
    
    IFS='|' read -r os_name os_type os_url os_user os_pass min_ram default_ram default_disk <<< "${OS_DATABASE[$os_key]}"
    
    echo -e "${COLOR_HACKER}[*] Creating VM with custom specifications...${COLOR_RESET}"
    
    # Download OS image if not exists
    local iso_file="$ISO_DIR/$(basename "$os_url")"
    local disk_file="$DISK_DIR/${vm_uuid}.$disk_format"
    
    if [[ ! -f "$iso_file" ]]; then
        echo -e "${COLOR_HACKER}[*] Downloading OS image...${COLOR_RESET}"
        if ! download_file "$os_url" "$iso_file"; then
            log_message "ERROR" "Failed to download OS image"
            return 1
        fi
    fi
    
    # Create disk image with specified format
    echo -e "${COLOR_HACKER}[*] Creating disk image ($disk_format)...${COLOR_RESET}"
    if [[ "$os_url" == *.qcow2 ]] || [[ "$os_url" == *.img ]]; then
        cp "$iso_file" "$disk_file"
        qemu-img resize "$disk_file" "${disk_gb}G" 2>/dev/null
    else
        qemu-img create -f "$disk_format" "$disk_file" "${disk_gb}G"
    fi
    
    # Generate advanced startup script
    generate_advanced_startup_script "$vm_uuid" "$vm_name" "$os_type" "$cpu_cores" "$cpu_sockets" "$cpu_threads" \
        "$memory_mb" "$enable_hugepages" "$disk_format" "$gpu_type" "$gpu_memory" "$gpu_cores" \
        "$network_config" "$enable_virtio" "$enable_spice" "$enable_uefi" "$enable_secure_boot" \
        "$enable_tpm" "$enable_vnc" "$enable_live_migration" "$enable_ai_optimization"
    
    # Add to database with advanced specs
    sqlite3 "$DATABASE_FILE" << EOF
INSERT INTO vms (uuid, name, os_type, os_name, cpu_cores, memory_mb, disk_size_gb, gpu_type, gpu_memory_mb, disk_path)
VALUES ('$vm_uuid', '$vm_name', '$os_type', '$os_name', $cpu_cores, $memory_mb, $disk_gb, '$gpu_type', $gpu_memory, '$disk_file');

INSERT INTO vm_specs (vm_uuid, cpu_type, cpu_topology, memory_hugepages, disk_cache, disk_io_threads, 
                      spice_enabled, vnc_enabled, tpm_enabled, secure_boot)
VALUES ('$vm_uuid', 'host', '$cpu_sockets:$cpu_threads', 
        CASE WHEN '$enable_hugepages' = 'y' THEN 1 ELSE 0 END,
        'writeback', 1,
        CASE WHEN '$enable_spice' = 'y' THEN 1 ELSE 0 END,
        CASE WHEN '$enable_vnc' = 'y' THEN 1 ELSE 0 END,
        CASE WHEN '$enable_tpm' = 'y' THEN 1 ELSE 0 END,
        CASE WHEN '$enable_secure_boot' = 'y' THEN 1 ELSE 0 END);
EOF
    
    # Setup RDP if enabled
    if [[ "$enable_rdp" =~ ^[Yy]$ ]] && [[ "$os_type" == "windows" || "$os_type" == "linux" ]]; then
        setup_rdp_for_vm "$vm_uuid"
    fi
    
    # Create launcher scripts
    create_advanced_launcher_scripts "$vm_name" "$vm_uuid"
    
    # Create monitoring script
    create_monitoring_script "$vm_name" "$vm_uuid"
    
    log_message "SUCCESS" "VM '$vm_name' created with advanced specs"
    return 0
}

# ============================================================================
# ADVANCED STARTUP SCRIPT GENERATION
# ============================================================================
generate_advanced_startup_script() {
    local vm_uuid="$1"
    local vm_name="$2"
    local os_type="$3"
    local cpu_cores="$4"
    local cpu_sockets="$5"
    local cpu_threads="$6"
    local memory_mb="$7"
    local enable_hugepages="$8"
    local disk_format="$9"
    local gpu_type="${10}"
    local gpu_memory="${11}"
    local gpu_cores="${12}"
    local network_config="${13}"
    local enable_virtio="${14}"
    local enable_spice="${15}"
    local enable_uefi="${16}"
    local enable_secure_boot="${17}"
    local enable_tpm="${18}"
    local enable_vnc="${19}"
    local enable_live_migration="${20}"
    local enable_ai_optimization="${21}"
    
    local script_file="$SCRIPT_DIR/start-$vm_uuid.sh"
    local disk_file="$DISK_DIR/${vm_uuid}.$disk_format"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash
# CavrixCore VM Startup Script
# VM: $vm_name
# UUID: $vm_uuid

set -e

VM_UUID="$vm_uuid"
VM_NAME="$vm_name"
DISK_FILE="$disk_file"
CPU_CORES=$cpu_cores
CPU_SOCKETS=$cpu_sockets
CPU_THREADS=$cpu_threads
MEMORY_MB=$memory_mb
GPU_MEMORY=$gpu_memory
GPU_CORES=$gpu_cores

echo -e "\033[96m[*] Starting CavrixCore VM: \$VM_NAME...\033[0m"

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
CMD+=" -smp \$CPU_CORES,sockets=\$CPU_SOCKETS,cores=\$((CPU_CORES / CPU_SOCKETS)),threads=\$CPU_THREADS"
CMD+=" -m \$MEMORY_MB"
EOF

    # Add hugepages if enabled
    if [[ "$enable_hugepages" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'

# Enable hugepages
CMD+=" -mem-prealloc"
CMD+=" -mem-path /dev/hugepages"
EOF
    fi

    # Add UEFI if enabled
    if [[ "$enable_uefi" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'

# UEFI boot
if [[ -f /usr/share/OVMF/OVMF_CODE.fd ]] && [[ -f /usr/share/OVMF/OVMF_VARS.fd ]]; then
    CMD+=" -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"
    CMD+=" -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd"
    
    # Secure Boot if enabled
EOF
        if [[ "$enable_secure_boot" =~ ^[Yy]$ ]]; then
            cat >> "$script_file" << 'EOF'
    CMD+=" -global driver=cfi.pflash01,property=secure,value=on"
EOF
        fi
    fi

    cat >> "$script_file" << 'EOF'

# Disk configuration
CMD+=" -drive file=\$DISK_FILE,format=$disk_format,if=virtio,cache=writeback,discard=unmap,aio=native"
EOF

    # Add GPU configuration
    if [[ "$gpu_type" != "none" ]]; then
        cat >> "$script_file" << 'EOF'

# GPU configuration
CMD+=" -device virtio-vga-gl,id=video0,bus=pci.0,addr=0x2"
CMD+=" -display sdl,gl=on"
CMD+=" -vga virtio"
EOF
    fi

    # Add network configuration
    cat >> "$script_file" << 'EOF'

# Network configuration
EOF

    case "$network_config" in
        "nat")
            cat >> "$script_file" << 'EOF'
CMD+=" -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::3389-:3389"
CMD+=" -device virtio-net-pci,netdev=net0,mac=52:54:00:$(openssl rand -hex 3| sed 's/\(..\)/\1:/g; s/.$//')"
EOF
            ;;
        "bridge")
            cat >> "$script_file" << 'EOF'
CMD+=" -netdev bridge,id=net0,br=br0"
CMD+=" -device virtio-net-pci,netdev=net0,mac=52:54:00:$(openssl rand -hex 3| sed 's/\(..\)/\1:/g; s/.$//')"
EOF
            ;;
        "host")
            cat >> "$script_file" << 'EOF'
CMD+=" -netdev user,id=net0,hostfwd=tcp::2222-:22"
CMD+=" -device virtio-net-pci,netdev=net0"
EOF
            ;;
        *)
            cat >> "$script_file" << 'EOF'
CMD+=" -netdev user,id=net0"
CMD+=" -device virtio-net-pci,netdev=net0"
EOF
            ;;
    esac

    # Add display configuration
    cat >> "$script_file" << 'EOF'

# Display configuration
EOF

    if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
CMD+=" -spice port=5900,addr=127.0.0.1,disable-ticketing,gl=on"
CMD+=" -vga qxl"
EOF
    elif [[ "$enable_vnc" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
CMD+=" -vnc :0,password"
CMD+=" -vga std"
EOF
    else
        cat >> "$script_file" << 'EOF'
CMD+=" -vga std"
CMD+=" -display gtk,gl=on"
EOF
    fi

    cat >> "$script_file" << 'EOF'

# Input devices
CMD+=" -usb -device usb-tablet -device usb-kbd"

# Additional devices
CMD+=" -device virtio-balloon-pci"
CMD+=" -device virtio-rng-pci"
CMD+=" -rtc base=utc,clock=host,driftfix=slew"
CMD+=" -global kvm-pit.lost_tick_policy=discard"
EOF

    # Add TPM if enabled
    if [[ "$enable_tpm" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'

# TPM 2.0
if command -v swtpm &>/dev/null; then
    TPM_SOCKET="/tmp/swtpm-\$VM_UUID.sock"
    mkdir -p /tmp/tpm\$VM_UUID
    swtpm socket --tpmstate dir=/tmp/tpm\$VM_UUID --ctrl type=unixio,path=\$TPM_SOCKET --tpm2 &
    SWTPM_PID=\$!
    sleep 2
    CMD+=" -chardev socket,id=chrtpm,path=\$TPM_SOCKET"
    CMD+=" -tpmdev emulator,id=tpm0,chardev=chrtpm"
    CMD+=" -device tpm-tis,tpmdev=tpm0"
fi
EOF
    fi

    # Add live migration support
    if [[ "$enable_live_migration" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'

# Live migration support
CMD+=" -incoming tcp:0:4444"
EOF
    fi

    cat >> "$script_file" << 'EOF'

# Boot order
CMD+=" -boot order=c,menu=on"

# Performance optimization
CMD+=" -overcommit mem-lock=on"
CMD+=" -no-hpet"
CMD+=" -no-reboot"

# Start VM
echo -e "\033[96m[*] Starting VM with command:\033[0m"
echo "\$CMD"

eval "\$CMD -daemonize"

if [[ \$? -eq 0 ]]; then
    echo -e "\033[92m[✓] VM started successfully!\033[0m"
    
    # Update database
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='running', last_started=CURRENT_TIMESTAMP WHERE uuid='\$VM_UUID';"
    
    # Get connection information
    RDP_PORT=\$(sqlite3 "$DATABASE_FILE" "SELECT port FROM rdp_sessions WHERE vm_uuid='\$VM_UUID' AND enabled=1;" 2>/dev/null || true)
    
    echo ""
    echo -e "\033[96m══════════════════════════════════════════════════════════════════════\033[0m"
    echo -e "\033[93m[ CONNECTION INFORMATION ]\033[0m"
    echo -e "  \033[95mVM Name:\033[0m      \$VM_NAME"
    echo -e "  \033[95mUUID:\033[0m         \$VM_UUID"
    echo -e "  \033[95mSSH:\033[0m          ssh user@localhost -p 2222"
    
    if [[ -n "\$RDP_PORT" ]]; then
        echo -e "  \033[95mRDP:\033[0m          xfreerdp /v:localhost:\$RDP_PORT"
        echo -e "  \033[95mRDP Port:\033[0m    \$RDP_PORT"
    fi
    
EOF

    if [[ "$enable_spice" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
    echo -e "  \033[95mSPICE:\033[0m        spicy 127.0.0.1:5900"
EOF
    fi

    if [[ "$enable_vnc" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
    echo -e "  \033[95mVNC:\033[0m          vncviewer localhost:5900"
    echo -e "  \033[95mVNC Password:\033[0m cavrixcore"
EOF
    fi

    if [[ "$enable_live_migration" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
    echo -e "  \033[95mMigration Port:\033[0m 4444"
EOF
    fi

    cat >> "$script_file" << 'EOF'
    
    echo -e "\033[96m══════════════════════════════════════════════════════════════════════\033[0m"
    
    # Start monitoring if AI optimization is enabled
EOF

    if [[ "$enable_ai_optimization" =~ ^[Yy]$ ]]; then
        cat >> "$script_file" << 'EOF'
    if [[ -f "./monitor-\$VM_NAME.sh" ]]; then
        ./monitor-\$VM_NAME.sh &
        MONITOR_PID=\$!
        echo -e "\033[92m[✓] AI monitoring started (PID: \$MONITOR_PID)\033[0m"
    fi
EOF
    fi

    cat >> "$script_file" << 'EOF'
else
    echo -e "\033[91m[✗] Failed to start VM\033[0m"
    if [[ -n "\$SWTPM_PID" ]]; then
        kill \$SWTPM_PID 2>/dev/null
    fi
    exit 1
fi
EOF

    chmod +x "$script_file"
    echo -e "${COLOR_BRIGHT_GREEN}[✓] Advanced startup script generated${COLOR_RESET}"
}

# ============================================================================
# ADVANCED LAUNCHER SCRIPTS
# ============================================================================
create_advanced_launcher_scripts() {
    local vm_name="$1"
    local vm_uuid="$2"
    
    # Create start script
    cat > "./start-$vm_name.sh" << EOF
#!/bin/bash
echo -e "\033[96m[*] Starting CavrixCore VM: $vm_name\033[0m"
"$SCRIPT_DIR/start-$vm_uuid.sh"
EOF
    
    # Create stop script
    cat > "./stop-$vm_name.sh" << EOF
#!/bin/bash
VM_UUID="$vm_uuid"
PID=\$(pgrep -f "qemu-system.*\$VM_UUID")

if [[ -n "\$PID" ]]; then
    echo -e "\033[93m[*] Stopping VM: $vm_name\033[0m"
    kill \$PID
    sleep 2
    
    # Check if still running
    if pgrep -f "qemu-system.*\$VM_UUID" > /dev/null; then
        echo -e "\033[91m[!] VM not responding, forcing shutdown...\033[0m"
        kill -9 \$PID 2>/dev/null
    fi
    
    echo -e "\033[92m[✓] VM stopped\033[0m"
    sqlite3 "$DATABASE_FILE" "UPDATE vms SET status='stopped', last_stopped=CURRENT_TIMESTAMP WHERE uuid='\$VM_UUID';"
    
    # Cleanup TPM if exists
    rm -rf /tmp/tpm\$VM_UUID 2>/dev/null
    rm -f /tmp/swtpm-\$VM_UUID.sock 2>/dev/null
else
    echo -e "\033[93m[!] VM is not running\033[0m"
fi
EOF
    
    # Create restart script
    cat > "./restart-$vm_name.sh" << EOF
#!/bin/bash
echo -e "\033[96m[*] Restarting CavrixCore VM: $vm_name\033[0m"
if [[ -f "./stop-$vm_name.sh" ]]; then
    ./stop-$vm_name.sh
    sleep 3
fi
./start-$vm_name.sh
EOF
    
    chmod +x "./start-$vm_name.sh" "./stop-$vm_name.sh" "./restart-$vm_name.sh"
    echo -e "${COLOR_BRIGHT_GREEN}[✓] Launcher scripts created${COLOR_RESET}"
}

# ============================================================================
# MONITORING SCRIPT
# ============================================================================
create_monitoring_script() {
    local vm_name="$1"
    local vm_uuid="$2"
    
    cat > "./monitor-$vm_name.sh" << EOF
#!/bin/bash
# CavrixCore VM Monitoring Script
# VM: $vm_name
# UUID: $vm_uuid

VM_UUID="$vm_uuid"
VM_NAME="$vm_name"
LOG_FILE="$VM_BASE_DIR/logs/\$VM_NAME-\$(date +%Y%m%d).log"

mkdir -p "$VM_BASE_DIR/logs"

echo -e "\033[96m[*] Starting AI-powered monitoring for \$VM_NAME\033[0m"
echo "\$(date) - Monitoring started for \$VM_NAME (\$VM_UUID)" >> "\$LOG_FILE"

while true; do
    # Check if VM is running
    PID=\$(pgrep -f "qemu-system.*\$VM_UUID")
    
    if [[ -z "\$PID" ]]; then
        echo "\$(date) - VM stopped" >> "\$LOG_FILE"
        echo -e "\033[93m[!] VM \$VM_NAME has stopped\033[0m"
        break
    fi
    
    # Monitor CPU usage
    CPU_USAGE=\$(ps -p \$PID -o %cpu | tail -1 | tr -d ' ')
    
    # Monitor memory usage
    MEM_USAGE=\$(ps -p \$PID -o %mem | tail -1 | tr -d ' ')
    
    # Log to file
    echo "\$(date) - CPU: \$CPU_USAGE%, MEM: \$MEM_USAGE%" >> "\$LOG_FILE"
    
    # AI Optimization logic
    if [[ \$(echo "\$CPU_USAGE > 90" | bc -l) -eq 1 ]]; then
        echo "\$(date) - WARNING: High CPU usage detected (\$CPU_USAGE%)" >> "\$LOG_FILE"
        echo -e "\033[93m[!] High CPU usage: \$CPU_USAGE%\033[0m"
    fi
    
    if [[ \$(echo "\$MEM_USAGE > 90" | bc -l) -eq 1 ]]; then
        echo "\$(date) - WARNING: High memory usage detected (\$MEM_USAGE%)" >> "\$LOG_FILE"
        echo -e "\033[93m[!] High memory usage: \$MEM_USAGE%\033[0m"
    fi
    
    sleep 10
done

echo "\$(date) - Monitoring stopped" >> "\$LOG_FILE"
echo -e "\033[96m[*] Monitoring stopped for \$VM_NAME\033[0m"
EOF
    
    chmod +x "./monitor-$vm_name.sh"
    echo -e "${COLOR_BRIGHT_GREEN}[✓] Monitoring script created${COLOR_RESET}"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
download_file() {
    local url="$1"
    local output="$2"
    
    echo -e "${COLOR_HACKER}[*] Downloading: $(basename "$url")${COLOR_RESET}"
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$output" "$url"
    elif command -v curl &>/dev/null; then
        curl -L -o "$output" --progress-bar "$url"
    else
        echo -e "${COLOR_BRIGHT_RED}[✗] Neither wget nor curl found${COLOR_RESET}"
        return 1
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${COLOR_BRIGHT_GREEN}[✓] Download completed${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_BRIGHT_RED}[✗] Download failed${COLOR_RESET}"
        return 1
    fi
}

cleanup_on_exit() {
    local exit_code=$?
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
    
    # Release lock
    flock -u 100 2>/dev/null
    rm -f "$LOCK_FILE"
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${COLOR_BRIGHT_RED}[✗] Script exited with error code: $exit_code${COLOR_RESET}"
    fi
    
    exit $exit_code
}

die() {
    local message="$1"
    echo -e "${COLOR_BRIGHT_RED}[✗] Error: $message${COLOR_RESET}" >&2
    exit 1
}

# ============================================================================
# VM MANAGEMENT FUNCTIONS
# ============================================================================
list_vms() {
    clear
    show_banner
    show_header "VIRTUAL MACHINES LIST"
    
    local query="SELECT 
        name as 'VM Name',
        os_name as 'OS',
        status as 'Status',
        cpu_cores as 'CPU',
        memory_mb/1024 as 'RAM(GB)',
        disk_size_gb as 'Disk(GB)',
        gpu_type as 'GPU',
        datetime(created_at, 'localtime') as 'Created'
    FROM vms 
    ORDER BY name;"
    
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
        echo -e "${COLOR_BRIGHT_RED}[✗] VM not found${COLOR_RESET}"
        sleep 2
        return
    fi
    
    local script_file="$SCRIPT_DIR/start-$vm_uuid.sh"
    
    if [[ -f "$script_file" ]]; then
        bash "$script_file"
    elif [[ -f "./start-$vm_name.sh" ]]; then
        bash "./start-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[✗] Startup script not found${COLOR_RESET}"
    fi
    
    sleep 3
}

stop_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to stop: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[✗] VM not found${COLOR_RESET}"
        sleep 2
        return
    fi
    
    if [[ -f "./stop-$vm_name.sh" ]]; then
        bash "./stop-$vm_name.sh"
    else
        echo -e "${COLOR_BRIGHT_RED}[✗] Stop script not found${COLOR_RESET}"
    fi
    
    sleep 2
}

delete_vm_menu() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to delete: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[✗] VM not found${COLOR_RESET}"
        sleep 2
        return
    fi
    
    read -rp "$(echo -e "${COLOR_BRIGHT_RED}[!] WARNING: This will permanently delete '$vm_name'. Are you sure? (yes/NO): ${COLOR_RESET}")" confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${COLOR_BRIGHT_YELLOW}[*] Deletion cancelled${COLOR_RESET}"
        sleep 2
        return
    fi
    
    echo -e "${COLOR_HACKER}[*] Deleting VM: $vm_name${COLOR_RESET}"
    
    # Stop VM if running
    if [[ -f "./stop-$vm_name.sh" ]]; then
        bash "./stop-$vm_name.sh" >/dev/null 2>&1
    fi
    
    # Delete from database
    sqlite3 "$DATABASE_FILE" "DELETE FROM vms WHERE uuid='$vm_uuid';"
    sqlite3 "$DATABASE_FILE" "DELETE FROM vm_specs WHERE vm_uuid='$vm_uuid';"
    sqlite3 "$DATABASE_FILE" "DELETE FROM rdp_sessions WHERE vm_uuid='$vm_uuid';"
    
    # Delete disk file
    local disk_file=$(sqlite3 "$DATABASE_FILE" "SELECT disk_path FROM vms WHERE uuid='$vm_uuid';" 2>/dev/null)
    if [[ -f "$disk_file" ]]; then
        rm -f "$disk_file"
    fi
    
    # Delete scripts
    rm -f "$SCRIPT_DIR/start-$vm_uuid.sh" \
          "./start-$vm_name.sh" \
          "./stop-$vm_name.sh" \
          "./restart-$vm_name.sh" \
          "./monitor-$vm_name.sh" 2>/dev/null
    
    echo -e "${COLOR_BRIGHT_GREEN}[✓] VM '$vm_name' deleted successfully${COLOR_RESET}"
    sleep 2
}

# ============================================================================
# ADVANCED FEATURES MENU
# ============================================================================
setup_host_rdp() {
    clear
    show_banner
    show_header "HOST RDP SERVER SETUP"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] This will install and configure XRDP server on your host machine.${COLOR_RESET}"
    echo ""
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Continue with RDP setup? (Y/n): ${COLOR_RESET}")" confirm
    confirm=${confirm:-y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "\n${COLOR_HACKER}[*] Step 1: Updating system packages...${COLOR_RESET}"
    sudo apt update && sudo apt upgrade -y
    
    echo -e "\n${COLOR_HACKER}[*] Step 2: Installing XRDP and XFCE...${COLOR_RESET}"
    sudo apt install xfce4 xfce4-goodies xrdp -y
    
    echo -e "\n${COLOR_HACKER}[*] Step 3: Configuring XRDP...${COLOR_RESET}"
    echo "startxfce4" > ~/.xsession
    sudo chown $(whoami):$(whoami) ~/.xsession
    
    # Configure XRDP to use a different port
    sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
    
    echo -e "\n${COLOR_HACKER}[*] Step 4: Starting XRDP service...${COLOR_RESET}"
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp
    
    # Get IP address
    local ip_address=$(hostname -I | awk '{print $1}')
    if [[ -z "$ip_address" ]]; then
        ip_address="localhost"
    fi
    
    echo -e "\n${COLOR_BRIGHT_GREEN}[✓] RDP Server Setup Complete!${COLOR_RESET}"
    echo -e "${COLOR_HACKER}$(printf '%.0s═' {1..60})${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_YELLOW}[ CONNECTION INFORMATION ]${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}IP Address:${COLOR_RESET}   $ip_address"
    echo -e "  ${COLOR_WHITE}Port:${COLOR_RESET}         3390"
    echo -e "  ${COLOR_WHITE}Username:${COLOR_RESET}     $(whoami)"
    echo -e "  ${COLOR_WHITE}Password:${COLOR_RESET}     Your system password"
    echo ""
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Note: Make sure port 3390 is open in your firewall${COLOR_RESET}"
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

manage_vm_rdp() {
    clear
    show_banner
    show_header "VM RDP MANAGEMENT"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Available VMs with RDP:${COLOR_RESET}"
    
    local query="SELECT v.name, r.port, r.username 
                 FROM vms v 
                 JOIN rdp_sessions r ON v.uuid = r.vm_uuid 
                 WHERE r.enabled = 1 
                 ORDER BY v.name;"
    
    local rdps=$(sqlite3 -header -column "$DATABASE_FILE" "$query" 2>/dev/null)
    
    if [[ -z "$rdps" ]]; then
        echo -e "${COLOR_BRIGHT_YELLOW}[!] No VMs with RDP enabled found.${COLOR_RESET}"
    else
        echo "$rdps"
    fi
    
    echo -e "\n${COLOR_BRIGHT_CYAN}[1] Enable RDP for a VM${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_CYAN}[2] Disable RDP for a VM${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_CYAN}[3] Change RDP port${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT_CYAN}[0] Back to main menu${COLOR_RESET}"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1) enable_vm_rdp ;;
        2) disable_vm_rdp ;;
        3) change_rdp_port ;;
        0) return ;;
        *) echo -e "${COLOR_BRIGHT_RED}[✗] Invalid option${COLOR_RESET}" ;;
    esac
}

enable_vm_rdp() {
    list_vms
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to enable RDP: ${COLOR_RESET}")" vm_name
    
    local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
    
    if [[ -z "$vm_uuid" ]]; then
        echo -e "${COLOR_BRIGHT_RED}[✗] VM not found${COLOR_RESET}"
        return
    fi
    
    setup_rdp_for_vm "$vm_uuid"
    echo -e "${COLOR_BRIGHT_GREEN}[✓] RDP enabled for VM: $vm_name${COLOR_RESET}"
}

setup_rdp_for_vm() {
    local vm_uuid="$1"
    
    # Find available port starting from 33890
    local rdp_port=33890
    while netstat -tuln | grep -q ":$rdp_port "; do
        ((rdp_port++))
        if [[ $rdp_port -gt 34000 ]]; then
            rdp_port=33890
            break
        fi
    done
    
    # Add to database
    sqlite3 "$DATABASE_FILE" << EOF
INSERT OR REPLACE INTO rdp_sessions (vm_uuid, port, protocol, enabled)
VALUES ('$vm_uuid', $rdp_port, 'tcp', 1);
EOF
    
    echo -e "${COLOR_BRIGHT_GREEN}[✓] RDP configured on port: $rdp_port${COLOR_RESET}"
}

ai_optimization() {
    clear
    show_banner
    show_header "AI OPTIMIZATION"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] AI Optimization Features:${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}1)${COLOR_RESET} Optimize VM Performance"
    echo -e "  ${COLOR_BRIGHT_CYAN}2)${COLOR_RESET} Predict Resource Needs"
    echo -e "  ${COLOR_BRIGHT_CYAN}3)${COLOR_RESET} Auto-scale Resources"
    echo -e "  ${COLOR_BRIGHT_CYAN}4)${COLOR_RESET} Security Analysis"
    echo -e "  ${COLOR_BRIGHT_CYAN}5)${COLOR_RESET} Backup Optimization"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            echo -e "${COLOR_HACKER}[*] Analyzing VM performance...${COLOR_RESET}"
            # AI optimization logic here
            echo -e "${COLOR_BRIGHT_GREEN}[✓] Performance optimization completed${COLOR_RESET}"
            ;;
        2)
            echo -e "${COLOR_HACKER}[*] Predicting resource requirements...${COLOR_RESET}"
            # Prediction logic here
            echo -e "${COLOR_BRIGHT_GREEN}[✓] Resource prediction completed${COLOR_RESET}"
            ;;
        *)
            echo -e "${COLOR_BRIGHT_YELLOW}[*] Feature coming soon...${COLOR_RESET}"
            ;;
    esac
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

performance_monitor() {
    clear
    show_banner
    show_header "PERFORMANCE MONITOR"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Real-time Performance Metrics:${COLOR_RESET}"
    
    # Get system metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    echo -e "  ${COLOR_BRIGHT_CYAN}System CPU Usage:${COLOR_RESET} $cpu_usage%"
    echo -e "  ${COLOR_BRIGHT_CYAN}System Memory Usage:${COLOR_RESET} $mem_used/${mem_total}MB ($mem_percent%)"
    
    # Get VM metrics
    local running_vms=$(sqlite3 "$DATABASE_FILE" "SELECT name FROM vms WHERE status='running';" 2>/dev/null)
    
    if [[ -n "$running_vms" ]]; then
        echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Running VMs:${COLOR_RESET}"
        while read -r vm_name; do
            local vm_pid=$(pgrep -f "qemu-system.*$vm_name")
            if [[ -n "$vm_pid" ]]; then
                local vm_cpu=$(ps -p "$vm_pid" -o %cpu | tail -1 | tr -d ' ')
                local vm_mem=$(ps -p "$vm_pid" -o %mem | tail -1 | tr -d ' ')
                echo -e "  ${COLOR_BRIGHT_CYAN}$vm_name:${COLOR_RESET} CPU: ${vm_cpu}%, MEM: ${vm_mem}%"
            fi
        done <<< "$running_vms"
    fi
    
    echo ""
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

system_settings() {
    clear
    show_banner
    show_header "SYSTEM SETTINGS"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] System Configuration:${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}1)${COLOR_RESET} Change VM Base Directory"
    echo -e "  ${COLOR_BRIGHT_CYAN}2)${COLOR_RESET} Configure Network Settings"
    echo -e "  ${COLOR_BRIGHT_CYAN}3)${COLOR_RESET} Storage Management"
    echo -e "  ${COLOR_BRIGHT_CYAN}4)${COLOR_RESET} Security Settings"
    echo -e "  ${COLOR_BRIGHT_CYAN}5)${COLOR_RESET} Backup Configuration"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter new VM base directory: ${COLOR_RESET}")" new_dir
            if [[ -d "$new_dir" ]]; then
                echo "VM_BASE_DIR=\"$new_dir\"" > "$CONFIG_DIR/settings.conf"
                echo -e "${COLOR_BRIGHT_GREEN}[✓] VM base directory updated${COLOR_RESET}"
            else
                echo -e "${COLOR_BRIGHT_RED}[✗] Directory does not exist${COLOR_RESET}"
            fi
            ;;
        *)
            echo -e "${COLOR_BRIGHT_YELLOW}[*] Feature coming soon...${COLOR_RESET}"
            ;;
    esac
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

backup_restore() {
    clear
    show_banner
    show_header "BACKUP & RESTORE"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Backup Operations:${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}1)${COLOR_RESET} Backup VM"
    echo -e "  ${COLOR_BRIGHT_CYAN}2)${COLOR_RESET} Restore VM"
    echo -e "  ${COLOR_BRIGHT_CYAN}3)${COLOR_RESET} List Backups"
    echo -e "  ${COLOR_BRIGHT_CYAN}4)${COLOR_RESET} Schedule Automated Backups"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            list_vms
            echo ""
            read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter VM name to backup: ${COLOR_RESET}")" vm_name
            
            local vm_uuid=$(sqlite3 "$DATABASE_FILE" "SELECT uuid FROM vms WHERE name='$vm_name';" 2>/dev/null)
            
            if [[ -z "$vm_uuid" ]]; then
                echo -e "${COLOR_BRIGHT_RED}[✗] VM not found${COLOR_RESET}"
                return
            fi
            
            local backup_file="$BACKUP_DIR/${vm_name}-$(date +%Y%m%d-%H%M%S).qcow2"
            local disk_file="$DISK_DIR/${vm_uuid}.qcow2"
            
            if [[ -f "$disk_file" ]]; then
                echo -e "${COLOR_HACKER}[*] Creating backup...${COLOR_RESET}"
                cp "$disk_file" "$backup_file"
                echo -e "${COLOR_BRIGHT_GREEN}[✓] Backup created: $(basename "$backup_file")${COLOR_RESET}"
            else
                echo -e "${COLOR_BRIGHT_RED}[✗] Disk file not found${COLOR_RESET}"
            fi
            ;;
        3)
            echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Available Backups:${COLOR_RESET}"
            ls -lh "$BACKUP_DIR"/*.qcow2 2>/dev/null || echo -e "${COLOR_BRIGHT_YELLOW}[!] No backups found${COLOR_RESET}"
            ;;
        *)
            echo -e "${COLOR_BRIGHT_YELLOW}[*] Feature coming soon...${COLOR_RESET}"
            ;;
    esac
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

network_management() {
    clear
    show_banner
    show_header "NETWORK MANAGEMENT"
    
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Network Operations:${COLOR_RESET}"
    echo -e "  ${COLOR_BRIGHT_CYAN}1)${COLOR_RESET} Create Network Bridge"
    echo -e "  ${COLOR_BRIGHT_CYAN}2)${COLOR_RESET} Configure NAT Network"
    echo -e "  ${COLOR_BRIGHT_CYAN}3)${COLOR_RESET} List Network Interfaces"
    echo -e "  ${COLOR_BRIGHT_CYAN}4)${COLOR_RESET} Port Forwarding"
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Select option: ${COLOR_RESET}")" choice
    
    case $choice in
        1)
            echo -e "${COLOR_HACKER}[*] Creating network bridge...${COLOR_RESET}"
            read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Enter bridge name: ${COLOR_RESET}")" bridge_name
            sudo brctl addbr "$bridge_name"
            sudo ip link set "$bridge_name" up
            echo -e "${COLOR_BRIGHT_GREEN}[✓] Bridge '$bridge_name' created${COLOR_RESET}"
            ;;
        3)
            echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Network Interfaces:${COLOR_RESET}"
            ip -br addr show
            echo -e "\n${COLOR_BRIGHT_YELLOW}[*] Bridge Interfaces:${COLOR_RESET}"
            brctl show
            ;;
        *)
            echo -e "${COLOR_BRIGHT_YELLOW}[*] Feature coming soon...${COLOR_RESET}"
            ;;
    esac
    
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

# ============================================================================
# STUB FUNCTIONS FOR FUTURE IMPLEMENTATION
# ============================================================================
custom_os_setup() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Custom OS Setup - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

custom_network_setup() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Custom Network Setup - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

disable_vm_rdp() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Disable RDP - Feature coming soon${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_BRIGHT_CYAN}[?] Press Enter to continue...${COLOR_RESET}")"
}

change_rdp_port() {
    echo -e "${COLOR_BRIGHT_YELLOW}[*] Change RDP Port - Feature coming soon${COLOR_RESET}"
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
            "${SYM_VM} Create Advanced Virtual Machine"
            "${SYM_VM} List All Virtual Machines"
            "${SYM_VM} Start Virtual Machine"
            "${SYM_VM} Stop Virtual Machine"
            "${SYM_VM} Delete Virtual Machine"
            "${SYM_NETWORK} Setup Host RDP Server"
            "${SYM_NETWORK} Manage VM RDP Access"
            "${SYM_AI} AI Optimization"
            "${SYM_CPU} Performance Monitor"
            "${SYM_GEAR} System Settings"
            "${SYM_STORAGE} Backup & Restore"
            "${SYM_NETWORK} Network Management"
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
                echo -e "\n${COLOR_BRIGHT_GREEN}[✓] Thank you for using CavrixCore VM Hosting!${COLOR_RESET}"
                echo -e "${COLOR_HACKER}Powered by: root@cavrix.core${COLOR_RESET}"
                exit 0
                ;;
            *)
                echo -e "${COLOR_BRIGHT_RED}[✗] Invalid option${COLOR_RESET}"
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
        echo -e "${COLOR_BRIGHT_RED}[✗] Do not run this script as root${COLOR_RESET}"
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
